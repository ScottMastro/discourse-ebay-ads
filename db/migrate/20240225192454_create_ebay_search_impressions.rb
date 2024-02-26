# frozen_string_literal: true

class CreateEbaySearchImpressions < ActiveRecord::Migration[6.0]
  def change
      create_table :ebay_search_impressions do |t|
        t.string :item_id
        t.integer :count, default: 0

        t.timestamps
      end
    end
  end


