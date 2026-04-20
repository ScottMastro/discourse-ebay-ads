# frozen_string_literal: true

class CleanupStalePluginStoreKeys < ActiveRecord::Migration[7.0]
  STALE_KEYS = %w[ebay_seller_weights ebay_ad_seller_weights ebay_ad_weight ebay_ad_weights].freeze

  def up
    execute <<~SQL
      DELETE FROM plugin_store_rows
      WHERE plugin_name = 'ebay_ad_plugin'
        AND key IN (#{STALE_KEYS.map { |k| "'#{k}'" }.join(",")})
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
