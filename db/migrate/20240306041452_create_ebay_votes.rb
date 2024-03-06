# frozen_string_literal: true

class CreateEbayVotes < ActiveRecord::Migration[6.0]
  def change
    create_table :ebay_votes do |t|
      t.integer :user_id
      t.string :item_id
      t.integer :vote

      t.timestamps
    end
  end
end
