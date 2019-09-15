#include <math.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <lua.h>
#include <lauxlib.h>

#include "common.h"

int failed(lua_State *L) {
		lua_pushnil(L);
		lua_pushstring(L, strerror(errno));
		return 2;
}

int just_sleep(lua_State *L) {
	useconds_t t = round(lua_tonumber(L, 1) * 1000000);  // time to sleep (sec)

	if (usleep(t) == -1)
		return failed(L);
	lua_pushboolean(L, 1);
	return 1;
}
