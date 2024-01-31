# frozen_string_literal: true

class CreateEbayListings < ActiveRecord::Migration[6.0]
  def change
      create_table :ebay_listings do |t|
        t.string :item_id
        t.string :legacy_id
        t.string :title
        t.text :description
        t.decimal :price
        t.string :currency
        t.string :image_url
        t.datetime :end_date
        t.string :location

        t.string :seller
        t.integer :feedback_score
        t.float :feedback_percent
        
        t.timestamps
      end
    end
  end


