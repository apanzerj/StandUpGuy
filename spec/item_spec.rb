require "spec_helper"
require_relative "../lib/StandUpGuy"

describe StandUpGuy::Item do
  describe "#add_to_today" do
    subject(:item) { StandUpGuy::Item.new }

    context "for zendesk tickets" do
      before do
        expect_zendesk("foo", "api/v2/tickets/1").
          to_return(headers: {"Content-Type" => "application/json"}, body: JSON.dump("ticket" => {"subject" => "test ticket"}))
        item.add_to_today("https://foo.zendesk.com/tickets/1")
      end

      it "includes the ticket subject in the description" do
        expect(item.data[:description]).to match(/test ticket/)
      end

      it "includes the original url" do
        expect(item.data[:description]).to match(/foo.zendesk.com\/tickets\/1/)
      end
    end

    context "for non-zendesk tickets" do
      it "takes an item" do
        item.add_to_today("foob")
        expect(item.data[:description]).to match(/foob/)
        expect(item.data[:name]).to match(`whoami`.chop)
        expect(item.data[:date]).to match(key)
      end
    end
  end

  describe "#save" do
    before do
      @datafile = create_test_file!
    end

    subject(:item) do
      test_item = StandUpGuy::Item.new
      test_item.add_to_today("foo")
      test_item
    end

    it "writes a file" do
      item.save
      expect_datafile(@datafile, %r{foo})
    end

    after do
      @datafile.close
      @datafile.unlink
    end
  end
end
