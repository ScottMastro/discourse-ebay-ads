class AddActiveToEbayListings < ActiveRecord::Migration[7.0]
  def change
    add_column :ebay_listings, :active, :boolean, default: true
  end
end
