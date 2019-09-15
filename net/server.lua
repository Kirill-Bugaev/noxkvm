--[[
     network server implementation
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
		return nil, em
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

function SERVER:examine(hosts)
	local res = false
	for _,h in pairs(hosts) do
		for i,c in pairs(self.clients) do
			if c.ip == h then
				if c:examine() then
					res = true
				else
					c:close()
					self.clients[i] = nil
				end
			end
		end
	end
	-- clean nils in clients array
	local c = #(self.clients)
	local i = 1
	while i <= c do
		if self.clients[i] == nil then
			table.remove(self.clients, i)
			c = c - 1
		else
			i = i + 1
		end
	end
	return res
end

function SERVER:broadcast(hosts, data)
	local res = false
	for _,h in pairs(hosts) do
		for _,c in pairs(self.clients) do
			if c.ip == h then
				if c:send(data) then
					res = true
				end
			end
		end
	end
	return res
end

function SERVER:close()
	for _,c in pairs(self.clients) do
		c:close()
	end
	self.clients = {}
	self.socket:close()
end

function CLIENT:send(data)
	data = "#" .. data
	data = data:gsub("\n", "%1#")
	data = data .. "\n*\n"
	return self.socket:send(data)
end

-- remote client should only receive data not send,
-- so try to catch closed on receive
function CLIENT:examine()
	local res = true
	self.socket:settimeout(0)
	local _, em = self.socket:receive("*l")
	if em == "closed" then
		res = false
	end
	self.socket:settimeout(self.connto)
	return res
end

function CLIENT:close()
	self.socket:close()
end

return setmetatable(SERVER, {__call = function(_, ...) return SERVER.new(...) end})
