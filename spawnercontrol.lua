require "constants"
require "config"

function modifySpawners(spawner)
	local dx = math.abs(spawner.position.x+Config.offsetX)
	local dy = math.abs(spawner.position.y+Config.offsetX)
	local dd = math.sqrt(dx*dx+dy*dy)/Config.spawnerDistanceFactor
	local f = getSpawnerProbability(dx, dy, dd, spawner)
	--game.player.print("Spawner: " .. spawner.name .. " @ " .. dd .. ", f=" .. f)
	if nextDouble() > f then
		spawner.destroy()
	else
		if spawner.name == "spitter-spawner" then
			local f2 = getSpawnerReplacement(dx, dy, dd)
			--game.player.print("Spawner: " .. spawner.name .. " @ " .. dd .. ", f2=" .. f2)
			if nextDouble() < f2 then
				replaceSpitterSpawner(spawner)
			end
		end
	end
end

function ensureNoGroupedSpawnersNearby(spawner, val)
	local x = spawner.position.x
	local y = spawner.position.y
	local dx = math.abs(x)
	local dy = math.abs(y)
	local dd = math.sqrt(dx*dx+dy*dy)
	if dd >= full_spawn_dist then
		return val
	end
	local allowedGrouping = getCosInterpolate(dd-min_grouping_dist, full_spawn_dist, full_group_count)--8*(dd--[[^interpolation]]-min_grouping_dist--[[^interpolation]])/(full_spawn_dist--[[^interpolation]]-min_grouping_dist--[[^interpolation]])
	if dd < min_grouping_dist then
		allowedGrouping = 0
	end
	local search = 16
	if allowedGrouping <= 0 then
		search = 24
	end
	local nearspawners = spawner.surface.find_entities_filtered({area = {{x-search, y-search}, {x+search, y+search}}, type="unit-spawner"})
	if getTableSize(nearspawners) > 1+allowedGrouping*Config.spawnerClustering then -- +1 for the spawner itself
		return 0
	end
	return val
end

function downsizeWorm(worm)
	local wname = worm.name
	if wname == "big-worm-turret" then
		wname = "medium-worm-turret"
	elseif wname == "medium-worm-turret" then
		wname = "small-worm-turret"
	end
	worm.surface.create_entity{name = wname, direction = worm.direction, position = {x = worm.position.x,y = worm.position.y}, force = worm.force}
	worm.destroy()
end

function modifyWorms(worm)
	local dx = math.abs(worm.position.x+Config.offsetX)
	local dy = math.abs(worm.position.y+Config.offsetX)
	local dd = math.sqrt(dx*dx+dy*dy)/Config.spawnerDistanceFactor
	local f = getWormProbability(dx, dy, dd, worm)
	--game.player.print("worm: " .. worm.name .. " @ " .. dd .. ", f=" .. f)
	local r = nextDouble()
	if r > f then
		worm.destroy()
	elseif f < 0.5 and r > f*0.75 then
		downsizeWorm(worm)
	end
end

function getWormProbability(dx, dy, dd, worm)
	if dd < min_worm_dist then
		return 0
	else
		return getCosInterpolate(dd-min_worm_dist, full_spawn_dist, full_spawn_amount)--(dd--[[^interpolation]]-min_worm_dist--[[^interpolation]])/(full_spawn_dist--[[^interpolation]]-min_worm_dist--[[^interpolation]])
	end
end

function getSpawnerProbability(dx, dy, dd, spawner)
	if dd < min_spawner_dist then
		return 0
	else
		local ret = getCosInterpolate(dd-min_spawner_dist, full_spawn_dist, full_spawn_amount)--(dd--[[^interpolation]]-min_spawner_dist--[[^interpolation]])/(full_spawn_dist--[[^interpolation]]-min_spawner_dist--[[^interpolation]])
		return ensureNoGroupedSpawnersNearby(spawner, ret)
	end
end

function getSpawnerReplacement(dx, dy, dd)
	if dd < min_spitter_dist then
		return 1
	else
		return 1-getCosInterpolate(dd-min_spitter_dist, full_spawn_dist, 1.0)--1-((dd--[[^interpolation]]-min_spitter_dist--[[^interpolation]])/(full_spawn_dist--[[^interpolation]]-min_spitter_dist--[[^interpolation]]))
	end
end

function replaceSpitterSpawner(spawner)
	spawner.surface.create_entity{name = "biter-spawner", direction = spawner.direction, position = {x = spawner.position.x,y = spawner.position.y}, force = spawner.force}
	--game.player.print("Replacing spitter spawner @ " .. )
	spawner.destroy()
end

function redoSpawnersAndWorms(surface, chunk)
	for num,spawner in pairs(surface.find_entities_filtered({area = {{chunk.left_top.x, chunk.left_top.y}, {chunk.right_bottom.x, chunk.right_bottom.y}}, type="unit-spawner"})) do
		spawner.destroy()
	end
	for num,worm in pairs(surface.find_entities_filtered({area = {{chunk.left_top.x, chunk.left_top.y}, {chunk.right_bottom.x, chunk.right_bottom.y}}, type="turret"})) do
		worm.destroy()
	end
	
	local x = (chunk.left_top.x+chunk.right_bottom.x)/2
	local y = (chunk.left_top.y+chunk.right_bottom.y)/2
	createSpillingSpawnerPatches(surface, chunk, x, y)
	tryCreateSpawnerPatch(surface, chunk, x, y)
end

