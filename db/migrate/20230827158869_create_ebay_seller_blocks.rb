# frozen_string_literal: true

class CreateEbaySellerBlocks < ActiveRecord::Migration[6.0]
  def change
      create_table :ebay_seller_blocks do |t|
        t.string :seller
        t.string :reason, default: ""
        
        t.timestamps
      end
    end
  end
