# Sneakers Shop

A sneakers e-commerce mobile app built with Flutter, featuring animated product
listings, a detail view with hero transitions, cart, and profile screens.

## Requirements

- Flutter 3.44+ (Dart 3.12+)
- Xcode (for iOS) / Android Studio (for Android)

## Getting started

```bash
flutter pub get
flutter run
```

## Project structure

```
lib/
  animation/    # fade/slide entrance animations
  data/         # dummy product data
  models/       # data models
  theme/        # colors, text styles
  utils/        # helpers
  view/
    home/       # product listing + animated cards
    detail/     # product detail screen
    bag/        # cart screen
    profile/    # profile screen
    navigator.dart
  widget/       # shared widgets
assets/
  images/       # product imagery
  fonts/        # OpenSans, Quicksand
```

## License

Apache-2.0 — see [LICENSE](LICENSE).
