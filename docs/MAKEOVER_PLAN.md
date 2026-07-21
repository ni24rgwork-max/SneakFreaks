# Sneakers Shop — Modernization & Makeover Plan

Audit date: 2026-07-21 · Flutter 3.44.6 / Dart 3.12.2
All package versions below were queried live from pub.dev on the audit date, not recalled.

---

## 1. What you actually have

Be clear-eyed about the starting point: this is a **UI demo, not an app skeleton**. It was
built to be filmed for a tutorial. That's not an insult — the visual composition is genuinely
good, and it's why it's worth keeping. But almost none of the plumbing survives contact with a
real product.

### 1.1 There is no state management

```dart
// lib/data/dummy_data.dart:64
List<ShoeModel> itemsOnBag = [];        // global mutable singleton
```

Every screen mutates this global directly and calls `setState` on itself. Consequences that are
already live bugs, not hypotheticals:

| Bug | Mechanism |
|---|---|
| Bag header shows a stale count | `lib/view/bag/widget/body.dart:22` — `int lengthsOfItemsOnBag = itemsOnBag.length;` is a **field initializer**. It evaluates once when the `State` is constructed. The bag page lives inside a `PageView` whose `State` is created once and kept alive, so `"Total N Items"` (line 64) is frozen at the value it had on first build. It only re-syncs when you *delete* an item (line 166). |
| No cart badge possible | Nothing can observe the list, so the nav bar can't show a count. |
| Duplicate add is silently rejected | `AppMethods.addToCart` uses `contains()` on identity — you can never buy two of the same shoe. There is no quantity concept at all. |
| Nothing survives app restart | No persistence layer of any kind. |

This is the single biggest structural problem and it blocks the backend conversation entirely.

### 1.2 The theme is structurally incompatible with dark mode

`lib/theme/custom_app_theme.dart` is ~25 hardcoded `static const TextStyle` values with colors
baked in:

```dart
static const TextStyle homeAppBar = TextStyle(
  fontSize: 30, fontWeight: FontWeight.bold,
  color: AppConstantsColor.darkTextColor,   // ← compile-time constant
);
```

A `const` color cannot respond to `Brightness`. **Dark mode is not a feature you can add on top
of this file — the file has to be deleted.** Same for `AppConstantsColor`: five raw hexes with
no semantic roles (`backgroundColor`, `darkTextColor`, `materialButtonColor`…). There is no
notion of "surface", "on-surface", "container", "outline", so there's nothing to invert.

Also note `main.dart` sets only `fontFamily: 'Quicksand'` and no `ColorScheme` at all — so every
Material widget is currently falling back to Flutter's default seeded M3 palette (blue/purple),
which is why the snackbars and ripples look off-brand against the pink accent.

### 1.3 Money is modelled wrong

```dart
double price;                                    // lib/models/shoe_model.dart
Text("\$${model.price.toStringAsFixed(2)}")      // 4 hardcoded sites
```

Two separate problems: `double` for currency (binary floating point cannot represent 0.1
exactly — totals drift once you add tax, discounts and quantities), and the `$` symbol
hardcoded at each render site with US-style `toStringAsFixed(2)` grouping.

Render sites to change: `home/components/body.dart:196`, `:369`,
`detail/components/body.dart:399`, `bag/widget/body.dart:155`.

### 1.4 The data model carries UI concerns

```dart
class ShoeModel {
  Color modelColor;        // ← a dart:ui type inside your domain model
}
```

`Color` is not JSON-serializable. The moment a backend returns this model, this field breaks.
There's also no `id`, no sizes, no stock, no images list (single asset path only), no brand
entity — so it cannot represent a real catalogue.

### 1.5 Layout is sized off full screen height

Every section is a fraction of `MediaQuery.size.height` (`height / 2.4`, `height / 4`, …). Those
fractions sum to ~72% of the *full screen*, but the `Scaffold` body only gets what's left after
the app bar and nav bar — which is why it overflowed by 42px before I wrapped it in a scroll
view. This will break again on tablets, foldables, and with large system font scales. It needs
intrinsic/flexible sizing, not screen-fraction sizing.

### 1.6 Fonts — a concrete ₹ landmine

I parsed the `cmap` table of every bundled font:

| Font | U+20B9 (₹) | Devanagari |
|---|---|---|
| Quicksand-{Light,Regular,Medium,Bold} | **YES** | no |
| OpenSans-{Regular,Bold} | **NO** | no |

