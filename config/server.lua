-- network
local port           = 46855                -- tcp port
local connto         = 0                    -- connection/send/receive timeout (sec)
                                            -- zero or very small value (0.001) is desirable for server,
                                            -- cause it should accept new connections, read from event
                                            -- devices in real-time and not hang on sending/receiving

-- tls
local ssl                                   -- when tls switched off it is insecure, you should install lua-sec and
pcall(function() ssl = require "ssl" end)   -- create PKI (see https://wiki.archlinux.org/index.php/Easy-RSA)
local tls_params     = {
	mode               = "server",
	protocol           = "tlsv1_2",
	key                = "./certs/noxkvm-server.key",
	certificate        = "./certs/noxkvm-server.crt",
	cafile             = "./certs/ca.crt",
	verify             = {"peer", "fail_if_no_peer_cert"},
	options            = "all"
}
local hsto           = 5                    -- tls handshake timeout (sec)

-- events
local autodetect     = true                 -- try to detect keyboard and mouse event handlers
local kb_dev         = "/dev/input/event16" -- you can find apropriate handlers (events) for your
local mouse_dev      = "/dev/input/event5"  -- keyboard and mouse using `cat /proc/bus/input/devices`
local eventto        = 0                    -- events reading timeout

-- key bindings
local binds          = {}
binds["local"]       = {hosts = "root",          keys = 172}  -- root binding should be present anyway,
                                                              -- without it you won't switch devices to use locally
binds["notebook"]    = {hosts = "192.168.1.79",  keys = 155}  -- you can obtain apropriate keycodes using
                                                              -- getkeys.lua program (not xev!)
binds["netbook"]     = {hosts = "192.168.1.110", keys = 217}
binds["everybody"]   = {                                           -- this key binding switch on devices for local
	hosts              = {"root", "192.168.1.79", "192.168.1.110"},  -- and remote hosts simultaneously,
	keys               = {125, 1}                                    -- it will be activated by pressing
}                                                                  -- "Super" (code 125) + "Esc" (code 1)

-- misc
local loopto         = 0.003                -- main loop timeout (sec), if mouse slows make it smaller
local forktobg       = false                -- fork to background after start, you need lua-posix for this
local debug          = false                -- debug (verbose) mode

local function factory()
	return port, connto, ssl, tls_params, hsto, autodetect, kb_dev, mouse_dev, eventto, binds, loopto, forktobg, debug
end

return factory
