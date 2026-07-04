bits 16
org 0x0000

start:
    mov [boot_drive], dl   ; BIOS passes boot drive in dl at startup - save it now
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE

    ; Load stage 2 (kernel) from floppy into 0x0000:0x8000
    ; Boot sector is sector 1 (CHS), so we start reading from sector 2.
    mov ax, 0x0000
    mov es, ax
    mov bx, 0x8000       ; es:bx = 0000:8000 destination

    mov ah, 0x02         ; BIOS read sectors function
    mov al, 20           ; number of sectors to read (20*512 = 10KB, plenty; raise if kernel grows)
    mov ch, 0            ; cylinder 0
    mov cl, 2            ; start at sector 2 (sector 1 = boot sector)
    mov dh, 0            ; head 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; jump to stage 2
    jmp 0x0000:0x8000

disk_error:
    mov si, err_msg
.loop:
    lodsb
    or al, al
    jz .hang
    mov ah, 0x0E
    int 0x10
    jmp .loop
.hang:
    cli
    hlt

boot_drive db 0
err_msg    db "Disk read error", 0

times 510-($-$$) db 0
dw 0xAA55