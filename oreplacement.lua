require "constants"
require "config"

function createResource(orename, surface, chunk, dx, dy, dr, drm)
	if isInChunk(dx, dy, chunk) and canPlaceOreAt(surface, orename, dx, dy) then
		local f = 1-0.5*(dr/(drm*drm))
		local amt = math.floor(f*getOreAmount(orename, dx, dy))
		surface.create_entity{name = orename, position = {x = dx, y = dy}, force = game.forces.neutral, amount = amt}
	end
end

local function createOrePlop(orename, surface, chunk, x, y, size)
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

local function createOrePatch(orename, surface, chunk, x, y, totalSize, plopSize, cf)
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

local function createLiquidPatch(orename, surface, chunk, x, y, wells)
	local r = wells > 12 and 10 or 6
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
		if global.oreverhaul.tierOres[tier] then
			if req ~= nil then
				--game.print(global.oreverhaul.tierOres[tier] .. ": " .. (req*Config.oreDistanceFactor*Config.oreTierDistanceFactor) .. "/" .. dist)
				game.print(dist)
				game.print(global.oreverhaul.tierOres[tier])
				game.print(req*Config.oreDistanceFactor*Config.oreTierDistanceFactor)
			else
				game.print("No requirement(?!) for " .. tier)
			end
		else
			game.print("No ores for " .. tier)
		end
		--]]
		if global.oreverhaul.tierOresSum[tier] and req*Config.oreDistanceFactor*Config.oreTierDistanceFactor <= dist and idx > ret then
			--[[
			game.print("-----------------------")
			game.print("Validating tier " .. tier .. ". Ores: ")
			for k, v in pairs(global.oreverhaul.tierOres[tier]) do
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
		--return getRandomTableEntry(Config.starterOres)
		return getCustomWeightedRandom(Config.starterOres, nextRangedInt)
	end
	local maxtier = getMaxOreTierAt(dist)
	--local tier = "tier".. nextRangedInt(0, maxtier)
		
	--[[
	game.print(tier .. "/" .. maxtier)
	game.print(global.oreverhaul.tierOres[tier])
	for k, v in pairs(global.oreverhaul.tierOres[tier]) do
	game.print(v)
	end
	--]]
	
	--[[
	game.print("--------------------------")
	game.print(dist .. " -> " .. maxtier)
	for k, v in pairs(global.oreverhaul.tierOresSum["tier" .. maxtier]) do
		game.print(maxtier .. " : " .. v)
	end
	--]]
	
	if not global.oreverhaul.tierOresSum then error("Null ore table!") end
	if not global.oreverhaul.tierOresSum["tier" .. maxtier] or #global.oreverhaul.tierOresSum["tier" .. maxtier] == 0 then error("No ores defined for tier " .. maxtier .. "!") end
	
	local ret = getRandomTableEntry(global.oreverhaul.tierOresSum["tier" .. maxtier], nextRangedInt)
	if Config.antiBias[ret] and nextDouble() < Config.antiBias[ret] then
		ret = getRandomTableEntry(global.oreverhaul.tierOresSum["tier" .. maxtier], nextRangedInt)
	end
	return ret
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
		return final_ore_patch_chance*Config.orePatchChanceFactor
	end
	local dc = final_ore_patch_chance-base_ore_patch_chance
	return (base_ore_patch_chance+dc*dist/dm)*Config.orePatchChanceFactor
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
	local ex = x-Config.offsetX
	local ey = y-Config.offsetY
	createSeed(surface, ex, ey, Config.oreMixinSeed)
	local dd = math.sqrt(ex*ex+ey*ey)
	local cf = getCondensationFactor(dd)
	local f = getOrePatchChance(dd)/(cf*2)--(cf*cf)
	while f > 0 do --allows for >1 patch per chunk
		--game.print(dd .. " >> " .. f)
		if nextDouble() > f then
			return
		end
		local ore = getOreForPlacementAt(dd)
		if isLiquid(ore) then
			local num = math.min(2+dd/50, 24)*(1+(cf-1)/2)
			createLiquidPatch(ore, surface, chunk, x, y, num)
		else
			local size = getOrePatchSize(dd)*cf
			local plopsize = getOrePlopSize(dd)*(1+(cf-1)/2)
			if Config.radiusFactors[ore] then
				size = math.max(min_patch_size, size*Config.radiusFactors[ore])
				plopsize = math.max(min_plop_size, plopsize*Config.radiusFactors[ore])
			end
			--game.print(dd .. " >> " .. size .. " & " .. plopsize)
			--testConsistency(x, y, size)
			createOrePatch(ore, surface, chunk, x, y, size, plopsize, cf)
		end
		f = f-1
	end
end

function getOrePatchSize(dd)
	return math.min(min_patch_size+(dd/60)*Config.oreSizeDistanceFactor, max_patch_size)
end

function getOrePlopSize(dd)
	return math.min(min_plop_size+(dd/120)*Config.oreSizeDistanceFactor, max_plop_size)
end

function getSpillSearchRadius(dd)
	return math.ceil((getCondensationFactor(dd)*1.5*(getOrePatchSize(dd)/4+getOrePlopSize(dd)))/CHUNK_SIZE)
end

function createSpillingOrePatches(surface, chunk, x, y)
	local ex = x+Config.offsetX
	local ey = y+Config.offsetY
	local dd = math.sqrt(ex*ex+ey*ey)
	local r = getSpillSearchRadius(dd)
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