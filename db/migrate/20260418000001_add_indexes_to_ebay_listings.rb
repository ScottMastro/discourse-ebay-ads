# frozen_string_literal: true

class AddIndexesToEbayListings < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  INDEXES = {
    "index_ebay_listings_on_seller_active" => {
      columns: %i[seller active],
      options: { where: "active = TRUE" },
    },
    "index_ebay_listings_on_item_id" => {
      columns: :item_id,
      options: { unique: true },
    },
  }.freeze

  def up
    # Dedupe item_id before the unique index. Keep the most-recently-updated
    # row in each duplicate group.
    execute <<~SQL
      DELETE FROM ebay_listings
      WHERE id IN (
        SELECT id FROM (
          SELECT id,
                 ROW_NUMBER() OVER (
                   PARTITION BY item_id
                   ORDER BY updated_at DESC, id DESC
                 ) AS rn
          FROM ebay_listings
        ) ranked
        WHERE rn > 1
      )
    SQL

    INDEXES.each do |name, spec|
      remove_index :ebay_listings, name: name, algorithm: :concurrently, if_exists: true
      add_index :ebay_listings,
                spec[:columns],
                **spec[:options].merge(name: name, algorithm: :concurrently)
    end
  end

  def down
    INDEXES.each_key do |name|
      remove_index :ebay_listings, name: name, algorithm: :concurrently, if_exists: true
    end
  end
end
