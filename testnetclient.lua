local client = require "net.client"

local port, connto = require("conf.net")()
local host = "192.168.1.68"
local ssl, tls_params, hsto = require("conf.tls")("client")

local c, em = client(host, port, connto, ssl, tls_params, hsto)
if not c then
	print("Can't connect to server: " .. em)
	return 1
end
print("Connection with server established")
print("Listening...")
while 1 do
	local data
	data, em = c:receive()
	if not data then
		if em == "closed" then
			print("Server closed connection")
			break
		elseif em == "protocol" then
			print("Protocol error")
		end
	else
		if data ~= "" then
			print("Server sent: " .. data)
		else
			print("Server sent nothing (PING?)")
		end
	end
end
