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
	print("can't change working directory")
	print("you should change working directory to directory where script placed before start it")
end

local grabber = require "lib.grabber"

if not arg[1] then
	print("Event handler not specified.")
	print("Usage: lua getkeys.lua <event_handler>")
	print("You can find appropriate event handlers for keyboard and mouse using `cat /proc/bus/input/devices`")
	os.exit(1)
end
local kb_event = arg[1]

local fd, em = grabber.open(kb_event)
if not fd then
	print("Can't open device. " .. em)
	os.exit(1)
end

local name
name, em = grabber.getname(fd)
if not name then
	print("Can't get device name. " .. em)
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
