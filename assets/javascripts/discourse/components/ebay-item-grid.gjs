import dIcon from "discourse/helpers/d-icon";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";

<template>
  <div class="ebay-item ebay-item-grid">
    <div class="ebay-item-grid-row">
      <div class="ebay-item-title">
        <a
          href="https://www.ebay.com/itm/{{@item.legacy_id}}"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{@item.title}}
        </a>
      </div>
    </div>

    <div class="ebay-item-grid-row">
      <div class="ebay-item-image">
        <img src={{@item.image_url}} alt={{@item.title}} />
      </div>
      <div class="ebay-item-details">
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
    </div>

    <div class="ebay-item-grid-row">
      <div class="ebay-item-link">
        <a
          class="ebay-item-link-button d-btn btn"
          href="https://www.ebay.com/itm/{{@item.legacy_id}}"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{i18n "ebay_ads.view_on_ebay"}}
          <span>{{dIcon "fab-ebay"}}</span>
        </a>
      </div>
    </div>
  </div>
</template>
