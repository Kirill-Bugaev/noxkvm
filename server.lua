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
local c, pip, pport, sslc, hsres, clip, r, _, to
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
	r, _, to = socket.select(clients, nil, connto)
	if to then goto checkcb end

	-- receive from first alive
	for _, rc in ipairs(r) do
		clip, em = common.receiveclip(rc)
		if not clip and em == "closed" then
			-- disconnect client
			rc:close()
			goto continue
		end

		if clip then
			if debug then print(dpre .. "received clipboard: " .. clip) end
			-- set clipboard
			clipsave = clip
			f = io.popen("xsel -i " .. sel, "w")
			f:write(clip)
			f:close()
			-- spread new clipboard value
			spread(clip, clients, peers)
			break
		end

		::continue::
	end

	-- check local clipboard
	::checkcb::
	f = io.popen("xsel -o " .. sel, "r")
	clip = f:read("*a")
	f:close()
	if clip ~= "" and clip ~= clipsave then
		if debug then print(dpre .. "clipboard changed locally: " .. clip) end
		clipsave = clip
		spread(clip, clients, peers)
	end

	socket.sleep(loopto)
end
