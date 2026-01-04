/* ***************************************************************** */
/* Error test: extrn vs variable collision.
	Declaring `extrn f;` then assigning `f = 1;` should be rejected. */
/* ***************************************************************** */

extrn f;

f = 1;