The bundled Open Sans is `Version 1.10`, a 2011-era cut that predates the rupee sign's addition.
**Any ₹ rendered in it would show as tofu (□).** Right now that's latent — Open Sans is declared
in `pubspec.yaml` but referenced **zero** times in `lib/`, so it's dead weight. Delete both files.

Quicksand does have ₹, but see §4.3 — it's the wrong typeface for this brief regardless.

### 1.7 Assets are real Nike product photography and trademarks

Flagged already, restating because it governs the makeover: `assets/images/` is Nike/Jordan
product imagery and the copy uses Nike marks. Fine for a portfolio piece; a trademark problem
the day this ships to a paying client under their own brand. The makeover is a good moment to
swap to either licensed imagery or an invented house brand.

---

## 2. Dependency audit — current vs. modern

Live pub.dev versions as of 2026-07-21.

### 2.1 Replace / remove

| Current | Verdict | Move to |
|---|---|---|
| `custom_navigation_bar 0.8.2` | **Remove.** Last meaningful release 2021, unmaintained, and it's re-implementing a widget the framework now ships. | Built-in `NavigationBar` (M3) + `NavigationBarThemeData`. Free theming, free a11y, free platform behaviour. |
| `simple_animations 5.3.0` | Maintained, but you're using ~2% of it for one fade. | `flutter_animate 4.5.2` for essentially all of it (§5). Keep `simple_animations` only if you end up wanting `MovieTween` timeline choreography. |
| `font_awesome_flutter 11.0.0` | Works, but you use exactly **two** of its icons. Bundling the full FA icon fonts for two glyphs is dead payload. | `material_symbols_icons 4.2951.0` — tracks Google's Material Symbols, variable weight/fill/grade axes, and the fill-on-select animation is the M3-native interaction. |
| `OpenSans-*.ttf` | Unused + no ₹ glyph. | Delete. |
| `flutter_lints 6.0.0` | Fine as a baseline. | Optionally `very_good_analysis 10.3.0` for a stricter production ruleset. |

### 2.2 Add — the load-bearing ones

| Package | Version | Why this one |
|---|---|---|
| `flutter_riverpod` | **3.3.2** | See §2.3. Replaces the global mutable list. |
| `riverpod_generator` | 4.0.4 | Codegen for providers; removes most boilerplate. |
| `go_router` | **17.3.0** | Declarative routing. You need this before deep links, and you *will* need deep links for an e-commerce app (share-a-product, push notifications into a PDP, payment gateway return URLs). Retrofitting routing later is painful. |
| `freezed` | 3.2.5 | Immutable models, `copyWith`, unions for UI state (`AsyncValue`-style). Makes the domain layer safe. |
| `json_serializable` | 6.14.0 | Backend-ready serialization. Pairs with freezed. |
| `intl` | **0.20.3** | Currency + date + pluralization. Non-negotiable for §4. |
| `cached_network_image` | 3.4.1 | Once the catalogue is remote, you need disk-cached images with placeholder/error states. Publish date looks old (2024) because it's simply finished — it's still the ecosystem standard. |
| `flutter_animate` | 4.5.2 | §5. Declarative animation chains. |
| `skeletonizer` | **2.1.3** | Modern replacement for `shimmer` (which last shipped in 2023). Generates skeletons from your *actual* widget tree instead of you hand-building a second grey mock layout. Big win. |

### 2.3 State management — my recommendation, with the tradeoff stated

**Use Riverpod 3.3.2.** For a catalogue + cart + auth app of this size:

- Cart, wishlist, auth session and catalogue filters are all cross-cutting state read by many
  widgets at different depths. Riverpod's provider graph handles this without `BuildContext`
  gymnastics or an `InheritedWidget` per concern.
- `AsyncNotifier` models loading/error/data as one type, which maps directly onto the
  skeleton/error/content UI states you need on every product screen.
- Auto-disposal and `ref.invalidate` give you cache invalidation (pull-to-refresh, post-checkout
  cart clear) almost for free.
- It's compile-time safe — no runtime "provider not found" like `provider`.

**The honest counter-argument:** `flutter_bloc 9.1.1` is equally production-grade and if the
client's other teams already use BLoC, consistency beats my preference. BLoC's explicit
event→state audit trail is genuinely nicer for complex checkout flows with many transitions.
The thing that matters is that you pick *one* and delete the global list — either choice is a
large improvement over the status quo. Don't use `GetX`.

