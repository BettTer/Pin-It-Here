# Pin It Here

Pin a note to a real wall, floor, or ceiling with your iPhone, walk away, and find it in the same spot when you come back.

Pin It Here is an iOS prototype built with **ARKit** and **RealityKit**. It is the technical core of a location-based social app idea: instead of matching strangers by their photos, people leave notes on real places, and the next person who stands there can read them and start a conversation with context.

## Status

This is a working prototype of the AR core, not a finished app.

| Area | State |
|---|---|
| Finding surfaces and placing notes | Working |
| Saving notes on the device | Working |
| Restoring notes in the same spot later | Working, with three fallbacks |
| Notes written by the user (text, audio, video) | Planned; the prototype places a sample card |
| Nearby discovery, comments, messages, friends | Planned |

## What it does

- **Finds surfaces in real time.** The session detects horizontal and vertical planes. Every frame, a raycast from the center of the screen looks for a surface, and a custom placement reticle shows when a note can be placed.
- **Renders notes from SwiftUI.** A note is a SwiftUI view rendered to an image with `ImageRenderer` and applied as an unlit material on a plane mesh, so any SwiftUI layout, emoji, or rich text can become a note in the room.
- **Uses scene reconstruction when available.** On devices with LiDAR, the session builds a classified mesh of the room.
- **Saves everything needed to find a note again.** Each note is stored locally as JSON with its transform, size, anchor, its pose relative to the camera at placement, an archived `ARWorldMap`, and the GPS position and true heading at that moment.
- **Restores notes through a chain of fallbacks:**
  1. **World map:** relaunch the session with the saved `ARWorldMap` and let ARKit relocalize.
  2. **GPS and heading:** if relocalization fails, convert the saved GPS position and true heading into a local east-north-up frame and place the note approximately.
  3. **Snap to a surface:** once a detected plane that is parallel to an approximately placed note and just behind it (within 10 cm) stays stable for a few frames, snap the note onto it so it doesn't float in the air.
- **Waits for a good map before placing.** The place button turns on only when tracking is normal, the reticle is on a surface, and world mapping has stayed `mapped` for several frames, so each saved map is more likely to relocalize.

## Tech stack

- Swift, SwiftUI, and UIKit
- ARKit (world tracking, plane detection, raycasting, scene reconstruction, `ARWorldMap`)
- RealityKit (`ARView`, `AnchorEntity`, `ModelEntity`, generated meshes, unlit materials)
- Core Location (GPS and true heading) and Core Motion
- A local Swift package, `LocalSharedPackage`, for the note model, storage, math helpers, and shared UI
- Swift Package Manager dependencies: Alamofire, ProgressHUD, and paper-onboarding

## Project structure

```
PinItHere/
├── PinItHere.xcodeproj
└── PinItHere/
    ├── Common/System/          App and scene delegates
    ├── Pages/
    │   ├── ARComposer_SUIV.swift       Main screen: AR view, place and remove buttons
    │   ├── SwiftUIVs/ARScene/          AR session, placement, saving, and restoring
    │   └── Old/                        Early experiments
    ├── Managers/               World map storage, location and heading, SwiftUI-to-texture
    │                           rendering, reticle meshes, AR models
    ├── LocalSharedPackage/     Note model and store, math (ENU and heading), utilities
    └── Resources/              Info.plist, assets, English and Simplified Chinese strings
```

## Requirements

- Xcode 26 or later
- iOS 18.6 or later
- A physical iPhone or iPad that supports ARKit world tracking. AR does not run in the Simulator.
- A LiDAR device is optional; it enables scene reconstruction.

## Getting started

1. Clone the repository and open `PinItHere/PinItHere.xcodeproj`.
2. In **Signing & Capabilities**, choose your own team and change the bundle identifier.
3. Build and run on a device, then allow camera, motion, and location access.
4. Point the camera at a wall or the floor and move slowly until the reticle shows the surface is ready.
5. Tap **Place the note**. Close the app, come back to the same spot, and reopen it to watch the note restore. **Remove all notes** clears everything.

## Roadmap

These come from the product plan and are not built yet:

- Notes written by the user, with text, audio, or video, using the camera view at that moment as the background
- Discovering notes within 1 to 10 km without opening the camera
- Comments, direct messages, friend requests, and a friend feed
- AI features: drafting notes, translating between languages, matching by shared interests, and spotting trending places

## About

I built this on my own in under three weeks, and it was my first time using ARKit and RealityKit. Most of the work went into the part users never see: making a note come back to the same place after the app has been closed.

Built by [Young Chen](https://github.com/BettTer).
