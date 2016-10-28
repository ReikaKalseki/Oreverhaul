require "config"
require "oreplacement"
require "spawnercontrol"
require "customrand"
require "constants"
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
function getCosInterpolate(x, xmax, ymax)
	if x >= xmax then
		return ymax
	end
	local func = 0.5-0.5*math.cos(x*math.pi/xmax)
	return func*ymax
end

function getRandPM(range)
	return nextDouble()*range*2-range
end

function isLiquid(ore)
	return ore == "crude-oil" or ore == "lithia-water" or ore == "ground-water"
end

function isInChunk(x, y, chunk)
	local minx = math.min(chunk.left_top.x, chunk.right_bottom.x)
	local miny = math.min(chunk.left_top.y, chunk.right_bottom.y)
	local maxx = math.max(chunk.left_top.x, chunk.right_bottom.x)
	local maxy = math.max(chunk.left_top.y, chunk.right_bottom.y)
	return x >= minx and x <= maxx and y >= miny and y <= maxy
end

function getOreAmount(ore, x, y)
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
	--local ret = 0.2-20+40/(1+((2.71*Config.distanceScaling)^(-dist_factor*(dx*dx+dy*dy-dist_const))))
	local ret = 0.25+getCosInterpolate(dd, ore_plateau*Config.oreDistanceFactor*Config.oreRichnessDistanceFactor, ore_plateau_value*Config.oreRichnessScalingFactor)
	--game.print(dd .. " >> " .. ret)
	if ore == "crude-oil" then
		ret = math.min(ret/2, ore_plateau_value*Config.oreRichnessScalingFactor/4)
	end
	if ore == "ground-water" then
		ret = math.min(0.5, (ret-0.025)/10)
	end
	ret = ret*getOreSpecificBias(dd, ore)
	--if dd > 5000 then
		--ret = math.max(ret, math.min(ret, ret*(1.001^-((x*x)+(y*y)))))
	--end
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

function createSeed(surface, x, y) --Used by Minecraft MapGen
	local seed = cantorCombine(surface.map_gen_settings.seed, cantorCombine(x, y))
	setRandSeed(seed)
end

function getRandomTableEntry(value)
	local size = getTableSize(value)
	local idx = nextRangedInt(0, size-1)
	--game.print(idx .. "/" .. size)
	local i = 0
	for key,val in pairs(value) do
		--game.print(i .. " >> " .. val)
		if i == idx then
			--game.print(val)
			return val
		end
		i = i+1
	end
end

function getWeightedRandom(values)
	local sum = 0
	for idx,num in pairs(values) do
		sum = sum+num
	end
	local rand = nextRangedInt(0, sum)
	local val = 0
	for key,num in pairs(values) do
		val = val+num
		if val >= rand then
			return key
		end
	end
	return 0
end

function getTableSize(val)
	local count = 0
	for key,num in pairs(val) do
		count = count+1
	end
	return count
end

function cantorCombine(a, b)
	--a = (a+1024)%16384
	--b = b%16384
	local k1 = a*2
	local k2 = b*2
	if a < 0 then
		k1 = a*-2-1
	end
	if b < 0 then
		k2 = b*-2-1
	end
	return 0.5*(k1 + k2)*(k1 + k2 + 1) + k2
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
	return getWeightedRandom(valid)
end

function getOreSpecificBias(dd, ore)
	if ore == "stone" then
		return math.min(1.8, math.max(1.2, dd/5000))
	end
	if ore == "sulfur" then
		return 0.8--0.6
	end
	if ore == "coal" then
		return math.min(1.1, math.max(0.9, dd/1000))
	end
	if isLiquid(ore) then
		return 40
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
	if surface.get_tile{x-1, y}.prototype.layer == "water-tile" then
		return true
	end
	if surface.get_tile{x+1, y}.prototype.layer == "water-tile" then
		return true
	end
	if surface.get_tile{x, y-1}.prototype.layer == "water-tile" then
		return true
	end
	if surface.get_tile{x, y+1}.prototype.layer == "water-tile" then
		return true
	end
end