--local seed = 0

function initSeed()
	--if seed ~= nil and seed ~= 0 then return end
	--if not global then global = {} end
	--if not global.oreverhaul then global.oreverhaul = {} end
	--if not global.oreverhaul.seed then global.oreverhaul.seed = 0 end
	--seed = global.oreverhaul.seed
	if not global.oreverhaul.rng then
		global.oreverhaul.rng = game.create_random_generator()
	end
end
--[[
initSeed()

local MULTIPLIER = 1103515245
local ADDEND = 12345
local MASK = 2147483647
local BITSHIFT = 7
--]]
--THIS RAND SUCKS

function setRandSeed(newseed)
	initSeed()
    --seed = bit32.band(newseed, 2147483647)
	--global.oreverhaul.seed = seed
	global.oreverhaul.rng.re_seed(bit32.band(newseed, 2147483647))
end

function nextDouble()
	initSeed()
	return global.oreverhaul.rng()
end

function nextInt(limit)
	initSeed()
	return global.oreverhaul.rng(limit)
end

function nextRangedInt(minval, maxval)
	initSeed()
	if minval >= maxval then return minval end
	return global.oreverhaul.rng(minval, maxval)
end