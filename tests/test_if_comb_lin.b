/* **************************************************************************** */
/* Test: combined conditionals and arithmetic.
   Computes x = 3 + 5*3, y = x+1, sets z when x is true, chooses w via if-else,
   and computes a = (z + w) * 2. Expect final a = 476.                          */
/* **************************************************************************** */

x = 3 + 5 * 3;
y = x + 1;

if (x) then 
	z = y * 2;

if (0) then 
	w = 100; 
else 
	w = 200;
	
a = (z + w) * 2;
