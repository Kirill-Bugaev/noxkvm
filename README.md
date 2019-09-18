# noxkvm (Not X11 KVM)

Low-level KVM for Linux. It lets you share keyboard and mouse between multiple computers.
It is written on Lua and C, and it is hardcore because reads and writes events directly
from and to Linux input devices.

Program doesn't work out of box:
* [lua-socket][] should be installed on every system where program will be used
* low-level libs should be built for your architecture
* server key bindings should be configured appropriate way
* superuser (root) privileges require for work with input devices

Then start `noxkvm-server` on machine which devices you want to share, and `noxkvm-client`
on other machines which will get access to shared devices. Configuration files for both
server and client placed in `./config` directory.

Enjoy.

## building libs
Go to `./lib/src` directory and run
```shell
$ make
$ make install
```
`grabber.so` and `flooder.so` should appear in `./lib` directory. If not something goes
wrong. Maybe Lua isn't installed on your system. If you are sure that your system is OK
write [issue][New issues].

## noxkvm-server
### key bindings
It is most complicated part of configuring so I try to describe it in details,
but it is really easy, believe me. First of all find `getkeys.lua` script in program
root directory. You will use it (not xev!) to determine key codes. Start script
```
$ sudo ./getkeys.lua
```
It tries to detect your keyboard input device automatically. If it is wrong, you should
run
```shell
$ cat /proc/bus/input/devices
```
Find your keyboard device. On my system it is
```shell
I: Bus=0003 Vendor=046d Product=4023 Version=0111
N: Name="Logitech Wireless Keyboard PID:4023"
P: Phys=usb-0000:00:16.0-4/input1:1
S: Sysfs=/devices/pci0000:00/0000:00:16.0/usb11/11-4/11-4:1.1/0003:046D:C534.0002/0003:046D:4023.0003/input/input32
U: Uniq=4023-00-00-00-00
H: Handlers=sysrq kbd event16 leds
B: PROP=0
B: EV=12001f
B: KEY=300ff 0 0 483ffff17aff32d bfd4444600000000 1 130ff38b17c007 ffff7bfad941dfff febeffdfffefffff fffffffffffffffe
B: REL=1040
B: ABS=100000000
B: MSC=10
B: LED=1f
```
We are interesting in `Handlers=sysrq kbd event16 leds` entry, more precisely in `event16`.
It is keyboard handler (on your system it is possibly different) which we will use as input
device. Run `getkeys.lua` again specifying found handler
```shell
$ sudo ./getkeys.lua /dev/input/event16
```
Now you can press keys and get corresponding key codes. If you are planing to use key
combinations, ALT+1 eg., for switching keyboard and mouse devices between computers,
you should first press ALT key and get its key code (56), then press 1 and get its
key code(2), but not (!) both keys simultaneously.

Now you can specify gotten key codes in `./config/server.lua`
```lua
local binds          = {}
binds["local"]       = {hosts = "root",          keys = {56, 2}}
binds["notebook"]    = {hosts = "192.168.1.79",  keys = {56, 3}}
```
In example above I bound ALT+1 to local machine and ALT+2 to my notebook. Note that
entry with single `hosts = "root"` should always be present in config, without it
you couldn't switch keyboard and mouse devices to local machine back.

That is. You can specify as many key bindings as you want. You can even specify same keys
for multiple machines (hosts). In this case keyboard and mouse will work on all hosts
simultaneously. Just funny feature :).

One more thing. If `getkeys.lua` has detected your keyboard and mouse wrong automatically,
specify device handlers found with `cat /proc/bus/input/devices` in `./config/server.lua`
and switch off autodetect
```lua
local autodetect     = false
local kb_dev         = "/dev/input/event16"
local mouse_dev      = "/dev/input/event5"
```
But you should be aware that device handlers can be changed after reboot. In this case
you need specify new handlers and restart server.
### other configuring
See comments in `./config/server.lua`.
### starting
```shell
$ sudo ./noxkvm-server
```

## noxkvm-client
### uinput
Client uses `uinput` kernel module to create virtual device. So it should be installed and
loaded (on my system it is loading on demand). To check it use
```shell
$ modinfo uinput
```
and
```shell
$ lsmod | grep uinput
```
### configuring
See comments in `./config/client.lua`.
### starting
```shell
$ sudo ./noxkvm-client
```
or
```shell
$ sudo ./noxkvm-client 192.168.0.1:46855
```

## TLS
Install [lua-sec][], create PKI (see ArchWiki [Easy-RSA][]) and move keys and certificates to
`./certs` directory (there are mine by default, replace it).

## issues
If you have any, [welcome][New issues].

[lua-socket]: https://www.archlinux.org/packages/community/x86_64/lua-socket/
[lua-sec]: https://www.archlinux.org/packages/community/x86_64/lua-sec/
[Easy-RSA]: https://wiki.archlinux.org/index.php/Easy-RSA
[New issues]: https://github.com/Kirill-Bugaev/noxkvm/issues/new
