# FB_FAME_M68000
Freebasic libreria de acceso al emulador FAME de Motorola 68000

Libreria (fichero .BI de FreeBasic) para acceder a la DLL del emulador FAME de Motorola 68000.
Viene con una ROM de ejemplo de un monitor ASM 68k de una placa de desarrollo llamada ZBUG.

La librería FAME se puede encontrar en:
http://www-personal.umich.edu/~williams/archive/m68k-emulators/index.html


Salida en pantalla de la ROM demo en ejecución:

------------------------------------------------------------------

zBug V1.0 for 68000-Based Single Board Computer (press ? for help)


100000>? monitor commands



A   About zBug V1.0

B   Boot from RAM [100000] -> SP [100004] ->PC

C   Clear memory with 0x0000

D   Disassemble machine code to mnemonic

E   Edit memory

F   Fill memory with 0xFFFF

H   Hex dump memory

J   Jump to address

L   Load Motorola s-record

N   New 24-bit pointer

R   Register(user) display

S   Stack(user)'s content

T   Trace instruction

.   Modify user registers, exp .PC .D0 .A0

?   Monitor commands list


100000>

--------------------------------------------------------------------

