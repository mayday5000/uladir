;-----------------------------------------------------------------------------
;              Creado por Damian Andres Ulanowicz (2003).
;-----------------------------------------------------------------------------

.8086           ;selecciona el procesador
.MODEL TINY     ;modelo TINY para .com

code_seg        segment
	   assume  cs:code_seg, ds:code_seg, es:code_seg, ss:code_seg
	   org     100h

start:  jmp     Program
	   out_str DB 80 DUP (' '),"$"
	   stratr   DB 1eh
	   vid_offs DW 0
	   ncols    DB 0
	   row      DB 0
	   col      DB 0

Buffer       DB  512 DUP (?)
Buff_Size    DW  $-Buffer
Boot_sect    DB  512 DUP (?)
Boot_size    DW  $-Boot_sect
byte_sect    DW  0
reserved     DW  0
root_entr    DW  0
sec_side     DW  1
cyl          DB  0
side         DB  0
sect         DB  1
tot_sides    DB  2
entry        DB  0
entry_lenght DB 32
entries_sect DW  0

Bar          DB   'Attrib Name     Ext   Id          Size Clust   Date     Time   Accessed Checksum'
;                  rhsadv 12345678.123 Del LFN 1123123456 65535 18-10-79 12.12.12 18-10-79
id_lfn       DB 'LFN    '
id_erased    DB 'Erased '
id_del_lfn   DB 'Del LFN'
id_volume    DB 'Volume '
id_directory DB 'Direct.'
id_archive   DB 'Archive'
blank_chksum DB  8 DUP(' ')
contad       DB  0
pause_str    DB 'Press any key to continue...',"$"
car_return   DB 0dh,0ah,"$"


Program:
   clc
   cld
   cli
   sti

   push es
   call DetectVideo
   pop es


show_bar:
   lea di,out_str               ;es:di=out_str
   lea si,Bar                   ;ds:si=Buffer
   mov cx,80                    ;cx=longitud del string
   rep movsb                    ;(es:di)<---(ds:si) ; si++ ; di++
   mov byte ptr [di],"$"
   call OutMsg                  ;Mostrar string en pantalla


init_disk:
   mov ah,00h                  ;Reset disk system
   mov dl,0
   int 13h
   dec tot_sides               ;(el primero se toma como 0)

read_boot_sector:
   mov ah,02h
   mov al,1                    ;#sect a leer
   mov ch,cyl                  ;cyl=0
   mov cl,sect                 ;sect=1
   mov dh,side                 ;side=head=0
   mov dl,0                    ;drive=0
   lea bx,Boot_sect
   int 13h

   lea si,Boot_sect
   mov ax,word ptr[si+11]
   mov byte_sect,ax
   mov ax,word ptr[si+14]
   mov reserved,ax
   mov ax,word ptr[si+17]
   mov root_entr,ax
   mov ax,word ptr[si+24]
   mov sec_side,ax

   mov bl,entry_lenght
   mov ax,byte_sect
;   clc                         ;Clear carry flag (CF=0)
;   div bl
   mov entries_sect,16          ;512/32=16

read_root:
   inc side

next_sect:
   xor ax,ax
   mov al,sect
   cmp ax,sec_side
   je next_side
   inc sect
   jmp read_disk
next_side:
   mov al,tot_sides
   cmp side,al
   je next_cyl
   inc side
   mov sect,1
   jmp read_disk
next_cyl:
   inc cyl
   mov side,0
   mov sect,1
read_disk:
   mov ah,02h
   mov al,1                    ;#sect a leer
   mov ch,cyl                  ;cyl
   mov cl,sect                 ;sect
   mov dh,side                 ;side=head
   mov dl,0                    ;drive
   lea bx,Buffer
   int 13h

   cld                         ;clear Direction Flag (DF)

   mov entry,0
