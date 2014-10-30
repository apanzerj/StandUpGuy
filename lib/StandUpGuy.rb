require "StandUpGuy/version"
require "zendesk_api"
require "tempfile"
require "haml"
require "launchy"

module StandUpGuy
  module DataMethods
    def date_key(date=:today)
      begin
        date = date == :today ? DateTime.now : DateTime.strptime(date,"%Y-%m-%d")
        date.strftime("%Y-%m-%d")
      rescue ArgumentError
        date = :today
        retry
      end
    end

    def filename
      File.join(StandUpGuy::Core::DATA_ROOT, "standup.json")
    end

    def load_data
      @current_standup = JSON.load(File.open(filename))
    end

    def write_data(current_standup)
      File.open(filename, "w") do |f|
        f << JSON.dump(current_standup)
      end
    end
  end

  class Core
    DATA_ROOT = File.join(ENV["HOME"], ".standupguy")
    def initialize(options)
      @report_available = true
      first_time! unless Dir.exists?(DATA_ROOT)
      if options[:item]
        item = StandUpGuy::Item.new
        item.add_to_today(options[:item])
        item.save
        date = DateTime.now.strftime("%Y-%m-%d")
        options = { report: "TEXT", date: date }.merge(options)
      end
      report = begin
        case options[:report] 
        when "HTML"
          StandUpGuy::HTMLReport.new(options[:date])
        when "TEXT"
          StandUpGuy::TextReport.new(options[:date])
        when "EMAIL"
          StandUpGuy::EmailReport.new(options[:date])
        else
          nil
        end
      end
      Kernel.puts("Not showing report, not data.") unless @report_available
      report.show if report && @report_available
    end

    def first_time!
      Kernel.puts("First time running...\nCreating data directory")
      Dir.mkdir(DATA_ROOT)
      File.open(File.join(DATA_ROOT, "standup.json"), "a+").close
      @report_available = false
    end
  end

  class Report
    include DataMethods
    attr_accessor :current_standup, :date

    def initialize(date = nil)
      @current_standup = JSON.load(File.open(filename))
      date ||= "ALL"
      @date = date == "ALL" ? :all : date_key(date)
    end

    def file
      # TODO Move this to HTMLReport
      @file ||= Tempfile.new(["report", ".html"])
    end

    def link
      "file:///"+file.path
    end

    def template(file)
      spec = Gem::Specification.find_by_name("StandUpGuy")
      gem_root = spec.gem_dir
      File.read(File.join(gem_root, "lib", "StandUpGuy", file))
    end

    def data(date = :all)
      scope = @current_standup
      scope = {date => @current_standup[date]} unless date == :all
      scope
    end
  end

  class HTMLReport < Report
    def show
      File.write(file, render)
      self.file.close
      Launchy.open self.link
      Kernel.sleep 5
      self.file.unlink
    end

    def render
      ::Haml::Engine.new(template("report.html.haml")).render(Object.new, :standup => data(@date))
    end
  end

  class TextReport < Report
    def show
      puts render
    end

    def render
      ::Haml::Engine.new(template("report.txt.haml")).render(Object.new, :standup => data(@date))
    end
  end

  class EmailReport < TextReport
    def show
      @date = !date.nil? ? date : date_key(:today)
      body = render
      Kernel.system('open "mailto:?subject=StandUp for #{date_key(:today)}&body=#{body}"') if mac?
    end

    def render
      ::Haml::Engine.new(template("report.email.haml")).render(Object.new, :standup => data(@date))
    end

    def mac?
      Launchy::Detect::HostOs.new().host_os.start_with?("darwin")
    end
  end

  class Item
    include DataMethods

    attr_accessor :data

    def method_missing(method, *args, &block)
      return unless [:description=, :name=, :date=].include?(method)
      method = method.to_s.chop.to_sym
      @data[method]=args.first
    end

    def save
      current_standup = load_data
      current_standup ||= {date_key =>[]}
      current_standup[date_key] = [] unless current_standup.keys.include?(date_key)
      current_standup[date_key] << @data
      write_data(current_standup)
    end

    def add_to_today(item)
      @data ||= {description: "", name: "", date: ""}
      ticket = TicketUrl.new(item)
      if ticket.valid?
        zendesk_ticket = client(ticket.subdomain).tickets.find(:id => ticket.id)
        self.description = "#{item} => (#{zendesk_ticket.subject})"
      else
        self.description = item
      end

      self.name = `whoami`.chop
      self.date = key
    end

    def client(subdomain)
      @client ||= ZendeskAPI::Client.new do |config|
        config.url = "https://#{subdomain}.zendesk.com/api/v2"
        config.username = ENV["zendesk_user"]
        config.token = ENV["zendesk_token"]
      end
    end

    TicketUrl = Struct.new(:url, :subdomain, :id) do
      CLASSIC_TICKET = /https?:\/\/(.*?)\.zendesk.com\/[a-z].*?\/(.*)/
      LOTUS_TICKET = /https?:\/\/(.*?)\.zendesk.com\/agent\/#?\/?tickets\/(\d+)\/?.*?/
      def initialize(url)
        [LOTUS_TICKET, CLASSIC_TICKET].each do |pattern|
          subdomain, id = url.downcase.scan(pattern).flatten
          super(url, subdomain, id)
          return if self.valid?
        end
      end

      def valid?
        !(self.id.nil? && self.subdomain.nil?)
      end
    end
  end
end