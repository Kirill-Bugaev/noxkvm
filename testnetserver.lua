local posix  = require "posix"
local server = require "net.server"

local port, connto = require("conf.net")()
local ssl, tls_params, hsto = require("conf.tls")("server")

local s, em = server(port, connto, ssl, tls_params, hsto)
if not s then
	print("Can't start: " .. em)
	return 1
end

local c
while 1 do
	c, em = s:accept()
	if c then
		print("Connection established with " .. c.ip .. ":" .. c.port .. ", connection timeout " .. c.connto)
		while 1 do
			print("Sending ping...")
			local t
			t, em = c:ping()
			if not t then
				print("No response: " .. em)
				if em == "closed" then
					break
				end
			else
				print("Client response in " .. t .. " seconds")
			end
			posix.sleep(1)
		end
	else
		print(em)
	end
	posix.sleep(1)
end
