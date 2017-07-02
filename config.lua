Config = {}

Config.oreTierDistances = {
	tier0 = 0,
	tier1 = 40,
	tier2 = 200,
	tier3 = 500,
	tier4 = 1000,
	tier5 = 2000
}

Config.oreTiers = {
	["coal"] = 0, --vanilla
	["iron-ore"] = 0, --vanilla
	["copper-ore"] = 0, --vanilla
	["stone"] = 0, --vanilla
	["ground-water"] = 0,
	["tin-ore"] = 1,
	["lead-ore"] = 1,
	["quartz"] = 1,
	["nickel-ore"] = 2,
	["silver-ore"] = 2,
	["crude-oil"] = 2, --vanilla
	["lithia-water"] = 2,
	["zinc-ore"] = 2,
	["sulfur"] = 2,
	["cobalt-ore"] = 3,
	["bauxite-ore"] = 3, --aluminum
	["gold-ore"] = 3,
	["gem-ore"] = 3,
	--["geothermal"] = 3,
	["rutile-ore"] = 4, --titanium
	["tungsten-ore"] = 4,
	["uraninite"] = 5,
	["fluorite"] = 5,
	["uranium-ore"] = 5, --vanilla
}

Config.richnessFactors = { --add entries here to add flat richness multipliers by ore type. Unspecified ores default to one. Some ores - notably liquids - are ignored in favor of internal code.
	["sulfur"] = 0.6
}

--Ores that MUST be present near the center
Config.starterOres = {
	"coal",
	"iron-ore",
	"copper-ore",
	"stone"
}

--Ores unaffected by custom distribution
Config.ignoredOres = {
	"geothermal"
}

--How much to flat-scale the distance gating
Config.oreDistanceFactor = 1
Config.oreRichnessDistanceFactor = 1
Config.oreTierDistanceFactor = 2--1
Config.spawnerDistanceFactor = 1.25--0.75--0.5--1

--Richness Scaling
Config.richnessScaling = true

--A multiplier for the base of richness scaling.
Config.oreRichnessScalingFactor = 2.5

--A flat-rate multiplier for richness.
Config.flatRichnessFactor = 1

--Spawner Scaling
Config.spawnerScaling = true

--Flat-rate spawner chance multiplier
Config.spawnerRateFactor = 1

Config.clearSmallPatches = true

--Should a custom ore/spawner placement algorithm be used? This helps clean up the otherwise messy and often balance-unfriendly generation
Config.redoOrePlacement = true
Config.redoSpawnerPlacement = true

--Should retrogeneration be enabled, and if so, at what minimum radius from the center?
Config.retrogenOreDistance = -1
Config.retrogenSpawnerDistance = -1

--These values (N1, N2) will make ore patches N times larger but 2N times rarer at the minimum and maximum distances. Intermediate distances are interpolated.
Config.orePatchCondensationStart = 1
Config.orePatchCondensationEnd = 2--3

--Enable behemoth (green) worms? The worm counterpart to the green biters.
Config.enableHugeWorms = true

--Should spawners be made more durable? This helps discourage clearing large swathes of land of biters, encouraging more defences rather than just "kill everything on the map"
Config.nestHealthFactor = 10