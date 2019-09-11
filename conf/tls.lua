--[[
      tls common configuration
]]

local ssl                                       -- when tls switched off it is insecure, you should install lua-sec and
pcall(function() ssl     = require "ssl" end)   -- create PKI (see https://wiki.archlinux.org/index.php/Easy-RSA)
local server_tls_params  = {
	mode                   = "server",
	protocol               = "tlsv1_2",
	key                    = "./certs/noxkvm-server.key",
	certificate            = "./certs/noxkvm-server.crt",
	cafile                 = "./certs/ca.crt",
	verify                 = {"peer", "fail_if_no_peer_cert"},
	options                = "all"
}
local client_tls_params  = {
	mode                   = "client",
	protocol               = "any",
	key                    = "./certs/noxkvm-client.key",
	certificate            = "./certs/noxkvm-client.crt",
	cafile                 = "./certs/ca.crt",
	verify                 = "peer",
	options                = {"all", "no_sslv3"}
}
local hsto               = 5                    -- tls handshake timeout (sec)

local function factory(mode)
	local tls_params
	if mode == "server" then
		tls_params = server_tls_params
	elseif mode == "client" then
		tls_params = client_tls_params
	end
	return ssl, tls_params, hsto
end

return factory
