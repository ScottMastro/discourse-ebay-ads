# frozen_string_literal: true

Fabricator(:ebay_seller, from: "EbayAdPlugin::EbaySeller") do
  ebay_username { sequence(:ebay_username) { |i| "seller_#{i}" } }
  hidden false
  blocked false
end
