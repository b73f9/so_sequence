## Description
This asm program checks whether or not the data given as input is a sequence of the form:
(permutation of M, 0, permutation of M, 0, ..., permutation of M, 0) for some set M \in {1...255}

Example correct sequences: 
(0)
(0, 0)
(1, 2, 0, 1, 2, 0)
(1, 2, 0, 2, 1, 0)

Example incorrect sequences:
()
(1)
(1, 1, 0)
(1, 2, 0, 1, 0)
(1, 2, 0, 1, 3, 0)

Each byte of the data is interpreted as an 8-bit unsigned number. 

## Compiling
``nasm -f elf64 -o sequence.o sequence.asm
ld --fatal-warnings -o sequence sequence.o``