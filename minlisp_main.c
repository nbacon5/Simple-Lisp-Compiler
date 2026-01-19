#include <stdio.h>
#include <stdlib.h>

extern int minlisp_main();

int input_v = 20;
char *S0 = "%d";
char *S1 = "%d ";


int minlisp_input() {
	return rand() % input_v;
}


int
main(int argc, char ** argv) {
	time_t t;
	 srand((unsigned) time(&t));
	 if (argc > 1) input_v = atoi(argv[1]);
	 if (input_v <= 0) input_v = 20;

	minlisp_main();
}
