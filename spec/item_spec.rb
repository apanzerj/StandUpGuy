require "spec_helper"
require_relative "../lib/Standupguy"

describe Standupguy::Item do
  before { @datafile = create_test_file! }
  describe "#add_to_today" do
    describe "for zendesk tickets" do
      before do
        @item = Standupguy::Item.new
        expect_zendesk("foo", "api/v2/tickets/1").
          to_return(headers: {"Content-Type" => "application/json"}, body: JSON.dump("ticket" => {"subject" => "test ticket"}))
        @item.add_to_today("https://foo.zendesk.com/tickets/1")
      end

      it "includes the ticket subject in the description" do
        expect(@item.data[:description]).to match(/test ticket/)
      end

      it "includes the original url" do
        expect(@item.data[:description]).to match(/foo.zendesk.com\/tickets\/1/)
      end

      it "includes the ticket_id" do
        expect(@item.data[:ticket_id]).to eq("https://foo.zendesk.com/tickets/1")
      end

      describe "adding the same ticket again" do
        subject { Standupguy::Item.new }

        before do
          @item.save
          expect_zendesk("foo", "api/v2/tickets/1").
            to_return(headers: {"Content-Type" => "application/json"}, body: JSON.dump("ticket" => {"subject" => "test ticket"}))
        end

        describe "choosing to continue" do
          it "adds the item" do
            Standupguy::Item.any_instance.expects(:continue?).returns(true)
            subject.add_to_today("https://foo.zendesk.com/tickets/1")
            subject.save
            expect(JSON.load(@datafile.read)[key].size).to eq(2)
          end

          describe "#continue?" do
            it "outputs" do
              STDIN.expects(:gets).returns("y")
              expect do
                subject.add_to_today("https://foo.zendesk.com/tickets/1")
                subject.save
              end.to output.to_stdout
            end
          end
        end

        describe "choosing not to continue" do
          it "does not add the item" do
            Standupguy::Item.any_instance.expects(:continue?).returns(false)
            subject.add_to_today("https://foo.zendesk.com/tickets/1")
            subject.save
            expect(JSON.load(@datafile.read)[key].size).to eq(1)
          end
        end
      end
    end

    describe "for non-zendesk tickets" do
      subject{ Standupguy::Item.new }

      it "takes an item" do
        subject.add_to_today("foob")
        expect(subject.data[:description]).to match(/foob/)
        expect(subject.data[:name]).to match(`whoami`.chop)
        expect(subject.data[:date]).to match(key)
      end
    end
  end

  describe "#save" do
    subject(:item) do
      test_item = Standupguy::Item.new
      test_item.add_to_today("foo bazzyle")
      test_item
    end

    it "writes a file" do
      item.save
      expect_datafile(@datafile, %r{foo})
    end
  end

  after do
    @datafile.close
    @datafile.unlink
  end
end
