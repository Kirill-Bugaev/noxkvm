local function tlswarn()
	print("Warning! Started without TLS.")
	print("Using it without TLS is insecure.")
	print("You should install lua-sec and create your own PKI.")
	print("See https://github.com/Kirill-Bugaev/clipnetsync#TLS")
end

local function forktobg()
	local fork
	local _, em = pcall(function () fork = require "posix".unistd.fork end)
	if not fork then
		return false, em
	end
	local pid
	pid, em = fork()
	if not pid then
		return false, em
	end
	if pid ~= 0 then
		os.exit(0)
	end
	return true
end

-- escape all lines with '#', add '\n*' to the end (end of data mark)
local function sendclip(socket, clip)
	clip = "#" .. clip
	clip = clip:gsub("\n", "%1#")
	clip = clip .. "\n*\n"
	return socket:send(clip) -- try to send at one go
end

local function receiveclip(socket)
	local out = ""
	while 1 do
		local line, em = socket:receive()
		if not line then return nil, em end
		if line == "*" then break end
		if out ~= "" then
			out = out .. "\n"
		end
		out = out .. line:sub(2)
	end
	return out
end

return {tlswarn = tlswarn, forktobg = forktobg, receiveclip = receiveclip, sendclip = sendclip}
