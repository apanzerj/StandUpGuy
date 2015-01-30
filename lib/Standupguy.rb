require "zendesk_api"
require "tempfile"
require "haml"
require "launchy"
require "open-uri"

# StandUpGuy manages your daily standups by giving you a simple command line
# interface to add new items. It grabs contextual information from the items
# in your standup and fetches additional information from available sources.
#
# Currently supported external sources:
#
# 1. Zendesk
#
# To be implemented
#
# 1. Jira
#
module Standupguy
  # Generic methods for pulling data from standup.json
  module DataMethods
    def date_key(date = :today)
      date = date == :today ? DateTime.now : DateTime.strptime(date, "%Y-%m-%d")
      date.strftime("%Y-%m-%d")
    rescue ArgumentError
      date = :today
      retry
    end

    def filename
      File.join(Standupguy::Core::DATA_ROOT, "standup.json")
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

  # Generic methods that were moved from bin/standupguy to here
  # in order to better test this code. Mostly init stuff.
  class Core
    DATA_ROOT = File.join(ENV["HOME"], ".standupguy")

    attr_accessor :options

    def initialize(options)
      @options = options

      first_time! unless Dir.exist?(DATA_ROOT)

      @options[:date] ||= DateTime.now.strftime("%Y-%m-%d")

      if @options[:item]
        item = Standupguy::Item.new
        item.add_to_today(@options[:item])
        item.save
      end
    end

    def show
      report.show
    end

    def report
      case @options[:report]
      when "HTML"
        Standupguy::HTMLReport.new(@options[:date])
      when "EMAIL"
        Standupguy::EmailReport.new(@options[:date])
      else
        Standupguy::TextReport.new(@options[:date])
      end
    end

    def first_time!
      Kernel.puts("First time running...\nCreating data directory")
      Dir.mkdir(DATA_ROOT)
      File.open(File.join(DATA_ROOT, "standup.json"), "a+").close
    end
  end

  # Generic methods for all types of report.
  class Report
    include DataMethods
    attr_accessor :current_standup, :date

    def initialize(date = nil)
      @current_standup = JSON.load(File.open(filename))
      date ||= "ALL"
      @date = date == "ALL" ? :all : date_key(date)
    end

    def link
      "file:///#{file.path}"
    end

    def template(file)
      spec = Gem::Specification.find_by_name("Standupguy")
      gem_root = spec.gem_dir
      File.read(File.join(gem_root, "lib", "Standupguy", file))
    end

    def data(date = :all)
      scope = @current_standup
      scope = { date => @current_standup[date] } unless date == :all
      scope
    end
  end

  # HTML Formatted report. Creates a tempfile that is deleted in 5 seconds.
  # Tempfile is opened in browser using Launchy.
  class HTMLReport < Report
    def show
      File.write(file, render)
      file.close
      Launchy.open link
      Kernel.sleep 5
      file.unlink
    end

    def render
      ::Haml::Engine.new(template("report.html.haml")).
        render(Object.new, standup: data(@date))
    end

    def file
      @file ||= Tempfile.new(["report", ".html"])
    end
  end

  # Text formatted report. Output to STDOUT
  class TextReport < Report
    def show
      puts render
    end

    def render
      ::Haml::Engine.new(template("report.txt.haml")).
        render(Object.new, standup: data(@date))
    end
  end

  # Basically a text report that is outputted to a mailto link. Only supports
  # the Mac OS operating system at the moment.
  class EmailReport < TextReport
    def show
      @date = !date.nil? ? date : date_key(:today)
      body = render
      parameters = ::URI.encode_www_form([
        ["subject", "StandUp for #{date_key(:today)}"],
        ["body", body]])
      link =  "mailto:?#{parameters}"
      Kernel.system("open '#{link}'") if mac?
    end

    def render
      ::Haml::Engine.new(template("report.email.haml")).
        render(Object.new, standup: data(@date))
    end

    def mac?
      Launchy::Detect::HostOs.new.host_os.start_with?("darwin")
    end
  end

  # Basic Item class. Each line in your standup is an Item.
  class Item
    include DataMethods

    attr_accessor :data

    def method_missing(method, *args)
      return unless [:description=, :name=, :date=].include?(method)
      method = method.to_s.chop.to_sym
      @data[method] = args.first
    end

    def save
      current_standup = load_data
      current_standup ||= { date_key => [] }
      data_exists = current_standup.keys.include?(date_key)
      current_standup[date_key] = [] unless data_exists
      current_standup[date_key] << @data
      write_data(current_standup)
    end

    def add_to_today(item)
      @data ||= { description: "", name: "", date: "" }
      ticket = TicketUrl.new(item)
      if ticket.valid?
        zendesk_ticket = client(ticket.subdomain).tickets.find(id: ticket.id)
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
      CLASSIC_TICKET = %r{https?:\/\/(.*?)\.zendesk.com\/[a-z].*?\/(.*)}
      LOTUS_TICKET = \
        %r{https?:\/\/(.*?)\.zendesk.com\/agent\/#?\/?tickets\/(\d+)\/?.*?}
      def initialize(url)
        [LOTUS_TICKET, CLASSIC_TICKET].each do |pattern|
          subdomain, id = url.downcase.scan(pattern).flatten
          super(url, subdomain, id)
          return if self.valid?
        end
      end

      def valid?
        !(id.nil? && subdomain.nil?)
      end
    end
  end
end
