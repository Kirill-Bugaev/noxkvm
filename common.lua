local function tlswarn()
	print("Warning! Started without TLS.")
	print("Using it without TLS is insecure.")
	print("You should install lua-sec and create your own PKI.")
	print("See https://github.com/Kirill-Bugaev/noxkvm#TLS")
end

local function forktobg()
	local unistd
	local _, em = pcall(function () unistd = require "posix".unistd end)
	if not unistd then
		return false, em
	end
	local fork = unistd.fork
	local pid
	pid, em = fork()
	if not pid then
		return false, em
	end
	if pid ~= 0 then
		os.exit(0)
	end
	local close = unistd.close
	close(0)
	close(1)
	close(2)
	return true
end

local function catchsigs(handler)
	local signal
	local _, em = pcall(function () signal = require "posix.signal" end)
	if not signal then
		return false, em
	end
	signal.signal(signal.SIGINT, handler)
	signal.signal(signal.SIGTERM, handler)
	signal.signal(signal.SIGHUP, handler)
	signal.signal(signal.SIGPIPE, handler)
	return true
end

return {tlswarn = tlswarn, forktobg = forktobg, catchsigs = catchsigs}
