# Architecture

How the app is put together, and the reasoning behind the decisions that aren't
obvious from reading the code.

---

## Layers

```
view/        screens and widgets — no business logic, no raw hex, no formatting
  ↓ watch
providers/   Riverpod — cart, catalogue, derived totals
  ↓ read
models/      ShoeModel, CartLine — plain immutable data
data/        catalogue fixture, SharedPreferences
theme/       ColorScheme × 2, BrandTokens, TextTheme
utils/       Money
```

The rule the codebase enforces: **a widget never computes a total, formats a
price, or names a colour.** It reads a provider and a theme token. Everything
derived lives in a provider so it cannot go stale.

---

## Theme

`theme/` is the load-bearing layer. Everything visual resolves through it.

- **`palette.dart`** — a hand-authored `ColorScheme` per brightness, including
  the full M3 `surfaceContainer` ramp.
- **`brand_tokens.dart`** — a `ThemeExtension` for what Material has no slot
  for: `sale`, `success`, `accentText`, `priceStrike`, `interactiveBorder`,
  `hairline`, radii, and motion durations.
- **`typography.dart`** — the type scale.
- **`app_theme.dart`** — assembles `ThemeData` and exposes `context.colors`,
  `context.text`, `context.brand`.

**Why hand-authored rather than `ColorScheme.fromSeed`.** Seeded schemes tint
their neutral surfaces toward the seed hue. That faint purple-grey cast is the
single most recognizable "default Flutter app" tell. For a multi-brand store the
surfaces need to be genuinely neutral so competing brand colours can sit on them
without clashing.

**Why elevation is expressed as lightness, not shadow.** On a dark surface a
shadow is nearly invisible. A raised card is a *lighter* surface — that's what
the `surfaceContainerLow/High/Highest` ramp is for. `cardTheme` sets `elevation:
0` and `surfaceTintColor: transparent` deliberately.

**Why dark mode isn't pure black.** `#0C0C0D`, not `#000000`. Pure black smears
visibly on OLED during scroll and leaves no headroom to express elevation.

### Two failure modes this layer is designed against

**Hardcoded surfaces are more dangerous than hardcoded text colours.** A literal
`Colors.white` card background looks fine in light mode and renders theme-white
text invisible in dark mode. It fails in exactly one brightness, so it survives
review. Every surface must come from the `ColorScheme`.

**A saturated accent is not automatically legible as text.** A colour bright
enough to be a good button fill is usually too light to be a readable label on a
light background. `BrandTokens.accentText` exists as a separate darkened token
for this reason, and `textButtonTheme` overrides Material's default of using
`colorScheme.primary` for link labels.

### Typography

Two bundled variable fonts: **Archivo** (display; has a width axis for condensed
product wordmarks) and **Inter** (UI and body).

- **Weights are applied via `FontVariation` on the `wght` axis, not
  `fontWeight`.** A variable font does not reliably respond to `fontWeight`
  alone — every style renders at the default weight. Both are set:
  `fontVariations` drives the axis, `fontWeight` keeps fallback and a11y
  behaviour correct.
- **All prices use tabular figures.** Without them, numerals in a list shift
  horizontally as values change, because `1` is narrower than `8`.
- **Verify `U+20B9` (₹) before bundling any font.** The Open Sans cut originally
  in this project was a 2011 version that predates the rupee sign — ₹ would have
  rendered as tofu. Parse the `cmap` table; don't assume.

---

## Money

```dart
extension type const Money(int paise)
```

**Integer paise, never `double`.** Binary floating point cannot represent 0.1
exactly. The error is invisible on a single price and compounds the moment
quantities, percentage discounts and tax are applied — and payment gateways
reject amounts that disagree by a paisa.

Formatting comes from `intl` with the `en_IN` locale, which supplies both the
2,2,3 digit grouping (`₹1,50,000`, not `₹150,000`) and the compact lakh/crore
suffixes (`₹1.5L`, `₹1.25Cr`). This is not hand-rolled — the grouping rule is
easy to get wrong.

`decimalDigits: 0` is deliberate. Indian retail quotes whole rupees; `₹12,999.00`
reads foreign.

---

## State

**Riverpod 3.** The cart is the interesting case.

```dart
class CartLine {
  final String productId;  // id, not a ShoeModel
  final String size;       // "7.5" — a code, not a number
  final int quantity;
}
```

**Lines store a product id, not a product object.** Three consequences: the cart
serializes to plain JSON without touching non-serializable UI types like
`Color`; a persisted cart survives the catalogue being replaced by an API
response; and orphaned lines (product delisted) resolve to nothing and
contribute zero to totals rather than crashing.

**Size is part of the line's identity.** The same shoe in two sizes is two
lines, not one with quantity 2. The line key is `productId#size`.

**Size is a `String`.** Half sizes exist (`"7.5"`), and EU/US codes aren't
integers either.

**Every total is a derived provider.** `cartCount`, `cartSubtotal`,
`cartMrpTotal`, `cartSavings`, `deliveryFee`, `cartTotal` — nothing caches a
value in widget state. This is a direct response to a real bug in the original
code, where the bag header read a count captured once in a `State` field
initializer and displayed a stale number for the life of the screen.

Persistence is JSON in `SharedPreferences` under a `_v1`-suffixed key. A corrupt
or schema-changed payload resets to empty rather than crashing on launch.

---

## Routing

`go_router`, with `StatefulShellRoute.indexedStack` giving each bottom-nav tab
its own navigator. Open a product from Home, switch to Bag, come back — you are
still on the product. The previous `PageView` could not express that.