next_entry:
   lea si,Buffer
   mov al,entry_lenght
   mul entry                    ;ax=entry_lenght*entry
   add si,ax                    ;si=offset Buffer+(entry_lenght*entry)
   inc entry                    ;incrementa numero de entrada
   call Put_strings
   call OutMsg                  ;Mostrar string en pantalla

   xor bx,bx
   mov bl,entry
   cmp bx,entries_sect
   je next_sect
   jmp next_entry


;-----------------------------------------------------------------------------
Exit proc near
    mov  ah,4ch                 ;DOS terminate program function
    int  21h                    ;termina el programa
    ret
Exit endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
Put_strings proc near
   call put_name
   call put_attr
   call put_access
   call put_time
   call put_date
   call put_cluster
   call put_size
   call put_checksum
   ret
Put_strings endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
put_name proc near
   cmp byte ptr ds:[si],0       ;si el name es nulo -> fin entries
   je Exit                      ;Termina el programa
   lea di,out_str
   add di,7                     ;posicion correcta en el string
   mov cx,8
   rep movsb
   mov byte ptr es:[di],"."     ;name=name+"."
   inc di
put_ext:
   mov cx,3
   rep movsb                    ;(es:di)<---(ds:si) ; si++ ; di++
ret
put_name endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
put_attr proc near
   lea di,out_str
   mov byte ptr [di]," "
   mov al,byte ptr [si]

   push di
   push si
   push ax
   call put_id
   pop ax
   pop si
   pop di

   mov ah,00000001b           ;Read only mask
   and ah,al
   cmp ah,00000001b           ;R bit = 1 ?
   jne bit_1
   mov byte ptr [di],"R"
bit_1:
   inc di
   mov byte ptr [di]," "
   mov ah,00000010b           ;Hidden mask
   and ah,al
   cmp ah,00000010b           ;H bit = 1 ?
   jne bit_2
   mov byte ptr [di],"H"
bit_2:
   inc di
   mov byte ptr [di]," "
   mov ah,00000100b           ;System mask
   and ah,al
   cmp ah,00000100b           ;S bit = 1 ?
   jne bit_5
   mov byte ptr [di],"S"
bit_5:
   inc di
   mov byte ptr [di]," "
   mov ah,00100000b           ;Archive mask
   and ah,al
   cmp ah,00100000b           ;A bit = 1 ?
   jne bit_4
   mov byte ptr [di],"A"
bit_4:
   inc di
   mov byte ptr [di]," "
   mov ah,00010000b           ;Directory mask
   and ah,al
   cmp ah,00010000b           ;D bit = 1 ?
   jne bit_3
   mov byte ptr [di],"D"
bit_3:
   inc di
   mov byte ptr [di]," "
   mov ah,00001000b           ;Volume mask
   and ah,al
   cmp ah,00001000b           ;V bit = 1 ?
   jne cont
   mov byte ptr [di],"V"
cont:
ret
put_attr endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
put_id proc near
   add di,7
   cmp byte ptr[di],0e5h       ;0e5h -> marca de borrado
   jne test_dir                ;si no tiene la marca testear dir.
   add di,13
   test al,00001111b           ;Es Del LFN ?
   je erased                   ;si no lo es marcar como arch. borrado
del_lfn:
   lea si,id_del_lfn
   mov cx,7
   rep movsb
   jmp end_test
erased:
   lea si,id_erased
   mov cx,7
   rep movsb
   jmp end_test
test_dir:
   add di,13
   test al,00010000b           ;Dir bit = 1 ?
   je test_lfn
   lea si,id_directory
   mov cx,7
   rep movsb
   jmp end_test
test_lfn:
   test al,00001111b           ;Es LFN ?
   je test_vol
   lea si,id_lfn
   mov cx,7
   rep movsb
   jmp end_test
test_vol:
   test al,00001000b           ;Vol bit = 1 ?
   je set_arch
   lea si,id_volume
   mov cx,7
   rep movsb
   jmp end_test
set_arch:
   lea si,id_archive
   mov cx,7
   rep movsb
