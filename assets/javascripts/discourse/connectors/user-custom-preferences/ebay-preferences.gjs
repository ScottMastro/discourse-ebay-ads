import Component from "@glimmer/component";
import EbayPreferencesSettings from "../../components/ebay-preferences-settings";

export default class EbayPreferences extends Component {
  static shouldRender(_args, { siteSettings }) {
    return siteSettings.enable_ebay_ads;
  }

  <template>
    <EbayPreferencesSettings @model={{@outletArgs.model}} />
  </template>
}
