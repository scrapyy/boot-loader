;; 'makefloppy.flp mbr.asm' will produce floppy.flp usable as a
;;; bootable (legacy boot only) floppy drive image for a virtual machine

bits 16
org 0x7c00

;;;
;;; real-mode 16 bits code
;;; the execution starts at the very first byte emitted by nasm
;;; state: CS:IP = 00 : 7C00 and DL = boot drive id
;;;


; start with disabling external interrupts as they might not be serviceable
; given the CPU configuration set by our code
cli

; make sure we're using know (&good) segments values
xor     ax,     ax          ; ax = 0
mov     ds,     ax
mov     es,     ax
mov     ss,     ax

; set fs such that [fs : X] points to 0xb8000 + X to allow
; access to the text-mode video memory
mov     ax,     0xb800
mov     fs,     ax

; output Hi on the top-left corner of the screen

mov ah,2
mov al,20 ; sectors to read count
mov ch,0 ; cyllinder
mov cl,2 ; the sector loadingmov dh,0 ; head
mov dh,0
mov bx,7e00h ; where to load
int 13h ; load sectors







jmp lets_get_magical




;;;
;;; TODO: add more code and/or change the above code
;;; while keeping the 0x55&0xAA signature and times directives in place
;;;


; fill-in the rest of the available sector space with NOP instructions
times (446 - ($-$$)) nop    ; nop = a harmless 'no operation' instruction

; fill-in the partition table with zeroes - this disk has no partitions
times ((512-2) - ($-$$)) db 0

; place the 'valid boot drive' signature
db 0x55, 0xAA

FLAT_DESCRIPTOR_CODE64      equ 0x002F9A000000FFFF  ; Code: Execute/Read
FLAT_DESCRIPTOR_DATA64      equ 0x00CF92000000FFFF  ; Data: Read/Write
FLAT_DESCRIPTOR_CODE32      equ 0x00CF9A000000FFFF  ; Code: Execute/Read
FLAT_DESCRIPTOR_DATA32      equ 0x00CF92000000FFFF  ; Data: Read/Write
FLAT_DESCRIPTOR_CODE16      equ 0x00009B000000FFFF  ;Code:Execute/Read, accessed
FLAT_DESCRIPTOR_DATA16      equ 0x000093000000FFFF  ; Data: Read/Write, accessed

structuraLgdt:
.limit          dw
(tabelDescriptori.tableEnd-tabelDescriptori.tableStart) - 1
        .Base           dd  tabelDescriptori; a se inlocui 0 cu
adresacorespunzatoare eticheteitabelDescriptori



tabelDescriptori:
    .tableStart:
        .dscZero        dq 0
        .dscCode32      dq FLAT_DESCRIPTOR_CODE32
        .dscData32      dq FLAT_DESCRIPTOR_DATA32
        .dscCode16      dq FLAT_DESCRIPTOR_CODE16
        .dscData16      dq FLAT_DESCRIPTOR_DATA16
    .tableEnd:


%define    SEL_NULL     (tabelDescriptori.dscZero - tabelDescriptori)
%define    SEL_CODE32   (tabelDescriptori.dscCode32 - tabelDescriptori)
%define    SEL_DATA32   (tabelDescriptori.dscData32 - tabelDescriptori)
%define    SEL_CODE16   (tabelDescriptori.dscCode16 - tabelDescriptori)
%define    SEL_DATA16   (tabelDescriptori.dscData16 - tabelDescriptori)

translation_table equ 4*1024

idt_real:
    dw 0x3ff        ; 256 entries, 4b each = 1K
    dd 0            ; Real Mode IVT @ 0x0000

savcr0:
    dd 0
table times 9 db '0'

cr dw 0
score dw 0
pos dw 0

l db 'This is the worst ten fast fingers ever bla ',0,0
msg db 'Type the words as fast as you can: ',0
time db 0
h dw 0
t dw 0
q dw 0
c db 10
sir times 10 db 0


;;;
;;; any code past this point is not loaded automatically
;;;


lets_get_magical:

mov si,msg

start1:
mov al,[si]
mov ah,10
mov cx,1
mov bh,0
int 10h

mov ah,3
int 10h

add dl,1
mov ah,2
int 10h

add si,1
cmp byte [si],0
jne start1
mov al,13
call judge_char
mov al,13
call judge_char

mov si,word l
mov [cr],si


