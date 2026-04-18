# frozen_string_literal: true

Fabricator(:ebay_listing, from: "EbayAdPlugin::EbayListing") do
  item_id { sequence(:item_id) { |i| "v1|#{100_000 + i}|0" } }
  legacy_id { sequence(:legacy_id) { |i| (100_000 + i).to_s } }
  title "Test Pokemon Card"
  price 9.99
  currency "USD"
  seller "seller_1"
  active true
end
