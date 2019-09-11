--[[
      net server and client common configuration
]]

local port   = 46855  -- server tcp port
local connto = 0.1    -- connection/send/receive timeout (sec)

local function factory()
	return port, connto
end

return factory
