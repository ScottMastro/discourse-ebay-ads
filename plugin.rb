# frozen_string_literal: true

# name: discourse-ebay-ads
# version: 1.0.1
# authors: ScottMastro
# url: https://github.com/ScottMastro/discourse-ebay-ads
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :enable_ebay_ads

register_svg_icon "fab-ebay" if respond_to?(:register_svg_icon)

register_asset 'stylesheets/desktop/desktop.scss', :desktop
register_asset 'stylesheets/mobile/mobile.scss', :mobile

register_asset 'stylesheets/common/common_listings.scss'

after_initialize do

  module ::EbayAdPlugin
    PLUGIN_NAME = "discourse-ebay-ads"
  end

  class EbayAdPlugin::Engine < ::Rails::Engine
    engine_name EbayAdPlugin::PLUGIN_NAME
    isolate_namespace EbayAdPlugin
  end

  require_relative 'app/controllers/ebay_controller.rb'
  require_relative 'app/controllers/ebay_ad_controller.rb'
  require_relative 'app/models/ebay_models.rb'

  require_relative 'lib/ebay_scraper.rb'
  require_relative 'lib/ebay_api.rb'

  require_relative 'jobs/api_jobs.rb'

  EbayAdPlugin::Engine.routes.draw do
    get '/ebay' => 'ebay#index'
    get "/ebay/info" => "ebay#info", constraints: StaffConstraint.new
    get "/ebay/seller/drop/:seller_name" => "ebay#drop_seller", constraints: StaffConstraint.new
    get "/ebay/seller/block/:seller_name" => "ebay#block_seller", constraints: StaffConstraint.new
    get "/ebay/seller/unblock/:seller_name" => "ebay#unblock_seller", constraints: StaffConstraint.new

    get "/ebay/random" => "ebay#random"
    get "/ebay/accounts" => "ebay#accounts", constraints: StaffConstraint.new
    get "/ebay/ad" => "ebay_ad#ad_data"

  end
  
  Discourse::Application.routes.append do
    mount EbayAdPlugin::Engine, at: "/"
  end

  def extract_ebay_urls(text)
    text.scan(/https?:\/\/(?:www\.)?ebay\.[a-z\.]{2,6}(?:\/\S*)?/i)
  end

  def extract_ebay_item_id(url)
    match = url.match(/(\d{11,14})/)
    match[1] if match
  end

  DiscourseEvent.on(:post_created) do |post, opts, user|

    if ! SiteSetting.ebay_topic_id.empty? && user.id != Discourse.system_user.id
      if post.topic_id == SiteSetting.ebay_topic_id.to_i
        urls = extract_ebay_urls(post.raw)

        urls.each do |url|
          item_id = extract_ebay_item_id(url)
          Jobs.enqueue(:item_lookup, item_id: item_id)
        end
      end
    end
  end
end

def get_id_from_post(text)
  match = text.match(/rowid:\s*(.+?)\n/)
  extracted_string = match[1] if match
end


DiscourseEvent.on(:post_destroyed) do |post, opts, user|
  if post.user == Discourse.system_user && post.topic_id == SiteSetting.ebay_topic_id.to_i     
    puts "DELETING"
    item_id = get_id_from_post(post.raw)
    if item_id
      puts item_id

      EbayAdPlugin::EbayListing.delete(item_id)
    end
  end
end