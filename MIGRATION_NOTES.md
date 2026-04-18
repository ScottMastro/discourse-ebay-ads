# Ebay Ads Plugin — Migration Notes

Context document for the component-template-resolving deprecation migration and other modernization work surfaced during that investigation. Pick up from here when returning to this plugin.

Reference: https://meta.discourse.org/t/handling-the-component-template-resolving-deprecation/370019

---

## Deprecation: `component-template-resolving`

Discourse is preparing for Ember 6. Templates under `templates/components/` resolved separately from their JS class trigger this deprecation. Fix is to **colocate** the `.hbs` next to the JS (or convert template-only components to `.gjs`).

## Components in this plugin

Inventory as of migration start. All paths relative to `assets/javascripts/discourse/`.

### 1. `ebay-ad-banner`

- Template: `templates/components/ebay-ad-banner.hbs`
- Backing class: `components/ebay-ad-banner.js.es6` (Glimmer component, `@tracked model`, `@tracked voteStatus`, actions for click/vote/impression tracking)
- Callers (classic invocation):
  - `connectors/discovery-list-container-top/ebay-ad-slot.hbs` → `{{ebay-ad-banner}}`
  - `connectors/topic-above-post-stream/ebay-ad-slot.hbs` → `{{ebay-ad-banner}}`

**Migration:**
1. `mv templates/components/ebay-ad-banner.hbs components/ebay-ad-banner.hbs`
2. Rename `components/ebay-ad-banner.js.es6` → `components/ebay-ad-banner.js` (drop legacy extension)
3. Template already uses `this.model` / `this.voteStatus` / `this.trackEbayClick` — matches class. No template edits needed.
4. Optional follow-up: convert callers to angle-bracket `<EbayAdBanner />`.

### 2. `ebay-item-row`

- Template: `templates/components/ebay-item-row.hbs`
- Backing class: none
- Callers: `templates/ebay-search.hbs:112` → `<EbayItemRow @item={{item}} @trackEbayClick={{this.trackEbayClick}} />`
- Already uses `@item.*` / `@trackEbayClick` throughout the template — clean.

**Migration:** convert to `.gjs` single-file component at `components/ebay-item-row.gjs`.
- Needs imports for `i18n`, `dIcon`, `formatDate`, and `@service siteSettings` (template accesses `siteSettings.ebay_epn_id`).
- Delete the old `.hbs` after conversion.
- No caller changes needed (already angle-bracket).

### 3. `ebay-item-grid`

- Template: `templates/components/ebay-item-grid.hbs`
- Backing class: none
- Callers: `templates/ebay-search.hbs:114` → `<EbayItemGrid @item={{item}} @trackEbayClick={{this.trackEbayClick}} />`
- **Caller passes `@item` but the template refers to bare `{{item.title}}`** (classic implicit-arg style). This currently works via classic component default behavior but breaks in strict-mode `.gjs`.

**Migration:**
1. Rewrite template to use `@item.*` everywhere.
2. Convert to `.gjs` at `components/ebay-item-grid.gjs`.
3. Needs imports for `i18n`, `dIcon`, `formatDate`.
4. No caller changes (already passes `@item`).

### 4. `ebay-preferences-settings`

- Template: `templates/components/ebay-preferences-settings.hbs`
- Backing class: **`preferences/components/ebay-preferences-settings.js.es6`** (non-standard location — lives under `preferences/components/` not `components/`). This is currently picked up by Ember's resolver. Class injects `ebayUserSettings` service and mirrors tracked state onto `this.ebayUsername` / `this.hideListings` / `this.discourseId` via getters/setters.
- Caller: `connectors/user-custom-preferences/ebay-preferences.hbs` → `{{ebay-preferences-settings model=this.model}}` (classic invocation)
- Related:
  - `preferences/services/ebay-user-settings.js.es6` — the backing service
  - `preferences/initializers/ebay-preferences-settings.js.es6` — registers a save-hook on `controller:preferences/profile` via `api.modifyClass(...)` with legacy `actions: { save() { this._super(...) } }` pattern

**Migration:**
1. Move backing class: `preferences/components/ebay-preferences-settings.js.es6` → `components/ebay-preferences-settings.js`
2. Move template: `templates/components/ebay-preferences-settings.hbs` → `components/ebay-preferences-settings.hbs`
3. Update connector to angle-bracket invocation:
   ```hbs
   {{#if siteSettings.enable_ebay_ads}}
     <EbayPreferencesSettings @model={{this.model}} />
   {{/if}}
   ```
4. Verify class still references `this.args.model.id` (line 35) — already correct.
5. Rename `.js.es6` → `.js` while touching it.

**Separate concern — not strictly part of this deprecation:** the initializer at `preferences/initializers/ebay-preferences-settings.js.es6` uses:
- `api.modifyClass('controller:preferences/profile', { actions: { save() { this._super(...) } } })`

This `actions:` hash + `_super` reopen pattern is deprecated Ember classic-class syntax. It may break on upgrade. Needs a plan:
- Likely path: convert to `api.modifyClass(..., (Superclass) => class extends Superclass { @action save() { super.save(...arguments); ... } })`. Verify the `preferences/profile` controller is still a class-based controller upstream before writing the replacement.

## Other legacy patterns in this plugin (not blocking the deprecation)

- Files still using `.js.es6` extension — harmless but legacy. Rename on touch.
- `lib/ebay_scraper.rb` is a stub returning hardcoded values; `text` is referenced but not defined (line 7). Dead code or in-progress.
- `plugin.rb` registers `onclick={{action this.X}}` usages in templates — `{{action}}` helper is deprecated in modern Ember; should become `{{on "click" this.X}}`. Relevant in `templates/components/ebay-ad-banner.hbs`, `templates/components/ebay-item-row.hbs`. Does not block the current deprecation.
- `templates/ebay-search.hbs` — not yet inspected for similar issues; audit when touching it for the item-row / item-grid conversions.

## Suggested execution order

1. `ebay-ad-banner` — colocate only, no logic risk. Proves the pattern end-to-end in dev.
2. `ebay-item-row` — clean `.gjs` convert.
3. `ebay-item-grid` — mechanical template rewrite + `.gjs` convert.
4. `ebay-preferences-settings` — move backing class out of `preferences/components/`, angle-bracket the connector.
5. (Separate PR/commit) fix the `actions:` / `_super` pattern in the preferences initializer.
6. (Opportunistic) `{{action}}` → `{{on}}` modifiers in the banner/row templates while they're being touched.

## Verification per step

After each component conversion:
- `pnpm lint:js` and `pnpm lint:hbs` on the plugin directory
- Load the dev site, open the relevant UI (front page banner, `/ebay` search page, user preferences page)
- Open DevTools console, search for `[deprecation id: component-template-resolving]` — should not appear for the migrated component
- Smoke test: ad click, vote, impression logging still record in the DB

## Efficiency / performance — observations

Separate track from the deprecation migration. Captured while reading the plugin. Validate numbers against real data once the dev DB is restored from the production backup.

### Ad serving path (`/ebay/ad` → `EbayAdController#ad_data`)

Hot path: runs on every banner impression on the front page and topic pages.

1. **`EbayListing.count > 0`** (line 6) — full count aggregation where `.exists?` would do. Cheap on small tables, wasteful on large.
2. **`ORDER BY RANDOM()`** (line 12) — classic Postgres anti-pattern. Full seq scan + sort on every request. For N active listings per seller this is O(N log N) per ad impression. Options:
   - `OFFSET floor(random() * count)` pattern (one count + one row fetch).
   - Cache the candidate listing-id array per seller in Redis/PluginStore on the same 6h TTL as weights; random-sample in Ruby.
3. **`weighted_random_selector`** (line 40) — builds a Ruby array with each seller pushed `weight` times, then `.sample`. For 100 sellers with weight ~100 that's 10K array allocations per ad request. Replace with:
   - Precomputed cumulative-weight array stored alongside `ebay_seller_weights` in the PluginStore. Binary search on `rand(total)` → O(log n) and zero allocations.
4. **Two separate cache keys would help**: current design caches weights (6h) but re-queries sellers+listings every request. A single combined cache of `{seller_id → [listing_ids]}` + cumulative weights would cut every ad request to one cache get + one listing fetch by id.
5. **`EbayAdPlugin::EbaySeller.where(hidden: false, blocked: false)`** runs twice per weight-cache-miss (once in `weighted_random_selector`, once in `calculate_all_weights`). De-duplicate.

### Data pull path (`Jobs::GetSellerListings` + `EbayAPI.fetch_listings_by_seller`)

1. **Per-row `find_or_initialize_by` + `save!`** in `ListingManager.record_ebay_listings` (line 38). For a seller with 200 listings, that's 200 `SELECT` + 200 `INSERT/UPDATE`. Replace with `upsert_all` keyed on `item_id`, or wrap the loop in a single transaction.
2. **`sleep SLEEP_TIME` (1s) inside a Sidekiq job loop** — blocks the worker. Better: re-enqueue with a delay between pages, or use a rate-limit token bucket.
3. **No deactivation of stale listings.** The schema has an `active` column (added 2024-04) but nothing in `record_ebay_listing` or the job ever sets it to `false`. Listings that end/sell remain `active=true` forever, polluting the ad pool. Need a diff step: "listings not seen in this fetch → active=false."
4. **`EbayApiCall` counter increments** via `find_or_initialize_by` + `increment!` → 2 queries per API call. Use `INSERT ... ON CONFLICT DO UPDATE SET count = count + 1` (`upsert` with raw SQL) or rely on a single atomic update.
5. **No dedup on `EbayBannerImpression`** (`ad_impression`, controller line 125). Every pageview creates a row. For heavy pages this grows fast. Consider bucketed counts (by hour) or dedup by `(user_id, item_id, date)`.

