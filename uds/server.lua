--[[
     unix domain socket server implementation
]]

local posix  = require "posix"
local socket = require "socket"
socket.unix  = require "socket.unix"

local SERVER = {}  -- this table for methods only (it is shared between all instances of server)
local server_meta = {__index = SERVER}

local CLIENT = {}  -- this table for methods only (it is shared between all instances of client)
local client_meta = {__index = CLIENT}

function SERVER:_clean()
	os.remove(self.file)
	os.remove(self.dir)
end

-- constructor
function SERVER.new(ssl, tls_params)
	local sock, em = socket.unix()
	if not sock then
		return nil, "can't create socket: " .. em
	end

	local tmpdir
	tmpdir, em = posix.mkdtemp("/tmp/noxkvm-uds-XXXXXX")
	if not tmpdir then
		return nil, "can't create temporary directory: " .. em
	end
	local sockfile =  tmpdir .. "/socket"

	local res
	res, em = sock:bind(sockfile)
	if not res then
		os.remove(tmpdir)
		return nil, string.format("can't bind socket to %s: %s", sockfile, em)
	end

	res, em = sock:listen()
	if not res then
		os.remove(sockfile)
		os.remove(tmpdir)
		return nil, "can't start listen: " .. em
	end

	local server = setmetatable({}, server_meta)
	-- Public properties
	server.dir        = tmpdir
	server.file       = sockfile
	server.socket     = sock
	server.ssl        = ssl
	server.tls_params = tls_params
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

	if self.ssl then
		-- try to establish secure connection
		local sslsock
		sslsock, em = self.ssl.wrap(sock, self.tls_params)
		if not sslsock then
			sock:close()
			return nil, "can't establish secure connection: " .. em
		end
		sock = sslsock

		-- try to handshake
		local hsres
		hsres, em = sock:dohandshake()
		if not hsres then
			sock:close()
			return nil, "can't do handshake: " .. em
		end
	end

	-- add new client
	local client = setmetatable({}, client_meta)
	-- Public properties
	client.socket = sock

	return client
end

return setmetatable(SERVER, {__call = function(_, ...) return SERVER.new(...) end})
