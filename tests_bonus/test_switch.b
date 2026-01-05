/* ****************************************************** */
/* test_switch.b — basic switch/case/default + goto/break */
/* ****************************************************** */

a = 0;
switch (3) {
  case 1:
    a = 10;
  case 3:
    a = 4;
    break;
  default:
    a = 1;
}
return a;
