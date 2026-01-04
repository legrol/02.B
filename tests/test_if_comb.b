/* **************************************************************************** */
/* Test: combined conditionals and arithmetic.
   Computes x = 3 + 5*3, y = x+1, sets z when x is true, tests z in a second if,
   chooses w via if-else and computes a = (z + w) * 2. Expect final a = 276.    */
/* **************************************************************************** */

x = 3 + 5 * 3;
y = x + 1;

if (x) then
    z = y * 2;

if (z) then
    w = 100;
else
    w = 200;

a = (z + w) * 2;
