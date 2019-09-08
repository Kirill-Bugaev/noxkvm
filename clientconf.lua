-- noxkvm client configuration

-- load common configuration
dofile("commonconf.lua")

local tls_params  = {
	mode                   = "client",
	protocol               = "any",
	key                    = "./certs/clipnetsync-client.key",
	certificate            = "./certs/clipnetsync-client.crt",
	cafile                 = "./certs/ca.crt",
	verify                 = "peer",
	options                = {"all", "no_sslv3"}
}
local kb_event    = "/dev/input/eventX"
local mouse_event = "/dev/input/eventX"

local function factory()
	return port, connto, loopto, ssl, hsto, tls_params, kb_event, mouse_event, forktobg, debug
end

return factory
