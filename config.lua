Config = {} --ignore this line; technical

--This is the configuration file for Oreverhaul, so used because the settings are too numerous and complex for the ingame setting system. To edit it, either extract the mod or use a program like WinRAR to edit it in situ.
--Defaults are how I play; you are obviously free to change it as you please. Some "past attempted values" can be seen in multiset comments (eg "0.5--0.25--0.375--0.125"); feel free to try those.
--Some values (such as ore plateau distance, some base chance values, etc) are defined in the "constants" file (in the same folder as this file);
--You can edit those too, but they are undocumented and were never designed for modification, so do so at your own risk. There will be no guarantee of support for such modifications.

--Generally, the idea is to 1) encourage exploration, as it yields better ore richness, 2) force trains during progression, as belting uranium 5000 tiles is idiotic, and 3) cause player-biter conflict due to the minimum spawner
--generation distance (usually) being less than the minmum distance for many ores.

--It is recommended that you test a set of options by generating, charting, and examining, to a large distance, at least 6 or so maps before committing to a playthrough with it.

--With Oreverhaul installed, all ore-/spawner-related map generation settings in the menu (size, frequency, richness) are entirely ignored except for water. This is for convenience, as this config is persistent between game
--sessions, and those menu settings are not.

--Oreverhaul should be able to do everything RSO can, and more; it was originally written for personal use when RSO proved insufficient:
-- https://www.reddit.com/r/factorio/comments/58otsk/help_with_rso_in_a_manyore_environment_and_with/

--Oreverhaul ore patches are usually composed of multiple "circles" of ore, which are immediately visually different from the noise-gen-based more..."angular" shapes of vanilla Factorio.
--This is normal, and their only gameplay influence is slightly more convenient mining drill placement, something I consider desirable.

--For reference, the general algorithm is one of interpolation between a "starter area" state and a "plateau" (max distance) state, with each state having preset ore patch chance, per-tile richness, and overall average size.
--There is no concept of "generate N units of ore per chunk", "ensure minimum distance of X between ore patches", or "generate ore A near ore B", so no such settings exist and that effect cannot be directly attempted.
--Indeed, most programmers will recognize the inherent difficulty of implementation of what may seem simple conceptually.

--If you have mods that make biters substantially more difficult - either directly, or by mechanics like faster evolution (eg NauvisDay mod) - it is suggested, though not required, that you also include a combat-boosting mod,
--such as EndgameCombat. You may otherwise find yourself, map generation depending, forced to take down a biter base full of medium biters with nothing better than low-tier grenades, an endeavour which usually proves lethal.


--#################################################################################################################
--These are the broad-stroke overall controls. They always apply (though details may vary based on other settings).
--#################################################################################################################

--Reasonably self-explanatory. How far (in tiles) must you travel before tier N ores begin to generate?
--You can also set all tier distances to zero to effectively disable tiering.
Config.oreTierDistances = {
	tier0 = 0,
	tier1 = 25, --was 40
	tier2 = 200,
	tier3 = 500,
	tier4 = 1000,
	tier5 = 2000
}

--Which ores fit in what tier. Anything not in this list is entirely ignored (deleted and not generated).
--Adding custom ores is entirely supported; use their internal names. Any specified ore that does not exist is ignored for generation but logged.
--BobMod ores configured with input from Bobingabout, and so should be reasonably fitting for his progression.
--AngelOres not included by default since their processing (more advanced resources based on processing the same ore type) is fundamentally incompatible with a distance tiering system.
--Add them if desired, but there is little point in doing so.
Config.oreTiers = {
	["coal"] = 0, --vanilla
	["iron-ore"] = 0, --vanilla
	["copper-ore"] = 0, --vanilla
	["stone"] = 0, --vanilla
	["ground-water"] = 0, --fluid
	["tin-ore"] = 1,
	["lead-ore"] = 1,
	["quartz"] = 1,
	["nickel-ore"] = 2,
	["silver-ore"] = 2,
	["crude-oil"] = 2, --vanilla, fluid
	["lithia-water"] = 2, --fluid
	["zinc-ore"] = 2,
	--["sulfur"] = 2, --not usually enabled in game
	["cobalt-ore"] = 3, --not usually enabled in source mod
	["bauxite-ore"] = 3, --alumin(i)um
	["gold-ore"] = 3,
	["gem-ore"] = 3,
	["rutile-ore"] = 4, --titanium
	["tungsten-ore"] = 4,
	["uraninite"] = 5, --not really relevant anymore as of 0.15, unless UraniumPower still exists(?)
	["fluorite"] = 5, --not really relevant anymore as of 0.15, unless UraniumPower still exists(?)
	["uranium-ore"] = 5, --vanilla
}

