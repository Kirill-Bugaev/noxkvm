--[[
     event flooder wrapper
]]

local flooder = require "lib.flooder"

local FLOODER = {}  -- this table for methods only (it is shared between all instances of client)

local flooder_meta = {__index = FLOODER}

-- constructor
function FLOODER.new()
	local fd, em = flooder.create()
	if not fd then
		return nil, string.format("can't create virtual device: %s", em)
	end

	local flood = setmetatable({}, flooder_meta)
	-- Public properties
	flood.fd      = fd

	return flood
end

-- API

function FLOODER.sleep(t)
	flooder.sleep(t)
end

function FLOODER:write(event)
	return flooder.writeevent(self.fd, event)
end

function FLOODER:close()
	return flooder.destroy(self.fd)
end

return setmetatable(FLOODER, {__call = function(_, ...) return FLOODER.new(...) end})