end_test:
ret
put_id endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
put_access proc near
   add di,58                    ;posicion correcta en el string
   xor ah,ah
   mov al,7
   add si,ax                    ;offset=11+7=18
   call unpack_date
ret
put_access endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
unpack_date proc near
month:
   mov ax,word ptr [si]         ;ax=access date
   mov bx,0000000111100000b     ;bx=month mask
   and bx,ax                    ;bx=month
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   mov ax,bx
   call conv_byte
   mov byte ptr [di],"-"
day:
   inc di                       ;posicion correcta en el string
   mov ax,word ptr [si]         ;ax=access date
   mov bx,0000000000011111b     ;bx=day mask
   and bx,ax                    ;bx=day
   mov ax,bx
   call conv_byte
   mov byte ptr [di],"-"
year:
   inc di                       ;posicion correcta en el string
   mov ax,word ptr [si]         ;ax=access date
   mov bx,1111111000000000b     ;bx=year mask
   and bx,ax                    ;bx=year
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   mov ax,bx
   call conv_byte
ret
unpack_date endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
put_time proc near
   sub di,17                     ;posicion correcta en el string
   xor ah,ah
   mov al,4
   add si,ax                     ;offset=18+4=22
   call unpack_time
ret
put_time endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
unpack_time proc near
hour:
   mov ax,word ptr [si]         ;ax=time
   mov bx,1111100000000000b     ;bx=hour mask
   and bx,ax                    ;bx=hour
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   mov ax,bx
   call conv_byte
   mov byte ptr [di],"-"
minutes:
   inc di                       ;posicion correcta en el string
   mov ax,word ptr [si]         ;ax=time
   mov bx,0000011111100000b     ;bx=minutes mask
   and bx,ax                    ;bx=minutes
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   shr bx,1
   mov ax,bx
   call conv_byte
   mov byte ptr [di],"-"
seconds:
   inc di                       ;posicion correcta en el string
   mov ax,word ptr [si]         ;ax=time
   mov bx,0000000000011111b     ;bx=seconds mask
   and bx,ax                    ;bx=seconds
   mov ax,bx
   call conv_byte
ret
unpack_time endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
put_date proc near
   sub di,17                     ;posicion correcta en el string
   xor ah,ah
   mov al,2
   add si,ax                     ;offset=22+2=24
   call unpack_date
ret
put_date endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
put_cluster proc near
   lea di,out_str
   add di,39                     ;posicion en string
   mov word ptr [di]," "
   inc di
   mov ax,2
   add si,ax                     ;offset=24+2=26
   mov ax,word ptr [si]          ;ax=cluster
   call conv_word
ret
put_cluster endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
put_size proc near
   lea di,out_str
   add di,28                     ;posicion en string
   mov cx,2
bucle:
   mov word ptr [di]," "
   inc di
   loop bucle
   mov ax,2
   add si,ax                     ;offset=26+4=30
   mov ax,word ptr [si]          ;ax=size
   call conv_word
   mov ax,2
   sub si,ax                     ;offset=30-2=28
   mov ax,word ptr [si]          ;ax=size
   call conv_word
ret
put_size endp
;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
put_checksum proc near
   lea di,out_str
write_blank:
   mov ax,72
   add di,ax                    ;posicion correcta para el string
   mov cx,8
   push si
   lea si,blank_chksum
   cld                          ;clear Direction flag (DF=0)
   rep movsb                    ;(es:di)<---(ds:si) ;si++ ;di++
   pop si
do_check:
   mov ax,60
   sub di,ax
   cmp byte ptr[di],"L"         ;el string es 'LFN    ' ?
   je calc_chksum
   cmp byte ptr[di+6],"N"       ;el string es 'Del LFN' ?
   je calc_chksum
   jmp end_chk
calc_chksum:
   mov ax,15
   sub si,ax                    ;offset=28-15=13
   mov al,byte ptr[si]          ;al=checksum
   mov bx,55
   add di,bx                    ;posicion correcta para el string
   call conv_byte
