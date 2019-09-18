#!/usr/bin/env lua

--[[
     get key codes from event device
		 usage:
		   # lua getkeys.lua <event_device>
		 example:
		   $ sudo lua getkeys.lua /dev/input/event2
]]

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
	print("Can't change working directory.")
	print("You should change working directory to directory where script placed before start it.")
end

local helper  = require "helper"
local grabber = require "lib.grabber"
local _, _, _, _, _, detect, kb_dev = require "config.server"()

if not arg[1] then
	if detect then
		-- try to detect handlers
		local han = helper.gethandler("-event-kbd")
		if han then
			print("Detected keyboard handler: " .. han)
			kb_dev = han
		else
			print("Keyboard handler not detected, use default: " .. kb_dev)
		end
	else
			print("Use default keyboard handler: " .. kb_dev)
	end
	print("If it is wrong you can find appropriate keyboard handler using `cat /proc/bus/input/devices`"
		.. "and specify it in cmd args."
	)
else
	kb_dev = arg[1]
end

local fd, em = grabber.open(kb_dev)
if not fd then
	print("Can't open device: " .. em)
	os.exit(1)
end

local name
name, em = grabber.getname(fd)
if not name then
	print("Can't get device name: " .. em)
	name = "Unknown"
end
print(string.format("Device (%s) opened for reading.", name))
print("Press key")

while 1 do
	local ev
	ev, em = grabber.readevent(fd)
	if not ev then
		print("Error: " .. em)
	elseif ev.type == 1 and ev.value == 1 then
		print("Keycode " .. ev.code)
	end
end
