require "config"

ore_plateau = 5000 --ore richness plateaus here
ore_plateau_value = 10 --multiplier at plateau

unclamped_ore_scaling = 0.06 --if plateauing is disabled

core_distance = 120 --the distance defining the "start area" to force all necessary starting ores and prevent any spawners
base_ore_patch_chance = 0.4--0.25--0.25--0.125--0.5--0.125
final_ore_patch_chance = 0.25--0.675--0.5--0.75--0.5
center_patch_chance = 1.5--1.625--1.5

center_richness_factor = 1

min_plop_size = 5
max_plop_size = 12
min_patch_size = 10
max_patch_size = 24

min_spawner_dist = 200 --was 300
min_spitter_dist = 400--500
min_worm_dist = 500--400
full_spawn_dist = 3000--1500
min_spawner_chance = 0.1875--0.25--0.1--0.0625--0.025 --lowest value of per-chunk chance of spawner cluster
full_spawn_amount = 0.125--0.1875--1--0.375--0.625 --chance per chunk of a spawner cluster --do not allow 100% spawn rate, as reaches impossible-without-mods densities by tier4 distances
full_group_count = 24--4 --number of allowable spawners in a cluster
full_spawn_spitters = 0.375 --fraction of spawners that are spitters, at full spawn distance
min_grouping_dist = 400
interpolation = 3.0

CHUNK_SIZE = 32

function initChokepointModifiers()
	log("Chokepoint detected, increasing ore scaling accordingly")
	--core_distance = core_distance*1.125
	base_ore_patch_chance = base_ore_patch_chance*1.25
	final_ore_patch_chance = final_ore_patch_chance*1.75
	center_patch_chance = center_patch_chance*1.75
	
	center_richness_factor = center_richness_factor/(1.5*1.25) --so there is still roughly the same total ore
	
	min_spawner_dist = min_spawner_dist*1.25
end

function initModifiers(isInit)
	if isInit and game.active_mods.ChokePoint or global.oreverhaul.chokepoint_loaded then
		initChokepointModifiers()
	end
	
	log("Multiplying spawner distances by configuration value of " .. Config.spawnerDistanceFactor)

	min_spawner_dist = min_spawner_dist*Config.spawnerDistanceFactor
	min_spitter_dist = min_spitter_dist*Config.spawnerDistanceFactor
	min_worm_dist = min_worm_dist*Config.spawnerDistanceFactor
	full_spawn_dist = full_spawn_dist*Config.spawnerDistanceFactor
	min_grouping_dist = min_grouping_dist*Config.spawnerDistanceFactor

	min_spawner_chance = min_spawner_chance*Config.spawnerRateFactor
	full_spawn_amount = full_spawn_amount*Config.spawnerRateFactor
end