require "config"

--local dist_factor = 0.00000012 --was 0.0000025 (count 0s)    --350 --was 3500, then 1500, then 1000, then 100, then 350
--local dist_const = 2000 --halfway point, the 10x; was 2000, then 3k, then 4k, then 10k, then 3k, then 2k

ore_plateau = 5000 --ore richness plateaus here
ore_plateau_value = 10 --multiplier at plateau

unclamped_ore_scaling = 0.08 --if plateauing is disabled

core_distance = 120 --the distance defining the "start area" to force all necessary starting ores and prevent any spawners
base_ore_patch_chance = 0.4--0.25--0.25--0.125--0.5--0.125
final_ore_patch_chance = 0.25--0.675--0.5--0.75--0.5
center_patch_chance = 1.625--1.5

min_spawner_dist = 200 --was 300
min_spitter_dist = 400--500
min_worm_dist = 500--400
full_spawn_dist = 3000--1500
min_spawner_chance = 0.1875--0.25--0.1--0.0625--0.025 --lowest value of per-chunk chance of spawner cluster
full_spawn_amount = 0.125--0.1875--1--0.375--0.625 --chance per chunk of a spawner cluster --do not allow 100% spawn rate, as reaches impossible-without-mods densities by tier4 distances
full_group_count = 24--4 --number of allowable spawners in a cluster --do not allow 100% spawn rate, as reaches impossible-without-mods densities by tier4 distances
full_spawn_spitters = 0.375 --fraction of spawners that are spitters
min_grouping_dist = 400
interpolation = 3.0

CHUNK_SIZE = 32

min_spawner_dist = min_spawner_dist*Config.spawnerDistanceFactor
min_spitter_dist = min_spitter_dist*Config.spawnerDistanceFactor
min_worm_dist = min_worm_dist*Config.spawnerDistanceFactor
full_spawn_dist = full_spawn_dist*Config.spawnerDistanceFactor
min_grouping_dist = min_grouping_dist*Config.spawnerDistanceFactor

min_spawner_chance = min_spawner_chance*Config.spawnerRateFactor
full_spawn_amount = full_spawn_amount*Config.spawnerRateFactor

--deprecated in favor of one in global
--worm_sizes = {"small-worm-turret", "medium-worm-turret", "big-worm-turret"}
--tierOres = {} -- a cache of ores by tier determined from ore tiers
--tierOresSum = {} -- like the above but where each entry also contains the previous entries