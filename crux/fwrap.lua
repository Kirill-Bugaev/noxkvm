--[[
     event flooder wrapper
]]

local flooder = require "crux.flooder"

local FLOODER = {}  -- this table for methods only (it is shared between all instances of client)

local flooder_meta = {__index = FLOODER}

-- constructor
function FLOODER.new(uinput, eventto)
	local fd, em = flooder.create(uinput)
	if not fd then
		return nil, string.format("can't create virtual device: %s", em)
	end

	local flood = setmetatable({}, flooder_meta)
	-- Public properties
	flood.uinput  = uinput
	flood.fd      = fd
	flood.eventto = eventto

	return flood
end

-- API

function FLOODER.sleep(t)
	flooder.sleep(t)
end

function FLOODER:write(data)
	return flooder.writeevent(self.fd, data, self.eventto)
end

function FLOODER:close()
	return flooder.destroy(self.fd)
end

return setmetatable(FLOODER, {__call = function(_, ...) return FLOODER.new(...) end})