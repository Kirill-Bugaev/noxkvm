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
local kb_event    = "/dev/input/event5"  -- you can find apropriate handlers (events) for your
local mouse_event = "/dev/input/eventX"  -- keyboard and mouse using `cat /proc/bus/input/devices`

-- define keyboard key bindings for switch between hosts
-- syntax: hosts_key_binds[key_code] = "ip_address"
--     or  hosts_key_binds[key_code] = {"ip_address1", "ip_address2", ...}
-- in last case same event's data will be sent different clients simultaneously
local hosts_key_binds = {}
hosts_key_binds[142]  = "localhost"
hosts_key_binds[227]  = "192.168.4.119"
-- you should use `grabber` program which comes together with this app, not `xev`, to determine key code
-- Example (assume that 'event5' is your keyboard handler):
--   $ grabber /dev/input/event5
--   \NAME
--   AT Translated Set 2 keyboard
-- Press any key ('1' for example) and you will see
--   \CODE
--   2
--   \RAW
--   eu]9eu]9eu]9
--   1\RAW
--   eu]reu]reu]r
-- Program shows key code and raw output from event5 device after you press key.
-- Number placed after line '\CODE' is key code ('2' in this example)

local function factory()
	return port, connto, loopto, ssl, hsto, tls_params, kb_event, mouse_event, hosts_key_binds, forktobg, debug
end

return factory
