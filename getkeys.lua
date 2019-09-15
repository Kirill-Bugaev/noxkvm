#!/usr/bin/env lua

--[[
     get key codes from event device
		 usage:
		   # lua getkeys.lua <event_device>
		 example:
		   $ sudo lua getkeys.lua /dev/input/event2
]]


local grabber = require "crux.grabber"

if not arg[1] then
	print("Event device not specified.")
	print("Usage: lua getkeys.lua <event_device>")
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
	local raw, code, val = grabber.getevent(fd)
	if not raw then
		print("Error: " .. code)
	elseif code and val == 1 then
		print("Keycode " .. code)
	end
end
