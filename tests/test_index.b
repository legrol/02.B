/* ************************************************************** */
/* Test: indexed access using scaled indexing (4-byte elements).
	Stores address of b0 into `a` and reads a[1] -> should be 20. */
/* ************************************************************** */

b0 = 10;
b1 = 20;
b2 = 30;

/* ************************************************************* */
/* store address of b0 into variable a using address-of operator */
/* ************************************************************* */

a = &b0;
x = a[1];
