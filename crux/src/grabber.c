#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/ioctl.h>
#include <linux/input.h>
#include <unistd.h>
#include <lua.h>
#include <lauxlib.h>
#include <poll.h>
#include <math.h>

#include "common.h"

#define EVSIZE sizeof(struct input_event)

int luaopen_grabber(lua_State *);
int luaopen_crux_grabber(lua_State *);

static int open_device(lua_State *);
static int get_device_name(lua_State *);
static int set_access(lua_State *, int);
static int enable_exclusive_access(lua_State *);
static int disable_exclusive_access(lua_State *);
static int read_event(lua_State *);
static int close_device(lua_State *);

// API
static const luaL_Reg grabber_lib[] = {
    {"open",      open_device},
    {"getname",   get_device_name},
    {"exclusive", enable_exclusive_access},
    {"release",   disable_exclusive_access},
    {"readevent", read_event},
    {"sleep",     just_sleep},
    {"close",     close_device},
    {NULL,        NULL}
};

int luaopen_grabber(lua_State *L) {
	luaL_newlib(L, grabber_lib);
	return 1;
}

int luaopen_crux_grabber(lua_State *L) {
	luaL_newlib(L, grabber_lib);
	return 1;
}

int open_device(lua_State *L) {
	const char *name = lua_tostring(L, 1);
	int fd, flags;

	fd = open(name, O_RDONLY);
	if (fd == -1)
		return failed(L);

	// set non-blocking access
	flags = fcntl(fd, F_GETFL);
	if (flags == -1)
		return failed(L);
	if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) == -1)
		return failed(L);

	lua_pushinteger(L, fd);
	return 1;
}

int get_device_name(lua_State *L) {
	int fd = lua_tointeger(L, 1);
	char name[256] = "Unknown";

	if (ioctl(fd, EVIOCGNAME(sizeof(name)), name) == -1)
		return failed(L);
	lua_pushstring(L, name);
	return 1;
}

int set_access(lua_State *L, int mode) {
	int fd = lua_tointeger(L, 1);

	if (ioctl(fd, EVIOCGRAB, mode) == -1)
		return failed(L);
	lua_pushboolean(L, 1);
	return 1;
}

int enable_exclusive_access(lua_State *L) {
	return set_access(L, 1);
}

int disable_exclusive_access(lua_State *L) {
	return set_access(L, 0);
}

int read_event(lua_State *L) {
	int fd = lua_tointeger(L, 1);
	struct pollfd pfd;
	int to;  // poll() timeout (seconds)
	if (lua_isnoneornil(L, 2))
		to = -1;
	else
		to = round(lua_tonumber(L, 2) * 1000);
	struct input_event ev;
	int ret, rs;

	pfd.fd = fd;
	pfd.events = POLLIN;
	ret = poll(&pfd, 1, to);
	if (ret == -1)
		return failed(L);
	else if (ret == 0) {
		lua_pushnil(L);
		lua_pushstring(L, "timeout");
		return 2;
	}
	
	rs = read(fd, &ev, EVSIZE);
	if (rs == -1)
		return failed(L);
	else if (rs != EVSIZE) {
		lua_pushnil(L);
		lua_pushstring(L, "corrupt");
		return 2;
	}

	// don't push raw data cause i686 and x86_64 have different size of
	// struct input_event, push parsed data instead
	lua_settop(L, 0);  // clear Lua stack
	lua_createtable(L, 0, 3);
	lua_pushstring(L, "type");
	lua_pushinteger(L, ev.type);
	lua_settable(L, 1);
	lua_pushstring(L, "code");
	lua_pushinteger(L, ev.code);
	lua_settable(L, 1);
	lua_pushstring(L, "value");
	lua_pushinteger(L, ev.value);
	lua_settable(L, 1);
	return 1;
}

int close_device(lua_State *L) {
	int fd = lua_tointeger(L, 1);

	if (close(fd) == -1)
		return failed(L);
	lua_pushboolean(L, 1);
	return 1;
}
