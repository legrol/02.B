# 🔧 Comandos para Evaluación - Compilador B

## 1️⃣ Compilación Completa del Proyecto

Limpia todo y recompila el compilador desde cero.

**Genera:** `./B` (compilador), `brt0.o` (runtime), `parser.tab.c`, `lex.yy.c`

```bash
make fclean && make re && make assemble
```

# --------------------------------------------------------------------------------------------

---

## 2️⃣ Ejecutar Baterías de Tests Automáticas

### Tests obligatorios
Ejecuta todos los tests (`tests/*.b`) y compara salida real vs esperada (`.expect`):

```bash
make test
```

### Tests de errores
Verifica que el compilador detecte errores correctamente (`tests_error/*.b`):

```bash
make test-errors
```

### Tests bonus
Ejecuta features bonus del lenguaje:

```bash
make test-bonus
```

### Librería bonus
Tests de funciones externas (`b_print`, `b_ipow`, `b_time`):

```bash
make test-bonus-lib
```

### Compilación masiva
Compila todos los tests de forma masiva (wildcard). `stderr` y `stdout` redirigidos juntos con `2>&1`:

```bash
make eval_compile ARGS='tests/test_*.b' 2>&1
```

# --------------------------------------------------------------------------------------------

---

## 3️⃣ Detección de Memory Leaks con Valgrind

### Básico
Valgrind sobre compilación masiva:

```bash
valgrind make eval_compile ARGS='tests/test_*.b' 2>&1
```

### Detallado (un test)
Muestra todos los leaks y su origen. Útil para debugging de `malloc/free`:

```bash
valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes \
  make eval_compile ARGS='tests/test_add.b' 2>&1
```

### Detallado (todos los tests)
Más lento pero exhaustivo:

```bash
valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes \
  make eval_compile ARGS='tests/test_*.b' 2>&1
```

# --------------------------------------------------------------------------------------------

---

## 4️⃣ Compilación Manual Paso a Paso

Flujo completo: **B → ASM → OBJ → Ejecutable → Run**

```bash
# Paso 1: Compilar código B a ensamblador NASM
./B < tests/test_add.b > out.asm

# Paso 2: Ensamblar ASM a código objeto (.o)
nasm -felf32 out.asm -o out.o

# Paso 3: Enlazar con runtime (brt0.o) para crear ejecutable
ld -m elf_i386 out.o brt0.o -o final

# Paso 4: Ejecutar el programa compilado (imprime resultado)
./final
```


---

## 5️⃣ Compilación Automática con Script

El script `compile_nasm.sh` hace los 3 pasos automáticamente.

**Genera:** `./final` (ejecutable listo)

```bash
./compile_nasm.sh tests/test_add.b
./final
```

# --------------------------------------------------------------------------------------------

---

## 5️⃣ bis Personalización de `make assemble`

Puedes sobrescribir variables del Makefile para controlar el flujo:

### Compilar con input diferente
```bash
make assemble INPUT=tests/test_mul.b    # Compila multiplicación en vez de suma
```

### Cambiar backend (GAS en vez de NASM)
⚠️ **Nota:** El compilador B solo genera sintaxis NASM (Intel). GAS (AT&T) no es compatible, solo usa NASM:

```bash
make assemble INPUT=tests/test_add.b BACKEND=nasm    # ✅ Correcto (por defecto)
# GAS no funcionará porque requeriría traducir la sintaxis Intel → AT&T
```

### Compilar con librería bonus
```bash
make assemble USE_BONUS_LIB=1    # Enlaza con B_bonus/lib/libb.a
```

### Personalización completa
```bash
make assemble INPUT=tests/test_vars.b BACKEND=nasm USE_BONUS_LIB=0
```

### Con tests bonus (floats, switch, etc.)
```bash
make assemble INPUT=tests_bonus/test_float_add.b BACKEND=nasm USE_BONUS_LIB=1
```

# --------------------------------------------------------------------------------------------

---

## 6️⃣ Ver Código Ensamblador Generado (para debugging)

### Opción A: CON helper `print_eax`
Assembly completo (~200 líneas).

**Muestra:** tu código + boilerplate + función `print_eax` completa

```bash
./B < tests/test_add.b
```

### Opción B: SIN helper `print_eax`
Solo tu código (~15 líneas).

La variable `NO_PRINT=1` omite la función `print_eax` del output. Útil para ver **SOLO** el código específico generado por tu test:

```bash
NO_PRINT=1 ./B < tests/test_add.b
NO_PRINT=1 ./B < tests/test_if_true.b
```

# --------------------------------------------------------------------------------------------

---

## 7️⃣ Formas Alternativas de Ejecutar el Compilador (estilo Unix)

### Redirección de stdin
Lee archivo y escribe ASM a `out.asm`:

```bash
./B < tests/test_add.b > out.asm
```

### Pipeline
Código inline directo desde `echo`:

```bash
echo "a = 2 + 2;" | ./B
```

### Concatenar múltiples archivos
⚠️ **Cuidado:** puede dar errores semánticos

```bash
cat tests/*.b | ./B
```

# --------------------------------------------------------------------------------------------

---

## 📋 Resumen Rápido

| Acción | Comando |
|--------|---------|
| **Compilar y ejecutar un test** | `./compile_nasm.sh tests/test_add.b && ./final` |
| **Ver solo tu código ASM** | `NO_PRINT=1 ./B < tests/test_add.b` |
| **Ejecutar todos los tests** | `make test` |
| **Detectar memory leaks** | `valgrind make eval_compile ARGS='tests/test_add.b' 2>&1` |
| **Paso a paso completo** | `./B < file.b > out.asm && nasm -felf32 out.asm -o out.o && ld -m elf_i386 out.o brt0.o -o final && ./final` |
| **Cambiar input** | `make assemble INPUT=tests/test_mul.b` |
| **Solo NASM (GAS no compatible)** | `make assemble BACKEND=nasm` |
| **Con librería bonus** | `make test-bonus USE_BONUS_LIB=1` |
