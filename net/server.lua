--[[
     net server implementation
]]

local socket = require "socket"

local SERVER = {}  -- this table for methods only (it is shared between all instances of server)
-- one aproach to set handler on property is use __usedindex
local server_meta = {
	__index = SERVER,
	__usedindex = function (t, k, v)
		if k == "connto" then
			t.socket:settimeout(v)
		end
		t[k] = v
	end
}

local CLIENT = {}  -- this table for methods only (it is shared between all instances of client)
-- another aproach to set handler on property is use __index and __newindex with private index and proxy
-- it is more flexible
local cindex = {}  -- private client index
local client_meta = {
	__index = function(t, k)
		return t[cindex][k] or CLIENT[k]
	end,
	__newindex = function (t, k, v)
		if k == "connto" then
			t[cindex].socket:settimeout(v)
		end
		t[cindex][k] = v
	end
}

-- constructor
function SERVER.new(port, connto, ssl, tls_params, hsto)
	local sock
	local res, em = pcall(function () sock = socket.bind("*", port) end)
	if not res then
		return nil, "can't bind socket to port " .. tostring(port) .. ": " .. em
	end
	sock:settimeout(connto)

	local server = setmetatable({}, server_meta)
	-- Public properties
	server.port       = port
	server.socket     = sock
	server.connto     = connto
	server.ssl        = ssl
	server.tls_params = tls_params
	server.hsto       = hsto
	server.clients    = {}

	return server
end

-- API

function SERVER:accept()
	-- accept new connection
	local sock, em = self.socket:accept()
	if not sock then
		return nil, "can't accept connections: " .. em
	end
	local ip, port = sock:getpeername()

	if self.ssl then
		-- try to establish secure connection
		local sslsock
		sslsock, em = self.ssl.wrap(sock, self.tls_params)
		if not sslsock then
			sock:close()
			return nil, string.format("can't establish secure connection with %s:%d: %s", ip, port, em)
		end
		sock = sslsock

		-- try to handshake
		sock:settimeout(self.hsto)
		local hsres
		hsres, em = sock:dohandshake()
		if not hsres then
			sock:close()
			return nil, string.format("can't do handshake with %s:%d: %s", ip, port, em)
		end
	end

	sock:settimeout(self.connto)

	-- add new client
	local client = setmetatable({}, CLIENT)
	-- Public properties
	client.ip     = ip
	client.port   = port
	client.socket = sock
	client.connto = self.connto
	local proxy = {}
	proxy[cindex] = client
	setmetatable(proxy, client_meta)
	table.insert(self.clients, proxy)
	return proxy
end

function CLIENT:ping()
	self.socket:send("* PING\n")
	local timestamp = socket.gettime()
	local data, em = self.socket:receive("*l")
	if not data or data ~= "* PONG" then
		if data and data ~= "* PONG" then
			em = "protocol"
		end
		return nil, em
	else
		return socket.gettime() - timestamp
	end
end

return setmetatable(SERVER, {__call = function(_, ...) return SERVER.new(...) end})
