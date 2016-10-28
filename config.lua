Config = {}


--Should certain ores be distance-gated?
Config.distanceGate = {
	--["copper-ore"] = true,
	["fluorite"] = true,
	["uraninite"] = true,
	["tungsten-ore"] = true,
	["gem-ore"] = true,
	["crude-oil"] = true,
	["sulfur"] = true,
	["titanium-ore"] = true,
	["nickel-ore"] = true,
	["silver-ore"] = true,
	["gold-ore"] = true,
	["cobalt-ore"] = true
}

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
	["sulfur"] = 2,
	["cobalt-ore"] = 3,
	["bauxite-ore"] = 3, --aluminum
	["zinc-ore"] = 3,
	["gold-ore"] = 3,
	["gem-ore"] = 3,
	["rutile-ore"] = 4, --titanium
	["tungsten-ore"] = 4,
	["uraninite"] = 5,
	["fluorite"] = 5,
}


--Ores that MUST be present near the center
Config.starterOres = {
	"coal",
	"iron-ore",
	"copper-ore",
	"stone",
}

--How much to flat-scale the distance gating
Config.oreDistanceFactor = 1
Config.oreRichnessDistanceFactor = 1
Config.oreTierDistanceFactor = 2--1
Config.spawnerDistanceFactor = 0.75--0.5--1

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
Config.retrogenOreDistance = -1--180
Config.retrogenSpawnerDistance = -1--0
--[[
--An ore-specific version of ore retrogen control, in case an ore was added.
Config.retrogenOreSet = {
	"sulfur"
}--]]

--[[
--If an ore is deleted due to distance gating, it is replaced with the mapping in this table
Config.replacementTable = {}

Config.replacementTable["copper-ore"] = "stone"
Config.replacementTable["tin-ore"] = "iron-ore"
Config.replacementTable["lead-ore"] = "iron-ore"
Config.replacementTable["sulfur"] = "coal-ore"
Config.replacementTable["silver-ore"] = "iron-ore"]]