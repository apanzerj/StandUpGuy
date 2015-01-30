require "spec_helper"
require_relative "../lib/Standupguy"

describe Standupguy::Core do
  before do
    Standupguy::Item.any_instance.stubs(:save)
    @file = create_test_file!
  end

  subject{ {} }
  it "takes options" do
    Standupguy::Core.new(subject)
  end

  describe "defaults" do
    subject{ Standupguy::Core.new( {} ) }

    it "defaults to the current date" do
      expect(subject.options[:date]).to eq(key)
    end

    it "defaults to a text report" do
      expect(subject.report).to be_a_kind_of(Standupguy::TextReport)
    end
  end

  it "can generate a TEXT report" do
    subject.merge!(report: "TEXT")
    Standupguy::TextReport.any_instance.expects(:show)
    Standupguy::Core.new(subject).show
  end

  it "can generate an HTML report" do
    subject.merge!(report: "HTML")
    Standupguy::HTMLReport.any_instance.expects(:show)
    Standupguy::Core.new(subject).show
  end

  it "can generate an EMAIL report" do
    subject.merge!(report: "EMAIL")
    Standupguy::EmailReport.any_instance.expects(:show)
    Standupguy::Core.new(subject).show
  end

  describe "adding an item" do
    it "can add an item" do
      subject.merge!(item: "Test Item", report: nil)
      Standupguy::Core.new(subject)
    end

    it "runs a text report for today" do
      subject.merge!(:item => "Test Item")
      report = stub
      Standupguy::TextReport.expects(:new).
        with(DateTime.now.strftime("%Y-%m-%d")).returns(report)
      report.expects(:show)
      Standupguy::Core.new(subject).show
    end
  end

  describe "#first_time!" do
    before do
      Kernel.stubs(:puts)
      Dir.stubs(:exist?).returns(false)
    end

    it "is called when no directory exists" do
      Standupguy::Core.any_instance.expects(:first_time!)
      Standupguy::Core.new({})
    end

    it "creates the directory and makes the file" do
      File.expects(:open).
        with(File.join(Standupguy::Core::DATA_ROOT, "standup.json"), "a+").
          returns(@file)
      Dir.expects(:mkdir)
      Standupguy::Core.new({})
    end
  end

  after do
    @file.close
    @file.unlink
  end
end