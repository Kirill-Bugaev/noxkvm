local function tlswarn()
	print("Warning! Started without TLS.")
	print("Using it without TLS is insecure.")
	print("You should install lua-sec and create your own PKI.")
	print("See https://github.com/Kirill-Bugaev/noxkvm#TLS")
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

return {tlswarn = tlswarn, forktobg = forktobg}
