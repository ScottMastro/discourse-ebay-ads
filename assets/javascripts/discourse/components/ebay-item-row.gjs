import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { service } from "@ember/service";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";

export default class EbayItemRow extends Component {
  @service siteSettings;

  <template>
    <div id="impression-observer-{{@item.item_id}}"></div>
    <a
      href="https://www.ebay.com/itm/{{@item.legacy_id}}?mkevt=1&mkcid=1&mkrid=711-53200-19255-0&campid={{@item.epn_id}}&toolid=1001"
      target="_blank"
      {{on "click" (fn @trackEbayClick @item.item_id)}}
    >
      <div class="ebay-item ebay-item-row">
        <div class="ebay-item-image">
          <img src={{@item.image_url}} alt={{@item.title}} />
        </div>
        <div class="ebay-item-details">
          <div class="ebay-item-title">{{@item.title}}</div>
          <div class="ebay-item-price">
            ${{@item.price}}
            {{@item.currency}}
          </div>
          <div class="ebay-item-end-date">
            {{i18n "ebay_ads.ebay_end_date"}}:
            {{formatDate @item.end_date}}
          </div>
          <div class="ebay-item-seller-details">
            <div class="ebay-item-location">
              {{i18n "ebay_ads.ebay_location"}}:
              {{@item.location}}
            </div>
            <div class="ebay-item-seller">
              {{@item.seller}}
              ({{@item.feedback_score}})
              {{@item.feedback_percent}}%
            </div>
          </div>
        </div>

        {{#if this.siteSettings.ebay_epn_id}}
          <div class="ebay-item-disclaimer">ADVERTISEMENT ⓘ</div>
        {{/if}}
      </div>
    </a>
  </template>
}