### 2.4 Deliberately NOT recommending

| Package | Why not |
|---|---|
| `isar 3.1.0+1` | Last release 2023, effectively abandoned in its v3 line. Don't start new work on it. Use `drift 2.34.2` (SQL, mature, excellent) or `hive_ce 2.19.3` (the community continuation of Hive) for simple key-value. |
| `shimmer 3.0.0` | Superseded by `skeletonizer`. |
| `gap 3.0.1` | **No longer needed.** `Row`/`Column`/`Flex` have a native `spacing:` parameter now — you can see it in the framework's own RenderFlex diagnostics. Use the built-in. |
| `sliver_tools 0.2.12` | Mostly absorbed into the framework's built-in slivers. |
| `flutter_screenutil` | It encourages the exact screen-fraction sizing that caused your overflow bug. Use `LayoutBuilder`, flexible widgets and `MediaQuery.textScalerOf` instead. |
| `google_fonts 8.2.0` | Not "never" — but note it **downloads fonts at runtime by default**, which means a first-launch network dependency and a text-restyle flash. For a premium feel, bundle the font files as assets instead (§4.3). Use the package for prototyping, ship bundled. |
| `flex_color_scheme 8.4.0` | Excellent package, genuinely good. But it's a large surface area to learn, and for a single-brand app a hand-authored `ColorScheme` (§4) gives you more control and zero indirection. Reach for it only if you end up needing many themes. |

---

## 3. Theming architecture — the core rewrite

This is the part that unlocks everything else. Three moves.

### 3.1 Delete `AppThemes`, use `TextTheme`

`AppThemes.homeAppBar`, `.bagTitle`, `.profileDevName` etc. are *per-site* styles — 25 of them,
each hardcoding a color. Replace with a single semantic `TextTheme` that both brightnesses
supply, consumed as `Theme.of(context).textTheme.headlineLarge`.

Mapping to start from:

| Old | New role |
|---|---|
| `homeAppBar` (30/bold), `bagTitle`/`bagTotal` (35/bold) | `displaySmall` / `headlineLarge` |
| `homeProductModel` (22/bold), `detailsAppBar` (22/w600) | `headlineSmall` / `titleLarge` |
| `homeMoreText` (22/bold), `profileDevName` (22/w800) | `titleLarge` |
| `homeProductName` (17/w500), `bagProductModel` (17/w500) | `titleMedium` |
| `homeGridPrice`, `bagProductPrice` | `titleMedium` + tabular figures (§4.4) |
| `detailsProductDescriptions` (grey) | `bodyMedium` w/ `onSurfaceVariant` |

Colors come off the styles entirely — Material resolves them from the `ColorScheme`.

### 3.2 Put brand-specific tokens in a `ThemeExtension`

Things Material has no slot for (product-card radii, the sale/urgency color, the price-strike
color, elevation shadows tuned per brightness) go in a typed extension so they're still
brightness-aware:

```dart
@immutable
class BrandTokens extends ThemeExtension<BrandTokens> {
  final Color sale;          // price-drop / urgency
  final Color success;       // in-stock, delivery confirmed
  final Color priceStrike;   // struck-through MRP
  final Color interactiveBorder;
  final double cardRadius;
  final Duration motionFast, motionBase, motionSlow;
  final Curve motionEmphasized;
  // const ctor, copyWith, lerp …
}

// usage
final brand = Theme.of(context).extension<BrandTokens>()!;
```

Add a `context.brand` getter extension so call sites stay short.

### 3.3 Wire both brightnesses + follow the system

```dart
MaterialApp(
  theme:      AppTheme.light,
  darkTheme:  AppTheme.dark,
  themeMode:  ref.watch(themeModeProvider),   // system | light | dark, persisted
  ...
)
```

Expose a three-way toggle in Profile. `ThemeMode.system` must be the default — on Android and
iOS in 2026, silently ignoring the OS setting reads as a broken app.

**On `ColorScheme.fromSeed`:** your SDK supports it with eight `DynamicSchemeVariant`s
(`tonalSpot`, `fidelity`, `vibrant`, `expressive`, `neutral`, `monochrome`, `content`,
`rainbow`) plus a `contrastLevel` knob. It's the fastest way to a *coherent* palette, and I'd
use it to generate the starting tonal ramp. But for a **premium** result don't ship raw
`fromSeed` output — its neutral surfaces get tinted toward the seed hue, which is exactly the
faint-purple-grey look that makes apps read as "default Flutter". Generate, then hand-correct
the surface ramp to true neutrals. That's what §4 does.

