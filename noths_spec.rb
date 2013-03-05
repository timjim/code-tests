require File.expand_path '../noths', __FILE__

describe Checkout do
  let(:lavender_heart) { stub 'Item', price_in_pence: 925, id: 'lavender_heart' }
  let(:cufflinks) { stub 'Item', price_in_pence: 4500, id: 'cufflinks' }
  let(:t_shirt) { stub 'Item', price_in_pence: 1995, id: 't_shirt' }
  let(:checkout) { Checkout.new }
  let(:bulk) do
    BulkRule.new threshold: 2, price: 850, item_id: 'lavender_heart'
  end
  let(:discount) { DiscountRule.new threshold: 6000, rate: 10 }

  describe '#scan' do
    before { checkout.scan lavender_heart }

    it('adds item to basket') { checkout.items.should == [lavender_heart] }
    it('updates the checkout total') { checkout.total.should == 9.25 }
  end

  context 'with 3 different items exceeding 60 pounds in total' do
    before do
      checkout.rules << discount
      checkout.scan(lavender_heart).scan(cufflinks).scan(t_shirt)
    end

    it('applies a 10% discount') { checkout.total.should == 66.78 }
  end

  context 'with 2 lavender hearts' do
    before do
      checkout.rules << bulk
      checkout.scan(lavender_heart).scan(t_shirt).scan(lavender_heart)
    end

    it('triggers the bulk price') { checkout.total.should == 36.95 }
  end

  context 'with 2 lavender hearts and over 60 pounds' do
    before do
      checkout.rules << bulk << discount
      checkout.
        scan(lavender_heart).
        scan(cufflinks).
        scan(lavender_heart).
        scan(t_shirt)
    end

    it 'triggers both bulk and discount rules' do
      checkout.total.should == 73.76
    end
  end
end