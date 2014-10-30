require "spec_helper"
require_relative "../lib/StandUpGuy"
include StandUpGuy::DataMethods

describe StandUpGuy::DataMethods do
  describe "#date_key" do
    it "returns the current date formatted string when give :today" do
      expect(date_key(:today)).to be_a_kind_of(String)
      expect(date_key(:today)).to match(/\d{4}-\d{2}-\d{2}/)
      expect(date_key(:today)).to eq(DateTime.now.strftime("%Y-%m-%d"))
    end

    it "returns the date formatted sting when given same" do
      expect(date_key("2014-10-10")).to be_a_kind_of(String)
      expect(date_key("2014-10-10")).to match(/\d{4}-\d{2}-\d{2}/)
      expect(date_key("2014-10-10")).to eq("2014-10-10")
    end

    it "returns today when given a non date formatted string" do
      expect(date_key("foo")).to eq(DateTime.now.strftime("%Y-%m-%d"))
    end
  end

  describe "#filename" do
    it { expect(filename).to eq(File.join(StandUpGuy::Core::DATA_ROOT, "standup.json")) }
  end

  describe "#load_data" do
    before do
      @file = Tempfile.new("foo")
      stubs(filename: @file.path)
    end

    it "reads an existing file" do
      File.write(@file, '{"foo": "bar"}')
      expect(load_data).to eq({"foo" => "bar"})
    end

    it "writes the current standup" do
      write_data({"foo" => "bar"})
      expect(File.read(@file)).to eq('{"foo":"bar"}')
      File.delete(@file)
    end

    after do
      @file.close
      @file.unlink
    end
  end
end