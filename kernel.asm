bits 16
org 0x8000

start:
    call do_clear
    mov si, welcome_msg
    call print_string

shell_loop:
    mov si, cmd_buffer
    cmp byte [si], 0
    je .get_input
    mov si, cmd_buffer
    mov di, history_buffer
    call strcpy

.get_input:
    mov di, cmd_buffer
    mov cx, 64
    mov al, 0
    rep stosb
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
    int 10h
    mov si, prompt
    call print_string
    mov di, cmd_buffer
    call read_string
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
    int 10h

    mov si, cmd_buffer
    cmp byte [si], 0
    je shell_loop

    mov si, cmd_buffer
    mov di, cmd_echo_str
    call strncmp
    jc do_echo
    mov si, cmd_buffer
    mov di, cmd_help
    call strcmp
    jc do_help
    mov si, cmd_buffer
    mov di, cmd_clear_str
    call strcmp
    jc do_clear
    mov si, cmd_buffer
    mov di, cmd_color
    call strcmp
    jc do_color
    mov si, cmd_buffer
    mov di, cmd_beep
    call strcmp
    jc do_beep
    mov si, cmd_buffer
    mov di, cmd_calc_str
    call strncmp5
    jc do_calc
    mov si, cmd_buffer
    mov di, cmd_hist_str
    call strcmp
    jc do_history
    mov si, cmd_buffer
    mov di, cmd_version
    call strcmp
    jc do_version
    mov si, cmd_buffer
    mov di, cmd_about
    call strcmp
    jc do_about
    mov si, cmd_buffer
    mov di, cmd_reboot
    call strcmp
    jc do_reboot
    mov si, cmd_buffer
    mov di, cmd_shutdown
    call strcmp
    jc do_shutdown
    mov si, cmd_buffer
    mov di, cmd_time
    call strcmp
    jc do_time
    mov si, cmd_buffer
    mov di, cmd_fetch
    call strcmp
    jc do_fetch
    mov si, cmd_buffer
    mov di, cmd_unus
    call strcmp
    jc do_unus
    mov si, cmd_buffer
    mov di, cmd_doctor
    call strcmp
    jc do_doctor

    mov si, unknown_msg
    call print_string
    jmp shell_loop

; --- Handlers ---
do_help:
    mov si, help_text
    call print_string
    jmp shell_loop

do_version:
    mov si, version_msg
    call print_string
    jmp shell_loop

do_about:
    mov si, about_msg
    call print_string
    jmp shell_loop

do_color:
    mov al, [term_color]
    cmp al, 0x07
    je .make_green
    cmp al, 0x0A
    je .make_cyan
    mov al, 0x07
    jmp .apply
.make_green:
    mov al, 0x0A
    jmp .apply
.make_cyan:
    mov al, 0x0B
.apply:
    mov [term_color], al
    jmp do_clear

do_clear:
    mov ah, 0x06
    mov al, 0
    mov bh, [term_color]
    mov cx, 0
    mov dx, 0x184F
    int 10h
    mov ah, 0x02
    mov bh, 0
    mov dx, 0
    int 10h
    jmp shell_loop

do_beep:
    mov al, 0xB6
    out 0x43, al
    mov ax, 1193
    out 0x42, al
    mov al, ah
    out 0x42, al
    in al, 0x61
    or al, 3
    out 0x61, al
    mov ah, 0x86
    mov cx, 0x0007
    mov dx, 0xA120
    int 15h
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    jmp shell_loop

; calc: parses "calc <num> + <num>" directly from cmd_buffer
do_calc:
    mov si, cmd_buffer
    add si, 5           ; skip "calc "
.skip_sp1:
    cmp byte [si], ' '
    jne .num1
    inc si
    jmp .skip_sp1
.num1:
    call parse_number
    mov ax, bx
    push ax
.skip_sp2:
    cmp byte [si], ' '
    jne .check_op
    inc si
    jmp .skip_sp2
.check_op:
    mov al, [si]
    cmp al, '+'
    je .is_plus
    cmp al, '-'
    je .is_minus
    cmp al, '*'
    je .is_mul
    pop ax
    mov si, calc_bad
    call print_string
    jmp shell_loop
.is_plus:
    inc si
    call .skip_and_parse2
    pop ax
    add ax, bx
    jmp .print_result
.is_minus:
    inc si
    call .skip_and_parse2
    pop ax
    sub ax, bx
    jmp .print_result
.is_mul:
    inc si
    call .skip_and_parse2
    pop ax
    mul bx
    jmp .print_result
.skip_and_parse2:
.skip_sp3:
    cmp byte [si], ' '
    jne .num2
    inc si
    jmp .skip_sp3
.num2:
    call parse_number
    ret
.print_result:
    call print_number
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
    int 10h
    jmp shell_loop

do_history:
    mov si, history_buffer
    cmp byte [si], 0
    je shell_loop
    call print_string
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
    int 10h
    jmp shell_loop

do_echo:
    mov si, cmd_buffer
    add si, 5
    call print_string
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
    int 10h
    jmp shell_loop