### Quick wins (ordered by payoff / effort)

1. `.count > 0` → `.exists?` in `ad_data`. One-line, always a win.
2. Replace `ORDER BY RANDOM()` with `OFFSET random() * count`. ~5 lines.
3. Batch `record_ebay_listings` via `upsert_all`. ~15 lines, huge throughput win for data pulls.
4. Move weighted random from per-request Ruby array-build to cumulative-weight binary search on the cached pool.
5. Add the active-deactivation step in the fetch job.

> **Note:** the hardcoded `query = "pokemon"` in `fetch_listings_by_seller` is intentional — this forum is pokemon-specific, so narrowing each seller's listings to pokemon items is the correct behavior. Not a bug.

### Measurement

Once the prod backup is restored we can:
- Time `ad_data` with real listing/seller counts via `Benchmark.measure` in rails console.
- Grab `pg_stat_statements` top-N to see which plugin queries dominate.
- Check row counts on `ebay_listings`, `ebay_banner_impressions`, `ebay_search_impressions` to size the impact.

## Status

- [x] 1. `ebay-ad-banner` — converted straight to `.gjs` (not just colocated). Also: `onclick={{action}}` → `{{on "click"}}`, `@action={{(fn ...)}}` → `@action={{this.method}}`, removed three `{{#if false}}` dead-code blocks, dropped unused console noise.
- [x] 2. `ebay-item-row` → `.gjs`. Template-only component gained a tiny class with `@service siteSettings` to fix the `this-property-fallback` deprecation on `{{siteSettings.ebay_epn_id}}`. `{{action}}` → `{{on "click" (fn @trackEbayClick @item.item_id)}}`.
- [x] 3. `ebay-item-grid` template rewrite + `.gjs`. Pure template-only (no service needed). Bare `{{item.*}}` → `{{@item.*}}`.
- [x] 4. `ebay-preferences-settings` relocation + angle-bracket. Backing class moved from `preferences/components/` to `components/` and colocated as `.gjs`. Connector updated to `<EbayPreferencesSettings @model={{this.model}} />`. Dropped the no-op `withPluginApi` wrapper in the constructor.
- [ ] 5. Preferences initializer modernization — deferred. `actions: { save } + this._super` pattern in `preferences/initializers/ebay-preferences-settings.js.es6`. Currently silent but may error on upgrade to main.
- [ ] 6. `{{action}}` → `{{on}}` cleanup — deferred. Main remaining site is `templates/ebay-search.hbs` which still uses `{{input}}`, `(action)` with pre-bound args, and string-name actions. No active deprecation at this commit.

## Other fixes done in the same pass

- `@ember/service` `inject as service` → `service` rename (folded into the preferences-settings conversion).
- `siteSettings` `this-property-fallback` fixed in three templates: `connectors/discovery-list-container-top/ebay-ad-slot.hbs`, `connectors/topic-above-post-stream/ebay-ad-slot.hbs`, `templates/ebay-search.hbs`.
- `{{ebay-ad-banner}}` classic invocation → `<EbayAdBanner />` in both connectors.
- Removed two stale debug `console.log` statements from `controllers/ebay-search.js.es6`.

## Verification done

Baseline established: Discourse `v3.6.0.beta1-dev` at commit `40a6542e62`, Ember `v6.6.0`, DB restored from `elite-fourum-2026-04-12-033939-v20250828011415.sql.gz` (17k users, 60k topics, 819k posts, 425k eBay listings). After these changes, console is free of ebay-specific deprecations. Visual/functional verification: ad banner renders on front-page and topic pages; `/ebay` search renders items; user preferences page renders the eBay Username field.

## Still to do (perf track, separate from deprecations)

See "Efficiency / performance — observations" above. Next concrete step is to capture a baseline measurement of `ad_data` against the restored 425k-listing DB, then ship the "Quick wins" PR and re-measure.

### Baseline (to fill in)

- `EXPLAIN ANALYZE` on the `ORDER BY RANDOM()` path: _pending_
- Avg ms per `ad_data` over 200 iterations: _pending_
- Queries per `ad_data`: _pending_
- Ruby allocation count during `weighted_random_selector`: _pending_