function createSpawner(spawnertype, surface, chunk, dx, dy)
	if isInChunk(dx, dy, chunk) and canPlaceSpawnerAt(surface, spawnertype, dx, dy) then
		return surface.create_entity{name = spawnertype, position = {x = dx, y = dy}, force = game.forces.enemy, direction = nextRangedInt(0, 7)} ~= nil
	else
		return false
	end
end

function createWorm(wormtype, surface, chunk, dx, dy)
	if isInChunk(dx, dy, chunk) and canPlaceSpawnerAt(surface, wormtype, dx, dy) then
		return surface.create_entity{name = wormtype, position = {x = dx, y = dy}, force = game.forces.enemy} ~= nil
	else
		return false
	end
end

function tryCreateWorm(wormtype, surface, chunk, x, y)
	local tries = 0
	local flag = false
	local dx = x
	local dy = y
	local r = 6
	while tries < 10 and not flag do
		flag = createWorm(wormtype, surface, chunk, dx, dy)
		tries = tries+1
		dx = x+getRandPM(r)
		dy = y+getRandPM(r)
	end
end

function tryCreateSpawner(spawnertype, surface, chunk, x, y)
	local tries = 0
	local flag = false
	local dx = x
	local dy = y
	local r = 6
	while tries < 10 and not flag do
		flag = createSpawner(spawnertype, surface, chunk, dx, dy)
		tries = tries+1
		dx = x+getRandPM(r)
		dy = y+getRandPM(r)
	end
	return flag
end

function createSpawnerPatch(surface, chunk, x, y, dist)
	local r = 6
	local nspawners = getSpawnerPatchSize(dist)
	local nworms = getWormCount(dist, nspawners)
	--if dist < 300 then game.print(dist .. " >> " .. nspawners) end
	--game.print(dist .. " >> " .. nworms)
	local ox = getRandPM(CHUNK_SIZE/4) --is already in the center of the chunk
	local oy = getRandPM(CHUNK_SIZE/4)
	local success = false
	for i = 1, nspawners do
		local spawnertype = getSpawnerType(dist)
		--game.print(spawnertype)
		local dx = ox+x+getRandPM(r)
		local dy = oy+y+getRandPM(r)
		if tryCreateSpawner(spawnertype, surface, chunk, dx, dy) then
			success = true
		end
	end
	if not success then --prevent placement of a worm cluster if there were no spawner spawns (ie in the middle of the forest)
		return
	end
	for i = 1, nworms do
		local wormtype = getWormType(dist)
		if wormtype ~= nil then
			local dx = ox+x+getRandPM(r)
			local dy = oy+y+getRandPM(r)
			--game.print(wormtype)
			tryCreateWorm(wormtype, surface, chunk, dx, dy)
		end
	end
end

function createSpillingSpawnerPatches(surface, chunk, x, y)
	for i = -1, 1 do
		for k = -1, 1 do
			if i ~= 0 or k ~= 0 then
				local dx = x+i*CHUNK_SIZE
				local dy = y+k*CHUNK_SIZE
				tryCreateSpawnerPatch(surface, chunk, dx, dy)
			end
		end
	end
end

function tryCreateSpawnerPatch(surface, chunk, x, y)
	local ex = x-Config.offsetX
	local ey = y-Config.offsetY
	createSeed(surface, ex, ey, Config.spawnerMixinSeed)
	local dd = math.sqrt(ex*ex+ey*ey)/Config.spawnerDistanceFactor
	local f = getSpawnerPatchChance(dd)
	--game.print(dd .. " >> " .. f)
	if nextDouble() > f then
		return
	end
	createSpawnerPatch(surface, chunk, x, y, dd)
end

function getSpawnerPatchChance(dist)
	local mind = math.min(min_spawner_dist, Config.minSpawnerDistance)*Config.spawnerDistanceFactor
	if dist < mind then
		return 0
	end
	if dist < core_distance then
		return 0
	end
	local ret = min_spawner_chance+getCosInterpolate(dist-mind, full_spawn_dist, full_spawn_amount-min_spawner_chance)
	return ret
end

function getSpawnerPatchSize(dist)
	return 1+math.floor(getCosInterpolate(dist-min_grouping_dist, full_spawn_dist, full_group_count))
end

function getSpawnerType(dist)
	if dist < min_spitter_dist then
		return "biter-spawner"
	end
	local f = getCosInterpolate(dist-min_spitter_dist, full_spawn_dist, full_spawn_spitters)
	local r = nextDouble()
	if r < f then
		return "spitter-spawner"
	else
		return "biter-spawner"
	end
end

function getWormCount(dist, spawners)
	if dist < min_worm_dist then
		return 0
	end
	return 1+math.floor(getCosInterpolate(dist-min_worm_dist, full_spawn_dist, math.floor(spawners*1.5)))
end

function getWormType(dist)
	local s = getCosInterpolate(dist-min_worm_dist, full_spawn_dist*#global.oreverhaul.availableWorms/3, #global.oreverhaul.availableWorms)
	s = math.min(s, #global.oreverhaul.availableWorms-0.25)
	s = s+getRandPM(0.5) --randomize worm spawns a bit
	s = math.floor(s+0.5) --round
	if s > 0 and s <= #global.oreverhaul.availableWorms then
		return global.oreverhaul.availableWorms[s]
	else
		return nil
	end
end

function canPlaceSpawnerAt(surface, spawner, x, y)
	return --[[what about trees, which spawners can overwrite?!--]] surface.can_place_entity{name = spawner, position = {x, y}} and not isWaterEdge(surface, x, y)
end