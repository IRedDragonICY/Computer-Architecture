name "Uji Kompetensi 2 - Oleh Mohammad Farid Hendianto 2200018401"

; this macro prints a char in AL and advances
; the current cursor position:
PUTC    MACRO   char
        PUSH    AX
        MOV     AL, char
        MOV     AH, 0Eh
        INT     10h     
        POP     AX
ENDM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

precision=30   ; max digits after the dot.

org 100h

jmp start

; define variables:
msg0 db "Fitur:",0Dh,0Ah
     db "+ Bisa menggunakan bilangan bulat positif maupun negatif:",0Dh,0Ah
     db "+ Hasil bisa berupa floating number:",0Dh,0Ah
     db "Pembatasan:",0Dh,0Ah
     db "- Nilai pada var A,B,C,D,E tidak bisa mengandung floating number",0Dh,0Ah,0Dh,0Ah
     db "Y = (A x B + C) / ( D x E)",0Dh,0Ah,'$'
msg1 db  0dh,0ah , 'Maka nilai Y =  $' 
msg2 db  0dh,0ah ,'Arigatou Nee OwO ~ ', 0Dh,0Ah, '$'

; Varible on Registers
A dw ?
B dw ?
C dw ?
D dw ?
E dw ?

string_input_A   DB 'Masukkan A : $'
string_input_B   DB 13,10,'Masukkan B : $'
string_input_C   DB 13,10,'Masukkan C : $'
string_input_D   DB 13,10,'Masukkan D : $'
string_input_E   DB 13,10,'Masukkan E : $'
string_res       DB 13,10,'Y=$'
sring_undefined  DB 'Undefined$'
; Temporary Variables;
TEMP dw ?
TEMP2 dw ?
ten             dw      10      ; used as multiplier.
four            dw      4       ; used as divider.
make_minus      db      ?       ; used as a flag in procedures.


start:

        mov dx, offset msg0
        mov ah, 9
        int 21h

        ; store A number:
        lea dx, string_input_A
        mov ah, 09h    ; output string at ds:dx
        int 21h  

        ; get the multi-digit signed number
        ; from the keyboard, and store
        ; the result in cx register:
        call scan_num
        mov A,cx
        
        ; store B number:
        lea dx, string_input_B
        mov ah, 09h    
        int 21h  
        call scan_num
        mov B,cx

        ; store C number:
        lea dx, string_input_C
        mov ah, 09h 
        int 21h  
        call scan_num
        mov C,cx

        ; store D number:
        lea dx, string_input_D
        mov ah, 09h   
        int 21h  
        call scan_num
        mov D,cx

        ; store E number:
        lea dx, string_input_E
        mov ah, 09h  
        int 21h  
        call scan_num
        mov E,cx


        ; Result step

        mov ah,09h
        mov dx,OFFSET string_res
        int 21h
        ; print (
        mov ah, 02h
        mov dl, '('
        int 21h

        ; print var A
        mov ax,A
        call print_num

        ; print x
        mov ah, 02h
        mov dl, 'x'
        int 21h

        ; print var B
        mov ax,B
        call print_num

        ; print +
        mov ah, 02h
        mov dl, '+'
        int 21h

        ; print var C
        mov ax,C
        call print_num

        ; print )
        mov ah, 02h
        mov dl, ')'
        int 21h

        ; print /
        mov ah, 02h
        mov dl, '/'
        int 21h

        ; print (
        mov ah, 02h
        mov dl, '('
        int 21h

        ; print var D
        mov ax,D
        call print_num

        ; print x
        mov ah, 02h
        mov dl, 'x'
        int 21h

        ; print var E
        mov ax,E
        call print_num  

        ; print )
        mov ah, 02h
        mov dl, ')'
        int 21h


        ; new line:
        putc 0Dh
        putc 0Ah


        lea dx, msg1
        mov ah, 09h      ; output string at ds:dx
        int 21h  


        ; A x B
        mov ax, A
        imul B ; (dx ax) = ax * A.
        mov TEMP,ax
        ; dx is ignored (calc works with tiny numbers only).

        ; + C
        mov ax, TEMP
        add ax, C
        mov TEMP,ax 

        ; D x E
        mov ax, D
        imul E
        mov TEMP2,ax
        cmp ax, 0
        je undefined

        ; Y = (A x B + C)/(D x C)
        ; dx is ignored (calc works with tiny integer numbers only).

        mov     ax, TEMP
        xor     dx, dx

        ; check the sign, make dx:ax negative if ax is negative:
        cmp     ax, 0
        jns     not_signed
        not     dx
not_signed:
        mov     bx, TEMP2   ; divider is in bx.

        ; 'A' is in dx:ax.
        ; 'B' is in bx.

        idiv    bx      ; ax = dx:ax / bx       (dx - remainder).

        ; 'A/B' is in ax.
        ; remainder is in dx.

        push    dx      ; store the remainder.


        pop     dx

        ; print 'A/B' as float:
        ; ax - whole part
        ; dx - remainder
        ; bx - divider
        call    print_float

        jmp    exit


        call print_float    ; print ax value.
        jmp exit
undefined:
        ; print "Undefined" if E is zero:
        lea dx, sring_undefined
        mov ah, 09h
        int 21h

