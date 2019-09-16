--[[
     network client implementation
]]

local socket = require "socket"

local CLIENT = {}  -- this table for methods only (it is shared between all instances of client)

local client_meta = {
	__index = CLIENT,
	__usedindex = function (t, k, v)
		if k == "connto" then
			t.socket:settimeout(v)
		end
		t[k] = v
	end
}

-- constructor
function CLIENT.new(host, port, connto, ssl, tls_params, hsto)
	-- connect to server
	local sock, em = socket.connect(host, port)
	if not sock then
		return nil, string.format("can't connect to %s:%d: %s", host, port, em)
	end

	if ssl then
		-- try to establish secure connection
		local sslsock
		sslsock, em = ssl.wrap(sock, tls_params)
		if not sslsock then
			sock:close()
			return nil, string.format("can't establish secure connection with %s:%d: %s", host, port, em)
		end
		sock = sslsock

		-- try to handshake
		sock:settimeout(hsto)
		local hsres
		hsres, em = sock:dohandshake()
		if not hsres then
			sock:close()
			return nil, string.format("can't do handshake with %s:%d: %s", host, port, em)
		end
	end

	-- success
	sock:settimeout(connto)

	local client = setmetatable({}, client_meta)
	-- Public properties
	client.host       = host
	client.port       = port
	client.socket     = sock
	client.connto     = connto

	return client
end

-- API

function CLIENT:receive()
	local event = {}

	-- type
	local line, em = self.socket:receive("*l")
	if not line then
		return nil, em
	end
	event.type = tonumber(line)

	-- code
	line, em = self.socket:receive("*l")
	if not line then
		return nil, em
	end
	event.code = tonumber(line)

	-- value
	line, em = self.socket:receive("*l")
	if not line then
		return nil, em
	end
	event.value = tonumber(line)

	return event
end

function CLIENT.sleep(t)
	socket.sleep(t)
end

function CLIENT:close()
	self.socket:close()
end

return setmetatable(CLIENT, {__call = function(_, ...) return CLIENT.new(...) end})
