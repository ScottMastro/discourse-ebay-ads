# frozen_string_literal: true

class CreateEbayBannerImpressions < ActiveRecord::Migration[6.0]
  def change
      create_table :ebay_banner_impressions do |t|
        t.integer :user_id
        t.string :item_id
        
        t.timestamps
      end
    end
  end


