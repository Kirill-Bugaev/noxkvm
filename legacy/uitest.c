#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/uinput.h>
#include <string.h>

#define EVENTSIZE  sizeof(struct input_event)
#define EVENTCOUNT 64
#define BUFSIZE    EVENTSIZE * EVENTCOUNT

void emit(int fd, int type, int code, int val)
{
   struct input_event ie;

   ie.type = type;
   ie.code = code;
   ie.value = val;
   /* timestamp values below are ignored */
   ie.time.tv_sec = 0;
   ie.time.tv_usec = 0;

   write(fd, &ie, sizeof(ie));
}

int main(int argc, char *argv[]) {
	int ifd, rs;
	char *buf;
	struct input_event ev;

	if (argc < 2) {
		printf("Input device not specified\n");
		exit(1);
	}

	// -- setup uinput --
	struct uinput_setup usetup;

	int ofd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
	if (ofd == -1) {
		printf("Can't open /dev/uinput");
		exit(1);
	}

	ioctl(ofd, UI_SET_EVBIT, EV_KEY);
//	ioctl(ofd, UI_SET_KEYBIT, KEY_SPACE);
	for (int i = 0; i < KEY_CNT; i++)
		if (ioctl(ofd, UI_SET_KEYBIT, i) == -1)
			printf("Could not enable a key event %d", i);

	memset(&usetup, 0, sizeof(usetup));
	usetup.id.bustype = BUS_USB;
	usetup.id.vendor = 0x1234; /* sample vendor */
	usetup.id.product = 0x5678; /* sample product */
	strcpy(usetup.name, "Example device");

	ioctl(ofd, UI_DEV_SETUP, &usetup);
	ioctl(ofd, UI_DEV_CREATE);

	sleep(1);

   emit(ofd, EV_KEY, KEY_J, 1);
   emit(ofd, EV_SYN, SYN_REPORT, 0);
   emit(ofd, EV_KEY, KEY_J, 0);
   emit(ofd, EV_SYN, SYN_REPORT, 0);
	// ------------------

	if ((ifd = open(argv[1], O_RDONLY)) == -1) {
		printf("Can't open device %s\n", argv[1]);
		exit(1);
	}

	buf = malloc(BUFSIZE);

	printf("EVENTSIZE = %d\n", EVENTSIZE);
	for (int j = 0; j < 2; j++) {
		rs = read(ifd, buf, BUFSIZE);
		printf("Read %d bytes\n", rs);
/*
		ev = *(struct input_event *)buf;
		printf("--event1--\n");
		printf("type = %hu\n", ev.type);
		printf("code = %hu\n", ev.code);
		printf("val = %d\n", ev.value);
		ev = *(struct input_event *)(buf + EVENTSIZE);
		printf("--event2--\n");
		printf("type = %hu\n", ev.type);
		printf("code = %hu\n", ev.code);
		printf("val = %d\n", ev.value);
		ev = *(struct input_event *)(buf + EVENTSIZE * 2);
		printf("--event3--\n");
		printf("type = %hu\n", ev.type);
		printf("code = %hu\n", ev.code);
		printf("val = %d\n", ev.value);
*/
/*
		ev = *(struct input_event *)(buf + EVENTSIZE);
		ev.type = 1;
		ev.code = 23;
		if ( j == 0 )
			ev.value = 1;
		else
			ev.value = 0;
		ev.time.tv_sec = 0;
		ev.time.tv_usec = 0;
*/
		struct input_event *evbuf;
		evbuf = (struct input_event *)(buf + EVENTSIZE);
		evbuf->code = 23;
		write(ofd, buf, rs);
//		emit(ofd, EV_SYN, SYN_REPORT, 0);
	}

	close(ifd);
	ioctl(ofd, UI_DEV_DESTROY);
	close(ofd);
}
