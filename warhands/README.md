# warHands — Prototype

A mobile third-person battle-royale-style prototype built in **Godot 4.3**
(GDScript). This is a real, runnable project — not a mockup — with a
GitHub Actions workflow that builds an installable debug APK on every push.

## What's actually in here

- **Boot sequence** matching your spec: `JagX` → `JRILICENSE` → `warHands`
  logo → animated loading bar → main menu (`scripts/Boot.gd`)
- **4 characters** with different speed/health stats (Raider, Ghost,
  Juggernaut, Viper) — `scripts/GameState.gd`
- **2 maps**: Dustbowl Ruins and Harbor District, each with cover objects,
  bot spawn/patrol points, and a player spawn
- **3 weapons** (pistol, rifle, sniper) with real stat differences, plus
  **attachment customization**: optics (red dot / 4x scope), grips, and
  magazines that measurably change spread/range/fire-rate/reload/mag size
- **Bot enemies** with a patrol → chase → attack state machine (stand-ins
  for other players until real netcode exists — see below)
- **Mobile touch controls**: left-side virtual joystick for movement,
  right-side drag-to-look, on-screen fire/reload/weapon-switch buttons
- **A GitHub Actions workflow** (`.github/workflows/android-build.yml`)
  that builds a signed debug `.apk` you can download and install directly

## Testing it right now (fastest path, no Android needed)

1. Install [Godot 4.3](https://godotengine.org/download) (the standard
   editor, not "Godot Mono" — this project uses pure GDScript).
2. Open Godot → "Import" → select this folder's `project.godot`.
3. Press the Play button (▶) in the top-right. It'll boot straight into
   the splash sequence, then the menu.
4. On desktop, movement is WASD, look is right-click-drag, shoot is
   the on-screen Fire button (still clickable with a mouse).

## Getting a real APK to install on your phone

You don't need Android Studio for this — GitHub's servers do the build:

1. Create a new **GitHub repository** and push this entire folder to it
   (`git init`, `git add .`, `git commit -m "warHands prototype"`,
   `git remote add origin <your-repo-url>`, `git push -u origin main`).
2. Go to the repo's **Actions** tab. The "Build Android APK" workflow
   runs automatically on push (or click "Run workflow" to trigger it
   manually).
3. Wait for the run to go green (a few minutes).
4. Open the finished run → scroll to **Artifacts** → download
   `warHands-debug-apk`. It's a zip containing `warHands.apk`.
5. Transfer that `.apk` to your Android phone and install it (you'll
   need to allow "install from unknown sources" — this is a debug
   build, not a Play Store release, so Android will warn you; that's
   expected for testing).

This workflow uses a **debug keystore** (auto-generated inside the CI
run), which is fine for testing on your own device but is not suitable
for publishing to the Play Store — that requires a real release
keystore you generate and keep private (never commit it to the repo).

## Current limitations, honestly

- **Bots, not real players.** True online multiplayer battle royale
  needs a networking backend (server-authoritative movement, hit
  validation, matchmaking). This prototype uses local bots so it's
  fully playable and testable today without any server.
- **Placeholder art.** Characters and weapons are capsules/boxes with
  flat colors, not modeled/animated assets. Swap in real 3D models
  (`.glb`/`.gltf`) by replacing the `MeshInstance3D` nodes.
- **No anti-cheat, no accounts, no persistence** — this is a design +
  mechanics prototype, not a live-service backend.

## Going online (the real path, when you're ready)

To turn this into an actual online multiplayer game:
1. Pick a networking layer: **Godot's built-in high-level multiplayer
   API** (ENet/WebRTC, good for learning) or a dedicated backend like
   **Photon Fusion** or **Nakama** (more production-ready, has
   matchmaking built in).
2. Move movement/shooting to a client-predicts-server-confirms model:
   the client shows instant feedback, but the server is the source of
   truth for hits/damage/positions (this is what stops cheating).
3. Add a matchmaking service so players get grouped into lobbies
   instead of everyone spawning locally.
4. Replace the `bots` group logic in `Bot.gd` with real remote player
   nodes synced over the network.

This is a genuinely large step (this is most of what makes COD Mobile/
PUBG Mobile expensive to build), but the game logic, map layout,
weapon system, and UI you have here carry over directly — you'd be
adding a networking layer underneath, not starting over.