exit:
        ; output of a string at ds:dx
        lea dx, msg2
        mov ah, 09h
        int 21h  

        ; wait for any key...
        mov ah, 0
        int 16h

        ret  ; return back to os.

;***************************************************************
; gets the multi-digit SIGNED number from the keyboard,
; and stores the result in CX register:
SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:
        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 0Dh  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:
        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:
        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
        SCAN_NUM        ENDP



;***************************************************************
; prints number in ax and it's fraction in dx.
; used to print remainder of 'div/idiv bx'.
; ax - whole part.
; dx - remainder.
; bx - the divider that was used to get the remainder from divident.
print_float     proc    near
        push    cx
        push    dx

        ; because the remainder takes the sign of divident
        ; its sign should be inverted when divider is negative
        ; (-) / (-) = (+)
        ; (+) / (-) = (-)
        cmp     bx, 0
        jns     div_not_signed
        neg     dx              ; make remainder positive.
div_not_signed:
        ; print_num procedure does not print the '-'
        ; when the whole part is '0' (even if the remainder is
        ; negative) this code fixes it:
        cmp     ax, 0
        jne     checked         ; ax<>0
        cmp     dx, 0
        jns     checked         ; ax=0 and dx>=0
        push    dx
        mov     dl, '-'
        call    write_char      ; print '-'
        pop     dx
checked:
        ; print whole part:
        call    print_num

        ; if remainder=0, then no need to print it:
        cmp     dx, 0
        je      done

        push    dx
        ; print dot after the number:
        mov     dl, '.'
        call    write_char
        pop     dx

        ; print digits after the dot:
        mov     cx, precision
        call    print_fraction
done:
        pop     dx
        pop     cx
        ret
print_float     endp

;***************************************************************
; prints dx as fraction of division by bx.
; dx - remainder.
; bx - divider.
; cx - maximum number of digits after the dot.
print_fraction  proc    near
        push    ax
        push    dx
next_fraction:
        ; check if all digits are already printed:
        cmp     cx, 0
        jz      end_rem
        dec     cx      ; decrease digit counter.

        ; when remainder is '0' no need to continue:
        cmp     dx, 0
        je      end_rem

        mov     ax, dx
        xor     dx, dx
        cmp     ax, 0
        jns     not_sig1
        not     dx
not_sig1:
        imul    ten             ; dx:ax = ax * 10
        idiv    bx              ; ax = dx:ax / bx   (dx - remainder)
        push    dx              ; store remainder.
        mov     dx, ax
        cmp     dx, 0
        jns     not_sig2
        neg     dx
not_sig2:
        add     dl, 30h         ; convert to ascii code.
        call    write_char      ; print dl.
        pop     dx

        jmp     next_fraction
end_rem:
        pop     dx
        pop     ax
        ret
print_fraction  endp

;***************************************************************
; this procedure prints number in ax
; used with print_numx to print "0" and sign.
; this procedure also stores the original ax,
; that is modified by print_numx.
print_num       proc    near
        push    dx
        push    ax

        cmp     ax, 0
        jnz     not_zero

        mov     dl, '0'
        call    write_char
        jmp     printed

not_zero:
        ; the check sign of ax,
        ; make absolute if it's negative:
        cmp     ax, 0
        jns     positive
        neg     ax

        mov     dl, '-'
        call    write_char
positive:
        call    print_numx
printed:
        pop     ax
        pop     dx
        ret
print_num       endp

;***************************************************************
; prints out a number in ax (not just a single digit)
; allowed values from 1 to 65535 (ffff)
; (result of /10000 should be the left digit or "0").
; modifies ax (after the procedure ax=0)
print_numx      proc    near
        push    bx
        push    cx
        push    dx
        ; flag to prevent printing zeros before number:
        mov     cx, 1
        mov     bx, 10000       ; 2710h - divider.
        ; check if ax is zero, if zero go to end_show
        cmp     ax, 0
        jz      end_show
begin_print:
        ; check divider (if zero go to end_show):
        cmp     bx,0
        jz      end_show
        ; avoid printing zeros before number:
        cmp     cx, 0
        je      calc
        ; if ax<bx then result of div will be zero:
        cmp     ax, bx
        jb      skip
calc:
        xor     cx, cx  ; set flag.
        xor     dx, dx
        div     bx      ; ax = dx:ax / bx   (dx=remainder).
        ; print last digit
        ; ah is always zero, so it's ignored
        push    dx
        mov     dl, al
        add     dl, 30h    ; convert to ascii code.
        call    write_char
        pop     dx
        mov     ax, dx  ; get remainder from last div.
skip:
        ; calculate bx=bx/10
        push    ax
        xor     dx, dx
        mov     ax, bx
        div     ten     ; ax = dx:ax / 10   (dx=remainder).
        mov     bx, ax
        pop     ax
        jmp     begin_print
end_show:
        pop     dx
        pop     cx
        pop     bx
        ret
print_numx      endp
;***************************************************************
; reads char from the keyboard into al
; (modifies ax!!!)
read_char       proc    near
        mov     ah, 01h
        int     21h
        ret
read_char       endp
;***************************************************************  
; prints out single char (ascii code should be in dl)
write_char      proc    near
        push    ax
        mov     ah, 02h
        int     21h
        pop     ax
        ret
write_char      endp
;***************************************************************