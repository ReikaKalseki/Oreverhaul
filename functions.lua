require "config"
require "oreplacement"
require "spawnercontrol"
require "customrand"
require "constants"

require "__DragonIndustries__.mathhelper"
require "__DragonIndustries__.arrays"
--[[
function cacheChunkOre(chunkloc, ore, amount, x, y)
	if chunkCache[chunkloc.keystring] == nil then
		chunkCache[chunkloc.keystring] = {}
	end
	local entry = {
		ore = ore,
		amount = amount,
		x = x,
		y = y
	}
	--game.print("Cached ore " .. ore .. " x" .. amount .. " @ " .. x .. ", " .. y)
	table.insert(chunkCache[chunkloc.keystring], entry)
end

function getChunkCoord(x, y)
	local cx = math.floor(math.abs(x/CHUNK_SIZE))
	local cy = math.floor(math.abs(y/CHUNK_SIZE))
	local ret = {
	posX = cx,
	posY = cy,
	keystring = cx .. ":" .. cy
	}
	return ret
end

function genCachedChunk(surface, chunkloc)
	local cache = chunkCache[chunkloc.keystring]
	--game.print("Genning cached chunk " .. chunkloc.posX .. ", " .. chunkloc.posY)
	if cache ~= nil then
		for _, entry in pairs(cache) do
			surface.create_entity{name = entry.ore, position = {x = entry.x, y = entry.y}, force = game.forces.neutral, amount = entry.amount}--placeOrCacheOre(entry.ore, entry.amount, entry.x, entry.y, surface)
		end
	end
	chunkCache[chunkloc.keystring] = nil
end
--]]
function buildWormList()
	global.oreverhaul.availableWorms = {"small-worm-turret", "medium-worm-turret", "big-worm-turret, behemoth-worm-turret"}
end

