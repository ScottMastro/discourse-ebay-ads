import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class AdminPluginsEbayController extends Controller {
  @tracked selectedUser = "";
  @tracked ebaySeller = "";
  @tracked ebaySellerInfo = null;
  @tracked allBlockedSellers = [];

  init(){
    super.init(...arguments);
    this.updateBlockedList();

  }

  updateBlockedList(){
    ajax("/ebay/info/blocked")
    .then((result) => {
      console.log(result)
      this.allBlockedSellers = result.all;
    }).catch(popupAjaxError);
  }

  updateSellerInfo(seller){
    const encodedSeller = encodeURIComponent(seller);
    if(seller){
      ajax(`/ebay/seller/info/${encodedSeller}`)
      .then((result) => {
        console.log(result)
        this.ebaySellerInfo = result;

      }).catch(popupAjaxError);
    } else{
      this.ebaySellerInfo = null;
    }
  }

  unblockSeller(seller) {
    const encodedSeller = encodeURIComponent(seller);
    ajax(`/ebay/seller/unblock/${encodedSeller}.json`)
      .then((result) => {

        if (result.status != "ok"){
          console.log("Error when attempting to unblock seller!")
          console.log(result);
        }
        this.updateSellerInfo(this.ebaySeller);
        this.updateBlockedList();

      }).catch(popupAjaxError);
  }

  @action
  onChangeUsername(username) {
    if(username && username.length == 1){

      ajax(`/ebay/user/info/${username}`)
      .then((result) => {
        this.selectedUser = result;
        this.ebaySeller = result.ebay_username;

      }).catch(popupAjaxError);
  
    } else{
      this.selectedUser = "";
      this.ebaySeller = "";
    }
  }

  @action
  searchForSeller(seller){
    this.updateSellerInfo(seller);
  }

  @action
  blockSeller() {
    const encodedBlockReason = encodeURIComponent(this.blockReason);

    ajax(`/ebay/seller/block/${this.ebaySeller}.json?reason=${encodedBlockReason}`)
      .then((result) => {
        console.log(result);

        if (result.status != "ok"){
          console.log("Error when attempting to block seller!")
          console.log(result);
        } 

        if (result.status == "ok"){
          this.updateSellerInfo(this.ebaySeller);
        }

        this.updateBlockedList();

      }).catch(popupAjaxError);
  }

  @action
  unblockSellerSearch() {
    this.unblockSeller(this.ebaySeller)
  }

  @action
  unblockSellerFromTable(seller) {
    this.unblockSeller(seller)
  }

  @action
  dumpListings(){
    const encodedSeller = encodeURIComponent(this.ebaySeller);

    ajax(`/ebay/seller/dump/${encodedSeller}.json`)
      .then((result) => {
        console.log(result);

        this.ebaySellerInfo.listings_count = 0;
      }).catch(popupAjaxError);
  }
}