--require "defines"
require "functions"
require "config"

local ore_debug = false
local spawner_debug = false

local ranTick = false

function initGlobal(force)
	if not global.oreverhaul then
		global.oreverhaul = {}
	end
	if force or global.oreverhaul.ranTick == nil then
		global.oreverhaul.ranTick = false
	end
	if game and game.entity_prototypes and (force or global.oreverhaul.availableWorms == nil or #global.oreverhaul.availableWorms == 0) then
		buildWormList()
	end
	if game and game.entity_prototypes and (force or global.oreverhaul.tierOresSum == nil or #global.oreverhaul.tierOresSum == 0) then
		buildOreList()
	end
	
	if game and game.active_mods then
		global.oreverhaul.chokepoint_loaded = game.active_mods.ChokePoint ~= nil
	end
end

initGlobal(true)

script.on_init(function()
	initGlobal(true)
	initModifiers(true)
end)

script.on_load(function()
	initModifiers(false)
end)

script.on_configuration_changed(function(data)
	initGlobal(false)
	if not game.is_multiplayer() and data.mod_changes.ChokePoint and data.mod_changes.ChokePoint.old_version == nil then --just added ChokePoint, AND SP, call init() once more
		initChokepointModifiers(false)
	end
end)

function controlChunk(surface, area, doOres, doSpawners)
	initGlobal(false)

	if doOres then
		local totals = {}
		local newtotals = {}
		local mults = {}
		local counts = {}
		
		for num,ore in pairs(surface.find_entities_filtered({area = {{area.left_top.x, area.left_top.y}, {area.right_bottom.x, area.right_bottom.y}}, type="resource"})) do
			if not ignoreOre(ore) then
				if Config.redoOrePlacement then
					ore.destroy()
				else
					local mult = getMultiply(area, ore)
					if mult == nil or mult <= 0 then
						if ore_debug then
							--game.player.print("Destroyed " .. ore.name .. " @ " .. ore.position.x .. "," .. ore.position.y)
						end
						ore.destroy()
					else
						local amt = math.min(4000000000, math.floor(ore.amount * mult))
						if amt <= 0 then
							ore.destroy()
						else
							ore.amount = amt
							
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
				end
			end
		end
		
		if ore_debug then
			printDebug(area, totals, newtotals, mults, counts)
		end
		
		if Config.redoOrePlacement then
			local x = (area.left_top.x+area.right_bottom.x)/2
			local y = (area.left_top.y+area.right_bottom.y)/2
			createSpillingOrePatches(surface, area, x, y)
			tryCreateOrePatch(surface, area, x, y)
			
			--local loc = getChunkCoord(x, y)
			--genCachedChunk(surface, loc)
		end
	end
	
	if doSpawners then
		if Config.redoSpawnerPlacement then
			redoSpawnersAndWorms(surface, area)
		elseif Config.spawnerScaling then
			for num,spawner in pairs(surface.find_entities_filtered({area = {{area.left_top.x, area.left_top.y}, {area.right_bottom.x, area.right_bottom.y}}, type="unit-spawner"})) do
				modifySpawners(spawner)
			end
			
			for num,worm in pairs(surface.find_entities_filtered({area = {{area.left_top.x, area.left_top.y}, {area.right_bottom.x, area.right_bottom.y}}, type="turret"})) do
				modifyWorms(worm)
			end
		end
	end
end

script.on_event(defines.events.on_tick, function(event)
	initGlobal(false)
	
	if not ranTick and (Config.retrogenOreDistance >= 0 or Config.retrogenSpawnerDistance >= 0) then
		if Config.retrogenSpawnerDistance >= 0 then
			game.forces["enemy"].kill_all_units()
		end
		local surface = game.surfaces["nauvis"]
		for chunk in surface.get_chunks() do
			local x = chunk.x
			local y = chunk.y
			if surface.is_chunk_generated({x, y}) then
				local area = {
					left_top = {
						x = x*CHUNK_SIZE,
						y = y*CHUNK_SIZE
					},
					right_bottom = {
						x = (x+1)*CHUNK_SIZE,
						y = (y+1)*CHUNK_SIZE
					}
				}
				local dx = x*CHUNK_SIZE+CHUNK_SIZE/2
				local dy = y*CHUNK_SIZE+CHUNK_SIZE/2
				local dist = math.sqrt(dx*dx+dy*dy)
				controlChunk(surface, area, (Config.retrogenOreDistance >= 0 and Config.retrogenOreDistance <= dist), (Config.retrogenSpawnerDistance >= 0 and Config.retrogenSpawnerDistance <= dist))
			end
		end
		ranTick = true
		for name,force in pairs(game.forces) do
			force.rechart()
		end
		--game.print("Ran load code")
	end
	
	--local pos=game.players[1].position
	--for k,v in pairs(game.surfaces.nauvis.find_entities_filtered{area={{pos.x-1,pos.y-1},{pos.x+1,pos.y+1}}, type="resource"}) do v.destroy() end
end)

script.on_event(defines.events.on_chunk_generated, function(event)
	if game.active_mods["rso-mod"] then
		game.print("Oreverhaul: RSO Detected; the two mods cannot function together. Oreverhaul can do most everything RSO can, making RSO's presence unnecessary.")
		return
	end
	controlChunk(event.surface, event.area, true, true)
end)

script.on_event(defines.events.on_biter_base_built, function(event)
	if Config.enforceSpawnerTieringForBuiltBases and (Config.redoSpawnerPlacement or Config.spawnerScaling) and math.random() > event.entity.force.evolution_factor then
		local base = event.entity
		if base.type == "unit-spawner" then
			modifySpawners(base)
			return
		end
		if base.type == "turret" then
			modifyWorms(base)
			return
		end
	end
end)