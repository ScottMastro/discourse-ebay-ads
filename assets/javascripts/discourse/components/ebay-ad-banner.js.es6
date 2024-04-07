import Component from '@glimmer/component';
import { tracked } from "@glimmer/tracking";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";
import { action } from "@ember/object"; 

export default class EbayAdBanner extends Component {
  @tracked model = null;
  @tracked voteStatus = 0;

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
      //console.log(result)

      this.model = result;
      let avatarUrl = this.model.seller_info.avatar;
      this.model.seller_info.avatar = avatarUrl.replace('{size}', '96');
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

  @action
  likeAd() {
    const vote = this.voteStatus == 1 ? 0 : 1; 
    const encodedId = encodeURIComponent(this.model.item_id);
    let url = `/ebay/vote/${encodedId}?vote=${vote}`;
    ajax(url).then((result) => { 
      this.voteStatus = vote;
    }).catch((error) => {
      console.error('Vote not recorded:', error);
    });
  }

  @action
  dislikeAd() {
    const vote = this.voteStatus == -1 ? 0 : -1; 
    const encodedId = encodeURIComponent(this.model.item_id);
    let url = `/ebay/vote/${encodedId}?vote=${vote}`;
    ajax(url).then((result) => { 
      this.voteStatus = vote;
      console.log(this.voteStatus)
    }).catch((error) => {
      console.error('Vote not recorded:', error);
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
