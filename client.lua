#!/usr/bin/env lua

local common  = require "common"
local flooder = require "crux.fwrap"
local client  = require "net.client"

local host, port, reconnto, connto, ssl, tls_params, hsto, uinput, eventto, loopto, fork, debug = require "config.client"()
local dpre = ""

-- TLS warning
if not ssl then common.tlswarn() end

-- parse cmd args
if arg[1] then
	local d = arg[1]:find(":")
	if not d then
		host = arg[1]
	else
		if d ~= 1 then
			host = arg[1]:sub(1, d - 1)
		end
		port = arg[1]:sub(d + 1)
	end
end

-- start flooder
local em
flooder, em = flooder(uinput, eventto)
if not flooder then
	print(dpre .. "flooder failed")
	print(dpre .. em)
	os.exit(1)
elseif debug then
	print(dpre .. "flooder started")
end

-- try to fork
if fork then
	local res
	res, em = common.forktobg()
	if res then
		dpre = "noxkvm-client: "
		if debug then print(dpre .. "forked to background") end
	else
		if debug then
			print(dpre .. "can't fork to background")
			print(em)
			print(dpre .. "stay foreground")
		end
	end
end

-- main loop
local conn, data
local fa = true
while 1 do
	-- try to connect
	conn, em = client(host, port, connto, ssl, tls_params, hsto)
	if not conn then
		if debug and fa then
			print(dpre .. em)
			fa = false
		end
		goto reconn
	elseif debug then
		print(string.format(dpre .. "connection established with %s:%d", host, port))
	end
	fa = true

	-- client loop
	while 1 do
		-- receive event
		conn:select()
		data, em = conn:receive()
		if not data then
			if em == "closed" then
				if debug then print(dpre .. "server closed connection") end
				goto closeconn
			elseif em == "timeout" then
				if debug then print(dpre .. "receiving timeout") end
				goto receive
			end
		end

		-- write event
		print(dpre .. "Server sends: " .. data)

		::receive::
		flooder.sleep(loopto)
	end

	::closeconn::
	conn:close()
	::reconn::
	client.sleep(reconnto)
end
