require "constants"
require "config"

function createResource(orename, surface, chunk, dx, dy, dr, drm)
	if isInChunk(dx, dy, chunk) and canPlaceOreAt(surface, orename, dx, dy) then
		local f = 1-0.5*(dr/(drm*drm))
		local amt = math.floor(f*getOreAmount(orename, dx, dy))
		surface.create_entity{name = orename, position = {x = dx, y = dy}, force = game.forces.neutral, amount = amt}
	end
end

function createOrePlop(orename, surface, chunk, x, y, size)
	for i = -size, size do
		for k = -size, size do
			local dr = i*i+k*k
			if dr < size*size then
				local dx = x+i
				local dy = y+k
				createResource(orename, surface, chunk, dx, dy, dr, size)
			end
		end
	end
end

function createOrePatch(orename, surface, chunk, x, y, totalSize, plopSize)
	local nplop = nextInt(8)
	local r = totalSize/4
	local ox = getRandPM(CHUNK_SIZE/4) --is already in the center of the chunk
	local oy = getRandPM(CHUNK_SIZE/4)
	for i = 1, nplop do
		local dx = ox+x+getRandPM(r)
		local dy = oy+y+getRandPM(r)
		local size = plopSize/2+nextInt(plopSize/2)
		createOrePlop(orename, surface, chunk, dx, dy, size)
	end
end

function createLiquidPatch(orename, surface, chunk, x, y, wells)
	local r = 6
	local ox = getRandPM(CHUNK_SIZE/4) --is already in the center of the chunk
	local oy = getRandPM(CHUNK_SIZE/4)
	for i = 1, wells do
		local dx = ox+x+getRandPM(r)
		local dy = oy+y+getRandPM(r)
		createResource(orename, surface, chunk, dx, dy, 0, 1)
	end
end

function getMaxOreTierAt(dist)
	local ret = -1
	local idx = 0
	for tier, req in pairs(Config.oreTierDistances) do
		if req*Config.oreDistanceFactor*Config.oreTierDistanceFactor <= dist and idx > ret then
			ret = idx
		end
		idx = idx+1
	end
	return ret
end

function getOreForPlacementAt(dist)
	if dist <= core_distance then
		return getRandomTableEntry(Config.starterOres)
	end
	local maxtier = getMaxOreTierAt(dist)
	local tier = nextRangedInt(0, maxtier)
	
	--[[
	game.print(tier .. "/" .. maxtier)
	game.print(tierOres[tier])
	for k, v in pairs(tierOres[tier]) do
	game.print(v)
	end
	--]]
	
	return getRandomTableEntry(tierOres[tier])
end

function getOrePatchChance(dist)
	if dist < core_distance then
		return 1
	end
	local dm = ore_plateau*Config.oreDistanceFactor
	if dist >= dm then
		return final_ore_patch_chance
	end
	local dc = final_ore_patch_chance-base_ore_patch_chance
	return base_ore_patch_chance+dc*dist/dm
end

function tryCreateOrePatch(surface, chunk, x, y)
	createSeed(surface, x, y)
	local dd = math.sqrt(x*x+y*y)
	local f = getOrePatchChance(dd)
	--game.print(dd .. " >> " .. f)
	if nextDouble() > f then
		return
	end
	local ore = getOreForPlacementAt(dd)
	if isLiquid(ore) then
		local num = math.min(2+dd/60, 12)
		createLiquidPatch(ore, surface, chunk, x, y, num)
	else
		local size = math.min(10+dd/60, 24)
		local plopsize = math.min(5+dd/120, 12)
		createOrePatch(ore, surface, chunk, x, y, size, plopsize)
	end
end

function createSpillingOrePatches(surface, chunk, x, y)
	for i = -1, 1 do
		for k = -1, 1 do
			if i ~= 0 or k ~= 0 then
				local dx = x+i*CHUNK_SIZE
				local dy = y+k*CHUNK_SIZE
				tryCreateOrePatch(surface, chunk, dx, dy)
			end
		end
	end
end

function canPlaceOreAt(surface, ore, x, y)
	return surface.can_place_entity{name = ore, position = {x, y}}--[[ and (not isLiquid(ore) or nextDouble() > 0.95)--]] and not isWaterEdge(surface, x, y)
end