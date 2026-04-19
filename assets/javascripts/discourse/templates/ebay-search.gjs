import { hash } from "@ember/helper";
import DButton from "discourse/components/d-button";
import TextField from "discourse/components/text-field";
import dIcon from "discourse/helpers/d-icon";
import UserChooser from "discourse/select-kit/components/user-chooser";
import { i18n } from "discourse-i18n";
import EbayItemGrid from "../components/ebay-item-grid";
import EbayItemRow from "../components/ebay-item-row";

export default <template>
  <div class="ebay-search-container">
    <div class="ebay-search-label">
      {{i18n "ebay_ads.ebay_search_label"}}
    </div>

    {{dIcon "search"}}
    <TextField
      @id="search-listings-keyword"
      @value={{@controller.search_keys}}
      @placeholderKey="ebay_ads.ebay_search_keywords"
      @onChange={{@controller.updateSearch}}
    />

    <br />

    {{dIcon "user"}}
    <UserChooser
      @id="search-listings-from"
      @value={{@controller.searchedTerms.username}}
      @onChange={{@controller.onChangeSearchForUsername}}
      @options={{hash maximum=1 excludeCurrentUser=false}}
    />

    {{#if @controller.mode_row}}
      <DButton
        @action={{@controller.switchModeGrid}}
        @icon="th"
        class="ebay-button-switch-mode"
      />
    {{else}}
      <DButton
        @action={{@controller.switchModeRow}}
        @icon="list"
        class="ebay-button-switch-mode"
      />
    {{/if}}
  </div>

  {{#if @controller.siteSettings.ebay_epn_id}}
    <div class="ebay-disclaimer">
      {{i18n "ebay_ads.ebay_epn_disclaimer"}}
    </div>
    <br />
  {{/if}}

  <div
    id="listings-container"
    class="ebay-items-list ebay-items-list-{{if @controller.mode_row 'row' 'grid'}}"
  >
    {{i18n "ebay_ads.total_results"}}
    {{@controller.totalCount}}
    {{#each @controller.ebayListings as |item|}}
      {{#if @controller.mode_row}}
        <EbayItemRow
          @item={{item}}
          @trackEbayClick={{@controller.trackEbayClick}}
        />
      {{else}}
        <EbayItemGrid
          @item={{item}}
          @trackEbayClick={{@controller.trackEbayClick}}
        />
      {{/if}}
    {{else}}
      No eBay items to display.
    {{/each}}
  </div>

  <div class="ebay-search-scroll-sentinel"></div>
</template>
