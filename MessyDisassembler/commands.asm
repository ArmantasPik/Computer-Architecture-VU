writeSreg:
	push ax bx dx cx
	
	xor ax, ax ;si procedura isprintina sreg bufferi
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov cl, 03h
	int 21h
	
	pop cx dx bx ax
	ret



changeSregName:
	push ax bx dx cx ;di laiko norimo vardo offset buferio
	
	xor cx, cx
	xor ax, ax
	mov bx, offset sreg
	mov cl, 03h
	sloopName:
		mov al, [di]
		mov [bx], al
		inc di
		inc bx
		loop sloopName

	pop cx dx bx ax
	ret



analyzeSregMUL1: ;iskviecia offseto programa, sutvarko skaiciavimo registrus, paraso atitinkamus baitus ir atliekama komanda
	push dx
	call position
	sub bx, 02h
	mov dl, [bx]
	add ax, 03h
	sub cx, 02h
	mov si, 0003h
	call writeBytes			
	xor dx, dx
	mov dx, offset opMUL
	call writeOp
	add bx, 02h
	pop dx
	ret
	
analyzeSregMULbyte1: ;atlieka ta pati tik papildomai yra 1 baito poslinkis
	push dx
	call position
	sub bx, 02h
	mov dl, [bx]
	add ax, 04h
	sub cx, 03h
	mov si, 0004h
	call writeBytes			
	xor dx, dx
	mov dx, offset opMUL
	call writeOp
	add bx, 02h
	pop dx
	ret
	
analyzeSregMULbyte2: ;atlieka ta pati tik papildomai yra 2 baitu poslinkis
	push dx
	call position
	sub bx, 02h
	mov dl, [bx]
	add ax, 05h
	sub cx, 04h
	mov si, 0005h
	call writeBytes			
	xor dx, dx
	mov dx, offset opMUL
	call writeOp
	add bx, 02h
	pop dx
	ret



analyzeSregMOD00:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je s0rm000
	cmp dl, 01h
	je s0rm001
	cmp dl, 02h
	je s0rm010
	cmp dl, 03h
	je s0rm011
	cmp dl, 04h
	je s0rm100
	cmp dl, 05h
	je s0rm101
	cmp dl, 06h
	je s0rm110
	cmp dl, 07h
	jne startingpoint
	jmp s0rm111
	startingpoint:
	
	s0rm000: ;sreg pakeiciam pries analyzeSregMOD komanda
		call analyzeSregMUL1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rm000
		call writeAddress
		pop dx
		
		ret
	s0rm001:
		call analyzeSregMUL1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rm001
		call writeAddress
		pop dx
		
		ret
	s0rm010:
		call analyzeSregMUL1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rm010
		call writeAddress
		pop dx
		
		ret
	s0rm011:
		call analyzeSregMUL1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rm011
		call writeAddress
		pop dx
		
		ret
	s0rm100:
		call analyzeSregMUL1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rm100
		call writeAddress
		pop dx
		
		ret
	s0rm101:
		call analyzeSregMUL1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rm101
		call writeAddress
		pop dx
		
		ret
	s0rm110:
		push dx
		call position
		sub bx, 02h
		mov dl, [bx]
		add ax, 05h
		sub cx, 04h
		mov si, 0005h
		call writeBytes			
		xor dx, dx
		mov dx, offset opMUL
		call writeOp
		mov dx, offset sreg 
		call writeSreg
		
		add bx, 04h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		inc bx	
		pop dx
		
		ret
	s0rm111:
		call analyzeSregMUL1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rm111
		call writeAddress
		pop dx
		
		ret
		
		
		
analyzeSregMOD01:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je s1rm000
	cmp dl, 01h
	je s1rm001
	cmp dl, 02h
	je s1rm010
	cmp dl, 03h
	je s1rm011
	cmp dl, 04h
	jne sabel8 
	jmp s1rm100
	sabel8:
	cmp dl, 05h
	jne sabel0
	jmp s1rm101
	sabel0:
	cmp dl, 06h
	jne s1abel1
	jmp s1rm110
	s1abel1:
	
	jmp s1rm111
	
	s1rm000:
		call analyzeSregMULbyte1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp000
		call writeAddress
		pop dx
		
		inc bx
		call convertByte
		call writeSeek
		call writeBracket
		
		ret
	s1rm001:
		call analyzeSregMULbyte1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp001
		call writeAddress
		pop dx
		
		inc bx
		call convertByte
		call writeSeek
		call writeBracket
		
		ret
	s1rm010:
		call analyzeSregMULbyte1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp010
		call writeAddress
		pop dx
		
		inc bx
		call convertByte
		call writeSeek
		call writeBracket
		
		ret
	s1rm011:
		call analyzeSregMULbyte1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp011
		call writeAddress
		pop dx
		
		inc bx
		call convertByte
		call writeSeek
		call writeBracket
		
		ret
	s1rm100:
		call analyzeSregMULbyte1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp100
		call writeAddress
		pop dx
		
		inc bx
		call convertByte
		call writeSeek
		call writeBracket
		
		ret
	s1rm101:
		call analyzeSregMULbyte1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp101
		call writeAddress
		pop dx
		
		inc bx
		call convertByte
		call writeSeek
		call writeBracket
		
		ret
	s1rm110:
		call analyzeSregMULbyte1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp110
		call writeAddress
		pop dx
		
		inc bx
		call convertByte
		call writeSeek
		call writeBracket
		
		ret
	s1rm111:
		call analyzeSregMULbyte1
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp111
		call writeAddress
		pop dx
		
		inc bx
		call convertByte
		call writeSeek
		call writeBracket
		
		ret
		
		
		
analyzeSregMOD10:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je s2rm000
	cmp dl, 01h
	je s2rm001
	cmp dl, 02h
	je s2rm010
	cmp dl, 03h
	jne slabel0
	jmp s2rm011
	slabel0:
	cmp dl, 04h
	jne slabel1
	jmp s2rm100
	slabel1:
	cmp dl, 05h
	jne slabel2
	jmp s2rm101
	slabel2:
	cmp dl, 06h
	jne slabel3
	jmp s2rm110
	slabel3:
	cmp dl, 07h
	jne slabel4
	jmp s2rm111
	slabel4:
	
	s2rm000:
		call analyzeSregMULbyte2
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp000
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		inc bx	
		
		ret
	s2rm001:
		call analyzeSregMULbyte2
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp001
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		inc bx	
		
		ret
	s2rm010:
		call analyzeSregMULbyte2
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp010
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		inc bx	
		
		ret
	s2rm011:
		call analyzeSregMULbyte2
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp011
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		inc bx	
		
		ret
	s2rm100:
		call analyzeSregMULbyte2
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp100
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		inc bx	
		
		ret
	s2rm101:
		call analyzeSregMULbyte2
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp101
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		inc bx	
		
		ret
	s2rm110:
		call analyzeSregMULbyte2
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp110
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		inc bx	
		
		ret
	s2rm111:
		call analyzeSregMULbyte2
		push dx
		mov dx, offset sreg 
		call writeSreg
		mov dx, offset rmp111
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		inc bx	
		
		ret