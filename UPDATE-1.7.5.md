# PullOver X 1.7.5

- Center menu: app search, force-close the media app, toggle configured VPN,
  and recreate the current hosted window.
- Search selections open inside PullOver X.
- Handle opacity supports 0-100 percent. Invisible handles retain touch input.
- The secondary handle sits opposite the primary handle with staggered vertical
  placement, including when the primary handle moves during landscape hosting.
- Window modes: 40-100 percent scaling, or a 16:9 logical app canvas (9:16 for
  portrait apps) fitted to the available screen.
- Removed the fixed 300 ms delay before opening a selected app. Existing scene
  readiness, cancellation generations, and retry logic remain.

VPN selector reference:
https://github.com/brkr1/BetterCCVPN/blob/main/VPNStore.m
The operation uses system VPNController and configured profiles. It does not
create profiles or supply credentials. Managed VPNs may reject switching.

Media termination is limited to the now-playing user-facing app with a valid
process ID. SpringBoard and this process are excluded.

Device validation is still required on iPhone 13 Pro / iOS 16.6.1 / Relaxin:
handle placement, opacity endpoints, gesture cancellation, menu actions, size
modes, keyboard positioning, rotation, locking, cold/warm launch, and VPN state.

Removing a fixed delay does not establish measured device launch speed.
The earlier reported SpringBoard failure has no confirmed diagnosis.
