.model small
.stack 100h
.data
    msg  db "Iveskite simboliu eilute: $"
    msg1 db 13, 10, "Cezario kodu perkoduotas tekstas: $"
    buff db 255, 0, 255 dup(?)
.code
start:
    mov dx, @data
    mov ds, dx  
     
    mov ah, 09h
    mov dx, offset msg
    int 21h
    
    mov ah, 0ah
    mov dx, offset buff
    int 21h
    
    xor cx, cx
    mov cl, [buff + 1]
    mov bx, offset buff + 2
      
compare:
    mov ah, [bx]
    cmp ah, 'A'
    jb skip
    cmp ah, 'z'
    ja skip
    cmp ah, 'Y'
    jb convert1
	cmp ah, '['
	jb convert2
    cmp ah, 'a'
    jb skip
	cmp ah, 'x'
	ja convert2
    
convert1:
    add ah, 02h
    mov [bx], ah

convert2:
	sub ah, 18h
	mov [bx], ah
    
skip:
    inc bx
    loop compare
 
    mov ah, 09h
    mov dx, offset msg1
    int 21h
    
    mov ah, 40h
    mov bx, 1
    xor cx, cx
    mov cl, [buff + 1]
    mov dx, offset buff + 2
    int 21h
    
    mov ax, 4c00h
    int 21h
end start