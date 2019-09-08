local port               = 46855                -- server tcp port
local connto             = 0.01                 -- connection/send/receive timeout (sec)
local loopto             = 0.5                  -- main loop timeout (sec)
local ssl                                       -- when tls switched off it is insecure, you should install lua-sec and
pcall(function() ssl     = require "ssl" end)   -- create PKI (see https://wiki.archlinux.org/index.php/Easy-RSA)
local hsto               = 5                    -- tls handshake timeout (sec)
local forktobg           = false                -- fork to background after start
local debug              = false                -- debug (verbose) mode