function buildOreList()
	
	global.oreverhaul.tierOres = {}
	global.oreverhaul.tierOresSum = {}
	maxTier = 0	
	
	--game.print("Oreverhaul: Building ore list...")
	
	local flag = false
	for ore, tiern in pairs(Config.oreTiers) do
		tier = "tier" .. tiern
		if game.entity_prototypes[ore] then
			--game.print("Oreverhaul: Detected ore '" .. ore .. "' @ tier " .. tier)
			if global.oreverhaul.tierOres[tier] == nil then
				global.oreverhaul.tierOres[tier] = {}
			end
			maxTier = math.max(maxTier, tiern)
			table.insert(global.oreverhaul.tierOres[tier], ore)
			--game.print("Adding " .. ore .. " to tier " .. tier)
		else
			if not global.oreverhaul.loggedMissingOre then
				if game then
					game.print("Oreverhaul: Ore '" .. ore .. "' was specified in tier " .. tiern .. ", but that ore does not exist in game. Skipping.")
				end
				log("Oreverhaul: Ore '" .. ore .. "' was specified in tier " .. tiern .. ", but that ore does not exist in game. Skipping.")
				flag = true
			end
		end
	end
	if flag then
		global.oreverhaul.loggedMissingOre = true
	end
	--[[
	for ore, tiern in pairs(Config.oreTiers) do
		tier = "tier" .. tiern
		if global.oreverhaul.tierOres[tier] then
			tierprev = "tier" .. (tiern-1)
			if not global.oreverhaul.tierOres[tierprev] then --empty prior tier, creating a 'gap'
				fillLowerTier(tiern-1)
			end
		end
	end
	--]]
	
	for ore, tiern in pairs(Config.oreTiers) do
		if game.entity_prototypes[ore] then
			tier = "tier" .. tiern
			for i=tiern,maxTier do
				tieri = "tier" .. i
				if global.oreverhaul.tierOresSum[tieri] == nil then
					global.oreverhaul.tierOresSum[tieri] = {}
				end
				table.insert(global.oreverhaul.tierOresSum[tieri], ore)
				--game.print("Oreverhaul: Adding " .. ore .. " to tier " .. i)
			end
		end
	end
	
	--[[
	game.print("Oreverhaul: Ore List:")
	for k,v in pairs(global.oreverhaul.tierOresSum) do
		game.print("Tier " .. k .. ": " .. #v .. " ores defined.")
	end
	--]]
	
end

function fillLowerTier(tier)
	if tier <= 0 then --never need to fill this tier
		return
	end
	--game.print("Filling void tier " .. tier)
	tiermin_num = tier-1
	tiermin = "tier" .. tiermin_num
	while not global.oreverhaul.tierOres[tiermin] do
		tiermin_num = tiermin_num-1
		tiermin = "tier" .. tiermin_num
	end
	--game.print("Filling with tier " .. tiermin)
	for i=tiermin_num+1,tier do
		global.oreverhaul.tierOres["tier" .. i] = {}
		for name,ore in pairs(global.oreverhaul.tierOres[tiermin]) do
			table.insert(global.oreverhaul.tierOres["tier" .. i], ore)
			--game.print("Oreverhaul: Copying " .. ore .. " from tier " .. tiermin .. " to tier " .. i)
		end
	end
end

function getRandPM(range)
	return nextDouble()*range*2-range
end

function ignoreOre(orec)
	--game.print("Testing ignore of ore " .. orec.name)
	for idx,ore in pairs(Config.ignoredOres) do
		--game.print("Comparing to " .. ore)
		if ore == orec.name then
			return true
		end
	end
	return false
end

function isLiquid(ore)
	return ore == "crude-oil" or ore == "lithia-water" or ore == "ground-water" or ore == "geothermal"
end

function isInChunk(x, y, chunk)
	local minx = math.min(chunk.left_top.x, chunk.right_bottom.x)
	local miny = math.min(chunk.left_top.y, chunk.right_bottom.y)
	local maxx = math.max(chunk.left_top.x, chunk.right_bottom.x)
	local maxy = math.max(chunk.left_top.y, chunk.right_bottom.y)
	return x >= minx and x <= maxx and y >= miny and y <= maxy
end

function getOreAmount(ore, x, y)
	local ret = getBaseOreAmount(ore, x, y)
	
	 --need to compensate for these, or the game becomes impossible quite easily; but do not completely negate the effects, keep the actual cost-per-resource net higher
	 
	 --TODO: MAKE CONFIGURABLE
	if game.difficulty_settings.recipe_difficulty == defines.difficulty_settings.recipe_difficulty.expensive then
		ret = math.ceil(ret*Config.expensiveRecipeMultiplier)
	end
	if game.difficulty_settings.technology_difficulty == defines.difficulty_settings.technology_difficulty.expensive then
		ret = math.ceil(ret*Config.expensiveTechMultiplier)
	end
	local tf = game.difficulty_settings.technology_price_multiplier
	ret = ret*(1+(tf-1)*Config.techCostMultiplierFactor)
	
	return ret
end

function getBaseOreAmount(ore, x, y)
	if not Config.richnessScaling then
		return 4000
	end
	return math.max(50, math.floor(500*getDistanceRichness(ore, x, y)))
end

function getMultiply(area, ore)
	local dx = math.abs(ore.position.x)
	local dy = math.abs(ore.position.y)
	local dd = math.sqrt(dx*dx+dy*dy)
	local mind = getMinGenerationDistance(ore)
	--game.print(ore.name .. " @ " .. dd .. "/" .. mind)
	if Config.distanceGate[ore.name] ~= nil and dd < mind then
		--game.print("Too close: " .. ore.name .. " @ " .. dd .. "/" .. mind)
		return 0
	end
	if not Config.richnessScaling then
		return 1
	end
	
	local off = math.sqrt(mind)
	--return 1+(math.sqrt((dx*dx)+(dy*dy)))/dist_factor
	--local ret = math.max(0.05, 0.05+(math.log((1+math.abs(dx*dx*dx))+(1+math.abs(dy*dy*dy)))/50))
	
	--local pre = 0--math.max(0, 400-dd)
	--local root = math.max(0, (math.max(0, dx*dx-off*off-pre*pre))+(math.max(0, dy*dy-off*off-pre*pre)))
	--local ret = 0.1+(math.sqrt(root)/dist_factor)
	
	local ret = getDistanceRichness(ore.position.x, ore.position.y)
	return ret
end

function getDistanceRichness(ore, x, y)
	local dx = math.abs(x)
	local dy = math.abs(y)
	local dd = math.sqrt(dx*dx+dy*dy)
	local core = dd < core_distance
	if Config.richnessPerOre then
		dd = math.max(0, dd-getMinGenerationDistance(ore))
	end
	local maxd = ore_plateau*Config.oreDistanceFactor*Config.oreRichnessDistanceFactor
	local platval = ore_plateau_value*Config.oreRichnessScalingFactor
	if dd >= maxd then
		if Config.plateauRichness then
			return platval
		else
			return platval+Config.oreRichnessScalingFactor*unclamped_ore_scaling*(dd-maxd)
		end
	end
	--local ret = 0.2-20+40/(1+((2.71*Config.distanceScaling)^(-dist_factor*(dx*dx+dy*dy-dist_const))))
	local ret = 0.25+getCosInterpolate(dd, maxd, platval)
	--game.print(dd .. " >> " .. ret)
	if ore == "crude-oil" or ore == "lithia-water" then
		ret = math.min(ret, ore_plateau_value*Config.oreRichnessScalingFactor/2)
	end
	if ore == "ground-water" then
		ret = math.min(0.5, (ret-0.025)/10)
	end
	ret = ret*getOreSpecificBias(dd, ore)
	--if dd > 5000 then
		--ret = math.max(ret, math.min(ret, ret*(1.001^-((x*x)+(y*y)))))
	--end
	
	if core then
		ret = ret*center_richness_factor
	end
	
	return ret*Config.flatRichnessFactor
end

--[[
function createSeed(surface, x, y) --Used by Minecraft MapGen
	local seed = surface.map_gen_settings.seed
	setRandSeed(seed)
	local r1 = nextRand()
	local r2 = nextRand()
	local a1 = x*r1
	local a2 = y*r2
	seed = bit32.bxor(surface.map_gen_settings.seed, bit32.bxor(a1, a2))
	setRandSeed(seed)
end
--]]

function createSeed(surface, x, y, mixin) --Used by Minecraft MapGen
	local seed = cantorCombine(surface.map_gen_settings.seed, cantorCombine(x, y))
	seed = bit32.bxor(seed, mixin)
	setRandSeed(seed)
end

function getValidOresAt(dx, dy, dd)
	local ores = {}
	for ore,dist in pairs(ORE_DIST) do
		if dist <= dd then
			ores[ore] = (dd-dist)*(dd-dist)
		end
	end
	return ores
end

function getReplacedOre(ore)
	local x = ore.position.x
	local y = ore.position.y
	--[[
	local ore_count = {}
	local ores = event.surface.find_entities_filtered({area = {{x-1, y-1}, {x+1, y+1}}, type="resource"})
	for num,ore in pairs(ores) do
		if ore_count[ore.name] == nil then
			ore_count[ore.name] = 0
		end
		ore_count[ore.name] = ore_count[ore.name]+1
	end
	return orenames[getWeightedRandom(ore_count)]
	-]]
	valid = getValidOresAt(math.abs(x), math.abs(y), math.sqrt(x*x+y*y))
	return getCustomWeightedRandom(valid, nextRangedInt)
end

function getOreSpecificBias(dd, ore)
	if ore == "stone" then
		return math.min(1.8, math.max(1.2, dd/5000))
	end
	--[[
	if ore == "sulfur" then
		return 0.6--0.8--0.6
	end
	--]]
	if ore == "coal" then
		return math.min(1.1, math.max(0.9, dd/1000))
	end
	if isLiquid(ore) then
		return game.entity_prototypes[ore].infinite_resource and 40 or math.min(200, 40+dd/100)
	end
	if Config.richnessFactors[ore] then
		return Config.richnessFactors[ore]
	end
	
	return 1
end

function getMinGenerationDistance(ore)
	local ret = Config.oreTierDistances[Config.oreTiers[ore.name]]--ORE_DIST[ore.name]
	if ret == nil then
		ret = 0
	end
	return ret*Config.oreDistanceFactor
end

function printDebug(area, totals, newtotals, mults, counts)
	for ore,v in pairs(mults) do
		local area = "Area [" .. area.left_top.x .. "," .. area.left_top.y .. "][" .. area.right_bottom.x .. "," .. area.right_bottom.y .. "]"
		local avgmult = string.format("%.3f", mults[ore]/counts[ore])
		local avg = string.format("%.0f", totals[ore]/counts[ore])
		local newavg = string.format("%.0f", newtotals[ore]/counts[ore])
		game.player.print(area .. ": Generated " .. counts[ore] .. " tiles of " .. ore .. ", total value from " .. totals[ore] .. " to " .. newtotals[ore] .. " (avg=" .. avg .. "/" .. newavg .. "), avg mult=" .. avgmult)
	end
end

function isWaterEdge(surface, x, y)
	if surface.get_tile{x-1, y}.valid and surface.get_tile{x-1, y}.prototype.layer == "water-tile" then
		return true
	end
	if surface.get_tile{x+1, y}.valid and surface.get_tile{x+1, y}.prototype.layer == "water-tile" then
		return true
	end
	if surface.get_tile{x, y-1}.valid and surface.get_tile{x, y-1}.prototype.layer == "water-tile" then
		return true
	end
	if surface.get_tile{x, y+1}.valid and surface.get_tile{x, y+1}.prototype.layer == "water-tile" then
		return true
	end
end