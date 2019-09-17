CC = gcc

# flags
#DEBUG = -g -Og
CFLAGS = $(INCS) $(DEBUG) -fPIC -Wall -Wextra
LDFLAGS = $(LIBS) -shared $(DEBUG)
