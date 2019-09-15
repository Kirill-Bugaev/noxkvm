#!/usr/bin/env lua

local common  = require "common"
local helper  = require "helper"
local grabber = require "crux.gwrap"
local server  = require "net.server"

local port, connto, ssl, tls_params, hsto, kb_dev, mouse_dev, eventto, binds, loopto, fork, debug = require "config.server"()
local dpre = ""

-- TLS warning
if not ssl then common.tlswarn() end

-- parse binds
binds = helper.parsebinds(binds)
if not binds then
	print(dpre .. "incorrect key bindings format")
	print(dpre .. "check config")
	os.exit(1)
end
local root = helper.findroot(binds)
if not root then
	print(dpre .. "root key binding not specified")
	print(dpre .. "check config")
	os.exit(1)
end

-- start keyboard grabber
local keyboard, em = grabber(kb_dev, eventto)
if not keyboard then
	print(dpre .. "keyboard grabber failed")
	print(dpre .. em)
	os.exit(1)
elseif keyboard and debug then
	print(string.format(dpre .. "keyboard grabber (%s) started", keyboard.name))
end

-- start mouse grabber
local mouse
mouse, em = grabber(mouse_dev, eventto)
if not mouse and debug then
	print(dpre .. "mouse grabber failed")
	print(dpre .. em)
elseif mouse and debug then
	print(string.format(dpre .. "mouse grabber (%s) started", mouse.name))
end

-- start network server
server, em = server(port, connto, ssl, tls_params, hsto)
if not server then
	print(dpre .. "can't start network server")
	print(dpre .. em)
	if mouse then mouse:close() end
	keyboard:close()
	os.exit(1)
else
	if debug then print(dpre .. "network server started") end
end

-- try to fork
if fork then
	local res
	res, em = common.forktobg()
	if res then
		dpre = "noxkvm-server: "
		if debug then print(dpre .. "forked to background") end
	else
		if debug then
			print(dpre .. "can't fork to background")
			print(dpre .. em)
			print(dpre .. "stay foreground")
		end
	end
end

-- main loop
local current = root
while 1 do
	-- accept new connections
	local c
	c, em = server:accept()
	if not c then
		if debug and em ~= "timeout" then print(em) end
	else
		if debug then print(dpre .. string.format("connection established with %s:%d", c.ip, c.port)) end
	end

	-- check keyboard event
	local raw, keys = keyboard:read()
	if raw then
		local new, isroot = helper.switch(binds, keys)
		if new and new ~= current then
			if server:examine(binds[new].hosts) then
				keyboard.exclusive = not isroot
				mouse.exclusive = not isroot
				current = new
			elseif current ~= root then
				keyboard.exclusive = false
				mouse.exclusive = false
				current = root
			end
		elseif current ~= root then
			if not server:broadcast(binds[current].hosts, raw) then
				keyboard.exclusive = false
				mouse.exclusive = false
				current = root
			end
		end
	end

	-- check mouse event
	raw = mouse:read()
	if raw and current ~= root then
		if not server:broadcast(binds[current].hosts, raw) then
			keyboard.exclusive = false
			mouse.exclusive = false
			current = root
		end
	end

	grabber.sleep(loopto)
end
