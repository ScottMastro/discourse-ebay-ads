import Component from "@glimmer/component";
import EbayAdBanner from "../../components/ebay-ad-banner";

export default class EbayAdSlot extends Component {
  static shouldRender(_args, { siteSettings }) {
    return siteSettings.enable_ebay_ads && siteSettings.show_ebay_ad_banner;
  }

  <template>
    <EbayAdBanner />
  </template>
}
