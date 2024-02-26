class AddBannerClickToEbayClicks < ActiveRecord::Migration[6.0]
  def change
    add_column :ebay_clicks, :banner_click, :boolean, default: false
  end
end
