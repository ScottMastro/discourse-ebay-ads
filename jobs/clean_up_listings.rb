# frozen_string_literal: true
module Jobs
  class CleanUpListings < ::Jobs::Base
    def execute(args)
      EbayAdPlugin::EbayListing
        .where(active: true)
        .where("updated_at < ?", 3.days.ago)
        .update_all(active: false, updated_at: Time.current)
    end
  end
end
