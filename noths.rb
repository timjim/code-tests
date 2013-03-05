class Checkout
  class ItemRequired < StandardError; end

  attr_accessor :items, :rules
  attr_reader :promotion, :total_in_pence

  def initialize promotion=nil
    @items = []
    @manager = RuleManager.new
    rules << promotion
    @total_in_pence = 0
  end

  def scan item
    raise ItemRequired if item.nil?
    add_item item
    self
  end

  def total_in_pence
    @total_in_pence = items.inject(0) do |sum, item|
      sum += item.price_in_pence
    end
    @total_in_pence = @manager.calculate_discounted_price_in_pence total_price: @total_in_pence, items: items
  end

  def rules
    @manager.rules
  end

  private
    def add_item item
      items << item
    end
end

class RuleManager
  attr_accessor :rules

  def initialize
    @rules = []
  end

  def calculate_discounted_price_in_pence args={}
    @rules.compact.inject(args[:total_price]) do |sum, rule| 
      sum = rule.apply(sum, args[:items])
    end
  end
end

class DiscountRule
  def initialize *args
    @threshold = args.first.fetch :threshold
    @rate = args.first.fetch :rate
  end

  def apply total_price, items
    if total_price > @threshold
      (total_price * (1.00 - (1.00 / @rate))).ceil
    else
      total_price
    end
  end
end

class BulkRule
  def initialize *args
    @threshold = args.first.fetch :threshold
    @price = args.first.fetch :price
    @item_id = args.first.fetch :item_id
  end

  def apply total_price, items
    bulk_items = items.select {|item| item.id == @item_id }
    if bulk_items.size >= @threshold
      total_price - (bulk_items.size * (bulk_items.first.price_in_pence - @price))
    else
      total_price
    end
  end
end