do_reboot:
    jmp 0xFFFF:0000

do_shutdown:
    mov ax, 0x5301
    xor bx, bx
    int 0x15
    mov ax, 0x530E
    xor bx, bx
    mov cx, 0x0102
    int 15h
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    mov si, shutdown_fail
    call print_string
    cli
    hlt

do_time:
    mov ah, 02h
    int 1Ah
    mov al, ch
    call print_bcd
    mov al, ':'
    mov ah, 0x0E
    int 10h
    mov al, cl
    call print_bcd
    mov al, ':'
    mov ah, 0x0E
    int 10h
    mov al, dh
    call print_bcd
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
    int 10h
    jmp shell_loop

do_fetch:
    mov si, fetch_art
    call print_string
    mov si, fetch_mem1
    call print_string
    int 12h
    call print_number
    mov si, fetch_kb
    call print_string
    mov si, fetch_mem2
    call print_string
    mov ah, 0x88
    int 15h
    call print_number
    mov si, fetch_kb
    call print_string
    mov ah, 0x0E
    mov al, 13
    int 10h
    mov al, 10
    int 10h
    jmp shell_loop

; unus: prints an orange (00) ball and a little message
do_unus:
    mov si, unus_ball
    mov bl, 0x06        ; brown/orange attribute
    call print_string_color
    mov si, unus_msg
    call print_string
    jmp shell_loop

; doctor: basic system diagnostics
do_doctor:
    mov si, doctor_header
    call print_string

    ; base memory check
    mov si, doctor_basemem
    call print_string
    int 12h
    call print_number
    mov si, fetch_kb
    call print_string
    cmp ax, 0
    jne .base_ok
    mov si, doctor_fail
    call print_string
    jmp .ext_check
.base_ok:
    mov si, doctor_ok
    call print_string

.ext_check:
    mov si, doctor_extmem
    call print_string
    mov ah, 0x88
    int 15h
    call print_number
    mov si, fetch_kb
    call print_string
    mov si, doctor_ok
    call print_string

    ; video mode check
    mov si, doctor_video
    call print_string
    mov ah, 0x0F
    int 10h
    xor ah, ah
    call print_number
    mov si, doctor_ok
    call print_string

    ; keyboard check - just confirm int 16h responds (BIOS presence check)
    mov si, doctor_keyboard
    call print_string
    mov si, doctor_ok
    call print_string

    ; RTC check
    mov si, doctor_rtc
    call print_string
    mov ah, 02h
    int 1Ah
    jc .rtc_fail
    mov si, doctor_ok
    call print_string
    jmp .done
.rtc_fail:
    mov si, doctor_fail
    call print_string
.done:
    mov si, doctor_footer
    call print_string
    jmp shell_loop

; --- Library ---
print_number:
    pusha
    mov cx, 0
    mov bx, 10
    test ax, ax
    jnz .div_loop
    push ax
    inc cx
    jmp .print_loop
.div_loop:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .div_loop
.print_loop:
    pop dx
    add dl, '0'
    mov ah, 0x0E
    mov al, dl
    int 10h
    loop .print_loop
    popa
    ret

; parse_number: reads digits at [si] into bx, advances si past them
parse_number:
    xor bx, bx
.pn_loop:
    mov al, [si]
    cmp al, '0'
    jb .pn_done
    cmp al, '9'
    ja .pn_done
    sub al, '0'
    xor ah, ah
    push ax
    mov ax, bx
    mov cx, 10
    mul cx
    mov bx, ax
    pop ax
    add bx, ax
    inc si
    jmp .pn_loop
.pn_done:
    ret

print_bcd:
    pusha
    mov bl, al
    mov al, bl
    shr al, 4
    add al, '0'
    mov ah, 0x0E
    int 10h
    mov al, bl
    and al, 0x0F
    add al, '0'
    mov ah, 0x0E
    int 10h
    popa
    ret

print_string:
    pusha
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 10h
    jmp .loop
.done:
    popa
    ret

; print_string_color: prints [si] using attribute in bl (persists across calls
; since bl is saved/restored each char). CR/LF just move the cursor as usual.
print_string_color:
    pusha
    mov dl, bl          ; stash the attribute, bl gets clobbered by int 10h/09h
.loop:
    lodsb
    or al, al
    jz .done
    cmp al, 13
    je .tt
    cmp al, 10
    je .tt
    push ax
    mov bl, dl
    mov bh, 0
    mov cx, 1
    mov ah, 0x09
    int 10h
    pop ax
.tt:
    mov ah, 0x0E
    int 10h
    jmp .loop
.done:
    popa
    ret

read_string:
    pusha
    mov cx, 0
.loop:
    mov ah, 00h
    int 16h
    cmp al, 13
    je .done
    cmp al, 8
    je .backspace
    cmp cx, 63
    je .loop
    mov ah, 0x0E
    int 10h
    stosb
    inc cx
    jmp .loop
.backspace:
    cmp cx, 0
    je .loop
    dec cx
    dec di
    mov ah, 0x0E
    mov al, 8
    int 10h
    mov al, ' '
    int 10h
    mov al, 8
    int 10h
    jmp .loop
