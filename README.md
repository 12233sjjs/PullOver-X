# PullOver X

Based on PullOver Pro by `c1d3rDev`.
Adapted for iOS 14+, added some features, and fixed some known issues.

## 1.7.3 gesture and routing changes

- While an application is fullscreen, long-press the handle and drag to the screen center to search installed apps; selecting an app starts it in the floating window.
- With handle position locked, swipe up to snap the floating panel closed; swipe down to host the current fullscreen app in the split window.
- In landscape fullscreen, the handle rail uses the right screen edge.
- Trusted links from an app in the floating session route to another app inside that session. Notification taps use the existing guarded route and preserve system fallback when the target cannot be safely hosted.
- Existing URL-routing preferences remain opt-in for launches from a closed panel.



- The existing handle long-press launcher opens in 0.2 seconds (previously 0.3 seconds); it uses the configured Recent Apps or Favorite Apps list.
- In the landscape hosted-card layout, the handle remains on the bottom-right edge while the card opens and closes.
- Handle position transitions are interruptible and can be interacted with while animating.
- Notification launches are kept within an already active floating session when the tapped app is the app currently hosted; other notification targets use the existing guarded route/fallback behavior.

Build success is not a substitute for on-device testing. The previously reported missing-handle issue is not confirmed resolved.

## 1.7.1 interaction changes

- Single-tap the handle while a floating app is open to move that app to native fullscreen.
- With the floating panel closed, single-tap still reveals/opens the panel.
- Opening the currently hosted app natively releases its floating session instead of routing it back into the panel.
- Long-press and drag gestures remain available. Double-tap is no longer required for fullscreen.

Build success is not a substitute for on-device testing. The previously reported missing-handle issue is not confirmed resolved.

## License

PullOver X is distributed under the [GNU General Public License v3.0](LICENSE).
