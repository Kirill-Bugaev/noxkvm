#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <linux/uinput.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>
#include <poll.h>
#include <math.h>

#include "common.h"

#define EVSIZE sizeof(struct input_event)

int luaopen_flooder(lua_State *);
int luaopen_crux_flooder(lua_State *);

static int create_device(lua_State *);
static int write_event(lua_State *);
static int destroy_device(lua_State *);

// API
static const luaL_Reg flooder_lib[] = {
    {"create",     create_device},
    {"writeevent", write_event},
    {"sleep",      just_sleep},
    {"destroy",    destroy_device},
    {NULL,         NULL}
};

int luaopen_flooder(lua_State *L) {
	luaL_newlib(L, flooder_lib);
	return 1;
}

int luaopen_lib_flooder(lua_State *L) {
	luaL_newlib(L, flooder_lib);
	return 1;
}

int create_device(lua_State *L) {
	struct uinput_setup usetup;
	int i;

	int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
	if (fd == -1)
		return failed(L);

	// register key events
	if (ioctl(fd, UI_SET_EVBIT, EV_KEY) == -1) {
		close(fd);
		return failed(L);
	}
	for (i = 0; i < KEY_CNT; i++)
		if (ioctl(fd, UI_SET_KEYBIT, i) == -1) {
			close(fd);
			return failed(L);
	}

	// register relative events
	if (ioctl(fd, UI_SET_EVBIT, EV_REL) == -1) {
		close(fd);
		return failed(L);
	}
	for (i = 0; i < REL_CNT; i++)
		if (ioctl(fd, UI_SET_RELBIT, i) == -1) {
			close(fd);
			return failed(L);
	}

	// describe virtual device
	memset(&usetup, 0, sizeof(usetup));
	usetup.id.bustype = BUS_USB;
	usetup.id.vendor = 0x6e6f;
	usetup.id.product = 0x7876;
	strcpy(usetup.name, "noxkvm virtual device");

	// create device
	if (ioctl(fd, UI_DEV_SETUP, &usetup) == -1 ||
			ioctl(fd, UI_DEV_CREATE) == -1) {
		close(fd);
		return failed(L);
	}

	// userspace needs time to detect new device, so wait
	sleep(1);
	
	lua_pushinteger(L, fd);
	return 1;
}

int write_event(lua_State *L) {
	int fd = lua_tointeger(L, 1);

	// get event entries
	struct input_event ev;
	lua_pushstring(L, "type");
	lua_gettable(L, 2);
	ev.type = lua_tointeger(L, lua_gettop(L));
	lua_pushstring(L, "code");
	lua_gettable(L, 2);
	ev.code = lua_tointeger(L, lua_gettop(L));
	lua_pushstring(L, "value");
	lua_gettable(L, 2);
	ev.value = lua_tointeger(L, lua_gettop(L));
	// timestamp values below are ignored
	ev.time.tv_sec = 0;
	ev.time.tv_usec = 0;

	if (write(fd, &ev, EVSIZE) == -1)
		return failed(L);

	lua_pushboolean(L, 1);
	return 1;
}

int destroy_device(lua_State *L) {
	int fd = lua_tointeger(L, 1);

	if (ioctl(fd, UI_DEV_DESTROY) == -1)
		return failed(L);
	if (close(fd) == -1)
		return failed(L);

	lua_pushboolean(L, 1);
	return 1;
}
