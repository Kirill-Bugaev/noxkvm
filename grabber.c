/* event grabber
 * usage: grabber <event> <blocking (0 or 1)>
 * examples:
 *   $ grabber /dev/input/event5 0  # grab events from event5 device in non-blocking mode
 *   $ grabber /dev/input/event5 1  # same in blocking mode
*/

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <linux/input.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

#define EVENTSIZE  sizeof(struct input_event)
#define EVENTCOUNT 64
#define BUFSIZE    EVENTSIZE * EVENTCOUNT

static int escape(char *, int, char **, int *);
static void freeres();
static void sighandler(int);
static int catchsigs(void);

int fd = -1;
char *buf = NULL, *ebuf = NULL;

#define ARGERR   "1"
#define SIGERR   "2"
#define OPENERR  "3"
#define NAMEERR  "4"
#define EXACCERR "5"
#define MEMERR   "6"
#define CORERR   "7"
#define ESCERR   "8"

void freeres() {
	free(buf);
	free(ebuf);
	if (fd != -1) {
		ioctl(fd, EVIOCGRAB, 0);
		close(fd);
	}
}

// escape new lines and slashes
int escape(char *inp, int isize, char **out, int *osize) {
	int i, j;

	*out = malloc(isize * 2);
	if (!(*out))
		return -1;
	for (i = 0, j = 0; i < isize; i++, j++)
		if (inp[i] == '\n') {
			(*out)[j] = '\\';
			j++;
			(*out)[j] = 'n';
		} else if (inp[i] == '\\') {
			(*out)[j] = '\\';
			j++;
			(*out)[j] = '\\';
		} else
			(*out)[j] = inp[i];
	*osize = j;
	return 0;
}

void sighandler(int signo) {
	if (signo == SIGINT || signo == SIGTERM || signo == SIGHUP ||
		 	signo == SIGPIPE) {
		freeres();
		exit(0);
	}
}

int catchsigs(void) {
	if (signal(SIGINT, sighandler) == SIG_ERR ||
			signal(SIGTERM, sighandler) == SIG_ERR ||
			signal(SIGHUP, sighandler) == SIG_ERR ||
			signal(SIGPIPE, sighandler) == SIG_ERR)
		return -1;
	else
		return 0;
}

int main(int argc, char* argv[]) {
	char devname[256] = "Unknown";
	int rs, ebs, i;
	struct input_event ev1, ev2;

	if (argc < 2) {
		// Event device should be specified
		printf("\\"ARGERR"\n");
		exit(1);
	}

	if (catchsigs() == -1) {
		// Failed to set signal handler
		printf("\\"SIGERR"\n");
		exit(1);
	}

	fd = open(argv[1], O_RDONLY);
	if (fd == -1) {
		// Failed to open event device
		printf("\\"OPENERR"\n");
		printf("%s\n", strerror(errno));
		exit(1);
	}

	if (ioctl(fd, EVIOCGNAME(sizeof(devname)), devname) == -1) {
		// Failed to read device name
		printf("\\"NAMEERR"\n");
		printf("%s\n", strerror(errno));
	} else {
		printf("\\NAME\n");
		printf("%s\n", devname);
	}

	if (ioctl(fd, EVIOCGRAB, 1) == -1) {
		// Failed to get exclusive access
		printf("\\"EXACCERR"\n");
		printf("%s\n", strerror(errno));
	} else
		printf("\\ACCESS\n");
	
	buf = malloc(BUFSIZE);
	if (!buf) {
		// Failed to allocate memory
		printf("\\"MEMERR"\n");
		freeres();
		exit(1);
	}

	// Main loop
	while (1) {
		rs = read(fd, buf, BUFSIZE);
		if (rs < EVENTSIZE) {
			// Corrupt data
			printf("\\"CORERR"\n");
			freeres();
			exit(1);
		}
		// Key code
		ev1 = *(struct input_event *)buf;
		ev2 = *(struct input_event *)(buf + EVENTSIZE);
		if (ev1.value != ' ' && ev2.value == 1 && ev2.type == 1) {
			printf("\\CODE\n");
			printf ("%d\n", ev2.code);
		}
		// Raw data
		if (escape(buf, rs, &ebuf, &ebs) == -1) {
			// Failed to escape data
			printf("\\"ESCERR"\n");
			freeres();
			exit(1);
		}
		printf("\\RAW\n");
		for (i = 0; i < ebs; i++)
			putchar(ebuf[i]);
		putchar('\n');
		free(ebuf);
		ebuf = NULL;
	}
}
