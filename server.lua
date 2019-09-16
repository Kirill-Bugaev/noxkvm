#!/usr/bin/env lua

local common  = require "common"
local helper  = require "helper"
local grabber = require "crux.gwrap"
local server  = require "net.server"

local port, connto, ssl, tls_params, hsto, kb_dev, mouse_dev, eventto, binds, loopto, fork, debug
	= require "config.server"()

-- TLS warning
if not ssl then common.tlswarn() end

-- parse binds
binds = helper.parsebinds(binds)
if not binds then
	print("incorrect key bindings format")
	print("check config")
	os.exit(1)
end
local root = helper.findroot(binds)
if not root then
	print("root key binding not specified")
	print("check config")
	os.exit(1)
end

-- start keyboard grabber
local keyboard, em = grabber(kb_dev, eventto)
if not keyboard then
	print("keyboard grabber failed")
	print(em)
	os.exit(1)
elseif keyboard and debug then
	print(string.format("keyboard grabber (%s) started", keyboard.name))
end

-- start mouse grabber
local mouse
mouse, em = grabber(mouse_dev, eventto)
if not mouse and debug then
	print("mouse grabber failed")
	print(em)
elseif mouse and debug then
	print(string.format("mouse grabber (%s) started", mouse.name))
end

-- start network server
server, em = server(port, connto, ssl, tls_params, hsto)
if not server then
	print("can't start network server")
	print(em)
	if mouse then mouse:close() end
	keyboard:close()
	os.exit(1)
else
	if debug then print("network server started") end
end

-- try to fork
if fork then
	local res
	res, em = common.forktobg()
	if not res then
		print("can't fork to background")
		print(em)
		print("stay foreground")
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
		if debug then print(string.format("connection established with %s:%d", c.ip, c.port)) end
	end

	-- check closed connections
	local closed = server:getclosed()
	if next(closed) ~= nil and debug then print(helper.ttostr(closed) .. " closed connection") end

	-- check keyboard event
	local event, keys = keyboard:read()
	if event then
		if debug then
			print(string.format(
				"got event from (%s) type=%d,code=%d,value=%d", keyboard.name, event.type, event.code, event.value
			))
		end
		local new, isroot = helper.switch(binds, keys)
		if new and new ~= current then
			if server:isactive(binds[new].hosts) then
				keyboard.exclusive = not isroot
				mouse.exclusive = not isroot
				current = new
				if debug then print("control switched to " .. helper.ttostr(binds[new].hosts)) end
			elseif current ~= root then
				keyboard.exclusive = false
				mouse.exclusive = false
				current = root
				if debug then print("control switched to root") end
			end
		elseif current ~= root then
			local active = server:broadcast(binds[current].hosts, event)
			if next(active) ~= nil then
				if debug then print("event sent to " .. helper.ttostr(active)) end
			else
				keyboard.exclusive = false
				mouse.exclusive = false
				current = root
				if debug then print("event sent nobody, control switched to root") end
			end
		end
	end

	-- check mouse event
	event = mouse:read()
	if event then
		if debug then
			print(string.format(
				"got event from (%s) type=%d,code=%d,value=%d", mouse.name, event.type, event.code, event.value
			))
		end
		if current ~= root then
			local active = server:broadcast(binds[current].hosts, event)
			if next(active) ~= nil then
				if debug then print("event sent to " .. helper.ttostr(active)) end
			else
				keyboard.exclusive = false
				mouse.exclusive = false
				current = root
				if debug then print("event sent nobody, control switched to root") end
			end
		end
	end

	grabber.sleep(loopto)
end
