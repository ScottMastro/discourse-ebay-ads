# frozen_string_literal: true

# name: discourse-ebay-ads
# version: 1.0.1
# authors: ScottMastro
# url: https://github.com/ScottMastro/discourse-ebay-ads
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :enable_ebay_ads

register_svg_icon "fab-ebay" if respond_to?(:register_svg_icon)
register_svg_icon "fa-broom" if respond_to?(:register_svg_icon)

register_asset 'stylesheets/common/common.scss'

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
  require_relative 'app/controllers/ebay_seller_controller.rb'
  require_relative 'app/controllers/ebay_ad_controller.rb'
  require_relative 'app/models/ebay_models.rb'

  require_relative 'lib/ebay_scraper.rb'
  require_relative 'lib/ebay_api.rb'
  require_relative 'lib/create_system_post.rb'
  require_relative 'lib/listing_manager.rb'

  require_relative 'jobs/dump_seller_listings.rb'
  require_relative 'jobs/get_seller_listings.rb'
  require_relative 'jobs/item_lookup.rb'

  add_admin_route 'ebay_ads.admin_title', 'ebay'

  Discourse::Application.routes.append do
    get '/admin/plugins/ebay' => 'admin/plugins#index', constraints: StaffConstraint.new
  end

  EbayAdPlugin::Engine.routes.draw do
    
    get '/ebay' => 'ebay#index'
    get '/ebay/search' => 'ebay#search'
    get "/ebay/info" => "ebay#info", constraints: StaffConstraint.new
    get "/ebay/user/update/:username" => "ebay#update_user", constraints: StaffConstraint.new
    get "/ebay/random" => "ebay#random"
    get "/ebay/ad" => "ebay_ad#ad_data"

    get "/ebay/adclick/:item_id" => "ebay_ad#ad_click"
    get "/ebay/adimpression/:item_ids" => "ebay_ad#ad_impression"

    get "/ebay/seller/custom_add/" => "ebay_seller#add_sellers_by_custom_field", constraints: StaffConstraint.new
    get "/ebay/seller/add/:ebay_username" => "ebay_seller#add_seller", constraints: StaffConstraint.new
    get "/ebay/seller/remove/:ebay_username" => "ebay_seller#remove_seller", constraints: StaffConstraint.new
    get "/ebay/user/update_settings/:ebay_username" => "ebay_seller#update_user_settings"
    get "/ebay/user/clear_settings/:user_id" => "ebay_seller#clear_user_settings"
    get "/ebay/user/settings/:user_id" => "ebay_seller#get_user_settings"
    get "/ebay/seller/info/:ebay_username" => "ebay_seller#seller_info", constraints: StaffConstraint.new
    get "/ebay/seller/info" => "ebay_seller#all_seller_info", constraints: StaffConstraint.new
    get "/ebay/seller/block/:ebay_username" => "ebay_seller#block_seller", constraints: StaffConstraint.new
    get "/ebay/seller/unblock/:ebay_username" => "ebay_seller#unblock_seller", constraints: StaffConstraint.new
    get "/ebay/seller/blocklist" => "ebay_seller#blocklist", constraints: StaffConstraint.new
    get "/ebay/seller/dump/:ebay_username" => "ebay_seller#dump_seller_listings", constraints: StaffConstraint.new

  end
  
  Discourse::Application.routes.append do
    mount EbayAdPlugin::Engine, at: "/"
  end


after_initialize do
  module ::Jobs
    class UpdateEbayListings < ::Jobs::Scheduled
      every 1.day

      def execute(args)
        EbayAdPlugin::EbaySeller.find_each do |seller|
          next if seller.user_id.nil?
          next if seller.blocked || seller.hidden

          user = User.find_by(id: seller.user_id)
          next if user.nil?
          next if !user.in_any_groups?(SiteSetting.ebay_seller_allowed_groups_map)

          ebay_username = seller.ebay_username
          
          #todo: run
          #Jobs.enqueue(:get_seller_listings, ebay_seller: ebay_username)

        end
      end
    end
  end
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