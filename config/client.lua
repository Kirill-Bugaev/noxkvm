-- network
local host           = "192.168.1.68"       -- server IP address
local port           = 46855                -- tcp port
                                            -- host and port can be specified directly through cmd args
local reconnto       = 1                    -- timeout (sec) between attempts to connect to server
local connto         = nil                  -- send/receive timeout (sec)
                                            -- nil value blocks indefinitely, this is normal behaviour for client,
                                            -- since it becomes active only when receiving data

-- tls
local ssl                                   -- when tls switched off it is insecure, you should install lua-sec and
pcall(function() ssl = require "ssl" end)   -- create PKI (see https://wiki.archlinux.org/index.php/Easy-RSA)
local tls_params     = {
	mode               = "client",
	protocol           = "any",
	key                = "./certs/noxkvm-client.key",
	certificate        = "./certs/noxkvm-client.crt",
	cafile             = "./certs/ca.crt",
	verify             = "peer",
	options            = {"all", "no_sslv3"}
}
local hsto           = 5                    -- tls handshake timeout (sec)

-- misc
local loopto         = 0                    -- receive loop timeout (sec), if connto set nil then zero value is optimal,
                                            -- otherwise you should set small non-zero value (0.01 eg.), note that
                                            -- big values cause events lost
local forktobg       = false                -- fork to background after start
local debug          = true                 -- debug (verbose) mode

local function factory()
	return host, port, reconnto, connto, ssl, tls_params, hsto, loopto, forktobg, debug
end

return factory
