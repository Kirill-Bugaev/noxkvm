#!/usr/bin/env lua

-- change current directory to directory of script location
local function fixdir()
	local lfs
	pcall(function () lfs = require "lfs" end)
	if not lfs then
		return false
	end
	local s = debug.getinfo(1,"S").source:sub(2)
	print(s)
	local f = io.open(s, "r")
	if not f then
		return false
	end
	f:close()
	s = s:match("(.*/)")
	if s and not lfs.chdir(s) then
		return false
	end
	return true
end
if not fixdir() then
	print("can't change working directory")
	print("you should change working directory to directory where script placed before start it")
end

local common  = require "common"
local helper  = require "helper"
local grabber = require "grabber"
local server  = require "net.server"

local port, connto, ssl, tls_params, hsto, detect, kb_dev, mouse_dev, eventto, binds, loopto, fork, debug
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

-- try to detect handlers
if detect then
	local han = helper.gethandler("-event-kbd")
	if han then
		if debug then print("detected keyboard handler: " .. han) end
		kb_dev = han
	else
		if debug then print("keyboard handler not detected, use default: " .. kb_dev) end
	end
	han = helper.gethandler("-event-mouse")
	if han then
		if debug then print("detected mouse handler: " .. han) end
		mouse_dev = han
	else
		if debug then print("mouse handler not detected, use default: " .. mouse_dev) end
	end
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

-- try to catch term signals
local function sighandler()
	if mouse then
		mouse:close()
	end
	keyboard:close()
	server:close()
	os.exit(0)
end
local res
res, em = common.catchsigs(sighandler)
if not res and debug then
	print("kill signals will not be caught")
	print(em)
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
