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

  [:html, :txt].each do |format|
    describe "#show" do
      subject(:report) do
        format == :html ? StandUpGuy::HTMLReport.new : StandUpGuy::TextReport.new
      end

      before do
        Launchy.stubs(:open)
        Kernel.stubs(:sleep)
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
end
