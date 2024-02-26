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
      this.setupImpressionWatcher();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  trackEbayClick() {
    const encodedId = encodeURIComponent(this.model.item_id);
    let url = `/ebay/adclick/${encodedId}?banner=true`;
    ajax(url).then((result) => { 

    }).catch((error) => {
      console.error('Click not recorded:', error);
    });
  }

  trackEbayImpression() {
    const encodedId = encodeURIComponent(this.model.item_id);
    let url = `/ebay/adimpression/${encodedId}?banner=true`;
    ajax(url).then((result) => { 

    }).catch((error) => {
      console.error('Impression not recorded:', error);
    });
  }

  setupImpressionWatcher() {
    let options = {root: null, rootMargin: '0px', threshold: 1.0 };

    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        this.trackEbayImpression();
        observer.disconnect();
      }
    }, options);

    const impression = document.querySelector('.impression-observer');
    if (!impression) {
      console.error('Impression sentinel element not found.');
    } else {
      observer.observe(impression);
    }
  }

}
