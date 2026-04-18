# frozen_string_literal: true

class RollupEbayBannerImpressions < ActiveRecord::Migration[7.0]
  def up
    create_table :ebay_impressions do |t|
      t.string :ebay_username, null: false
      t.date :date, null: false
      t.integer :count, null: false, default: 0
      t.timestamps
    end

    add_index :ebay_impressions,
              %i[ebay_username date],
              unique: true,
              name: "index_ebay_impressions_on_username_date"

    add_index :ebay_impressions,
              :date,
              name: "index_ebay_impressions_on_date"

    # Backfill banner impressions only. Search impressions carry no per-day
    # history (lifetime counter per item) — not worth approximating.
    execute <<~SQL
      INSERT INTO ebay_impressions
        (ebay_username, date, count, created_at, updated_at)
      SELECT l.seller,
             DATE(i.created_at) AS date,
             COUNT(*),
             NOW(),
             NOW()
      FROM ebay_banner_impressions i
      INNER JOIN ebay_listings l ON l.item_id = i.item_id
      WHERE l.seller IS NOT NULL
      GROUP BY l.seller, DATE(i.created_at)
    SQL
  end

  def down
    drop_table :ebay_impressions
  end
end
