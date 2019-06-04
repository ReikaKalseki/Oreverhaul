require "config"

--moved here for other mods to handle AFTER
if Config.nestHealthFactor > 1 then
	for k, spawner in pairs(data.raw["unit-spawner"]) do
		spawner.max_health = spawner.max_health*Config.nestHealthFactor
	end
end