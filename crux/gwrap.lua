--[[
     event grabber wrapper
]]

local grabber = require "crux.grabber"

local GRABBER = {}     -- this table for methods only (it is shared between all instances of server)
local gindex = {}  -- grabber private index

local function grabberExclusiveSetter(t, v)
	if t[gindex].exclusive ~= v then
		if not t[gindex].exclusive then
			t:getexclusive()
		else
			t:release()
		end
	end
end

local grabber_prop_setters = {}
grabber_prop_setters.exclusive = grabberExclusiveSetter

local grabber_meta = {
	__index = function(t, k)
		return t[gindex][k] or GRABBER[k]
	end,
	__newindex = function (t, k, v)
		if grabber_prop_setters[k] ~= nil then
			grabber_prop_setters[k](t, v)
		end
	end
}

-- constructor
function GRABBER.new(dev, eventto)
	local fd, em = grabber.open(dev)
	if not fd then
		return nil, string.format("can't open device %s: %s", dev, em)
	end

	local name, _ = grabber.getname(fd)
	if not name then
		name = "Unknown"
	end

	local grab = setmetatable({}, GRABBER)
	-- Public properties
	grab.dev          = dev
	grab.name         = name
	grab.fd           = fd
	grab.exclusive    = false
	grab.eventto      = eventto
	grab.keychain     = {}

	local proxy = {}
	proxy[gindex] = grab
	setmetatable(proxy, grabber_meta)
	return proxy
end

-- API

function GRABBER.sleep(t)
	grabber.sleep(t)
end

function GRABBER:getexclusive()
	if not self[gindex].exclusive then
		local res, em = grabber.exclusive(self.fd)
		if res then
			self[gindex].exclusive = true
		end
		return res, em
	else
		return nil, "exclusive access already set"
	end
end

function GRABBER:release()
	if self[gindex].exclusive then
		local res, em = grabber.release(self.fd)
		if res then
			self[gindex].exclusive = false
		end
		return res, em
	else
		return nil, "exclusive access not set yet"
	end
end

function GRABBER:read()
	local ev, em = grabber.readevent(self.fd, self.eventto)
	if not ev then
		return nil, em
	end

	if ev.type == 1 then
		if ev.value == 1 then
			table.insert(self.keychain, ev.code)
		elseif ev.value == 0 then
			for k, v in pairs(self.keychain) do
				if v == ev.code then
					table.remove(self.keychain, k)
					break
				end
			end
		end
	end

	return ev, self.keychain
end

function GRABBER:close()
	return grabber.close(self.fd)
end

return setmetatable(GRABBER, {__call = function(_, ...) return GRABBER.new(...) end})
