# frozen_string_literal: true

module EbayAdPlugin
  class EbayListing < ActiveRecord::Base
    self.table_name = 'ebay_listings'
  end

  class EbayApiCall < ActiveRecord::Base
    self.table_name = 'ebay_api_calls'
  end

  class EbaySeller < ActiveRecord::Base
    self.table_name = 'ebay_sellers'
  end

  class EbayClick < ActiveRecord::Base
    self.table_name = 'ebay_clicks'
  end
end