# Dipi (دیپی) branding

## Idea
- "Dipi" is an Old Persian word for "writing". The mark is a **D** with a **cuneiform wedge** cut out of it.
- The wedge is a stylus mark. It is inspired by cuneiform. It is not a real letter.
- Colors: turquoise ink and gold.

## Colors
| Name | Hex |
|---|---|
| teal900 | `#08292F` |
| teal800 (icon background, seed) | `#0D3B42` |
| teal600 | `#14525C` |
| gold300 | `#F8D26A` |
| gold500 | `#F5C453` |
| gold700 | `#D9962A` |

## Files
| File | Use |
|---|---|
| `assets/branding/dipi_logo.svg` | Master logo with rounded background |
| `assets/branding/dipi_mark.svg` | Gold mark, transparent |
| `assets/branding/dipi_mark_dark.svg` | Teal mark, for light backgrounds |
| `assets/branding/app_icon.png` | 1024 px source icon |
| `assets/branding/app_icon_foreground.png` | Adaptive icon foreground |
| `assets/branding/app_icon_monochrome.png` | Android 13+ themed icon |
| `assets/branding/splash_logo.png` | Splash image |
| `assets/branding/splash_android12.png` | Android 12+ splash image |
| `assets/branding/store_icon_512.png` | Store icon (Play, Bazaar, Myket) |
| `android/app/src/main/res/...` | Ready Android icon files |
| `lib/core/theme/brand_colors.dart` | Colors and gradients |
| `lib/shared/branding/dipi_logo.dart` | `DipiMark` and `DipiLogo` widgets |

## Setup
1. Copy all folders into the Flutter project root. Merge `res/` with the existing one.
2. Add the assets from `pubspec_additions.yaml`.
3. In `android/app/src/main/AndroidManifest.xml` set `android:label="دیپی"`.
4. Splash:
   ```
   flutter pub add --dev flutter_native_splash
   dart run flutter_native_splash:create
   ```
   (`flutter_native_splash.yaml` is in the project root.)
5. Optional, to rebuild icons after a logo change:
   ```
   flutter pub add --dev flutter_launcher_icons
   dart run flutter_launcher_icons
   ```

## In-app use
```dart
const DipiLogo(size: 120, showName: true);                // gold, animated
const DipiMark(size: 40, color: BrandColors.teal800);     // on light surfaces
```

## Rules
- Keep clear space around the mark of at least 1/4 of its height.
- Use gold on dark teal. Use teal on light backgrounds.
- Do not stretch, rotate, or add shadows.