Do **not** wire `dynamic_color` (Material You wallpaper theming) for this app. Letting a user's
wallpaper repaint a brand storefront is the opposite of premium, and it makes the product photos
clash unpredictably.

---

## 4. Palette & aesthetics

### 4.1 The governing principle

**In sneaker commerce, the product supplies the color.** Your catalogue is already loud —
`#DE0106` red, `#3F7943` green, `#E66863` coral, per-product. The current UI then adds a hot
pink `#fa2f65` accent on a flat `#ebebeb` grey. That's three competing chroma sources, and it's
the main reason the app reads "tutorial" rather than "retail".

Every premium reference — Nike SNKRS, END, SSENSE, and locally VegNonVeg and Superkicks — solves
this the same way: **near-monochrome chrome, generous negative space, editorial typography, and
one restrained accent reserved for commercial signals** (sale, low stock). The product photo is
the only thing allowed to be loud.

Both directions below are built on that principle. I ran every pair through WCAG.

### 4.2 Direction A — "Ink" (monochrome premium)

Warm-neutral surfaces, near-black primary, chroma reserved for commerce signals only.
This is the safer, more timeless, more obviously "premium retail" option.

**Light**

| Role | Hex | Contrast |
|---|---|---|
| `surface` (page) | `#FAFAF9` | — |
| `surfaceContainerLowest` (cards) | `#FFFFFF` | — |
| `surfaceContainerLow` | `#F5F5F4` | — |
| `surfaceContainer` | `#EFEFED` | — |
| `surfaceContainerHigh` | `#E8E8E6` | — |
| `surfaceContainerHighest` | `#E1E1DE` | — |
| `onSurface` | `#1C1B1A` | 16.47:1 on page ✅ |
| `onSurfaceVariant` (muted) | `#57534E` | 7.30:1 ✅ |
| `primary` (CTA fill) | `#18181B` | — |
| `onPrimary` | `#FAFAF9` | 16.96:1 ✅ |
| `sale` / urgency | `#B23A22` | 5.71:1 ✅ |
| `success` / in-stock | `#1B7A4B` | 5.11:1 ✅ |
| interactive border | `#79766F` | 4.34:1 ✅ (>3:1 req.) |
| hairline divider | `#E7E5E4` | decorative |

**Dark**

| Role | Hex | Contrast |
|---|---|---|
| `surface` (page) | `#0C0C0D` | — |
| `surfaceContainerLow` | `#17171A` | — |
| `surfaceContainer` | `#1F1F23` | — |
| `onSurface` | `#F4F4F5` | 17.79:1 ✅ |
| `onSurfaceVariant` | `#A1A1AA` | 7.63:1 ✅ |
| `primary` (inverts) | `#FAFAF9` | — |
| `onPrimary` | `#18181B` | 16.96:1 ✅ |
| `sale` | `#FF7A5C` | 7.63:1 ✅ |
| `success` | `#4ADE80` | 11.22:1 ✅ |
| interactive border | `#71717A` | 4.05:1 ✅ |
| hairline divider | `#27272A` | decorative |

### 4.3 Direction B — "Saffron & Ink"

Same neutral discipline, but the accent is a warm marigold/saffron `#E8A33D` instead of a red.
Reads warm-premium and carries an India resonance without resorting to literal tricolour kitsch;
it also sits more comfortably next to festive-sale merchandising (Diwali/EOSS), which you *will*
be asked for. Slightly higher risk: gold-on-dark is harder to keep from looking cheap, and it
competes with any yellow/orange product.

**Light:** page `#FBF9F6`, ink `#1A1614` (17.10:1 ✅), muted `#5C5348` (7.17:1 ✅),
accent-as-text `#8A5A12` (5.63:1 ✅), saffron fill `#E8A33D` with ink label (8.33:1 ✅),
border `#776E60` (4.78:1 ✅).

**Dark:** page `#100E0C`, text `#F5F1EA` (17.11:1 ✅), muted `#A89E90` (7.30:1 ✅),
saffron as text `#E8A33D` (8.93:1 ✅), border `#7A7167` (4.02:1 ✅).

