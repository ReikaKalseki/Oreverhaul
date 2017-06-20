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

function createOrePatch(orename, surface, chunk, x, y, totalSize, plopSize, cf)
	local nplop = math.ceil(nextInt(8)*cf)
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
		--[[
		if tierOres[tier] then
			if req ~= nil then
				--game.print(tierOres[tier] .. ": " .. (req*Config.oreDistanceFactor*Config.oreTierDistanceFactor) .. "/" .. dist)
				game.print(dist)
				game.print(tierOres[tier])
				game.print(req*Config.oreDistanceFactor*Config.oreTierDistanceFactor)
			else
				game.print("No requirement(?!) for " .. tier)
			end
		else
			game.print("No ores for " .. tier)
		end
		--]]
		if tierOresSum[tier] and req*Config.oreDistanceFactor*Config.oreTierDistanceFactor <= dist and idx > ret then
			--[[
			game.print("-----------------------")
			game.print("Validating tier " .. tier .. ". Ores: ")
			for k, v in pairs(tierOres[tier]) do
				game.print(v)
			end
			game.print("-----------------------")
			--]]
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
	--local tier = "tier".. nextRangedInt(0, maxtier)
		
	--[[
	game.print(tier .. "/" .. maxtier)
	game.print(tierOres[tier])
	for k, v in pairs(tierOres[tier]) do
	game.print(v)
	end
	--]]
	
	--[[
	game.print("--------------------------")
	game.print(dist .. " -> " .. maxtier)
	for k, v in pairs(tierOresSum["tier" .. maxtier]) do
		game.print(maxtier .. " : " .. v)
	end
	--]]
	
	return getRandomTableEntry(tierOresSum["tier" .. maxtier])
end

function getCondensationFactor(dist)
	if dist <= core_distance then
		return Config.orePatchCondensationStart
	end
	
	local dm = ore_plateau*Config.oreDistanceFactor
	if dist >= dm then
		return Config.orePatchCondensationEnd
	else
		local df = Config.orePatchCondensationEnd-Config.orePatchCondensationStart
		return Config.orePatchCondensationStart+df*dist/dm
	end
end

function getOrePatchChance(dist)
	if dist < core_distance then
		return center_patch_chance
	end
	local dm = ore_plateau*Config.oreDistanceFactor
	if dist >= dm then
		return final_ore_patch_chance
	end
	local dc = final_ore_patch_chance-base_ore_patch_chance
	return base_ore_patch_chance+dc*dist/dm
end

local vals = {}

function testConsistency(x, y, val)
	if vals[x] then
		if vals[x][y] then
			if vals[x][y] ~= val then
				game.print("Value mismatch!! @ " .. x .. " & " .. y .. " >> " .. "" .. " > " .. val)
			end
		else
			vals[x][y] = val
		end
	else
		vals[x] = {}
		vals[x][y] = val
	end
end

function tryCreateOrePatch(surface, chunk, x, y)
	createSeed(surface, x, y)
	local dd = math.sqrt(x*x+y*y)
	local cf = getCondensationFactor(dd)
	local f = getOrePatchChance(dd)/(cf*2)--(cf*cf)
	while f > 0 do --allows for >1 patch per chunk
		--game.print(dd .. " >> " .. f)
		if nextDouble() > f then
			return
		end
		local ore = getOreForPlacementAt(dd)
		if isLiquid(ore) then
			local num = math.min(2+dd/60, 12)*(1+(cf-1)/2)
			createLiquidPatch(ore, surface, chunk, x, y, num)
		else
			local size = getOrePatchSize(dd)*cf
			local plopsize = getOrePlopSize(dd)*(1+(cf-1)/2)
			--game.print(dd .. " >> " .. size .. " & " .. plopsize)
			--testConsistency(x, y, size)
			createOrePatch(ore, surface, chunk, x, y, size, plopsize, cf)
		end
		f = f-1
	end
end

function getOrePatchSize(dd)
	return math.min(10+dd/60, 24)
end

function getOrePlopSize(dd)
	return math.min(5+dd/120, 12)
end

function getSpillSearchRadius(x, y, dd)
	return math.ceil((getCondensationFactor(dd)*1.5*(getOrePatchSize(dd)/4+getOrePlopSize(dd)))/CHUNK_SIZE)
end

function createSpillingOrePatches(surface, chunk, x, y)
	local dd = math.sqrt(x*x+y*y)
	local r = getSpillSearchRadius(x, y, dd)
	--game.print(dd .. " >> " .. r)
	--error(serpent.block("R " .. r))
	for i = -r, r do
		for k = -r, r do
			if i ~= 0 or k ~= 0 then
				local dx = x+i*CHUNK_SIZE
				local dy = y+k*CHUNK_SIZE
				tryCreateOrePatch(surface, chunk, dx, dy)
			end
		end
	end
end

function canPlaceOreAt(surface, ore, x, y)
	return surface.can_place_entity{name = ore, position = {x, y}} and not isWaterEdge(surface, x, y)
end