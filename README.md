# TrendSurge: Viral Challenge Arena

TrendSurge is a Roblox party experience designed for virality. Players ride the latest internet trends inside a neon-soaked arena, competing in rapid-fire challenges while showing off meme-ready cosmetics. This repository contains scripts, design notes, and implementation guidelines to bootstrap the experience inside Roblox Studio.

## Contents
- `docs/GameDesign.md` – Detailed game design document covering loop, monetization, and roadmap.
- `src/ReplicatedStorage/ChallengeDefinitions.lua` – Definitions for launch mini-games.
- `src/ServerScriptService/ViralChallengeManager.server.lua` – Handles rotating trending challenges.
- `src/ServerScriptService/RewardService.module.lua` & `RewardBootstrap.server.lua` – Persistence, streak tracking, and autosave wiring.
- `src/ServerScriptService/ChallengeArenaController.lua` – Spawns arena models and tracks finishes.
- `src/ServerScriptService/RemotesSetup.server.lua` – Guarantees RemoteEvents exist for client messaging.
- `src/StarterPlayer/StarterPlayerScripts/ClientUI.client.lua` – Client UI for trending meter and rewards.

## Getting Started
1. Create a new Roblox place and upload the contents of `src/` into the matching services:
   - `ReplicatedStorage` → `ChallengeDefinitions` ModuleScript. The included `RemotesSetup` script will create the `Remotes` folder and RemoteEvents automatically when the server boots.
   - `ServerScriptService` → `ViralChallengeManager`, `ChallengeArenaController` ModuleScript, `RewardService` ModuleScript, `RewardBootstrap` Script, and `RemotesSetup` Script.
   - `StarterPlayer/StarterPlayerScripts` → `ClientUI` LocalScript.
2. In **ServerStorage**, create a folder named `Arenas` and place one model per challenge inside it. Each model should contain:
   - A folder named `Spawns` with SpawnLocation parts or base parts for teleport positions.
   - A folder named `GoalPads` containing parts players touch to finish the round.
   - (Optional) A folder named `Hazards` containing parts that eliminate players on touch.
3. Update `ChallengeDefinitions.lua` with the model names you placed in `ServerStorage.Arenas` (defaults already match `FloorIsLava`, `ViralParkour`, and `DanceDuel`).
4. Add a `LobbySpawns` folder to **Workspace** with at least one SpawnLocation or Part to define intermission spawn points.
5. Publish the place and run a test server—RemoteEvents, leaderstats, DataStores, and UI will wire themselves up automatically.

## Virality Strategy
TrendSurge is purpose-built for shareability:
- **Frequent Content Drops** keep the experience fresh and reward returning players.
- **Highlight Reel Moments** occur whenever players finish first, win a dance duel, or trigger hidden emote combos.
- **Community Voting Terminals** empower the audience to influence future content updates.
- **Influencer Tooling** like private trend arenas and streamer-friendly camera modes encourage creators to feature the game.

## Monetization Hooks
- Premium emotes, limited-time cosmetics, and a season pass extend revenue beyond session counts.
- Temporary boosts that affect the global Trending Meter encourage cooperative spending.
- VIP private servers offer curated experiences for influencers and friend groups.

## Next Steps
- Build greybox prototypes of the three launch challenges listed in `ChallengeDefinitions.lua` and drop them in `ServerStorage.Arenas`.
- Integrate DataStore throttling/backoff to handle scale safely.
- Implement social features (party queueing, friend challenges) to drive organic growth.

