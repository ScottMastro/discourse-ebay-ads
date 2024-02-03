# frozen_string_literal: true

class CreateEbaySellerTable < ActiveRecord::Migration[6.0]
  def change
      create_table :ebay_seller do |t|
        t.integer :user_id
        t.string :ebay_username
        t.boolean :hidden, default: false
        
        t.timestamps
      end
    end
  end
