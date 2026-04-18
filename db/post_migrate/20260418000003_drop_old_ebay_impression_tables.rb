# frozen_string_literal: true

class DropOldEbayImpressionTables < ActiveRecord::Migration[7.0]
  def up
    execute "DROP TABLE IF EXISTS ebay_banner_impressions"
    execute "DROP TABLE IF EXISTS ebay_search_impressions"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