> Note on the accent: `#E8A33D` is a *fill* color, not a text color, in light mode — saffron
> text on near-white only reaches ~2:1. The token set above already handles this by using the
> darkened `#8A5A12` for accent text on light. This asymmetry is normal and is exactly the kind
> of thing a raw `fromSeed` palette gets wrong.

### 4.4 Typography

Drop Quicksand. It's a geometric rounded sans — friendly, soft, and it reads *consumer-cute*,
not premium. It's the single biggest reason the current UI feels like a template.

Recommended pairing, both bundled as assets (not fetched at runtime):

- **Display / product names:** a tight grotesque with real weight range — **Archivo** (has a
  variable width axis, so you can go condensed for `AIR-MAX` style product wordmarks) or
  **Bricolage Grotesque** for more character.
- **UI / body:** **Inter** — the de facto standard for interface text, superb at small sizes,
  full ₹ coverage, and its **tabular figures** feature is important for you.

Two typographic details that separate professional retail UI from amateur:

1. **Tabular figures on all prices.** `fontFeatures: [FontFeature.tabularFigures()]`. Without
   it, prices in a list jitter horizontally because `1` is narrower than `8`. Apply to every
   price, total and quantity.
2. **Verify ₹ coverage before bundling.** Run the same `cmap` check I ran here on any font you
   add. Also check U+20B9 renders in *bold* and *italic* cuts, not just regular — subsetted
   families often drop it from the less-used weights.

If Hindi/Marathi/Tamil localization is on the roadmap, plan for **Noto Sans Devanagari** as a
`fontFamilyFallback` now; retrofitting script fallback after layout is finalized causes
line-height chaos.

### 4.5 Dark mode specifics worth getting right

- **Don't use pure `#000000`.** Use `#0C0C0D`. Pure black causes visible OLED smearing on scroll
  and makes elevation impossible to express. (The exception is a deliberate AMOLED power-saving
  mode as a *third* user-selectable option.)
- **Express elevation with surface tint, not shadow.** Shadows are nearly invisible on dark.
  That's exactly what the `surfaceContainerLow/High/Highest` ramp is for — a raised card is a
  *lighter* surface, not a shadowed one.
- **Desaturate product-derived colors in dark mode.** Your `modelColor` values (`#DE0106` etc.)
  were picked against a light grey. On `#0C0C0D` they'll vibrate. Apply a brightness-aware
  transform — reduce chroma ~15–20% and lift lightness — rather than using the raw hex.
- **Product photography needs handling.** Your PNGs are cut-outs on transparency, so they'll
  survive dark mode. Any future JPEG on white will look like a glowing brick — enforce
  transparent-PNG or auto-matted assets at the ingestion layer.

---

## 5. Motion & animation system

### 5.1 What's there now

One `FadeAnimation` (opacity + 30px translate, 500ms), applied per item with a delay multiplier.
Three `Hero` tags between grid and detail. That's it. The Heroes are the good part — keep the
concept.

### 5.2 Standardize motion tokens first

Before adding any animation, put durations and curves in the `BrandTokens` extension and use
them everywhere. Ad-hoc `Duration(milliseconds: 500)` scattered across files is how apps end up
feeling incoherent.

| Token | Value | Use |
|---|---|---|
| `motionFast` | 150ms | State changes: selection, toggle, ripple |
| `motionBase` | 300ms | Enters/exits, list staggers |
| `motionSlow` | 500ms | Page/container transforms |
| `motionEmphasized` | `Curves.easeOutCubic` | Default for entrances |

Rule of thumb: **anything the user initiated should feel instant (≤200ms); only transitions
where they're waiting on the app should take longer.** The current 500ms fade on every list item
is too slow and makes the app feel sluggish on repeat visits.

### 5.3 Concrete upgrades

| Now | Upgrade | Why |
|---|---|---|
| Custom `FadeAnimation` widget | `flutter_animate`: `.animate().fadeIn(duration: 300.ms).slideY(begin: .15)` | Same effect, one line, no custom widget, composable. Stagger with `.animate(delay: (60 * i).ms)`. |
| `Hero` grid→detail | `animations` **2.2.0** `OpenContainer` | Material's container-transform. The card *morphs* into the page instead of the image flying over a hard cut. This is the single highest-impact visual upgrade available. |
| Nothing during load | `skeletonizer` | Skeleton screens generated from the real widget tree. Perceived-performance win, and mandatory once data is remote. |
| `PageView` + `jumpToPage` | Keep the `PageView`, but pair with M3 `NavigationBar` | `jumpToPage` is correct here — cross-fade is right for tab switches; sliding through an intermediate tab is disorienting. Keep it. |
| Static "add to cart" | Cart-badge count animation + brief haptic (`HapticFeedback.selectionClick`) | Confirmation feedback. Indian users on mid-range Android especially rely on haptics as latency masking. |
| — | `flutter_animate` `.shimmer()` on the primary CTA, sparingly | One accent moment. Overuse kills it. |