mov di,l
mov [t],word 0
r:
mov [q],di
start:
mov al,[di]
mov ah,10
mov cx,1
mov bh,0
int 10h

mov ah,3
int 10h

add dl,1
mov ah,2
int 10h

add di,1
cmp byte [di],' '
jne start

mov ah,3
int 10h

add dh,1
mov dl,0
mov ah,2
int 10h

mov [cr],di
mov di,0
mov si,[q]

editor:
mov ah,0
int 16h
cmp al,13
jne o
jmp y
o:
cmp al,[si]
jne g
add [t],word 1
g:
mov [q],si
mov ah,10
mov cx,1
mov bh,0
int 10h

mov ah,3
int 10h

add dl,1
mov ah,2
int 10h

mov si,[q]
add si,1
jmp editor

y:
mov ah,3
int 10h

add dh,1
mov dl,0
mov ah,2
int 10h



mov di,[cr]
add di,1
cmp [di],word 0
jne r

mov ax,[t]
mov si,word sir

s:

div byte [c]
mov bx,ax
add ah,48
mov [si],ah
mov ax,0
mov al,bl
add si,1
cmp al,0
jne s

sub si,1
bg:
mov al,[si]
mov ah,10
mov cx,1
mov bh,0
int 10h

mov ah,3
int 10h

add dl,1
mov ah,2
int 10h

sub si,1

mov ax,word sir
cmp si,ax
jge bg







    cli

    lgdt [structuraLgdt]

    mov eax,cr0
    or eax,1
    mov cr0,eax ; set lsb of eax


    jmp SEL_CODE32:here


    here: ; set code segment

    bits 32 ; switch in 32


    mov ax,SEL_DATA32
    mov ss,ax
    mov ds,ax
    mov es,ax ; set data segments

    mov ebx,0
    mov edx,translation_table


    fill:
        mov eax,87h
        mov ecx,ebx

        shl ecx,22
        add eax,ecx

        mov [edx],eax
        add ebx,1


        add edx,4
        cmp ebx,1024

    jne fill




    mov eax,cr4
    or eax,010000b
    and eax,0xFFFFFFDF
    mov cr4,eax

    mov  eax,translation_table
    mov cr3,eax


    mov eax,cr0
    or eax,0x80000000
    mov cr0,eax

    ;mov [4100],dword 87h ; make second page point to location
inmemory from 0 - 4 mb

    ;mov [0xb8000],dword 'H0I0' ; put message in addres 4 mb +
b8000,because of the pagination it should write to b8000

hlt

judge_char:

cmp al,13 ; check if its enter


jne not_enter

call center ; here if its enter
ret

not_enter:

cmp al,8

jne not_backspace ; check if its backspace

call backspace ; here if its backspace
ret

not_backspace:

cmp al,-1

jne not_left_arrow

call left_arrow
ret

not_left_arrow:
call char ; here if its any other char
ret



ten_fast_fingers:
ret

left_arrow:
mov ah,3
mov bh,0
int 10h ; get current position of cursor

cmp dl,0

jne not__0

cmp dh,0
je gata_0
sub dh,1
mov dl,78
jmp gata_0 ; if col is 0, go to prev line on last col

not__0:

sub dl,1 ; go to prev position

gata_0:

mov ah,2
mov bh,0
int 10h ; set cursor
ret

center:
mov ah,3
int 10h ; get current position of cursor

add dh,1 ; go to the next line
mov dl,0

mov ah,2
mov bh,0
int 10h ; set new cursor
ret

backspace:
mov ah,3
int 10h ; get current position of cursor
mov al,32
mov bl,3
mov cx,1
mov bh,0
mov ah,10
int 10h ; eliminate char from there

mov ah,3
mov bh,0
int 10h ; get current position of cursor

cmp dl,0

jne not_0

cmp dh,3
je gata
sub dh,1
mov dl,78
jmp gata ; if col is 0, go to prev line on last col

not_0:

sub dl,1 ; go to prev position

gata:

mov ah,2
mov bh,0
int 10h ; set cursor

ret

char:
mov bl,3
mov cx,1
mov bh,0
mov ah,10
int 10h ; print char

mov ah,3
int 10h ; get cursor

add dl,1 ; go to next position

cmp dl,79 ; if it out of range, go to next line on col 0

jne no

add dh,1
mov dl,0
no:

mov ah,2
mov bh,0
int 10h
ret
