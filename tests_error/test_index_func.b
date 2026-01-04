/* **************************************************************** */
/* Error test: indexing a function symbol.
   Using `f[1]` where `f` is a function should be a semantic error. */
/* **************************************************************** */

function f
    return 0;
endfunction

a = f[1];
