require "defines"
require "functions"

local ore_debug = false
local spawner_debug = false

script.on_event(defines.events.on_chunk_generated, function(event)	--best used with http://i.imgur.com/Fg7epFd.jpg
	local totals = {}
	local newtotals = {}
	local mults = {}
	local counts = {}
	
	for num,ore in pairs(event.surface.find_entities_filtered({area = {{event.area.left_top.x, event.area.left_top.y}, {event.area.right_bottom.x, event.area.right_bottom.y}}, type="resource"})) do
		local mult = getMultiply(event.area, ore)
		if mult == nil or mult <= 0 then
			if ore_debug then
				--game.player.print("Destroyed " .. ore.name .. " @ " .. ore.position.x .. "," .. ore.position.y)
			end
			ore.destroy()
		else
			ore.amount = math.floor(ore.amount * mult)
			
			--game.player.print("Generated " .. ore.amount .. " of ore " .. ore.name .. ", multiply by " .. mult)
			if ore_debug then
				if totals[ore.name] == nil then
					totals[ore.name] = 0
					newtotals[ore.name] = 0
					mults[ore.name] = 0
					counts[ore.name] = 0
				end
				totals[ore.name] = totals[ore.name] + ore.amount
				mults[ore.name] = mults[ore.name] + mult
				counts[ore.name] = counts[ore.name] + 1
				newtotals[ore.name] = newtotals[ore.name] + ore.amount
			end
		end
	end
	if ore_debug then
		printDebug(event.area, totals, newtotals, mults, counts)
	end
	
	for num,spawner in pairs(event.surface.find_entities_filtered({area = {{event.area.left_top.x, event.area.left_top.y}, {event.area.right_bottom.x, event.area.right_bottom.y}}, type="unit-spawner"})) do
		modifySpawners(event.area, spawner)
	end
	
	for num,worm in pairs(event.surface.find_entities_filtered({area = {{event.area.left_top.x, event.area.left_top.y}, {event.area.right_bottom.x, event.area.right_bottom.y}}, type="turret"})) do
		modifyWorms(event.area, worm)
	end
	
end)