# frozen_string_literal: true

# name: discourse-ebay-ads
# version: 1.0.0
# authors: ScottMastro
# url: https://github.com/ScottMastro/discourse-ebay-ads
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :enable_ebay_ads

register_asset 'stylesheets/desktop/desktop.scss', :desktop
register_asset 'stylesheets/mobile/mobile.scss', :mobile

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

  require_relative 'app/models/ebay_listing.rb'
  require_relative 'lib/ebay_scraper.rb'
  require_relative 'lib/ebay_api.rb'
  require_relative 'jobs/api_jobs.rb'

  EbayAdPlugin::Engine.routes.draw do
    get '/ebay' => 'ebay#index'
    get "/ebay/accounts" => "ebay#accounts"
    get "/ebay/api_calls" => "ebay#api_calls"
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