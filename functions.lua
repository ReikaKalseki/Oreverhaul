local dist_factor = 0.00000012 --was 0.0000025 (count 0s)    --350 --was 3500, then 1500, then 1000, then 100, then 350
local dist_const = 2000 --halfway point, the 10x; was 2000, then 3k, then 4k, then 10k, then 3k, then 2k

local min_spawner_dist = 200 --was 300
local min_spitter_dist = 500
local min_worm_dist = 400
local full_spawn_dist = 1500
local interpolation = 3.0

function getMultiply(area, ore)
	local dx = math.abs(ore.position.x)
	local dy = math.abs(ore.position.y)
	local dd = math.sqrt(dx*dx+dy*dy)
	local mind = getMinGenerationDistance(ore)
	--game.player.print(ore.name .. " @ " .. dd .. "/" .. mind)
	if dd < mind then
		--game.player.print("Too close: " .. ore.name .. " @ " .. dd .. "/" .. mind)
		return 0
	end
	local off = math.sqrt(mind)
	--return 1+(math.sqrt((dx*dx)+(dy*dy)))/dist_factor
	--local ret = math.max(0.05, 0.05+(math.log((1+math.abs(dx*dx*dx))+(1+math.abs(dy*dy*dy)))/50))
	
	--local pre = 0--math.max(0, 400-dd)
	--local root = math.max(0, (math.max(0, dx*dx-off*off-pre*pre))+(math.max(0, dy*dy-off*off-pre*pre)))
	--local ret = 0.1+(math.sqrt(root)/dist_factor)
	
	local ret = 0.2-20+40/(1+(2.71^(-dist_factor*(dx*dx+dy*dy-dist_const))))
	--game.player.print(dd .. " >> " .. ret)
	ret = ret*getOreSpecificBias(dd, ore)
	--if dd > 5000 then
		--ret = math.max(ret, math.min(ret, ret*(1.001^-((x*x)+(y*y)))))
	--end
	return ret
end

function getOreSpecificBias(dd, ore)
	if ore.name == "stone" then
		return math.min(1.8, math.max(1.2, dd/5000))
	end
	if ore.name == "sulfur" then
		return 0.6
	end
	if ore.name == "coal" then
		return math.min(1.1, math.max(0.9, dd/1000))
	end
	
	return 1
end

function getMinGenerationDistance(ore)
	if ore.name == "copper-ore" then
		return 60
	end
	if ore.name == "quartz" then
		return 90
	end
	if ore.name == "tin-ore" then
		return 120
	end
	if ore.name == "bauxite-ore" then
		return 180 --was 170
	end
	if ore.name == "crude-oil" then
		return 240 --was 500
	end
	if ore.name == "sulfur" then
		return 300 --was 750
	end
	if ore.name == "lead-ore" then
		return 375 --was 200
	end
	if ore.name == "zinc-ore" then
		return 450 --was 250
	end
	if ore.name == "silver-ore" then
		return 700 --was 300
	end
	if ore.name == "gold-ore" then
		return 850 --was 400
	end
	if ore.name == "rutile-ore" then
		return 1000
	end
	if ore.name == "tungsten-ore" then
		return 1200
	end
	if ore.name == "fluorite" then
		return 1500
	end
	if ore.name == "uraninite" then
		return 2000
	end
	if ore.name == "gem-ore" then
		return 3000
	end
	
	return 0
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

function modifySpawners(area, spawner)
	local dx = math.abs(spawner.position.x)
	local dy = math.abs(spawner.position.y)
	local dd = math.sqrt(dx*dx+dy*dy)
	local f = 1--getSpawnerProbability(area, dx, dy, dd, spawner)
	--game.player.print("Spawner: " .. spawner.name .. " @ " .. dd .. ", f=" .. f)
	if math.random() > f then
		spawner.destroy()
	else
		if spawner.name == "spitter-spawner" then
			local f2 = getSpawnerReplacement(area, dx, dy, dd)
			--game.player.print("Spawner: " .. spawner.name .. " @ " .. dd .. ", f2=" .. f2)
			if math.random() < f2 then
				replaceSpitterSpawner(area, dx, dy, dd, spawner)
			end
		end
	end
end

function modifyWorms(area, worm)
	local dx = math.abs(worm.position.x)
	local dy = math.abs(worm.position.y)
	local dd = math.sqrt(dx*dx+dy*dy)
	local f = getWormProbability(area, dx, dy, dd, worm)
	--game.player.print("worm: " .. worm.name .. " @ " .. dd .. ", f=" .. f)
	if math.random() > f then
		worm.destroy()
	end
end

function getWormProbability(area, dx, dy, dd, worm)
	if dd < min_worm_dist then
		return 0
	else
		return (dd^interpolation-min_worm_dist^interpolation)/(full_spawn_dist^interpolation-min_worm_dist^interpolation)
	end
end

function getSpawnerProbability(area, dx, dy, dd, spawner)
	if dd < min_spawner_dist then
		return 0
	else
		return (dd^interpolation-min_spawner_dist^interpolation)/(full_spawn_dist^interpolation-min_spawner_dist^interpolation)
	end
end

function getSpawnerReplacement(area, dx, dy, dd)
	if dd < min_spitter_dist then
		return 1
	else
		return 1-((dd^interpolation-min_spitter_dist^interpolation)/(full_spawn_dist^interpolation-min_spitter_dist^interpolation))
	end
end

function replaceSpitterSpawner(area, dx, dy, dd, spawner)
	spawner.surface.create_entity{name = "biter-spawner", direction = spawner.direction, position = {x = spawner.position.x,y = spawner.position.y}, force = spawner.force}
	--game.player.print("Replacing spitter spawner @ " .. dx .. "," .. dy)
	spawner.destroy()
end