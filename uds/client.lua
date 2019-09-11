--[[
     unix domain socket client implementation
]]

local socket = require "socket"
socket.unix  = require "socket.unix"

local CLIENT = {}  -- this table for methods only (it is shared between all instances of client)
local client_meta = {__index = CLIENT}

-- constructor
function CLIENT.new(sockfile, ssl, tls_params)
	-- create socket
	local sock, em = socket.unix()
	if not sock then
		return nil, "can't create socket: " .. em
	end

	-- connect to server
	local res
	res, em = sock:connect(sockfile)
	if not res then
		return nil, "can't connect: " .. em
	end

	if ssl then
		-- try to establish secure connection
		local sslsock
		sslsock, em = ssl.wrap(sock, tls_params)
		if not sslsock then
			sock:close()
			return nil, "can't establish secure connection: " .. em
		end
		sock = sslsock

		-- try to handshake
		res, em = sock:dohandshake()
		if not res then
			sock:close()
			return nil, "can't do handshake: " .. em
		end
	end

	local client = setmetatable({}, client_meta)
	-- Public properties
	client.file   = sockfile
	client.socket = sock

	return client
end

return setmetatable(CLIENT, {__call = function(_, ...) return CLIENT.new(...) end})
