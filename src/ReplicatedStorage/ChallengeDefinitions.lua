local ChallengeDefinitions = {
    FloorIsLava = {
        displayName = "Floor is Lava",
        description = "Hop across disappearing platforms before the lava rises!",
        duration = 90,
        difficulty = 1.2,
        rewardMultiplier = 1.3,
        arenaAssetId = "rbxassetid://1234567",
        instructions = {
            "Platforms disappear faster as time goes on.",
            "Bonus clout for staying mobile and emoting mid-air.",
        },
    },
    ViralParkour = {
        displayName = "Viral Parkour",
        description = "Race across a short-form obstacle course inspired by trending clips.",
        duration = 75,
        difficulty = 1.0,
        rewardMultiplier = 1.1,
        arenaAssetId = "rbxassetid://2345678",
        instructions = {
            "Use speed pads to outpace rivals.",
            "Triggers highlight replay for the first finisher.",
        },
    },
    DanceDuel = {
        displayName = "Dance Duel",
        description = "Follow emote prompts to rack up combo multipliers in a rhythm showdown.",
        duration = 60,
        difficulty = 1.4,
        rewardMultiplier = 1.5,
        arenaAssetId = "rbxassetid://3456789",
        instructions = {
            "Perfect combos increase trend contribution.",
            "Trigger special emotes for bonus hype.",
        },
    },
}

return ChallengeDefinitions
