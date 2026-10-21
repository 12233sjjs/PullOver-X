# PullOver X 1.7.6

- Double tapping the hosted window or either handle promotes the hosted app to
  fullscreen and immediately ends the floating/split session. An explicit native
  activation bypass prevents the fullscreen request being routed back into a window.
- App-to-app URL and attributed application opens route to the hosted window for
  all user-facing targets. The previous whitelist and toggle no longer gate this.
  Existing system trust checks, source attribution, scene readiness, native
  fallback on failure, and notification routing are preserved.
- Window corner radius is adjustable from 0 to 100 points, default 20.
  Content clipping and shadow paths use the configured radius.
- Window size remains adjustable from 40 to 100 percent, now in 1 percent steps.
  The alternate 16:9 canvas mode remains available.

Double tap is installed on the hosted content container without cancelling touches.
Apps with their own double-tap gestures should be checked on-device.

Validation required on the target device: fullscreen takeover without a leftover
placeholder, app-to-app URL payload delivery from both native and hosted apps,
notification opens, ordinary system prompts, launch failures, size/radius
endpoints, rotation, and hosted keyboard behavior. These private system paths
cannot be fully exercised by the macOS compiler.
