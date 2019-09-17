# noxkvm

Low-level KVM for Linux. It lets you share keyboard and mouse between multiple computers.
It is written on Lua and C, and it is hardcore because reads and writes events directly
from and to Linux input devices.

[lua-socket][] should be installed on every system where program will be used. Superuser (root)
privileges require for work with input devices. You start noxkvm-server on machine which devices
you want to share, and noxkvm-client on other machines which will get access to shared devices.
Configuration files for both server and client placed in `./config` directory.

Enjoy.

## noxkvm-server
### starting
```shell
$ sudo noxkvm-server
```
### configuring
See comments in `./config/server.lua`.

## noxkvm-client
### starting
```shell
$ sudo noxkvm-client
```
or
```shell
$ sudo noxkvm-client 192.168.0.1:46855
```
### configuring
See comments in `./config/client.lua`.

## TLS
Install [lua-sec][], create PKI (see ArchWiki [Easy-RSA][]) and move keys and certificates to
`./certs` directory (there are mine by default, replace it).

## issues
If you have any [welcome][New issues].

[lua-socket]: https://www.archlinux.org/packages/community/x86_64/lua-socket/
[lua-sec]: https://www.archlinux.org/packages/community/x86_64/lua-sec/
[Easy-RSA]: https://wiki.archlinux.org/index.php/Easy-RSA
[New issues]: https://github.com/Kirill-Bugaev/clipnetsync/issues/new
