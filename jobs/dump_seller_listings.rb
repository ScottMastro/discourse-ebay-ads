module Jobs
    class DumpSellerListings < ::Jobs::Base
      def execute(args)
        
        seller_name = args[:seller_name]
  
        if seller_name.blank?
          Rails.logger.error "Error dropping items for seller: Seller name is required."
          return
        end
  
        begin
          EbayAdPlugin::EbayListing.where(seller: seller_name).destroy_all
        rescue => e
          Rails.logger.error "Error dropping items for eBay seller #{seller_name}: #{e.message}"
        end
      end
    end
  end