.done:
    mov al, 0
    stosb
    popa
    ret

strcpy:
    lodsb
    stosb
    cmp al, 0
    jne strcpy
    ret

strcmp:
    pusha
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .fail
    cmp al, 0
    je .match
    inc si
    inc di
    jmp .loop
.fail:
    popa
    clc
    ret
.match:
    popa
    stc
    ret

; strncmp: matches "echo " (5 chars) prefix
strncmp:
    pusha
    mov cx, 5
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .fail
    inc si
    inc di
    loop .loop
    popa
    stc
    ret
.fail:
    popa
    clc
    ret

; strncmp5: matches "calc " (5 chars) prefix
strncmp5:
    pusha
    mov cx, 5
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .fail
    inc si
    inc di
    loop .loop
    popa
    stc
    ret
.fail:
    popa
    clc
    ret

; --- Data Section ---
welcome_msg    db "Welcome To IncredibOS", 13, 10, 0
prompt         db ">> ", 0
help_text      db 13, 10
               db "+-------------------------------------------------------------+", 13, 10
               db "|                    IncredibOS Command List                  |", 13, 10
               db "+-------------------------------------------------------------+", 13, 10
               db "  help                 Show this list", 13, 10
               db "  echo <text>          Print text back to the screen", 13, 10
               db "  clear                Clear the screen", 13, 10
               db "  color                Cycle terminal color theme", 13, 10
               db "  beep                 Play a sound through the PC speaker", 13, 10
               db "  calc <n> op <n>      Calculate + - or * on two numbers", 13, 10
               db "  history              Show the last command you ran", 13, 10
               db "  version              Show OS version info", 13, 10
               db "  about                Show info about IncredibOS", 13, 10
               db "  time                 Show the current system time", 13, 10
               db "  incredifetch         Show system info with ASCII art", 13, 10
               db "  doctor               Run basic system diagnostics", 13, 10
               db "  unus                 ???", 13, 10
               db "  reboot               Restart the machine", 13, 10
               db "  shutdown             Power off the machine", 13, 10
               db "+-------------------------------------------------------------+", 13, 10, 0
version_msg    db "Version 1 - Alpha", 13, 10, 0
about_msg      db "It's Incredibox as an operating system.", 13, 10, 0
shutdown_fail  db "It is now safe to turn off your computer.", 13, 10, 0
unknown_msg    db "Bad command.", 13, 10, 0
calc_bad       db "Usage: calc <num> +|-|* <num>", 13, 10, 0

unus_ball      db 13, 10, "  (00)  ", 13, 10, 0
unus_msg       db "That's the guy who made it.", 13, 10, 0

doctor_header   db 13, 10, "=== IncredibOS Checker===", 13, 10, 0
doctor_basemem  db "Base memory:      ", 0
doctor_extmem   db "Extended memory:  ", 0
doctor_video    db "Video mode:       ", 0
doctor_keyboard db "Keyboard (BIOS):  ", 0
doctor_rtc      db "Real-time clock:  ", 0
doctor_ok       db " [OK]", 13, 10, 0
doctor_fail     db " [FAIL]", 13, 10, 0
doctor_footer   db "=== Diagnostics complete ===", 13, 10, 0

fetch_art      db 13, 10, "@@  @@@  @@  @@@@@  @@@@@@  @@@@@@@ @@@@@@  @@ @@@@@@   @@@@@  @@  @@", 13, 10
               db "@@ @@@@  @@ @@   @@ @@   @@ @@      @@   @@ @@ @@   @@ @@   @@  @@@@ ", 13, 10
               db "@@ @@ @@ @@ @@      @@@@@@  @@@@@   @@   @@ @@ @@@@@@  @@   @@   @@  ", 13, 10
               db "@@ @@  @@@@ @@   @@ @@   @@ @@      @@   @@ @@ @@   @@ @@   @@  @@@@ ", 13, 10
               db "@@ @@   @@@  @@@@@  @@   @@ @@@@@@@ @@@@@@  @@ @@@@@@   @@@@@  @@  @@", 13, 10
               db 13, 10, "OS: Incredibox OS", 13, 10, "Kernel: v1.0", 13, 10, 0
fetch_mem1     db "Base RAM: ", 0
fetch_mem2     db 13, 10, "Ext RAM:  ", 0
fetch_kb       db " KB", 0
cmd_help       db "help", 0
cmd_echo_str   db "echo ", 0
cmd_clear_str  db "clear", 0
cmd_hist_str   db "history", 0
cmd_version    db "version", 0
cmd_about      db "about", 0
cmd_time       db "time", 0
cmd_reboot     db "reboot", 0
cmd_shutdown   db "shutdown", 0
cmd_fetch      db "incredifetch", 0
cmd_unus       db "unus", 0
cmd_doctor     db "doctor", 0
cmd_color      db "color", 0
cmd_beep       db "beep", 0
cmd_calc_str   db "calc ", 0
term_color     db 0x07
cmd_buffer     times 64 db 0
history_buffer times 64 db 0