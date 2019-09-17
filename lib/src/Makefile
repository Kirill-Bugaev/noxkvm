.POSIX:

include config.mk

SRC = grabber.c flooder.c common.c
OBJ = $(SRC:.c=.o)

all: options grabber flooder
	
options:
	@echo noxkvm build options:
	@echo "CFLAGS  = $(CFLAGS)"
	@echo "LDFLAGS = $(LDFLAGS)"
	@echo "CC      = $(CC)"

.c.o:
	$(CC) $(NOXCFLAGS) -c $<
	
$(OBJ): config.mk

grabber: $(OBJ)
	$(CC) -o grabber.so grabber.o common.o $(LDFLAGS)

flooder: $(OBJ)
	$(CC) -o flooder.so flooder.o common.o $(LDFLAGS)
	
clean:
	rm -f grabber.so flooder.so $(OBJ)

install:
	chmod a-x grabber.so flooder.so
	cp -f grabber.so flooder.so ../

uninstall:
	rm -f ../grabber.so ../flooder.so