end_chk:
   ret
put_checksum endp
;-----------------------------------------------------------------------------



num_uword proc
;--------------------------------------
; Convert unsigned word to ascii, any base
;
; inputs:  AX    word
;          DS:DI address for string
;          BX    base (must be 2 - 36; no error checking)
;
; outputs: string at DS:DI
;          CX length
;--------------------------------------

			  push   ax
			  push   dx
			  push   si
			  push   es
			  pushf

			  push   ds                   ; ES = DS for stosb
			  pop    es

			  mov    si, di               ; save starting ptr
			  cld
wta_1:
			  xor    dx, dx
			  div    bx
			  xchg   ax, dx
			  add    al, '0'              ; convert to decimal digit
			  cmp    al, '9'
			  jbe    wta_2
			  add    al, 7                ; adjust to alpha for base 11 and above
wta_2:
			  stosb
			  mov    ax, dx
			  or     ax, ax               ; if zero then done
			  jnz    wta_1

			  stosb                       ; terminate with a null

; reverse byte order

			  mov    cx, di
			  sub    cx, si
			  dec    cx

			  push   cx
			  lea    di, [si-1]
			  add    di, cx               ; DI = SI + CX - 1 (last byte)
			  shr    cx, 1                ; count to reverse
			  jz     wta_4                ; done if only 1 byte
wta_3:
			  lodsb                       ; xchg front and back bytes
			  xchg   al, [di]             ;  while moving towards center
			  mov    [si-1], al
			  dec    di
			  loop   wta_3
wta_4:
			  pop    cx

			  popf
			  pop    es
			  pop    si
			  pop    dx
			  pop    ax
			  pop    ds
			  ret

num_uword endp


; -----------------------------------------------------------------------
; -                                                                     -
; - Subroutine to convert a word or byte to hex ASCII                   -
; -                                                                     -
; -   call with AX = binary value                                       -
; -             DI = address to store string                            -
; -                                                                     -
; -----------------------------------------------------------------------

conv_word       proc    near

					push    ax
					mov     al,ah
					call    conv_byte       ; convert upper byte
					pop     ax
					call    conv_byte       ; convert lower byte
					ret                     ; and return
conv_word       endp

conv_byte       proc    near

					push    cx              ; save cx
					sub     ah,ah           ; clear upper byte
					mov     cl,16
					div     cl              ; divide binary data by 16
					call    conv_ascii      ; the quotient becomes the
					stosb                   ; ASCII character
					mov     al,ah
					call    conv_ascii      ; the remainder becomes the
					stosb                   ; second ASCII character
					pop     cx              ; restore cx
					ret
conv_byte       endp

conv_ascii      proc    near            ; convert value 0-0Fh in al
					add     al,'0'          ; into a "hex ascii" character
					cmp     al,'9'
					jle     conv_ascii_2    ; jump if in range 0-9
					add     al,'A'-'9'-1    ; offset it to range A-F
conv_ascii_2:   ret                     ; return ASCII character in al
conv_ascii      endp


DetectVideo proc near
   mov ax,40h                   ;BIOS data area
   mov es,ax
   mov ax,es:[004ah]
   shl ax,1                     ;ax=ax*2
   mov ncols,al
   ret
DetectVideo endp


OutMsg proc near
   push es
   inc contad
   mov ax,40h                   ;BIOS data area
   mov es,ax
   mov ax,es:[0050h]            ;cursor position (ah=fila, al=columna)
   cmp ah,24
   jne write_str
   cmp contad,24
   jne write_str
pause:
   mov ah,09
   lea dx,pause_str
   int 21h
   xor ah,ah
   int 16h                      ;Wait for keypress and read char
   mov ah,09
   lea dx,car_return            ;retorno de carro
   int 21h
   mov contad,1
write_str:
   mov ah,09
   lea dx,out_str
   int 21h
   pop es
   ret
OutMsg endp


code_seg        ends
	   end     start

