# frozen_string_literal: true

module EbayAdPlugin
    class EbayListing < ActiveRecord::Base
      self.table_name = 'ebay_listings'
    end
  end