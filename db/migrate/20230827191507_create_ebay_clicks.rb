# frozen_string_literal: true

class CreateEbayClicks < ActiveRecord::Migration[6.0]
  def change
      create_table :ebay_clicks do |t|
        t.integer :user_id
        t.string :item_id

        t.timestamps
      end
    end
  end


