require "spec_helper"
require_relative "../lib/StandUpGuy"

describe StandUpGuy::Report do
  before do
    @datafile = create_test_file!
    @item = StandUpGuy::Item.new
    @item.add_to_today("foob a doob")
    @item.save
  end

  describe "#initialize" do
    subject(:report) { StandUpGuy::Report.new }

    it "reads current standup data" do
      expect(report.current_standup[key].first["description"]).to match(@item.data[:description])
    end
  end

  describe "#link" do
    subject(:report) { StandUpGuy::Report.new }

    it "returns a link" do
      expect(report.link).to match(%r{file:///})
    end
  end

  describe "#data" do
    let(:report) { StandUpGuy::Report.new }

    it "returns the current_standup without a date" do
      expect(report.data).to be(report.current_standup)
    end

    it "returns scoped data when passed a date" do
      report.instance_variable_set(:@current_standup, {"2014-10-10"=>["foo"], "2014-10-11"=>[nil]})
      expect(report.data("2014-10-10").first).to eq(["2014-10-10", ["foo"]])
    end
  end

  [:html, :txt, :email].each do |format|
    describe "#show" do
      subject(:report) do
        case format
        when :html then StandUpGuy::HTMLReport.new
        when :txt then StandUpGuy::TextReport.new
        when :email then StandUpGuy::EmailReport.new
        end
      end

      before do
        Launchy.stubs(:open)
        StandUpGuy::EmailReport.any_instance.stubs(:mac?).returns(true)
        Kernel.stubs(:sleep)
        Kernel.stubs(:system)
        StandUpGuy::TextReport.send(:define_method, :puts) { |*args| ""}
      end

      describe format.to_s do
        it "calls #render" do
          report.expects(:render).returns("foo")
          report.show
        end

        describe "#render" do
          it "renders a HAML template" do
            @file = "= key"
            report.expects(:template).with("report.#{format}.haml").returns(@file)
            expect(report.render).to match(key)
          end

          it "is rendered with the current_standup" do
            expect(report.render).to match(/foob a doob/)
          end
        end
      end
    end
  end

  after do
    @datafile.close
    @datafile.unlink
  end
end
