import Component from "@glimmer/component";
import { Input } from "@ember/component";
import { service } from "@ember/service";
import dIcon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class EbayPreferencesSettings extends Component {
  @service ebayUserSettings;

  constructor() {
    super(...arguments);
    this.ebayUserSettings.discourseId = this.args.model.id;
    ajax(`/ebay/user/settings/${this.args.model.id}`)
      .then((result) => {
        if (result.seller) {
          this.ebayUserSettings.ebayUsername = result.seller.ebay_username;
          this.ebayUserSettings.hideListings = result.seller.hidden;
        }
      })
      .catch(popupAjaxError);
  }

  get ebayUsername() {
    return this.ebayUserSettings.ebayUsername;
  }
  set ebayUsername(value) {
    this.ebayUserSettings.ebayUsername = value;
  }

  get hideListings() {
    return this.ebayUserSettings.hideListings;
  }
  set hideListings(value) {
    this.ebayUserSettings.hideListings = value;
  }

  <template>
    <h1>{{i18n "ebay_ads.preferences.title"}}</h1>

    <div class="control-group">
      <label class="control-label">
        {{i18n "ebay_ads.preferences.ebay_username"}}
      </label>
      <div class="controls">
        <label class="text-label">
          <Input
            @type="text"
            @value={{this.ebayUsername}}
            class="input-xxlarge"
          />
        </label>
        <a
          href="https://www.ebay.com/usr/{{this.ebayUsername}}"
          target="_blank"
        >
          {{dIcon "link"}}
          https://www.ebay.com/usr/{{this.ebayUsername}}
        </a>

        <div class="controls">
          <label class="checkbox-label">
            <Input @type="checkbox" @checked={{this.hideListings}} />
            {{i18n "ebay_ads.preferences.hide_listings"}}
          </label>
        </div>
      </div>
    </div>
  </template>
}
