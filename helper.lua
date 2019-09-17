--[[
      misc helper routine
]]

-- table length
local function tlength(t)
	local c = 0
	for _, _ in pairs(t) do
		c = c + 1
	end
	return c
end

-- find key sequence in binds table
local function findkeys(binds, keys)
	local found
	for i, b in pairs(binds) do
		if tlength(b.keys) == tlength(keys) then
			local eq = true
			for j, k in pairs(b.keys) do
				if k ~= keys[j] then
					eq = false
					break
				end
			end
			if eq then
				found = i
				break
			end
		end
	end
	return found
end

-- find host in host table
local function findhost(ht, h)
	local found
	for k, v in pairs(ht) do
		if v == h then
			found = k
			break
		end
	end
	return found
end

-- convert config key bindings to array of tables of tables
local function parsebinds(binds)
	local out = {}
	for _, cb in pairs(binds) do
		local b = {}
		-- parse keys
		if type(cb.keys) == "table" then
			b.keys = {}
			for _, k in pairs(cb.keys) do
				if type(k) == "number" then
					table.insert(b.keys, k)
				else
					return nil
				end
			end
		elseif type(cb.keys) == "number" then
			b.keys = {cb.keys}
		else
			return nil
		end
		-- try to find this key sequence in out table
		-- (maybe key sequence have been added already)
		local found = findkeys(out, b.keys)
		local ht
		if found then
			ht = out[found].hosts
		else
			b.hosts = {}
			ht = b.hosts
		end
		-- parse hosts
		if type(cb.hosts) == "table" then
			for _, h in pairs(cb.hosts) do
				if type(h) == "string" then
					if not findhost(ht, h) then  -- maybe host have been added already
						table.insert(ht, h)
					end
				else
					return nil
				end
			end
		elseif type(cb.hosts) == "string" then
			if not findhost(ht, cb.hosts) then  -- maybe host have been added already
				table.insert(ht, cb.hosts)
			end
		else
			return nil
		end
		if not found then
			table.insert(out, b)
		end
	end
	return out
end

-- find root key binding
local function findroot(binds)
	for k, b in pairs(binds) do
		if next(b.hosts, 1) == nil and b.hosts[1] == "root" then
			return k
		end
	end
	return nil
end

-- return binds index which corresponds to keys
local function switch(binds, keys)
	if next(keys) == nil then
		-- keys is empty
		return nil
	end

	-- find keys in binds
	local found = findkeys(binds, keys)
	local isroot = false
	if found then
		-- check root in found hosts
		if findhost(binds[found].hosts, "root") then
			isroot = true
		end
	end

	return found, isroot
end

-- convert table to string with ', ' delimiter
local function ttostr(t)
	local out = ""
	for _,v in pairs(t) do
		if out ~= "" then
			out = out .. ", "
		end
		out = out .. tostring(v)
	end
	return out
end

-- try to find event handler with given suffix
local function gethandler(suffix)
	local scan_path = "/dev/input/by-id/"
	local quotepattern = "(["..("%^$().[]*+-?"):gsub("(.)", "%%%1").."])"
	local list = io.popen("/bin/ls --format=single-column " .. scan_path, "r")

	local handler
	local file = ""
	while file do
		file = list:read("*l")
		if file and file:match(suffix:gsub(quotepattern, "%%%1")) then
			local target = io.popen("readlink -f " .. scan_path .. file)
			handler = target:read()
			target:close()
			if handler then
				break
			end
		end
	end

	list:close()
	return handler
end

return {
	tlength    = tlength,
	findkeys   = findkeys,
	findhost   = findhost,
	parsebinds = parsebinds,
	findroot   = findroot,
	switch     = switch,
	ttostr     = ttostr,
	gethandler = gethandler
}