--Ores that MUST be present near the center. Numerical values are their relative weights (since not all are of equal need in the early game).
Config.starterOres = {
	["coal"] = 4,
	["iron-ore"] = 7,
	["copper-ore"] = 4,
	["stone"] = 2,
}

--Ores unaffected by custom distribution; usually things that have their own gen code that should not be tampered with (eg biome specific, certain patterns, etc).
Config.ignoredOres = {
	"geothermal"
}

--Should a custom ore/spawner placement algorithm be used? This helps clean up the otherwise messy and often balance-unfriendly generation. Many settings have no effect if this is disabled.
Config.redoOrePlacement = true
Config.redoSpawnerPlacement = true

--Should richness scaling be enabled? If not, richness is flat across the map.
Config.richnessScaling = true


--#################################################################################################################
--Fine tuning controls.
--#################################################################################################################

--Add or modify entries here to add flat richness multipliers by ore type. Unspecified ores default to one. Some ores - notably liquids - are ignored in favor of internal code.
--No ore has this by default (that I know of).
Config.richnessFactors = {
	["sulfur"] = 0.6
}

--Add or modify entries here to add flat ore patch size multipliers by ore type. Unspecified ores default to one. No effect on liquids. Some clamping is applied to avoid tiny ore patches (clamped at starter area size).
--In the base game, stone has a penalty (equivalent to assigning a value of 0.67); this is removed by default since it is usually irritating.
--Only meaningful if ore generation override is ENABLED.
Config.radiusFactors = {
	["sulfur"] = 0.75
}

--At a given distance, there is a set of ores which are permitted for generation (determined by distance gating). When an ore patch is to be generated, one entry in that list is selected.
--Normally every ore is equally likely to generate, being randomly selected from that set; this option allows you to reduce the overall frequency of certain ores (those patches may become something else).
--Anti-biasing triggers a "reroll" of the ore if the first selection has a corresponding value; it may select the same ore again (with the same chance as before),
--Anti-biasing is applied once per patch only; even if the new ore is the same as the old one, it will NOT reroll again, nor will it do anything if the new ore also has an anti-bias.
--The numerical effect of an anti-bias on a certain ore, assuming N possible ores, and an anti-bias of 'f', is a chance reduction from 1/N to (1/N)-((1/N)*f*(1-1/N)).
--So, for example, if sulfur is one of eight candidate ores, and has a 25% anti-bias, one quarter of the sulfur gets "rerolled", 7/8ths of which becomes something other than sulfur, or a total reduction of 0.125*0.25*0.875.
--Only meaningful if ore generation override is ENABLED, and does not apply to the start area.
--Anti-biases must be between zero and one. Values outside this range will at best have no effect and at worst cause serious issues.
Config.antiBias = {
	["sulfur"] = 0.8,
	["stone"] = 0.2 --this one is not recommended for a BobMods environment (at least not as the 0.4 default) due to the greater need for stone, but helps in vanilla to deal with excessive amounts of it
}


--These values are mixed into the world seed for ore/spawner generation, so you can keep terrain/biome/etc while choosing a new ore/spawner distribution. Mixins of 0 have no effect.
Config.oreMixinSeed = 16756750
Config.spawnerMixinSeed = 1

--Raw offsets for the entire oregen pattern, in case you have terrain you like "off center" but would like to move the ore or spawner patches to effectively move the starting area.
Config.offsetX = 0
Config.offsetY = 0

--How much to flat-scale the distance gating (Ore Tier Distances)
Config.oreTierDistanceFactor = 2--1

--A base scaling for the distance-richness curve. At 2, you need to travel 2x as far for the same richness boost.
Config.oreRichnessDistanceFactor = 1

--How much to flat-scale the distance gating (Ore Tier Distances) AND richness curve. Basically the above two options combined.
Config.oreDistanceFactor = 1

