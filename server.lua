local socket  = require "socket"
local common  = require "common"

local port, connto, loopto, ssl, hsto, tls_params, kb_event, mouse_event, host_binds, fork, debug = require("config")
local dpre = ""

-- TLS warning
if not ssl then common.tlswarn() end

-- try to fork
if fork then
	local s, em = common.forktobg()
	if s then
		if debug then print("forked to background") end
		dpre = "noxkvm-server: "
	else
		if debug then
			print("can't fork to background")
			print(em)
			print("stay foreground")
		end
	end
end

-- start grabbers
local kbg = io.popen("./grabber " .. kb_event, "r")
local resp = kbg:read("*l")
local msg = kbg:read("*l")
if resp == "\\NAME" then
	-- started OK
	if debug then print(string.format("device %s (%s) opened for reading", kb_event, msg)) end
else
	if resp ~= "\\5" or debug then
		print(string.format("error occured while starting grabber for %s device", kb_event))
		print(msg)
	end
	if resp ~= "\\5" then
		kbg:close()
		os.exit(1)
	end
	-- started OK, but can't read device name
	if debug then print(string.format("device %s (Unknown) opened for reading", kb_event)) end
end

-- start server
local server, em = socket.bind("*", port)
if not server then
	print(dpre .. "can't bind socket to port " .. port)
	print(dpre .. em)
	os.exit(1)
end
server:settimeout(connto)
local clients = {}
local peers = {}

-- main loop
local c, pip, pport, sslc, hsres
while 1 do
	c = server:accept()
	if not c then goto examine end

	-- save ip and port of client
	pip, pport = c:getpeername()

	if not ssl then
		-- add new client (insecure)
		if debug then print(dpre .. string.format("insecure connection established with %s:%d", pip, pport)) end
		c:settimeout(connto)
		table.insert(clients, c)
		table.insert(peers, {ip = pip, port = pport})
		goto examine
	end

	-- try to establish secure connection
	sslc, em = ssl.wrap(c, tls_params)
	if not sslc then
		if debug then
			print(dpre .. string.format("can't establish secure connection with %s:%d", pip, pport))
			print(dpre .. em)
		end
		c:close()
		goto examine
	end

	c = sslc
	-- try to handshake
	c:settimeout(hsto)
	hsres, em = c:dohandshake()
	if not hsres then
		if debug then
			print(dpre .. string.format("can't do handshake with %s:%d", pip, pport))
			print(dpre .. em)
		end
		c:close()
		goto examine
	end

	-- add new client (secure)
	if debug then print(dpre .. string.format("secure connection established with %s:%d", pip, pport)) end
	c:settimeout(connto)
	table.insert(clients, c)
	table.insert(peers, {ip = pip, port = pport})
	goto examine

	-- examine events
	::examine::
	socket.sleep(loopto)
end
