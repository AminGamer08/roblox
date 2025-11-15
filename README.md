# TrendSurge: Viral Challenge Arena

TrendSurge is a Roblox party experience designed for virality. Players ride the latest internet trends inside a neon-soaked arena, competing in rapid-fire challenges while showing off meme-ready cosmetics. This repository contains scripts, design notes, and implementation guidelines to bootstrap the experience inside Roblox Studio.

## Contents
- `docs/GameDesign.md` – Detailed game design document covering loop, monetization, and roadmap.
- `src/ReplicatedStorage/ChallengeDefinitions.lua` – Definitions for launch mini-games.
- `src/ServerScriptService/ViralChallengeManager.server.lua` – Handles rotating trending challenges.
- `src/ServerScriptService/RewardService.server.lua` – Persistence and reward calculations.
- `src/StarterPlayer/StarterPlayerScripts/ClientUI.client.lua` – Client UI for trending meter and rewards.

## Getting Started
1. Create a new Roblox place and upload the contents of `src/` into the matching services:
   - `ReplicatedStorage` → `ChallengeDefinitions` ModuleScript and `Remotes` folder.
   - `ServerScriptService` → `ViralChallengeManager` & `RewardService` scripts.
   - `StarterPlayer` → `StarterPlayerScripts/ClientUI` LocalScript.
2. In `ReplicatedStorage/Remotes`, create RemoteEvents named `TrendingUpdated`, `ChallengeState`, and `RewardGranted`.
3. Replace `arenaAssetId` placeholders in `ChallengeDefinitions.lua` with actual asset IDs for your challenge maps.
4. Hook the teleport logic in `ViralChallengeManager` to your challenge arenas or reserved servers.
5. Publish the place and begin playtesting.

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
- Build greybox prototypes of the three launch challenges listed in `ChallengeDefinitions.lua`.
- Integrate DataStore throttling/backoff to handle scale safely.
- Implement social features (party queueing, friend challenges) to drive organic growth.

