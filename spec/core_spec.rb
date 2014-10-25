require "spec_helper"
require_relative "../lib/StandUpGuy"

describe StandUpGuy::Core do
  before do
    StandUpGuy::Item.any_instance.stubs(:save)
    @file = create_test_file!
  end

  subject{ {} }
  it "takes options" do
    StandUpGuy::Core.new(subject)
  end

  it "can generate a TEXT report" do
    subject.merge!(:report => "TEXT")
    StandUpGuy::TextReport.expects(:new)
    StandUpGuy::Core.new(subject)
  end

  it "can generate an HTML report" do
    subject.merge!(:report => "HTML")
    StandUpGuy::HTMLReport.expects(:new)
    StandUpGuy::Core.new(subject)
  end

  describe "adding an item" do
    it "can add an item" do
      subject.merge!(:item => "Test Item", :report => "skip")
      StandUpGuy::Core.new(subject)
    end

    it "runs a text report for today" do
      subject.merge!(:item => "Test Item")
      StandUpGuy::TextReport.expects(:new).with(DateTime.now.strftime("%Y-%m-%d"))
      StandUpGuy::Core.new(subject)
    end
  end

  after do
    @file.close
    @file.unlink
  end
end