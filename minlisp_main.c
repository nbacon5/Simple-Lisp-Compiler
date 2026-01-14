#include <stdio.h>
#include <stdlib.h>

extern int minlisp_main();

int input_v = 20;
char *S0 = "%d";
char *S1 = "%d ";


int minlisp_input() {
	//No idea why I can't get schanf to work in this context
	//or when called directly from my generated code.  I have
	//replaced it with a mock input using the rand function
	//so I can get different inputs
	//scanf("%d",&d);
	return rand() % input_v;
}


int
main(int argc, char ** argv) {
	time_t t;
	// setup for the input.   By default generates a random sequence of numbers from 0..19.   Can change this to be a different number using command line.
	 srand((unsigned) time(&t));
	 if (argc > 1) input_v = atoi(argv[1]);
	 if (input_v <= 0) input_v = 20;

	minlisp_main();
}
