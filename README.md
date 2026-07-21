# SneakFreaks

**An AI-powered premium multi-brand sneaker store.** Built with Flutter, priced
in ₹, designed for India.

Owner / maintainer: **[@ni24rgwork-max](https://github.com/ni24rgwork-max)**

---

## What this is

A curated multi-brand sneaker storefront — Nike, Adidas, Jordan, Puma and
others under one roof — where the discovery layer is driven by a recommendation
engine rather than a static grid.

The intent is that the catalogue reorders itself around the shopper: fit and
size history, brand affinity, price band, and what they were last looking at.
Search is conversational ("something for monsoon running under ₹12,000"), not
keyword matching against a product title.

The design system is deliberately monochrome. In a multi-brand store the chrome
cannot favour any one brand's colours — Nike red, Adidas blue and Jordan green
all have to sit on neutral ground. Product photography supplies the colour; the
interface supplies the restraint.

---

## Status — read this before evaluating

This is an **honest status board**, not a feature list. Nothing below is
aspirational unless it says so.

### Built and running

| Area | State |
|---|---|
| Design system | Two-brightness M3 theme, hand-authored palette, all pairs WCAG-verified |
| Dark / light / system | Working, persisted across restarts |
| Typography | Bundled Inter + Archivo variable fonts, tabular figures on all prices |
| Currency | ₹ throughout — integer paise, `en_IN` lakh/crore grouping |
| Cart | Riverpod state, quantities, per-size lines, persisted to disk |
| Pricing UI | MRP strikethrough, % off, free-delivery threshold, inclusive-of-taxes |
| Routing | `go_router` — per-tab stacks, deep links, auth guard |
| Product detail | Collapsing gallery, discount block, size selector with stock states, pincode check, sticky CTA |
| Account screen | Reflects real session — signed-out state, no fake identity |
| Loading states | Skeletons from the real widget tree; pull-to-refresh |
| Motion | Tokenised durations, shared-axis page transitions, reduced-motion honoured |
| The Locker | Collectible card binder — TCG-proportioned cards from real catalogue data, rarity by price, personal collection tracker |
| Tests | 55 tests over cart, money, feed, routing, PDP, locker and motion |

### Not built yet

| Area | State |
|---|---|
| **AI recommendations** | **Designed, not implemented.** See [docs/AI.md](docs/AI.md) |
| Backend | Not started — catalogue is an in-memory fixture |
| Auth, checkout, payments | Routes and guard exist; screens are stubs |
| Search | Route exists; conversational search not built |
| Orders, addresses, wishlist | Not started |

> The app currently ships **zero** AI functionality. The recommendation
> architecture is specified in `docs/AI.md` and is the next major workstream.
> Please don't read the name as a claim about what runs today.

---

## Requirements

- Flutter 3.44+ / Dart 3.12+
- Xcode (iOS) or Android Studio (Android)

## Running it

```bash
flutter pub get
flutter run
```

Tests:

```bash
flutter test
```

---

## Project layout

```
lib/
  theme/        design system — palette, tokens, typography, ThemeData
  models/       ShoeModel, CartLine
  providers/    Riverpod — cart, catalogue
  data/         catalogue fixture, SharedPreferences provider
  utils/        Money (integer paise, ₹ formatting)
  view/         home · detail · bag · profile
  widget/       shared widgets
assets/
  images/       product photography
  fonts/        Inter, Archivo (both carry ₹ and tabular figures)
docs/           architecture and planning
test/           unit tests
```

---

## Documentation

| Doc | What's in it |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the app is put together and why |
| [docs/AI.md](docs/AI.md) | The recommendation architecture — model choice, cost, privacy |
| [docs/MAKEOVER_PLAN.md](docs/MAKEOVER_PLAN.md) | Modernization audit and phased roadmap |

---

## Notes for anyone picking this up

**Money is never a `double`.** It's integer paise behind a `Money` extension
type. Binary floating point can't represent 0.1, and the drift shows up the
moment tax, discounts and quantities compound — payment gateways reject amounts
that disagree by a paisa.

**Prices are Indian MRPs, not converted dollars.** Multiplying a USD price by
the exchange rate produces numbers no Indian retailer would display. Prices sit
on the `,995` / `,999` points the market actually uses.

**Brand is data, never hardcoded.** Anywhere a screen would have said "Nike",
it reads `product.name`. That's what makes the store multi-brand rather than a
Nike app with other logos in it.

**Sizes are strings, not numbers.** `"7.5"` exists, and EU/US codes aren't
integers either.

---

## Credits

The initial UI composition was derived from an Apache-2.0 licensed Flutter
project; that license is retained in [LICENSE](LICENSE). Everything since —
design system, state layer, currency handling, and the AI architecture — is
original work.

Product photography in `assets/` is placeholder material and is **not** cleared
for commercial use. It must be replaced with licensed or own-shot imagery
before this ships.

## Third-party assets

Bundled fonts are **Inter** and **Archivo**, both under the SIL Open Font
License 1.1 — see `assets/fonts/OFL-Inter.txt` and `assets/fonts/OFL-Archivo.txt`.

## License

Apache-2.0 — see [LICENSE](LICENSE).
