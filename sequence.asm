buffer_size equ 2048

section .bss
  ; In practice, all initialized to zero, by the os
  buffer                 resb buffer_size
  expected_pattern       resb 256
  expected_pattern_list  resb 256

section .text
    global _start

_start:
    ; Check if argc == 2
    pop rax                 ; rax = argc
    cmp rax, 2
    jne exit_err            ; if rax != 2: exit_err

    ; get argv[1] into rdi    
    pop rdi                 ; rdi = argv[0]
    pop rdi                 ; rdi = argv[1]

    ; Open the file
    mov eax, 2              ; modifying the eax zeroes the rest of rax
    xor esi, esi
    syscall                 ; rax = sys_open(rdi, O_RDONLY)
    
    ; Initialize the registers
    mov rdi, rax            ; file descriptor
    mov rbx, 1              ; last character
    mov r13b, 1             ; whether the program is in the learning mode or not
    xor r14, r14            ; how many characters remaining in the current permutation

    loop:
        ; Read data from the file
        xor eax, eax
        mov rsi, buffer  
        mov rdx, buffer_size
        syscall              ; rax = sys_read(fd, buffer, bufsize), rdi initialized earlier

        ; Handle errors, end of file and avialable data
        cmp rax, 0
        jl exit_err         ; if(rax < 0) jmp exit_err
        jne do_parse        ; if(rax != 0) jmp do_parse
        ; if end of file, check whether or not the last character was a zero
        cmp bl, 0
        je exit_ok
        jmp exit_err        ; if(rax == 0) {jmp bl==0 ? exit_ok : exit_err} 
        
        do_parse:
            add rax, rsi ; rax = size(avialable_data) +  buffer
            loop_2:
                ; Get the current character to parse
                mov bl, [rsi]           ; rbx/bl = [rsi] / i-th position in the buffer

                ; If we're not in the learning mode, jump to the correct place
                cmp r13b, 0
                je not_learning

                ; If current character isn't a zero, handle that
                cmp bl, 0
                jne learning_not_zero

                ; Current character is a zero, that means no more learning
                ; Disable learning mode, and init the data structures
                ; From there, the program will jump to next_character
                xor r13, r13
                jmp init_after_learning

                ; Still learning, got a character that's not a zero
                learning_not_zero:
                    ; If we've already encountered this character, jmp exit_err
                    cmp byte [expected_pattern+rbx], 1
                    je exit_err
                    ; Otherwise, note the encounter and jmp next_character
                    mov byte [expected_pattern+rbx], 1
                    jmp next_char

                ; We already know the allowed element set
                ; Now, it's time to check whether or not it's the only thing
                ; the program will encounter in the input
                not_learning:
                    ; If the current character is not a zero, handle that
                    cmp bl, 0
                    jne not_learning_not_zero
                    ; If the current character is zero
                    ; Check whether or not all elements were represented
                    cmp r14, 0
                    jne exit_err
                    ; If they were, check the next group
                    jmp init_matching
                    
                    not_learning_not_zero:
                        ; If this particular character isn't still alive, jmp exit_err
                        cmp byte [expected_pattern+rbx], 0
                        je exit_err
                        ; otherwise, mark it as visited and decrease the counter
                        mov byte [expected_pattern+rbx], 0
                        dec r14

                next_char:
                    inc rsi
                    cmp rsi, rax
                    jne loop_2
            jmp loop

exit_ok:
    xor edi, edi
    jmp exit
exit_err:
    mov edi, 1
exit:
    mov eax, 60    ; sys_exit(rdi/edi)
    syscall

init_after_learning:
    xor edx, edx
    mov rcx, expected_pattern_list   ; OPT can be ecx
    loop_4:
        ; If expected_pattern[i] == 0: jmp after_append
        cmp byte [expected_pattern+rdx], 0
        je loop_4_after_append
        ; Append the ith element to the list
        mov [rcx], dl
        inc rcx
        loop_4_after_append:
        ; Increment the adress and the counter
        inc dl
        ; If counter == 256, exit the loop
        cmp dl, 0
        jne loop_4
    mov [rcx], dl
    
init_matching:
    mov rcx, expected_pattern_list   ; OPT can be ecx
    loop_3:
        ; if(expected_pattern_list[i]==0) jmp next_char
        cmp byte [rcx], 0
        je next_char

        ; expected_pattern[expected_pattern_list[i]]=1
        movzx edx, byte [rcx]
        mov byte [expected_pattern+rdx], 1
        ; increment the address and the element count
        inc r14
        inc rcx
        jmp loop_3
    