### 5.4 Lottie vs Rive

- **`lottie 3.5.1`** — use for anything a designer hands you from After Effects. Empty-cart
  illustration, order-confirmed checkmark, payment-success. Easy pipeline.
- **`rive 0.14.9`** — use only if you want *interactive, state-machine-driven* animation (a
  wishlist heart that responds to drag, an animated nav icon reacting to scroll). Much more
  powerful, much more design investment. For v1, Lottie is the right call.

Neither should be on the critical path of first paint.

### 5.5 Accessibility guard

Wrap significant motion in a reduced-motion check — `MediaQuery.disableAnimationsOf(context)`.
This is both an a11y requirement and free insurance against jank on low-end devices.

---

## 6. Currency & India localization

### 6.1 Model money as integer paise

```dart
extension type const Money(int paise) {
  factory Money.rupees(num r) = ...;
  Money operator +(Money o) => Money(paise + o.paise);
  Money operator *(int qty) => Money(paise * qty);
}
```

Never `double`. Store paise, format at the edge. This matters the moment you add GST,
percentage discounts and quantities — floating-point drift produces totals that are off by a
paisa, and payment gateways reject mismatched amounts.

### 6.2 `intl` handles Indian formatting natively — verified

I ran this against `intl 0.20.3` rather than assuming:

```dart
NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 1)
```

| Value | `currency` | `compactCurrency` |
|---|---|---|
| 999 | `₹999` | `₹999` |
| 12999 | `₹12,999` | `₹13K` |
| 150000 | **`₹1,50,000`** | **`₹1.5L`** |
| 1250000 | `₹12,50,000` | `₹12.5L` |
| 12500000 | `₹1,25,00,000` | **`₹1.25Cr`** |

Both the **lakh/crore digit grouping** (2,2,3 not 3,3,3) and the **L/Cr compact suffixes** come
out correctly for free. Do not hand-roll this — people do, and they get the grouping wrong.

Wrap it once in a `PriceText` widget so no screen ever formats a price itself. Set
`decimalDigits: 0` — Indian retail prices are quoted in whole rupees; showing `₹12,999.00` looks
foreign.

### 6.3 Reprice the catalogue properly

**Do not multiply the USD prices by ~83.** `$130 → ₹10,790` is not a price any Indian sneaker
retailer would show. Indian MRPs are set independently and land on psychological price points.
Realistic bands for this catalogue (verify against the actual retailer before shipping):

| Product | Sensible INR band |
|---|---|
| Air Force 1 | ₹8,995 – ₹10,995 |
| Air Max | ₹12,995 – ₹16,995 |
| Air Jordan 1 Mid | ₹12,795 – ₹14,995 |
| Zoom | ₹10,995 – ₹13,995 |

Note the `,995` / `,999` endings — that convention is near-universal in Indian retail and its
absence reads as fake.

### 6.4 India-specific commerce UX to build in

These are expectations, not nice-to-haves. Ignoring them is the fastest way for an app to feel
foreign to Indian users:

| Element | Detail |
|---|---|
| **MRP + discount** | Show struck-through MRP, the sale price, and the **% off** badge. The percentage is the primary decision driver in Indian e-commerce — more than the absolute price. |
| **"Inclusive of all taxes"** | Legal Metrology (Packaged Commodities) Rules require the displayed price to be all-inclusive MRP. Put the phrase under the price. ⚠️ **Verify the current GST slab for footwear with a CA at implementation time** — the rate has changed more than once and I'm not going to state a number I can't verify today. |
| **Delivery pincode check** | An input on the PDP that returns an ETA. Users expect to check serviceability *before* adding to cart. |
| **UPI first** | UPI is the dominant payment rail. Payment sheet order should be UPI → Cards → Netbanking → Wallets → COD. Razorpay/PhonePe/Cashfree are the usual gateways. |
| **COD** | Still expected in a large share of the market, especially outside metros. Needs to be a first-class flow with its own state, not an afterthought. |
| **EMI / pay-later** | For ₹10k+ footwear, "EMI from ₹X/month" on the PDP measurably lifts conversion. |
| **Sizing** | Indian listings quote **UK/IND** sizes primarily, with US/EU secondary. Include a size chart and a "size out of stock → notify me" path. |
| **Returns/exchange** | State the window prominently. Exchange (for size) matters more than refund in footwear. |
| **Festive merchandising** | Build a themeable sale-banner slot now. You'll be asked for Diwali/EOSS/Republic Day campaigns. |

