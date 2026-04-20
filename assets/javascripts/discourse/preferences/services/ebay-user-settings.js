import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";

export default class EbayUserSettingsService extends Service {
  @tracked discourseId = null;
  @tracked ebayUsername = "";
  @tracked hideListings = false;
}