**Routes carry ids, not objects.** `DetailScreen` takes a `productId` and
resolves it from the catalogue. A route has to be reconstructable from a URL
string, and an object cannot travel in one.

**Browse routes hang off the Home branch only.** `go_router` requires route
names to be globally unique, so the same named route cannot be attached to
several branches. It also matches use: every path into a product starts from
the feed. If the Bag ever needs a PDP, give it a prefixed copy
(`/bag/product/:id`).

**Deep links use a custom scheme** — `sneakfreaks://product/sku-001`. That works
without owning a domain. Universal Links (iOS) and App Links (Android) need a
verified domain serving `apple-app-site-association` and `assetlinks.json`;
those are a TODO for when a domain exists.

⚠️ **Custom-scheme URIs need normalizing.** `Uri.parse` reads
`sneakfreaks://product/sku-004` as **host** `product` with path `/sku-004`, so
nothing matches and the user hits the not-found page. The router folds the host
back into the path before matching. This was caught by opening a real link on a
device — the widget tests passed either way.

**The auth guard exists before auth does.** `/checkout` redirects to `/sign-in`
carrying `?from=`, so signing in returns the user to checkout rather than home.
The session is a stub, but the gate is in place so checkout cannot ship without
one.

## Product detail

Rebuilt as a `CustomScrollView`: collapsing gallery hero, content slivers, and
the purchase bar pinned outside the scroll view.

**The purchase bar is `Scaffold.bottomNavigationBar`, not an inline widget.**
The old page put ADD TO BAG in the scroll column, so it left the screen as soon
as you read the description. On a page whose only job is converting, the
primary action stays reachable.

**The PDP is full-screen, above the shell.** The bottom nav both competes with
the sticky CTA and costs 68px. Nike SNKRS, Myntra and Ajio all do this.

**The discount appears here, not only in the feed.** The previous page showed a
bare selling price — the strongest purchase signal vanished at the point of
decision.

**Sold-out sizes render struck through rather than hidden.** "Not for me" and
"out of stock right now" are different messages, and only one of them keeps the
shopper on the page.

**Size selection is keyed by product id.** A global selection would leak into
the next product opened, which silently ships the wrong item.

Layout bugs this replaced, all caused by fixed screen-fraction sizing:
`Container(height: height * 1.1)` around the page so content could not grow;
`height / 9` around the description, slicing it mid-sentence with no ellipsis;
and `width / 9` around the "UK" label, which wrapped it onto two lines.

## Loading states

`catalogueProvider` is a synchronous *view* of an asynchronous source:

```dart
catalogueAsyncProvider          // AsyncNotifier — the real, awaited source
catalogueProvider               // .value ?? const []  — what derived logic reads
catalogueLoadingProvider        // .isLoading — what the UI reads
```

Splitting it this way meant making the catalogue async did not ripple through
the ten derived providers built on top of it. Swapping the fixture for an HTTP
call is a change to one method body.

**Skeletons are generated from the real widget tree** (`skeletonizer`), not
hand-built grey mocks — a mock is a second layout that drifts from the first.

**Placeholder rows never reach business logic.** While loading,
`catalogueProvider` stays empty and only the feed substitutes placeholder
products for Skeletonizer to paint, so the cart can never resolve a line
against a fake product.

## Indian commerce specifics

These are expectations in the Indian market, not embellishments.

- **Lead with the discount.** MRP struck through, sale price, **% off** badge.
  The percentage drives the decision more than the absolute price.
- **"Inclusive of all taxes."** Legal Metrology (Packaged Commodities) Rules
  require the displayed price to be all-inclusive MRP.
- **The cart summary starts from Total MRP.** Listing a discounted subtotal and
  *then* subtracting the discount double-counts it and reads as broken
  arithmetic. The column must add up.
- **UK sizing first.** Indian listings quote UK, with US/EU secondary.
- **Free-delivery threshold.** ₹1,999, with an "add ₹X more" nudge.

⚠️ **The GST slab for footwear is not encoded anywhere in this app and should
not be guessed.** The rate has changed more than once. Confirm the current slab
with a CA before any invoice or tax-breakup feature is built.

---

## Known gaps

| Gap | Impact |
|---|---|
| Screen-fraction layout | Home sizes sections as fractions of full screen height. Wrapped in a scroll view as a stopgap; needs `CustomScrollView` before tablets/foldables. |
| `ShoeModel.modelColor` | A `dart:ui` `Color` inside a domain model. Not serializable — must leave before a backend supplies the catalogue. |
| Product imagery | Placeholder material, not cleared for commercial use. |
| Gesture coverage | Swipe-to-delete and the size sheet are unit-tested at the logic level but the gestures themselves are unexercised. |
| Hero on cards | A product renders in several rails at once, so per-card `Hero` tags collided. Only the carousel is a hero source; Phase 6 replaces this with `OpenContainer`. |
| Pincode check | Returns a plausible ETA for any valid 6-digit input. Needs a real serviceability API before shipping. |
| Product copy | Descriptions and specs are marked `PLACEHOLDER` in the fixture. Grep for it. |
| Gallery | Products carry one image, so the gallery shows one page. Ready for multiple angles when real photography lands. |
| Universal / App Links | Custom scheme only. Needs a verified domain. |

---

## Toolchain

Flutter 3.44.6 / Dart 3.12.2. Key dependencies: `flutter_riverpod` 3.x, `intl`,
`shared_preferences`, `flutter_animate`-ready.

Deliberately **not** used: `flutter_screenutil` (encourages the screen-fraction
sizing that caused the original layout bug), `gap` (`Row`/`Column` ship a native
`spacing` parameter), `shimmer` (superseded by `skeletonizer`), `isar`
(effectively unmaintained since 2023).
