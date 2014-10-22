require "StandUpGuy/version"
require "zendesk_api"
require "tempfile"
require "haml"
require "launchy"

module StandUpGuy
  class Report

    attr_accessor :current_standup

    def initialize
      @current_standup = JSON.load(File.open(filename))
    end

    def file
      @file ||= Tempfile.new(["report", ".html"])
    end

    def filename
      # This is for testing only. Oy.
      "standup.json"
    end

    def link
      "file:///"+file.path
    end

    def template(file)
      File.read(File.join(`pwd`.chop, "lib", "StandUpGuy", file))
    end
  end

  class HTMLReport < Report
    def show
      File.write(file, render)
      self.file.close
      Launchy.open self.link
      sleep 5
      self.file.unlink
    end

    def render
      ::Haml::Engine.new(template("report.html.haml")).render(Object.new, :standup => @current_standup)
    end
  end

  class TextReport < Report
    def show
      puts render
    end

    def render
      ::Haml::Engine.new(template("report.txt.haml")).render(Object.new, :standup => @current_standup)
    end
  end

  class Item
    attr_accessor :data

    def method_missing(method, *args, &block)
      return unless [:description=, :name=, :date=].include?(method)
      method = method.to_s.chop.to_sym
      @data[method]=args.first
    end

    def filename
      # This is for testing only. Oy.
      "standup.json"
    end

    def save
      `touch standup.json` unless File.exists?(filename)
      current_standup = JSON.load(File.open(filename))
      current_standup ||= {key =>[]}
      current_standup[key] = [] unless current_standup.keys.include?(key)
      current_standup[key] << @data
      File.open(filename, "w") do |f|
        f << JSON.dump(current_standup)
      end
    end

    def add_to_today(item)
      @data ||= {:description=>"", :name => "", :date=>""}
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

    def key(date=:today)
      return DateTime.now.strftime("%Y-%m-%d") if date==:today
      return DateTime.strptime(date,"%Y-%m-%d") if date.is_a?(String)
    end
  end
end