--How much to flat-scale the ore patch size distance scaling. Values larger than one "compress" the scaling, values less than one (but more than zero) expand it, all by that corresponding factor.
Config.oreSizeDistanceFactor = 1

--Like the above, but for spawners (base size, worm tier, etc)
Config.spawnerDistanceFactor = 0.9--1.25--0.75--0.5--1

--A multiplier for the base rate of richness scaling.
Config.oreRichnessScalingFactor = 2.5

--A flat-rate multiplier for richness.
Config.flatRichnessFactor = 1

--A flat-rate multiplier for ore patch chance per chunk. Higher means more ore patches (not recommended above base settings unless you have a world with little space for ore); lower means patches are rarer.
--Be careful in an environment with many ores, lest you make hunting for a specific ore type painful.
--Only meaningful if ore generation override is ENABLED.
Config.orePatchChanceFactor = 1.25--1

--Does the richness plateau at an internally calculated distance, or does it keep growing forever? Note that this can create ore patches with billions of ore if set to false.
Config.plateauRichness = false

--Spawner Scaling (making spawners "tier up" with distance); Only meaningful if spawner generation override is DISABLED, as the feature is built into the override.
Config.spawnerScaling = true

--Flat-rate spawner chance multiplier. Only meaningful if spawner generation override is ENABLED.
Config.spawnerRateFactor = 1

--Should small (few-tile) ore patches (usually the result of ore deletion) be cleaned up? Only meaningful if ore generation override is DISABLED, as the override generation does not have this issue.
Config.clearSmallPatches = true

--These values (N1, N2) will make ore patches N times larger but 2N times rarer at the minimum and maximum distances. Intermediate distances are interpolated.
--Only meaningful if ore generation override is ENABLED.	
--Be warned that excessive patch size (above ~3.2) will cause ore patch cutoffs, as the ore patches become greater than 3x3 chunks in size, and the generation algorithm, for performance reasons, does not model a 5x5 chunk area.
Config.orePatchCondensationStart = 1
Config.orePatchCondensationEnd = 2--3

--If false, richness is a global parameter shared by all ores, so at the same distance, explicit multipliers notwithstanding, iron, tin, gold, and uranium and so on will have the same richness.
--If true, each ore starts its richness curve "fresh" from when it first appears. So if ore A appears at distance X and B at distance Y, the richnesses would be equal at N blocks from X or Y respectively.
Config.richnessPerOre = false

--Should spawners be made more durable? This helps discourage clearing large swathes of land of biters, encouraging more defences rather than just "kill everything on the map". Not strictly worldgen, but does dovetail with it.
Config.nestHealthFactor = 10

--Should retrogeneration be enabled, and if so, at what minimum radius from the center? A value of "-1" Disables it entirely; >= 0 enables it with that minimum distance. May not be MP compatible. Obviously causes lag spikes.
Config.retrogenOreDistance = -1
Config.retrogenSpawnerDistance = -1

--Should newly-built enemy bases have the distance (worm size, spawner type, etc) restrictions and distance scaling forcibly applied?
--Helpful if you have a nice clear ore patch then get a spitter nest plopped on it four hours into the game.
--No performance impact unless your biters are expanding more aggressively than AIs in a game of Civilization on the Deity difficulty (and if that is the case, you need a lot more than this to help you).
--Does not affect already-built bases, and tapers off as the evolution factor rises (100% effect at evo 0, 0% at evo 1)
Config.enforceSpawnerTieringForBuiltBases = true

--If a save is using expensive recipe or technology mode, all ore richnesses are multiplied by this, so as to reduce the chance of becoming 'stranded' without the resources with which to build/research trains.
--Combine with each other, as well as other difficulty-based multipliers if applicable. Must be positive, and is generally advised to be >1, since making harder recipes have *less* ore nearly guarantees stranding.
Config.expensiveRecipeMultiplier = 1.5
Config.expensiveTechMultiplier = 1.125

--If using a technology cost factor greater than one, that factor is multiplied by this then multiplied into the ore richness, to partially (or depending on settings, completely) offset the increased resource cost.
--Like the above, to reduce the risk of stranding and will combine with other multipliers as necessary. At difficulty 1x, nothing has any effect.
--The actual formula is R=1+(D-1)*F, where D is the tech cost factor, F is this option's value, and R is the net richness multiplier. Must be positive.
Config.techCostMultiplierFactor = 0.4