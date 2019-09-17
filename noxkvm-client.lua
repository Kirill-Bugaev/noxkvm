#!/usr/bin/env lua

-- change current directory to directory of script location
local function fixdir()
	local lfs
	pcall(function () lfs = require "lfs" end)
	if not lfs then
		return false
	end
	local s = debug.getinfo(1,"S").source:sub(2)
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
local flooder = require "flooder"
local client  = require "net.client"

local host, port, reconnto, connto, ssl, tls_params, hsto, loopto, fork, debug = require "config.client"()
local conn

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
flooder, em = flooder()
if not flooder then
	print("virtual device failed")
	print(em)
	os.exit(1)
elseif debug then
	print("virtual device started")
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
local termsigs
local function sighandler(signo)
	for _,s in pairs(termsigs) do
		if s == signo then
			if conn then
				conn:close()
			end
			flooder:close()
			os.exit(0)
		end
	end
end
local res
termsigs, em = common.catchsigs(sighandler)
if not termsigs and debug then
	print("kill signals will not be caught")
	print(em)
end

-- main loop
local event
local fa = true
while 1 do
	-- try to connect
	conn, em = client(host, port, connto, ssl, tls_params, hsto)
	if not conn then
		if debug and fa then
			print(em)
			fa = false
		end
		goto reconn
	elseif debug then
		print(string.format("connection established with %s:%d", host, port))
	end
	fa = true

	-- client loop
	while 1 do
		-- receive event
		event, em = conn:receive()
		if event then
			if debug then print(string.format("got event type=%d,code=%d,value=%d", event.type, event.code, event.value)) end
		else
			if em == "closed" then
				if debug then print("server closed connection") end
				goto closeconn
			else
				if debug then print("receiving timeout") end
				goto receivenext
			end
		end

		-- write event
		res, em = flooder:write(event)
		if debug then
			if res then
				print("event written to virtual device")
			else
				print("can't write event to virtual device")
				print(em)
			end
		end

		::receivenext::
		flooder.sleep(loopto)
	end

	::closeconn::
	conn:close()
	::reconn::
	client.sleep(reconnto)
end
