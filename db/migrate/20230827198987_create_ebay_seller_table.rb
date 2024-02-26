# frozen_string_literal: true

class CreateEbaySellerTable < ActiveRecord::Migration[6.0]
  def change
    unless table_exists?(:ebay_sellers)
      create_table :ebay_sellers do |t|
        t.integer :user_id
        t.string :ebay_username, null: false, index: { unique: true }
        t.boolean :hidden, default: false
        t.boolean :blocked, default: false

        t.timestamps
      end
    end
  end
end
