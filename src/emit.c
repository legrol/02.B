/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   emit.c                                             :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: rdel-olm <rdel-olm@student.42malaga.com>   +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2025/12/30 00:50:02 by rdel-olm          #+#    #+#             */
/*   Updated: 2026/01/04 23:33:39 by rdel-olm         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../includes/emit.h"

static int label_id = 0;

/****************************************************************************** */
/*
 * emit.c — simple emission buffer and helpers
 *
 * Responsibilities:
 *  - Provide `emit()` for accumulating formatted assembly text into an in-
 *    memory buffer (used by Bison semantic actions to perform
 *    syntax-directed translation).
 *  - Support capture semantics via `emit_begin_capture()` / `emit_end_capture()`
 *    so code fragments (e.g., function bodies) can be emitted later or
 *    reordered to avoid fall-through.
 *  - Maintain a small label stack used by control-flow semantic actions
 *    (`push_label`, `pop_label`, `peek_label`).
 *  - `flush_emit()` writes the accumulated buffer to stdout when appropriate.
 *  - `new_label()` generates unique local labels for use in jumps.
 *
 * Notes:
 *  - The buffer is a simple realloc-backed string; this keeps the emitter
 *    lightweight and suitable for a code-golfing compiler.
 */
/****************************************************************************** */

/* *************************************************** */
/* accumulation buffer for emitted code (text section) */
/* *************************************************** */
static char *buf = NULL;
static size_t len = 0;

/* ********************************************************************* */
/* capture stack to support buffering emissions for statement reordering */
/* ********************************************************************* */
static size_t capture_stack[64];
static int capture_top = 0;

/* *************************************** */
/* label stack for control-flow generation */
/* *************************************** */
static char *label_stack[256];
static int label_top = 0;

void push_label(char *lbl)
{
    if (label_top < 256)
        label_stack[label_top++] = lbl;
}

char *pop_label(void)
{
    if (label_top > 0)
        return label_stack[--label_top];
    return NULL;
}

char *peek_label(void)
{
    if (label_top > 0)
        return label_stack[label_top - 1];
    return NULL;
}

void emit(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);

    char tmp[512];
    int n = vsnprintf(tmp, sizeof(tmp), fmt, ap);
    va_end(ap);

    char *nbuf = realloc(buf, len + n + 1);
    if (!nbuf)
        return;
    buf = nbuf;

    memcpy(buf + len, tmp, n);
    len += n;
    buf[len] = 0;
}

void emit_begin_capture(void)
{
    if (capture_top < 64)
        capture_stack[capture_top++] = len;
}

char *emit_end_capture(void)
{
    if (capture_top <= 0)
        return NULL;
    size_t start = capture_stack[--capture_top];
    size_t n = len - start;
    char *s = malloc(n + 1);
    if (!s)
        return NULL;
    if (n)
        memcpy(s, buf + start, n);
    s[n] = '\0';

    /* ******************************** */
    /* shrink main buffer back to start */
    /* ******************************** */
    char *nbuf = realloc(buf, start + 1);
    if (nbuf || start == 0)
    {
        buf = nbuf;
        len = start;
        if (buf)
            buf[len] = 0;
    }
    return s;
}

void flush_emit(void)
{
    if (buf)
        fwrite(buf, 1, len, stdout);
}

char *new_label(void)
{
    char lbl[32];
    snprintf(lbl, sizeof(lbl), ".L%d", label_id++);
    return strdup(lbl);
}