### 6.5 Localization scaffolding

Set up `flutter_localizations` + ARB files now even if you ship English-only. Retrofitting i18n
after 40 screens of hardcoded strings is one of the most expensive avoidable rewrites in mobile
work. Locale `en_IN` from day one, with the `Money`/date formatting already locale-driven.

---

## 7. Screen-by-screen makeover

**Home** — Replace the fixed-fraction `Column` with a `CustomScrollView`. Featured carousel
becomes a proper `PageView` with `smooth_page_indicator` and parallax on the shoe image.
Category chips → M3 `FilterChip`s. Add a search entry point (`SearchAnchor`) — a catalogue app
without search is not credible. Product cards get `OpenContainer` transitions, wishlist heart
with an optimistic-update animation, and a `% OFF` badge.

**Detail (PDP)** — This is where conversion happens and it's currently the thinnest screen.
Needs: image gallery (multi-image, pinch-zoom), size selector with out-of-stock states, MRP +
discount block, pincode/ETA check, EMI line, a sticky bottom `Add to bag` bar that survives
scroll, and delivery/returns accordions.

**Bag** — Fix the stale-count bug by construction (derive from the provider, never cache in a
field). Add quantity steppers, swipe-to-delete with undo, "move to wishlist", coupon input, and
an itemized price breakdown (subtotal / delivery / discount / **total**). Empty state gets a
Lottie plus a real CTA back into the catalogue.

**Profile** — Currently a placeholder with a fake user. Real structure: orders, addresses,
wishlist, payment methods, **theme toggle (system/light/dark)**, language, support, logout.

**New screens the makeover implies** — Search + results, Wishlist, Address book, Order history
and tracking, Checkout, Onboarding/auth. Scope these before quoting.

---

## 8. Suggested sequencing

Ordered so each phase is independently shippable and nothing gets built twice.

| Phase | Work | Why here |
|---|---|---|
| **0** ✅ | Modernize toolchain, remove footprints, fix overflow | Done. |
| **1** | Design system: `ColorScheme` ×2, `TextTheme`, `BrandTokens`, bundled fonts, delete `AppThemes` + `AppConstantsColor`, `themeMode` toggle | Everything downstream consumes these tokens. Doing this after the UI work means touching every widget twice. |
| **2** | Money + INR: `Money` type, `PriceText`, `intl`, reprice catalogue, MRP/discount UI, ARB scaffolding | Small, self-contained, visible client win. |
| **3** | State management: Riverpod, kill the global list, real `Cart` with quantities, fix the stale-count bug, persist with `hive_ce`/`drift` | Must precede backend work. This is the load-bearing refactor. |
| **4** | Navigation: `go_router`, typed routes, deep links | Needs to exist before payment-gateway returns and push notifications. |
| **5** | UI makeover: M3 `NavigationBar`, `CustomScrollView` home, PDP rebuild, bag rebuild, `skeletonizer` | Now it's cheap — tokens, state and routing all exist. |
| **6** | Motion: `flutter_animate`, `OpenContainer`, Lottie states, haptics, reduced-motion | Polish pass on a stable UI. |
| **7** | Backend | Separate conversation. Phase 3's model layer determines how smooth this is. |

Phases 1–2 are the fastest route to something that *looks* transformed, if you need an early
client demo.

---

## 9. Open decisions

1. **Palette: Direction A (Ink) or B (Saffron & Ink)?** Governs Phase 1.
2. **Riverpod or BLoC?** Governs Phase 3. Riverpod unless the client's team standardizes on BLoC.
3. **Brand identity** — stay Nike-branded (portfolio only) or invent a house brand? Determines
   whether the asset/trademark problem needs solving now.
4. **Scope** — is this catalogue-only, or full commerce (auth, checkout, orders, payments)? The
   new-screens list in §7 roughly triples the surface area.
