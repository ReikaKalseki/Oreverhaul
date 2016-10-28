local seed = 0
local MULTIPLIER = 1103515245
local ADDEND = 12345
local MASK = 2147483647
local BITSHIFT = 7

--THIS RAND SUCKS

function setRandSeed(newseed)
    seed = bit32.band(newseed, 2147483647)
end

function nextRand()
    seed = bit32.band((seed * MULTIPLIER + ADDEND), MASK)
    return bit32.rrotate(seed, BITSHIFT)
end

function nextDouble()
	return nextRand() / 2147483647
end

function nextInt(limit)
	return 1+(nextRand() % limit)
end

function nextRangedInt(minval, maxval)
	if minval == maxval then
		return minval
	end
	return minval+nextRand()%(1+maxval-minval)
end

function randWithSeed(cseed)
    local oldseed = seed
	local ret = nextRand()
	seed = oldseed
	return ret
end