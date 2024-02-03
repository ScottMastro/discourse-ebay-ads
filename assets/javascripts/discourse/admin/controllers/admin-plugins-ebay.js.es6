import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class AdminPluginsEbayController extends Controller {
  @tracked allSellers = [];
  @tracked ebaySeller = "";
  @tracked blockReason = null;

  init(){
    super.init(...arguments);
    this.updateSellerList();
  }

  updateSellerList(){
    ajax("/ebay/seller/info")
    .then((result) => {
      this.allSellers = result.sellers;
    }).catch(popupAjaxError);
  }

  @action
  addSeller() {
    if (this.ebaySeller != ""){
      const encodedSeller = encodeURIComponent(this.ebaySeller);
      ajax(`/ebay/seller/add/${encodedSeller}`)
      .then((result) => {
        updateSellerList();
      }).catch(popupAjaxError);
    }
  }

  @action
  blockSeller() {
    if (this.ebaySeller != ""){

      const encodedUsername = encodeURIComponent(this.ebaySeller);

      let reason = "";
      if (this.blockReason != ""){
        const encodedBlockReason = encodeURIComponent(this.blockReason);
        reason = `?reason=${encodedBlockReason}`;
      }

      ajax(`/ebay/seller/block/${encodedUsername}.json${reason}`)
        .then((result) => {
          updateSellerList();
        }).catch(popupAjaxError);
      }
  }


  @action
  deleteSellerFromTable(ebay_username){
    const encodedUsername = encodeURIComponent(ebay_username);
    ajax(`/ebay/seller/remove/${encodedUsername}`)
    .then((result) => {
      if(result.status == "ok"){
        this.allSellers = this.allSellers.filter(seller => seller.ebay_username !== ebay_username);
      }
    }).catch(popupAjaxError);    
  }

  updateBlockedList(){
    ajax("/ebay/info/blocked")
    .then((result) => {
      console.log(result)
      this.allBlockedSellers = result.all;
    }).catch(popupAjaxError);
  }

  updateSellerInfo(ebay_username){
    const encodedSeller = encodeURIComponent(ebay_username);
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
  unblockSellerSearch() {
    this.unblockSeller(this.ebaySeller)
  }

  @action
  unblockSellerFromTable(seller) {
    this.unblockSeller(seller)
  }
  @action
  blockSellerFromTable(seller) {
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