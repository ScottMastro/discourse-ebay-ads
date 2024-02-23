import Component from '@glimmer/component';
import { tracked } from "@glimmer/tracking";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";
import { action } from "@ember/object"; 

export default class EbayAdBanner extends Component {
  @tracked model = null;

  constructor() {
    super(...arguments);
    this.loadAd();
  }

  get formattedPrice() {
    if (this.model && this.model.price) {
      return "$" + parseFloat(this.model.price).toFixed(2);
    }
    return '?';
  }

  async loadAd() {
    try {
      const result = await ajax("/ebay/ad");
      this.model = result;
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  trackEbayClick(itemId) {
    const encodedId = encodeURIComponent(itemId);
    let url = `/ebay/adclick/${encodedId}`;
    ajax(url).then((result) => { 

    }).catch((error) => {
      console.error('Click not recorded:', error);
    });
  }
}
