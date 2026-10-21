# PullOver X 1.7.7

- Replaces the central action list with a circular picker. Search, force-close
  media app, VPN, and window reload surround the center Cancel button.
- Search still opens a searchable app list and hosts selections in the window.
  Returning from search restores the radial picker.
- Each edge handle supports independent vertical dragging and saved normalized
  positions, including rotation. Horizontal swipes retain their panel behavior.
- Position lock applies to both handles.
- Both manual dragging and relayout enforce a vertical gap between handle touch
  areas and keep positions inside the safe-area limits.

Verify on-device: radial action/cancel hit targets, search navigation and keyboard
cleanup, status feedback, each handle's position persistence, collision behavior,
rotation, left-handed mode, position lock, long-press search and double tap.

The circular picker uses native UIKit buttons/SF Symbols and existing routing,
without adding an external menu dependency.
