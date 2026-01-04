/* **************************************************************************** */
/* Error test: label/variable collision.
	Declaring a variable `a` then a label `a:` should produce a semantic error. */
/* **************************************************************************** */

a = 1;
a:
