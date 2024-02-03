module Jobs
    class DumpSellerListings < ::Jobs::Base
      def execute(args)
        
        ebay_username = args[:ebay_username]
  
        if ebay_username.blank?
          Rails.logger.error "Error dropping items for seller: Seller name is required."
          return
        end
  
        begin
          EbayAdPlugin::EbayListing.where(seller: ebay_username).destroy_all
        rescue => e
          Rails.logger.error "Error dropping items for eBay seller #{seller_name}: #{e.message}"
        end
      end
    end
  end