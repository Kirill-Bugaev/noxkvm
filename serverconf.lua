-- noxkvm server configuration

-- load common configuration
dofile("commonconf.lua")

local tls_params  = {
	mode            = "server",
	protocol        = "tlsv1_2",
	key             = "./certs/clipnetsync-server.key",
	certificate     = "./certs/clipnetsync-server.crt",
	cafile          = "./certs/ca.crt",
	verify          = {"peer", "fail_if_no_peer_cert"},
	options         = "all"
}
local kb_event    = "/dev/input/event5"  -- you can find apropriate events for keyboard and mouse
local mouse_event = "/dev/input/eventX"  -- using `cat /proc/bus/input/devices`

-- define keyboard key bindings for switch between hosts
-- syntax: host_binds["ip_address"] = key_code
-- you should use `keycode` program which comes together with this app, not `xev`
local host_binds            = {}
host_binds["localhost"]     = 142
host_binds["192.168.4.119"] = 227

local function factory()
	return port, connto, loopto, ssl, hsto, tls_params, kb_event, mouse_event, host_binds, forktobg, debug
end

return factory
