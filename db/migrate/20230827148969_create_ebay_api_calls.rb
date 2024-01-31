# frozen_string_literal: true

class CreateEbayApiCalls < ActiveRecord::Migration[6.0]
  def change
      create_table :ebay_api_calls do |t|
        t.date :date
        t.integer :count
        t.string :call_type
        
        t.timestamps
      end
    end
  end
