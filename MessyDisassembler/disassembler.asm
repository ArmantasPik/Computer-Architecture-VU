.model small
.stack 100h
.data
	fhIn dw 0
	fhOut dw 0
	SfileIn db 13, 0, 12 dup(0)
	SfileOut db 13, 0, 12 dup(0)
	fileIn db 12 dup(0) 
	fileOut db 12 dup(0)
	
	msg1	db "Iveskite ivesties failo varda: $"
	msg2	db 10, 13, "Iveskite isvesties failo varda: $"
	msgError db 10, 13, "Ivyko klaida atidarant faila", 13, 10, "$"
	msgHelp    db "Programa apdoroja komandas RET, MUL, IMUL, OR, SHL, CLC, STC, CMC, CLD, STD, CLI, pusf, popf", 13, 10, "$"
	
	opCALL  db    " CALL  "
	opRET	db    " RET   "
	opRETF  db    " RETF  "
	opMUL1  db    " MUL   "
	opMUL	db    "       "
	opIMUL	db    " IMUL  "
	opOR    db    " OR    "
	opSHL   db    " SHL   "
	opCLC   db    " CLC   "
	opSTC   db    " STC   "
	opCMC   db    " CMC   "
	opCLD   db    " CLD   "
	opSTD   db    " STD   "
	opCLI   db    " CLI   "
	opPUSHF db    " PUSHF "
	opPOPF  db    " POPF  "
	opError db    " ????  "
	SHLind1 db    " {1}   "
	SHLindC db    " {CL}  "
	
	; w = 0
	w000     db "AL       "
	w001     db "CL       "
	w010     db "DL       "
	w011     db "BL       "
	w100     db "AH       "
	w101     db "CH       "
	w110     db "DH       "
	w111     db "BH       "
	
	; w = 1
	wm000     db "AX       "
	wm001     db "CX       "
	wm010     db "DX       "
	wm011     db "BX       "
	wm100     db "SP       "
	wm101     db "BP       "
	wm110     db "SI       "
	wm111     db "DI       "
	
	; kai mod = 00
	rm000    db "[BX + SI]"
	rm001    db "[BX + DI]"
	rm010    db "[BP + SI]"
	rm011    db "[BP + DI]"
	rm100    db "[SI]     "
	rm101    db "[DI]     "
	rm110    db "[BP]     "
	rm111    db "[BX]     "
	
	; kai mod = 01 arba mod = 10, yra poslinkis
	rmp000    db "[BX+SI+  "
	rmp001    db "[BX+DI+  "
	rmp010    db "[BP+SI+  "
	rmp011    db "[BP+DI+  "
	rmp100    db "[SI +    "
	rmp101    db "[DI +    "
	rmp110    db "[BP +    "
	rmp111    db "[BX +    "
	
	sreg      db "XX:"
	sreg00    db "ES:"
	sreg01    db "CS:"
	sreg10    db "SS:"
	sreg11    db "DS:"
	
	seek01 db 48, 48
	seek10 db 6 dup (32)
	maxbit db "FF"
	
	zero db 0
	varNum1 db 48
	varNum2 db 48
	
	endline db 13, 10
	comma   db ", "
	bracket db "] "
	
	buffer db 200h dup(?)
	positionBuffer db 13, 10, 4 dup(48), 32
	byteBuffer db 19 dup(32)
	
	
	
.code
start:
    mov dx, @data
    mov ds, dx  
	
	mov bx, 81h
	
check:
	;help simbolio /? ieskojimas, jei jis yra
	mov ax, es:[bx]
	inc bx
	
	cmp al, 13 ;jei baigiasi newline tai nera parametru
	je furtherStdin
	cmp al, 20h ;ignoruojam space
	je check
	cmp ax, "?/" ;jei parametras ne /? tai nereikia help message
	jne parameters ;sokam i parametru ieskojima
	mov ax, es:[bx] ;jei tai /?, tai tikrinam ar po jo newline
	cmp ah, 13
	je help ;jei newline tai isvedam pagalbos pranesima, jei ne tai atidarom failus ir bus isvestas klaidos pranesimas
	jmp further
	
	
	
parameters:
	;iskvieciam parametru parsinimo procedura
	call readWord
	jmp further
	
	
	
help:
	mov dx, offset msgHelp ;pagalbos zinute ir iseiname is programos
	mov ah, 09h
	int 21h
	
	jmp exit



furtherStdin:
	;JEIGU STANDARTINE IVESTIS
	mov dx, offset msg1 ;jei stdin prasome ivesti duom faila 
	mov ah, 09h
	int 21h
	
	mov dx, offset SfileIn ;nuskaitome i fileIn bufferi varda
	mov ah, 0Ah
	int 21h
	mov bx, offset SfileIn
	call fixFile ;sutaisome failo varda kad gale butu 0
	
	mov dx, offset msg2 ;jei stdin prasome ivesti rez faila
	mov ah, 09h
	int 21h
	
	mov dx, offset SfileOut ; nuskaitome i fileOut bufferi varda
	mov ah, 0Ah
	int 21h
	mov bx, offset SfileOut
	call fixFile ;sutaisome failo varda kad gale butu 0
	
	mov ax, 3D00h ;atidarom duom faila
	mov dx, offset SfileIn + 2 ;vardas bufferyje nuo 3 baito
	int 21h
	jc klaida ;jei negalima atidaryti arba klaida cf=1
	mov fhIn, ax ;idedam file handle
	
	mov ax, 3C00h ;atidarom rez faila
	xor cx, cx
	mov dx, offset SfileOut + 2 ;vardas bufferyje nuo 3 baito
	int 21h
	jc klaida ;jei negalima atidaryti arba klaida cf=1
	mov fhOut, ax ;idedam file handle
	jmp beginRead



further:
	;JEIGU PER KOMANDINIUS PARAMETRUS
	mov ax, 3D00h ;atidarom duom faila
	mov dx, offset fileIn ;vardas bufferyje 
	int 21h
	jc klaida ;jei negalima atidaryti arba klaida cf=1
	mov fhIn, ax ;idedam file handle
	
	mov ax, 3C00h ;atidarom rez faila
	xor cx, cx
	mov dx, offset fileOut ;vardas bufferyje
	int 21h
	jc klaida ;jei negalima atidaryti arba klaida cf=1
	mov fhOut, ax ;idedam file handle
	
	xor di, di
	jmp beginRead
	
	
	
klaida:
	mov ah, 09h ;isvedam klaidos zinute ir programa baigs darba
	mov dx, offset msgError
	int 21h
	jmp exit
	
	
	
beginRead:
	;inicializuojam bufferi
	push di
	mov cx, 0200h
	mov bx, offset buffer
	xor di, di
	mov ah, 00
	
	initializeBuff:
		mov [bx + di], ah
		inc di
		loop initializeBuff
	pop di



	mov ah, 3Fh ;nuskaitome duomenu faila
	mov bx, fhIn
	mov cx, 200h ; 512 baitu blokais
	mov dx, offset buffer
	int 21h
	push di
	mov cx, ax ;ciklui idedam kiek nuskaitem i cx
	cmp cx, 0
	jnz jump ;jei nebenuskaite jokiu baitu, tai baigiam programa
	jmp endRead
	
jump:
	;|||||||||||||ALGORITMO PRADZIA||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	xor dx, dx
	xor ax, ax
	add ax, di
	xor si, si
	mov bx, offset buffer ; i bx idedam nuskaityta duomenu failo bufferi
	loopByte:
	
		call initializeByteBuffer ;inicializuojam baitu buferi, kad neliktu nieko is praeito ciklo
		mov dl, [bx]
		xor si, si
		
		galSRegES:
		cmp dl, 26h ;ES
		jne galSRegCS
			mov di, offset sreg00
			call changeSregName
			mov si, 0001h
			inc bx
			mov dl, [bx]
			jmp galCALL1
		
		galSRegCS:
		cmp dl, 2Eh ;CS
		jne galSRegSS
			mov di, offset sreg01
			call changeSregName
			mov si, 0001h
			inc bx
			mov dl, [bx]
			jmp galCALL1
		
		galSRegSS:
		cmp dl, 36h ;SS
		jne galSRegDS
			mov di, offset sreg10
			call changeSregName
			mov si, 0001h
			inc bx
			mov dl, [bx]
			jmp galCALL1
		
		galSRegDS:
		cmp dl, 3Eh ;DS
		jne galCALL1
			mov di, offset sreg11
			call changeSregName
			mov si, 0001h
			inc bx
			mov dl, [bx]
			jmp galCALL1


		
		galCALL1:
		cmp dl, 9Ah   ;||||||||||||||||||CALL (isorinis tiesioginis)
		jne galCALL2
			call position
			add ax, 05h
			sub cx, 04h
			mov si, 0005h
			call writeBytes
			push dx
			xor dx, dx
			mov dx, offset opCALL
			call writeOp
			pop dx
			call writeCALL1
			jmp cmdSuccess
			
		galCALL2:
		cmp dl, 0E8h  ;|||||||||||||||||||CALL (vidinis tiesioginis)
		jne galRET1
			call position
			add ax, 03h
			sub cx, 02h
			mov si, 0003h
			call writeBytes
			push dx
			xor dx, dx
			mov dx, offset opCALL
			call writeOp
			pop dx
			add bx, 02h
			call convertByte
			call writeSeek
			dec bx 
			call convertByte
			call writeSeek
			inc bx
			jmp cmdSuccess
		
		;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
		
		galRET1:
		cmp dl, 0C3h  ;|RET (vidine be steko islyginimo)
		jne galRET2
			call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opRET
			call writeOp
			pop dx
			jmp cmdSuccess
			
		galRET2:
		cmp dl, 0C2h  ;|RET (vidine su steko islyginimu)
		jne galRETF1
			call position
			add ax, 03h
			sub cx, 02h
			mov si, 0003h
			call writeBytes
			push dx
			xor dx, dx
			mov dx, offset opRET
			call writeOp
			pop dx
			add bx, 02h
			call convertByte
			call writeSeek
			dec bx 
			call convertByte
			call writeSeek
			inc bx
			jmp cmdSuccess
		
		galRETF1:
		cmp dl, 0CBh  ;|RETF (isorinis be steko islyginimo)
		jne galRETF2
			call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opRETF
			call writeOp
			pop dx
			jmp cmdSuccess
			
		galRETF2:
		cmp dl, 0CAh  ;|RETF (isorinis su steko islyginimu)
		jne galMUL1
			call position
			add ax, 03h
			sub cx, 02h
			mov si, 0003h
			call writeBytes
			push dx
			xor dx, dx
			mov dx, offset opRETF
			call writeOp
			pop dx
			add bx, 02h
			call convertByte
			call writeSeek
			dec bx 
			call convertByte
			call writeSeek
			inc bx
			jmp cmdSuccess
			
		;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||	
			
		galMUL1:
		cmp dl, 0F6h  ;MUL 1111 011w mod 100 r\m [poslinkis] | w=0
		jne galMUL2
			inc bx       ;tikrinimas ar XX100XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 20h
			je starting
			jmp galMUL2
			starting:
			
			mov di, offset opMUL1
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je mod11
			cmp dl, 00h
			je mod00
			cmp dl, 80h
			je mod10
			cmp dl, 40h
			je mod01
			mod00:       ;r\m
				cmp si, 0001h
				je wsreg00
				call analyzeMOD00
				jmp cmdSuccess
				wsreg00:
				call analyzeSregMOD00
				jmp cmdSuccess
			mod11:
				call analyzeW0MOD11
				jmp cmdSuccess
			mod01:
				cmp si, 0001h
				je wsreg01
				call analyzeMOD01
				jmp cmdSuccess
				wsreg01:
				call analyzeSregMOD01
				jmp cmdSuccess
			mod10:
				cmp si, 0001h
				je wsreg10
				call analyzeMOD10
				jmp cmdSuccess
				wsreg10:
				call analyzeSregMOD10
				jmp cmdSuccess
			
		
		galMUL2:
		cmp dl, 0F7h  ;MUL 1111 011w mod 100 r\m [poslinkis] | w=1
		jne galIMUL1
			inc bx       ;tikrinimas ar XX100XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 20h
			jne galIMUL1
			
			mov di, offset opMUL1
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je Mmod11
			cmp dl, 00h
			je Mmod00
			cmp dl, 80h
			je Mmod10
			cmp dl, 40h
			je Mmod01
			Mmod00:       ;r\m
				cmp si, 0001h
				je wwsreg00
				call analyzeMOD00
				jmp cmdSuccess
				wwsreg00:
				call analyzeSregMOD00
				jmp cmdSuccess
			Mmod11:
				call analyzeW1MOD11
				jmp cmdSuccess
			Mmod01:
				cmp si, 0001h
				je wwsreg01
				call analyzeMOD01
				jmp cmdSuccess
				wwsreg01:
				call analyzeSregMOD01
				jmp cmdSuccess
			Mmod10:
				cmp si, 0001h
				je wwsreg10
				call analyzeMOD10
				jmp cmdSuccess
				wwsreg10:
				call analyzeSregMOD10
				jmp cmdSuccess
		
		galIMUL1:
		mov dl, [bx]
		cmp dl, 0F6h  ;MUL 1111 011w mod 101 r\m [poslinkis] | w=0
		jne galIMUL2
			inc bx       ;tikrinimas ar XX101XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 28h
			je started
			jmp galIMUL2
			started:
			
			mov di, offset opIMUL
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je Imod11
			cmp dl, 00h
			je Imod00
			cmp dl, 80h
			je Imod10
			cmp dl, 40h
			je Imod01
			Imod00:       ;r\m
				cmp si, 0001h
				je dsreg00
				call analyzeMOD00
				jmp cmdSuccess
				dsreg00:
				call analyzeSregMOD00
				jmp cmdSuccess
			Imod11:
				call analyzeW0MOD11
				jmp cmdSuccess
			Imod01:
				cmp si, 0001h
				je dsreg01
				call analyzeMOD01
				jmp cmdSuccess
				dsreg01:
				call analyzeSregMOD01
				jmp cmdSuccess
			Imod10:
				cmp si, 0001h
				je dsreg10
				call analyzeMOD10
				jmp cmdSuccess
				dsreg10:
				call analyzeSregMOD10
				jmp cmdSuccess
			
		
		galIMUL2:
		mov dl, [bx]
		cmp dl, 0F7h  ;MUL 1111 011w mod 101 r\m [poslinkis] | w=1
		jne galORrmreg1
			inc bx       ;tikrinimas ar XX101XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 28h
			jne galORrmreg1
			
			mov di, offset opIMUL
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je IImod11
			cmp dl, 00h
			je IImod00
			cmp dl, 80h
			je IImod10
			cmp dl, 40h
			je IImod01
			IImod00:       ;r\m
				cmp si, 0001h
				je ddsreg00
				call analyzeMOD00
				jmp cmdSuccess
				ddsreg00:
				call analyzeSregMOD00
				jmp cmdSuccess
			IImod11:
				call analyzeW1MOD11
				jmp cmdSuccess
			IImod01:
				cmp si, 0001h
				je ddsreg01
				call analyzeMOD01
				jmp cmdSuccess
				ddsreg01:
				call analyzeSregMOD01
				jmp cmdSuccess
			IImod10:
				cmp si, 0001h
				je ddsreg10
				call analyzeMOD10
				jmp cmdSuccess
				ddsreg10:
				call analyzeSregMOD10
				jmp cmdSuccess
		
		
		;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
		
		galORrmreg1: ; OR r/m ~ reg 0000 10dw mod reg r\m [poslinkis] | d=0 w=0
		cmp dl, 08h
		je 	startORrmreg1
		jmp galORrmreg2
			startORrmreg1:
			mov di, offset opOR
			call changeName
			
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je or1mod11
			cmp dl, 00h
			je or1mod00
			cmp dl, 80h
			je or1mod10
			cmp dl, 40h
			je or1mod01
			or1mod00:       ;r\m
				cmp si, 0001h
				jne normalOR0
				call analyzeSregMOD00
				call writeComma
				mov dl, [bx]
				call writeREGw0
				jmp cmdSuccess
				normalOR0:
				call analyzeMOD00
				call writeComma
				mov dl, [bx]
				call writeREGw0
				jmp cmdSuccess
				
			or1mod11:
				call analyzeW0MOD11
				call writeComma
				mov dl, [bx]
				call writeREGw0
				jmp cmdSuccess
			or1mod01:
				cmp si, 0001h
				jne normalOR1
				call analyzeSregMOD01
				call writeComma
				sub bx, 01h ; ieskosime registro
				mov dl, [bx]
				call writeREGw0
				add bx, 01h
				jmp cmdSuccess
				normalOR1:
				call analyzeMOD01
				call writeComma
				sub bx, 01h ; ieskosime registro
				mov dl, [bx]
				call writeREGw0
				add bx, 01h
				jmp cmdSuccess
			or1mod10:
				cmp si, 0001h
				jne normalOR2
				call analyzeSregMOD10
				call writeComma
				sub bx, 02h ; ieskosime registro
				mov dl, [bx]
				call writeREGw0
				add bx, 02h
				jmp cmdSuccess
				normalOR2:
				call analyzeMOD10
				call writeComma
				sub bx, 02h ; ieskosime registro
				mov dl, [bx]
				call writeREGw0
				add bx, 02h
				jmp cmdSuccess
				
				
		galORrmreg2: ; d=0 w=1
		cmp dl, 09h
		je starter1
		jmp galORrmreg3
			starter1:
			mov di, offset opOR
			call changeName
			
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je or2mod11
			cmp dl, 00h
			je or2mod00
			cmp dl, 80h
			je or2mod10
			cmp dl, 40h
			je or2mod01
			or2mod00:       ;r\m
				cmp si, 0001h
				jne normalOR00
				call analyzeSregMOD00
				call writeComma
				mov dl, [bx]
				call writeREGw1
				jmp cmdSuccess
				normalOR00:
				call analyzeMOD00
				call writeComma
				mov dl, [bx]
				call writeREGw1
				jmp cmdSuccess
				
			or2mod11:
				call analyzeW0MOD11
				call writeComma
				mov dl, [bx]
				call writeREGw1
				jmp cmdSuccess
			or2mod01:
				cmp si, 0001h
				jne normalOR11
				call analyzeSregMOD01
				call writeComma
				sub bx, 01h ; ieskosime registro
				mov dl, [bx]
				call writeREGw1
				add bx, 01h
				jmp cmdSuccess
				normalOR11:
				call analyzeMOD01
				call writeComma
				sub bx, 01h ; ieskosime registro
				mov dl, [bx]
				call writeREGw1
				add bx, 01h
				jmp cmdSuccess
			or2mod10:
				cmp si, 0001h
				jne normalOR22
				call analyzeSregMOD10
				call writeComma
				sub bx, 02h ; ieskosime registro
				mov dl, [bx]
				call writeREGw1
				add bx, 02h
				jmp cmdSuccess
				normalOR22:
				call analyzeMOD10
				call writeComma
				sub bx, 02h ; ieskosime registro
				mov dl, [bx]
				call writeREGw1
				add bx, 02h
				jmp cmdSuccess
		
		galORrmreg3: ; d=1 w=0
		cmp dl, 0Ah
		je startoror
		jmp galORrmreg4
			startoror:
			
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je or3mod11
			cmp dl, 00h
			jne galORMOD10
			galORMOD10:
			jmp or3mod00
			cmp dl, 80h
			jne galORMOD01 
			jmp or3mod10
			galORMOD01:
			cmp dl, 40h
			jne starter
			jmp or3mod01
			starter:
			or3mod00:       ;r\m
				cmp si, 0001h
				jne ORnormal0
				call position
				add ax, 03h
				sub cx, 02h
				mov si, 0003h
				sub bx, 02h
				call writeBytes
				add bx, 02h
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw0
				call writeComma
				push dx
				mov dx, offset sreg
				call writeSreg
				pop dx
				call writeRM00
				jmp cmdSuccess
			
				ORnormal0:
				call position
				add ax, 02h
				sub cx, 01h
				mov si, 0002h
				dec bx
				call writeBytes
				inc bx
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw0
				call writeComma
				call writeRM00
				jmp cmdSuccess
				
			or3mod11:
				call position
				add ax, 02h
				sub cx, 01h
				mov si, 0002h
				dec bx
				call writeBytes
				inc bx
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw0
				call writeComma
				call writeW0RM11
				
				jmp cmdSuccess
			or3mod01:
				cmp si, 0001h
				jne ORnormal1
				call position
				add ax, 04h
				sub cx, 03h
				mov si, 0004h
				sub bx, 02h
				call writeBytes
				add bx, 02h
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw0
				call writeComma
				push dx
				mov dx, offset sreg
				call writeSreg
				pop dx
				call writeRM0110
				inc bx
				call convertByte
				call writeSeek 
				call writeBracket
				jmp cmdSuccess
			
				ORnormal1:
				call position
				add ax, 03h
				sub cx, 02h
				mov si, 0003h
				dec bx
				call writeBytes
				inc bx
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw0
				call writeComma
				call writeRM0110
				inc bx
				call convertByte
				call writeSeek 
				call writeBracket
				
				jmp cmdSuccess
			or3mod10:
				cmp si, 0001h
				jne ORnormal2
				call position
				add ax, 05h
				sub cx, 04h
				mov si, 0005h
				sub bx, 02h
				call writeBytes
				add bx, 02h
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw0
				call writeComma
				push dx
				mov dx, offset sreg
				call writeSreg
				pop dx
				call writeRM0110
				add bx, 02h
				call convertByte
				call writeSeek
				dec bx 
				call convertByte
				call writeSeek
				call writeBracket
				inc bx
				jmp cmdSuccess
			
				ORnormal2:
				call position
				add ax, 04h
				sub cx, 03h
				mov si, 0004h
				dec bx
				call writeBytes
				inc bx
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw0
				call writeComma
				call writeRM0110
				add bx, 02h
				call convertByte
				call writeSeek
				dec bx 
				call convertByte
				call writeSeek
				call writeBracket
				inc bx
				
				jmp cmdSuccess
		
		
		
		galORrmreg4: ; d=1 w=1
		cmp dl, 0Bh
		je startor 
		jmp galORboak1
			startor:
			mov di, offset opOR
			call changeName
			
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je or4mod11
			cmp dl, 00h
			je or4mod00
			cmp dl, 80h
			jne galOR4mod01
			jmp or4mod10
			galOR4mod01:
			cmp dl, 40h
			jne galOR4mod10
			jmp or4mod01
			galOR4mod10:
			or4mod00:       ;r\m
				cmp si, 0001h
				jne ORnormal00
				call position
				add ax, 03h
				sub cx, 02h
				mov si, 0003h
				sub bx, 02h
				call writeBytes
				add bx, 02h
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw1
				call writeComma
				push dx
				mov dx, offset sreg
				call writeSreg
				pop dx
				call writeRM00
				jmp cmdSuccess
			
				ORnormal00:
				call position
				add ax, 02h
				sub cx, 01h
				mov si, 0002h
				dec bx
				call writeBytes
				inc bx
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw1
				call writeComma
				call writeRM00
				
				jmp cmdSuccess
				
			or4mod11:
				call position
				add ax, 02h
				sub cx, 01h
				mov si, 0002h
				dec bx
				call writeBytes
				inc bx
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw1
				call writeComma
				call writeW1RM11
				
				jmp cmdSuccess
			or4mod01:
				cmp si, 0001h
				jne ORnormal11
				call position
				add ax, 04h
				sub cx, 03h
				mov si, 0004h
				sub bx, 02h
				call writeBytes
				add bx, 02h
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw1
				call writeComma
				push dx
				mov dx, offset sreg
				call writeSreg
				pop dx
				call writeRM0110
				inc bx
				call convertByte
				call writeSeek 
				call writeBracket
				jmp cmdSuccess
			
				ORnormal11:
				call position
				add ax, 03h
				sub cx, 02h
				mov si, 0003h
				dec bx
				call writeBytes
				inc bx
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw1
				call writeComma
				call writeRM0110
				inc bx
				call convertByte
				call writeSeek
				call writeBracket
				
				jmp cmdSuccess
			or4mod10:
				cmp si, 0001h
				jne ORnormal22
				call position
				add ax, 05h
				sub cx, 04h
				mov si, 0005h
				sub bx, 02h
				call writeBytes
				add bx, 02h
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw1
				call writeComma
				push dx
				mov dx, offset sreg
				call writeSreg
				pop dx
				call writeRM0110
				add bx, 02h
				call convertByte
				call writeSeek
				dec bx 
				call convertByte
				call writeSeek
				call writeBracket
				inc bx
				jmp cmdSuccess
			
				ORnormal22:
				call position
				add ax, 04h
				sub cx, 03h
				mov si, 0004h
				dec bx
				call writeBytes
				inc bx
				push dx
				mov dx, offset opOR
				call writeOp
				pop dx
				call writeREGw1
				call writeComma
				call writeRM0110
				add bx, 02h
				call convertByte
				call writeSeek
				dec bx 
				call convertByte
				call writeSeek
				call writeBracket
				inc bx
				
				jmp cmdSuccess
		
		
		
		galORboak1: ; OR akum. ~ b.o.| 0000 110w b.o.j [b.o.v. jei w =1]
		cmp dl, 0Ch ; w=0
		jne galORboak2
			call position
			add ax, 02h
			sub cx, 01h
			mov si, 0002h
			call writeBytes
			push dx
			xor dx, dx
			mov dx, offset opOR
			call writeOp
			mov dx, offset w000
			call writeAddress
			call writeComma
			pop dx
			inc bx
			call convertByte
			call writeSeek 
			jmp cmdSuccess
		
		galORboak2: ; w=1
		cmp dl, 0Dh 
		jne galORborm1
			call position
			add ax, 03h
			sub cx, 02h
			mov si, 0003h
			call writeBytes
			push dx
			xor dx, dx
			mov dx, offset opOR
			call writeOp
			mov dx, offset wm000
			call writeAddress
			call writeComma
			pop dx
			add bx, 02h
			call convertByte
			call writeSeek
			dec bx 
			call convertByte
			call writeSeek
			inc bx
			jmp cmdSuccess




		galORborm1: ; OR b.o. ~ r\m | 1000 00sw mod 001 r\m [poslinkis] b.o.j [b.o.v]
		mov dl, [bx]
		cmp dl, 80h ; s=0 w=0
		je beginningg
		jmp galORborm2
			beginningg:
			inc bx       ;tikrinimas ar XX001XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 08h
			je next
			jmp galORborm2
			next:
			
			mov di, offset opOR
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je omod11
			cmp dl, 00h
			je omod00
			cmp dl, 80h
			je omod10
			cmp dl, 40h
			je omod01
			omod00:       ;r\m
				cmp si, 0001h
				jne galORbo1
				call analyzeSregMOD00
				jmp finishOR
				
				galORbo1:
				call analyzeMOD00
				finishOR:
				call writeComma
				push dx
				add ax, 01h
				sub cx, 01h
				inc bx
				call convertByte
				call writeSeek
				pop dx
				
				jmp cmdSuccess
			omod11:
				call analyzeW0MOD11
				call writeComma
				push dx
				add ax, 01h
				sub cx, 01h
				inc bx
				call convertByte
				call writeSeek
				pop dx
				
				jmp cmdSuccess
			omod01:
				cmp si, 0001h
				jne galORbo11
				call analyzeSregMOD01
				jmp finishOR1
				
				galORbo11:
				call analyzeMOD01
				finishOR1:
				call writeComma
				push dx
				add ax, 01h
				sub cx, 01h
				inc bx
				call convertByte
				call writeSeek
				pop dx
				
				jmp cmdSuccess
			omod10:
				cmp si, 0001h
				jne galORbo2
				call analyzeSregMOD10
				jmp finishOR2
				
				galORbo2:
				call analyzeMOD10
				finishOR2:
				call writeComma
				push dx
				add ax, 01h
				sub cx, 01h
				inc bx
				call convertByte
				call writeSeek
				pop dx
				
				jmp cmdSuccess
		
		galORborm2: ; s=0 w=1
		mov dl, [bx]
		cmp dl, 81h
		je beginning 
		jmp galORborm3
			beginning:
			inc bx       ;tikrinimas ar XX001XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 08h
			je nnext
			jmp galORborm3
			nnext:
			
			mov di, offset opOR
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je oomod11
			cmp dl, 00h
			je oomod00
			cmp dl, 80h
			je oomod10
			cmp dl, 40h
			je oomod01
			oomod00:       ;r\m
				cmp si, 0001h
				jne galORbor1
				call analyzeSregMOD00
				jmp finishORr
				
				galORbor1:
				call analyzeMOD00
				finishORr:
				call writeComma
				add ax, 02h
				sub cx, 02h
				add bx, 02h
				call convertByte
				call writeSeek
				dec bx 
				call convertByte
				call writeSeek
				inc bx
				
				jmp cmdSuccess
			oomod11:
				call analyzeW1MOD11
				call writeComma
				add ax, 02h
				sub cx, 02h
				add bx, 02h
				call convertByte
				call writeSeek
				dec bx 
				call convertByte
				call writeSeek
				inc bx
				
				pop dx
				
				jmp cmdSuccess
			oomod01:
				cmp si, 0001h
				jne galORbo13
				call analyzeSregMOD01
				jmp finishOR3
				
				galORbo13:
				call analyzeMOD01
				finishOR3:
				call writeComma
				add ax, 02h
				sub cx, 02h
				add bx, 02h
				call convertByte
				call writeSeek
				dec bx 
				call convertByte
				call writeSeek
				inc bx
				
				jmp cmdSuccess
			oomod10:
				cmp si, 0001h
				jne galORbo14
				call analyzeSregMOD10
				jmp finishOR4
				
				galORbo14:
				call analyzeMOD10
				finishOR4:
				call writeComma
				add ax, 02h
				sub cx, 02h
				add bx, 02h
				call convertByte
				call writeSeek
				dec bx 
				call convertByte
				call writeSeek
				inc bx
				
				jmp cmdSuccess
		
		galORborm3: ; s=1 w=0
		mov dl, [bx]
		cmp dl, 82h
		jne galORborm4
		
		galORborm4: ; s=1 w=1
		mov dl, [bx]
		cmp dl, 83h
		je  startORborm
		jmp galSHL1
			startORborm:
			inc bx       ;tikrinimas ar XX001XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 08h
			je nnnext
			jmp galSHL1
			nnnext:
			
			mov di, offset opOR
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je ooomod11
			cmp dl, 00h
			je ooomod00
			cmp dl, 80h
			je ooomod10
			cmp dl, 40h
			je ooomod01
			ooomod00:       ;r\m
				cmp si, 0001h
				jne galORbo8
				call analyzeSregMOD00
				jmp finishOR8
				
				galORbo8:
				call analyzeMOD00
				finishOR8:
				call writeComma
				add ax, 01h
				sub cx, 01h
				inc bx
				call analyzeByte
				
				jmp cmdSuccess
			ooomod11:
				call analyzeW1MOD11
				call writeComma
				add ax, 01h
				sub cx, 01h
				inc bx
				call analyzeByte
				
				jmp cmdSuccess
			ooomod01:
				cmp si, 0001h
				jne galORbo88
				call analyzeSregMOD01
				jmp finishOR88
				
				galORbo88:
				call analyzeMOD01
				finishOR88:
				call writeComma
				add ax, 01h
				sub cx, 01h
				inc bx
				call analyzeByte
				
				jmp cmdSuccess
			ooomod10:
				cmp si, 0001h
				jne galORbo9
				call analyzeSregMOD10
				jmp finishOR9
				
				galORbo9:
				call analyzeMOD10
				finishOR9:
				call writeComma
				add ax, 01h
				sub cx, 01h
				inc bx
				call analyzeByte
				
				jmp cmdSuccess
		
		;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
		
		galSHL1:     ; SHL r\m | 1101 00vw mod 100 r\m [poslinkis]
		mov dl, [bx]
		cmp dl, 0D0h ; v=0 w=0
		je  startSHLL1 
		jmp galSHL2
			startSHLL1:
			inc bx       ;tikrinimas ar XX100XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 20h
			je startedd
			jmp galSHL2
			startedd:
			
			mov di, offset opSHL
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je smod11
			cmp dl, 00h
			je smod00
			cmp dl, 80h
			je smod10
			cmp dl, 40h
			je smod01
			smod00:       ;r\m
				cmp si, 0001h
				jne startSHL0
				call analyzeSregMOD00
				jmp finishSHL0
				startSHL0:
				call analyzeMOD00
				finishSHL0:
				push dx
				mov dx, offset SHLind1
				call writeOp
				pop dx
				jmp cmdSuccess
			smod11:
				call analyzeW0MOD11
				push dx
				mov dx, offset SHLind1
				call writeOp
				pop dx
				jmp cmdSuccess
			smod01:
				cmp si, 0001h
				jne startSHL1
				call analyzeSregMOD01
				jmp finishSHL1
				startSHL1:
				call analyzeMOD01
				finishSHL1:
				push dx
				mov dx, offset SHLind1
				call writeOp
				pop dx
				jmp cmdSuccess
			smod10:
				cmp si, 0001h
				jne startSHL2
				call analyzeSregMOD10
				jmp finishSHL2
				startSHL2:
				call analyzeMOD10
				finishSHL2:
				push dx
				mov dx, offset SHLind1
				call writeOp
				pop dx
				jmp cmdSuccess
		
		galSHL2:
		mov dl, [bx]
		cmp dl, 0D1h ; v=0 w=1
		je  startSHLL2 
		jmp galSHL3
			startSHLL2:
			inc bx       ;tikrinimas ar XX100XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 20h
			je starteddd
			jmp galSHL3
			starteddd:
			
			mov di, offset opSHL
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je s2mod11
			cmp dl, 00h
			je s2mod00
			cmp dl, 80h
			je s2mod10
			cmp dl, 40h
			je s2mod01
			s2mod00:       ;r\m
				cmp si, 0001h
				jne startSHL00
				call analyzeSregMOD00
				jmp finishSHL00
				startSHL00:
				call analyzeMOD00
				finishSHL00:
				push dx
				mov dx, offset SHLind1
				call writeOp
				pop dx
				jmp cmdSuccess
			s2mod11:
				call analyzeW1MOD11
				push dx
				mov dx, offset SHLind1
				call writeOp
				pop dx
				jmp cmdSuccess
			s2mod01:
				cmp si, 0001h
				jne startSHL01
				call analyzeSregMOD01
				jmp finishSHL01
				startSHL01:
				call analyzeMOD00
				finishSHL01:
				push dx
				mov dx, offset SHLind1
				call writeOp
				pop dx
				jmp cmdSuccess
			s2mod10:
				cmp si, 0001h
				jne startSHL02
				call analyzeSregMOD10
				jmp finishSHL02
				startSHL02:
				call analyzeMOD10
				finishSHL02:
				push dx
				mov dx, offset SHLind1
				call writeOp
				pop dx
				jmp cmdSuccess
		
		galSHL3:
		mov dl, [bx]
		cmp dl, 0D2h ; v=1 w=0
		je  startSHLL3
		jmp galSHL4
			startSHLL3:
			inc bx       ;tikrinimas ar XX100XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 20h
			je star
			jmp galSHL4
			star:
			
			mov di, offset opSHL
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je s3mod11
			cmp dl, 00h
			je s3mod00
			cmp dl, 80h
			je s3mod10
			cmp dl, 40h
			je s3mod01
			s3mod00:       ;r\m
				cmp si, 0001h
				jne startSHLC0
				call analyzeSregMOD00
				jmp finishSHLC0
				startSHLC0:
				call analyzeMOD00
				finishSHLC0:
				push dx
				mov dx, offset SHLindC
				call writeOp
				pop dx
				jmp cmdSuccess
			s3mod11:
				call analyzeW0MOD11
				push dx
				mov dx, offset SHLindC
				call writeOp
				pop dx
				jmp cmdSuccess
			s3mod01:
				cmp si, 0001h
				jne startSHLC1
				call analyzeSregMOD01
				jmp finishSHLC1
				startSHLC1:
				call analyzeMOD01
				finishSHLC1:
				push dx
				mov dx, offset SHLindC
				call writeOp
				pop dx
				jmp cmdSuccess
			s3mod10:
				cmp si, 0001h
				jne startSHLC2
				call analyzeSregMOD10
				jmp finishSHLC2
				startSHLC2:
				call analyzeMOD10
				finishSHLC2:
				push dx
				mov dx, offset SHLindC
				call writeOp
				pop dx
				jmp cmdSuccess
		
		galSHL4:
		mov dl, [bx]
		cmp dl, 0D3h ; v=1 w=1
		je  startSHLL4 
		jmp galPUSHF
			startSHLL4:
			inc bx       ;tikrinimas ar XX100XXX
			mov dl, [bx]
			and dl, 38h
			dec bx
			cmp dl, 20h
			je sta
			jmp galPUSHF
			sta:
			
			mov di, offset opSHL
			call changeName
			inc bx       ;mod
			mov dl, [bx]
			and dl, 0C0h
			cmp dl, 0C0h
			je s4mod11
			cmp dl, 00h
			je s4mod00
			cmp dl, 80h
			je s4mod10
			cmp dl, 40h
			je s4mod01
			s4mod00:       ;r\m
				cmp si, 0001h
				jne startSHLC00
				call analyzeSregMOD00
				jmp finishSHLC00
				startSHLC00:
				call analyzeMOD00
				finishSHLC00:
				push dx
				mov dx, offset SHLindC
				call writeOp
				pop dx
				jmp cmdSuccess
			s4mod11:
				call analyzeW1MOD11
				push dx
				mov dx, offset SHLindC
				call writeOp
				pop dx
				jmp cmdSuccess
			s4mod01:
				cmp si, 0001h
				jne startSHLC01
				call analyzeSregMOD01
				jmp finishSHLC01
				startSHLC01:
				call analyzeMOD01
				finishSHLC01:
				push dx
				mov dx, offset SHLindC
				call writeOp
				pop dx
				jmp cmdSuccess
			s4mod10:
				cmp si, 0001h
				jne startSHLC02
				call analyzeSregMOD10
				jmp finishSHLC02
				startSHLC02:
				call analyzeMOD10
				finishSHLC02:
				push dx
				mov dx, offset SHLindC
				call writeOp
				pop dx
				jmp cmdSuccess
		
		;||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
		
		galPUSHF:
		cmp dl, 9Ch   ;PUSHF
		jne galPOPF
			call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opPUSHF
			call writeOp
			pop dx
			jmp cmdSuccess
		
		galPOPF:
		cmp dl, 9Dh   ;POPF
		jne galCLC
			call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opPOPF
			call writeOp
			pop dx
			jmp cmdSuccess
		
		galCLC:
		cmp dl, 0F8h   ;CLC
		jne galSTC
		call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opCLC
			call writeOp
			pop dx
			jmp cmdSuccess
		
		galSTC:
		cmp dl, 0F9h   ;STC
		jne galCMC
		call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opSTC
			call writeOp
			pop dx
			jmp cmdSuccess
		
		galCMC:
		cmp dl, 0F5h   ;CMC
		jne galCLD
		call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opCMC
			call writeOp
			pop dx
			jmp cmdSuccess
		
		galCLD:
		cmp dl, 0FCh   ;CLD
		jne galSTD
		call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opCLD
			call writeOp
			pop dx
			jmp cmdSuccess
		
		galSTD:
		cmp dl, 0FDh   ;STD
		jne galCLI
		call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opSTD
			call writeOp
			pop dx
			jmp cmdSuccess
		
		galCLI:
		cmp dl, 0FAh   ;CLI
		jne noOPK
		call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opCLI
			call writeOp
			pop dx
			jmp cmdSuccess
		
		noOPK:
			call position
			add ax, 01h
			mov si, 0001h
			call writeBytes
			push dx
			mov dx, offset opError
			call writeOp
			pop dx
		
		cmdSuccess:
		dec cx
		inc bx
		cmp cx, 0
		jz endLoop
		jmp loopByte
	
	endLoop:
	pop di
	add di, 0200h
	jmp beginRead ;toliau skaitom kita bloka
	
	
	
	;|||||||||Failu uzdarymas|||||||||||
endRead:	
	mov ah, 3Eh ;uzdarom rezultatu faila
	mov bx, fhOut
	int 21h
	
	mov ah, 3Eh ;uzdarom duomenu faila
	mov bx, fhIn
	int 21h



exit:   
    mov ax, 4c00h
    int 21h
	
	
	
	;||||||||Pavadinimo duom ir rez failu sutaisymas, kai naudojama stdin||||||||||
fixFile:
	push dx ;issaugom dx reiksme nes ja naudosim
	
	xor dx, dx ;procedura padaro kad failo vardo gale butu 0
	mov dl, [bx + 1] ;kiek baitu irasyta bufferyje
	add bx, dx
	mov dx, 0
	mov [bx + 2], dx ;pridedam 2 prie bx prie kurio ir taip buvo prideda tiek baitu kiek yra baitu bufferyje ir tada padarom /n => 0	
	
	pop dx
	ret ;griztam
	
	
	
	;||||||||||||||||||||Komandines eilutes parsinimo procedura||||||||||||||||||||||
readWord:
	mov si, 81h ;pradedam nuo pirmo simbolio
	xor ax, ax
	
	readStart:	
	mov ax, es:[si] ;po viena einam prie kito simbolio
	inc si
	
	cmp al, 20h ;jei tai "space", tada pradedam skaityt nuo kito simbolio, t.y. ignoruojam space
	je readStart 
	
	mov bx, offset fileIn ;i bx idedam duomenu failo offset
	
	readToFileIn:
		mov [bx], al ;i duomenu faila idedam pirma simboli
		inc bx
		
		cmp ah, 20h ;jei sekantis simbolis yra "space", tai einam uzbaigti duomenu failo bufferio
		je endWord
		
		mov ax, es:[si] ;jei tai ne "space", tai toliau skaitom
		inc si
		jmp readToFileIn
	
	endWord:
		mov dl, zero ;paskutini simboli padarome null
		mov [bx], dl
	
	readToFileOut1:
		mov ax, es:[si] ;Nuskaicius duomenu faila ta pati darom ir su rezultatu failu...
		inc si
		
		cmp al, 20h
		je readToFileOut1
		
		mov bx, offset fileOut
	
	readToFileOut2:
		mov [bx], al 
		inc bx
		
		cmp ah, 13 ;jei rezultatu failas baigiasi enter, tai griztam i pagrindine programa (griztam)
		je readExit
		
		mov ax, es:[si]
		inc si
		jmp readToFileOut2
		
		readExit:
		ret 
	;|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	
	
	
	;;;proceduros;;;
changeName:
	push ax bx dx cx ;di laiko norimo vardo offset buferio
	
	xor cx, cx
	xor ax, ax
	mov bx, offset opMUL
	mov cl, 07h
	loopName:
		mov al, [di]
		mov [bx], al
		inc di
		inc bx
		loop loopName

	pop cx dx bx ax
	ret
	
	
	
writeBytes: ;si procedura skirta tam, kad po offset isprintintu baitu buferi komandos
	push ax bx dx cx
	
	xor dx, dx
	xor ax, ax
	mov cx, si ;bx nuskaitytas buferis, seek01 baitas, byteBuffer, si rodo kiek ascii baitu reik irasyt i buferi
	loopWriteByte:
		call convertByte
		push bx
		mov bx, offset seek01
		mov dh, [bx]
		mov dl, [bx + 1]
		mov bx, offset byteBuffer
		add bx, ax
		mov [bx], dh
		mov [bx + 1], dl
		pop bx
		inc bx
		add ax, 03h
		loop loopWriteByte
		
	sub bx, si
	
	xor ax, ax ;si procedura isprintina baitu bufferi
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx 
	mov dx, offset byteBuffer
	mov cl, 19h
	int 21h
	
	pop cx dx bx ax
	ret
	
	
analyzeByte:
	push dx ax bx cx
	
	mov dl, [bx]
	cmp dl, 80h
	jl noConvert
	
	push bx
	xor ax, ax ;si procedura praplecia baita arba ne
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov dx, offset maxbit
	mov cl, 02h
	int 21h
	pop bx
	
	xor dx, dx
	mov dl, [bx]
	call convertByte
	call writeSeek
	jmp ending
	
	noConvert:
	call convertByte
	call writeSeek
	
	ending:
	pop cx bx ax dx
	ret
	
	
	
writeCALL1:
	add bx, 02h
	call convertByte
	call writeSeek
	dec bx
	call convertByte
	call writeSeek
	call writeComma
	add bx, 02h
	call convertByte
	call writeSeek
	dec bx
	call convertByte
	call writeSeek
	inc bx
    ret
	
	
convert: ;hex to ascii byte
	push bx ;si procedura tiesiog konvertuoja hex 4bitus i ascii baita
	push ax
	push cx
	push dx
	
	mov al, [bx]
	add al, 30h
	cmp al, 3Ah
	jl endConvert
	add al, 07h
	
	endConvert:
		mov [bx], al
		
		pop dx
		pop cx
		pop ax
		pop bx
		ret
	
	
	
writeOp:
	push ax bx dx cx
	
	xor ax, ax ;si procedura isprintina op bufferi
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov cl, 07h
	int 21h
	
	pop cx dx bx ax
	ret
	

writeAddress:
	push ax bx dx cx
	
	xor ax, ax ;si procedura isprintina adreso bufferi
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov cl, 09h
	int 21h
	
	pop cx dx bx ax
	ret
	
	
	
convertByte: ;procedura pavercia baita esanti bx adresu i ta pati ascii atitikmeni ir ideda i buferi seek01
	push ax bx dx cx
	
	mov al, [bx] ;Kadangi bx buvo nuskaityto bufferio adresas, tai i al idedam 1 nuskaityta simboli
	push bx
	xor bx, bx
	mov bx, offset seek01 ;dabar i bx idedam baitu bufferio adresa
	push bx ;issaugom baitu bufferio adresa
	
	xor dx, dx ;sis blokas is nuskaityto simbolio paema vyresniuosius 4 bitus ir juos pavercia i ascii hex simboli
	mov cl, 04
	mov dl, al
	shr dl, cl
	mov bx, offset varNum1
	mov [bx], dl
	call convert
	
	xor dx, dx ;sis blokas is nuskaityto simbolio paema jaunesniuosius 4 bitus ir juos pavercia i ascii hex simboli
	mov dl, al
	and dl, 0Fh
	mov bx, offset varNum2
	mov [bx], dl
	call convert
	
	pop bx ;pasiemam baitu buferio adresa
	xor ax, ax
	mov al, varNum1 ;is pradziu idedam vyresniuosiu 4 bitus paverstus i ascii simboli
	mov [bx], al
	xor ax, ax
	mov al, varNum2 ;po to idedam janesniuosius 4 bitus paverstus i ascii simboli
	inc bx
	mov [bx], al
	pop bx
	
	pop cx dx bx ax
	ret



writeSeek:
	push ax bx dx cx
	
	xor ax, ax ;si procedura isprintina poslinkio buferi
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov dx, offset seek01
	mov cl, 02h
	int 21h

	pop cx dx bx ax
	ret
	
writeComma:
	push ax bx dx cx
	
	xor ax, ax 
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov dx, offset comma
	mov cl, 02h
	int 21h
	
	pop cx dx bx ax
	ret
	
writeBracket:
	push ax bx dx cx
	
	xor ax, ax 
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov dx, offset bracket
	mov cl, 02h
	int 21h
	
	pop cx dx bx ax
	ret
	
position: ;offset spausdinimas
	push bx ax cx dx ;ax saugo offset
	mov bx, offset positionBuffer + 2 ; pirmi 2 baitai newline
	
	xor dx, dx ;su siais keturiai blokais kiekvieno ax skaiciu po viena idedame i position bufferi
	mov cl, 04
	mov dl, ah
	shr dl, cl
	mov [bx], dl
	inc bx
	
	xor dx, dx
	mov dl, ah
	and dl, 0Fh
	mov [bx], dl
	inc bx
	
	xor dx, dx
	mov cl, 04
	mov dl, al
	shr dl, cl
	mov [bx], dl
	inc bx
	
	xor dx, dx
	mov dl, al
	and dl, 0Fh
	mov [bx], dl
	
	xor cx, cx
	mov cl, 04 ;ciklas vyks 4 kartus nes 4 skaicia offsetui
	mov bx, offset positionBuffer + 2
	loopConvert:
		call convert ;iskvieciame procedura, kuri konvertuoja hex skaiciu i toki pati ascii atitikmeni
		inc bx
		loop loopConvert
	
	xor ax, ax ; si procedura isprintina offset bufferi
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov cl, 07h
	mov dx, offset positionBuffer
	int 21h
	
	pop dx cx ax bx 
	ret

	
	
writeEndline:
	push ax bx dx cx
	
	xor ax, ax 
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov dx, offset endline
	mov cl, 02h
	int 21h
	
	pop cx dx bx ax
	ret
	
	
	
initializeByteBuffer:
	push ax bx dx cx
	mov cx, 0019h
	mov bx, offset byteBuffer
	mov ah, 32
	
	initializeByteBuff:
		mov [bx], ah
		inc bx
		loop initializeByteBuff
	pop cx dx bx ax
	ret
	
	
	
analyzeMUL1: ;iskviecia offseto programa, sutvarko skaiciavimo registrus, paraso atitinkamus baitus ir atliekama komanda
	push dx
	dec bx
	mov dl, [bx]
	call position
	add ax, 02h
	sub cx, 01h
	mov si, 0002h
	call writeBytes			
	xor dx, dx
	mov dx, offset opMUL
	call writeOp
	pop dx
	ret
	
analyzeMULbyte1: ;atlieka ta pati tik papildomai yra 1 baito poslinkis
	push dx
	dec bx
	mov dl, [bx]
	call position
	add ax, 03h
	sub cx, 02h
	mov si, 0003h
	call writeBytes			
	xor dx, dx
	mov dx, offset opMUL
	call writeOp
	pop dx
	ret
	
analyzeMULbyte2: ;atlieka ta pati tik papildomai yra 2 baitu poslinkis
	push dx
	dec bx
	mov dl, [bx]
	call position
	add ax, 04h
	sub cx, 03h
	mov si, 0004h
	call writeBytes			
	xor dx, dx
	mov dx, offset opMUL
	call writeOp
	pop dx
	ret
	
	
;|||||||||||analyzeMOD analizuoja adresavimo baita pagal tai koks yra mod, ir atlieka atitinkamus veiksmus

analyzeMOD00:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je rrm000
	cmp dl, 01h
	je rrm001
	cmp dl, 02h
	je rrm010
	cmp dl, 03h
	je rrm011
	cmp dl, 04h
	je rrm100
	cmp dl, 05h
	je rrm101
	cmp dl, 06h
	je rrm110
	cmp dl, 07h
	je rrm111
	
	rrm000:
		call analyzeMUL1
		push dx
		mov dx, offset rm000
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrm001:
		call analyzeMUL1
		push dx
		mov dx, offset rm001
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrm010:
		call analyzeMUL1
		push dx
		mov dx, offset rm010
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrm011:
		call analyzeMUL1
		push dx
		mov dx, offset rm011
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrm100:
		call analyzeMUL1
		push dx
		mov dx, offset rm100
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrm101:
		call analyzeMUL1
		push dx
		mov dx, offset rm101
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrm110:
		call analyzeMUL1
		push dx
		mov dx, offset rm110
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrm111:
		call analyzeMUL1
		push dx
		mov dx, offset rm111
		call writeAddress
		pop dx
		
		inc bx
		ret



analyzeW1MOD11:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je xm000
	cmp dl, 01h
	je xm001
	cmp dl, 02h
	je xm010
	cmp dl, 03h
	je xm011
	cmp dl, 04h
	je xm100
	cmp dl, 05h
	je xm101
	cmp dl, 06h
	je xm110
	cmp dl, 07h
	je xm111
	
	xm000:
		call analyzeMUL1
		push dx
		mov dx, offset wm000
		call writeAddress
		pop dx
		
		inc bx
		ret
	xm001:
		call analyzeMUL1
		push dx
		mov dx, offset wm001
		call writeAddress
		pop dx
		
		inc bx
		ret
	xm010:
		call analyzeMUL1
		push dx
		mov dx, offset wm010
		call writeAddress
		pop dx
		
		inc bx
		ret
	xm011:
		call analyzeMUL1
		push dx
		mov dx, offset wm011
		call writeAddress
		pop dx
		
		inc bx
		ret
	xm100:
		call analyzeMUL1
		push dx
		mov dx, offset wm100
		call writeAddress
		pop dx
		
		inc bx
		ret
	xm101:
		call analyzeMUL1
		push dx
		mov dx, offset wm101
		call writeAddress
		pop dx
		
		inc bx
		ret
	xm110:
		call analyzeMUL1
		push dx
		mov dx, offset wm110
		call writeAddress
		pop dx
		
		inc bx
		ret
	xm111:
		call analyzeMUL1
		push dx
		mov dx, offset wm111
		call writeAddress
		pop dx
		
		inc bx
		ret



analyzeW0MOD11:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je rrrm000
	cmp dl, 01h
	je rrrm001
	cmp dl, 02h
	je rrrm010
	cmp dl, 03h
	je rrrm011
	cmp dl, 04h
	je rrrm100
	cmp dl, 05h
	je rrrm101
	cmp dl, 06h
	je rrrm110
	cmp dl, 07h
	je rrrm111
	
	rrrm000:
		call analyzeMUL1
		push dx
		mov dx, offset w000
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrrm001:
		call analyzeMUL1
		push dx
		mov dx, offset w001
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrrm010:
		call analyzeMUL1
		push dx
		mov dx, offset w010
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrrm011:
		call analyzeMUL1
		push dx
		mov dx, offset w011
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrrm100:
		call analyzeMUL1
		push dx
		mov dx, offset w100
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrrm101:
		call analyzeMUL1
		push dx
		mov dx, offset w101
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrrm110:
		call analyzeMUL1
		push dx
		mov dx, offset w110
		call writeAddress
		pop dx
		
		inc bx
		ret
	rrrm111:
		call analyzeMUL1
		push dx
		mov dx, offset w111
		call writeAddress
		pop dx
		
		inc bx
		ret
		
		
		
analyzeMOD01:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je rrrrm000
	cmp dl, 01h
	je rrrrm001
	cmp dl, 02h
	je rrrrm010
	cmp dl, 03h
	je rrrrm011
	cmp dl, 04h
	je rrrrm100
	cmp dl, 05h
	jne llabel0
	jmp rrrrm101
	llabel0:
	cmp dl, 06h
	jne llabel1
	jmp rrrrm110
	llabel1:
	
	jmp rrrrm111
	
	rrrrm000:
		call analyzeMULbyte1
		push dx
		mov dx, offset rmp000
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		call writeBracket
		
		ret
	rrrrm001:
		call analyzeMULbyte1
		push dx
		mov dx, offset rmp001
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		call writeBracket	
		
		ret
	rrrrm010:
		call analyzeMULbyte1
		push dx
		mov dx, offset rmp010
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		call writeBracket		
		
		ret
	rrrrm011:
		call analyzeMULbyte1
		push dx
		mov dx, offset rmp011
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		call writeBracket		
		
		ret
	rrrrm100:
		call analyzeMULbyte1
		push dx
		mov dx, offset rmp100
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		call writeBracket	
		
		ret
	rrrrm101:
		call analyzeMULbyte1
		push dx
		mov dx, offset rmp101
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		call writeBracket	
		
		ret
	rrrrm110:
		call analyzeMULbyte1
		push dx
		mov dx, offset rmp110
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		call writeBracket	
		
		ret
	rrrrm111:
		call analyzeMULbyte1
		push dx
		mov dx, offset rmp111 
		call writeAddress
		pop dx
		
		add bx, 02h
		call convertByte
		call writeSeek
		call writeBracket	
		
		ret
		
		
		
analyzeMOD10:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je m000
	cmp dl, 01h
	je m001
	cmp dl, 02h
	je m010
	cmp dl, 03h
	jne label0
	jmp m011
	label0:
	cmp dl, 04h
	jne label1
	jmp m100
	label1:
	cmp dl, 05h
	jne label2
	jmp m101
	label2:
	cmp dl, 06h
	jne label3
	jmp m110
	label3:
	cmp dl, 07h
	jne label4
	jmp m111
	label4:
	
	m000:
		call analyzeMULbyte2
		push dx
		mov dx, offset rmp000
		call writeAddress
		pop dx
		
		add bx, 03h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		add bx, 01h		
		
		ret
	m001:
		call analyzeMULbyte2
		push dx
		mov dx, offset rmp001
		call writeAddress
		pop dx
		
		add bx, 03h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		add bx, 01h			
		
		ret
	m010:
		call analyzeMULbyte2
		push dx
		mov dx, offset rmp010
		call writeAddress
		pop dx
		
		add bx, 03h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		add bx, 01h		
		
		ret
	m011:
		call analyzeMULbyte2
		push dx
		mov dx, offset rmp011
		call writeAddress
		pop dx
		
		add bx, 03h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		add bx, 01h			
		
		ret
	m100:
		call analyzeMULbyte2
		push dx
		mov dx, offset rmp100
		call writeAddress
		pop dx
		
		add bx, 03h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		add bx, 01h		
		
		ret
	m101:
		call analyzeMULbyte2
		push dx
		mov dx, offset rmp101
		call writeAddress
		pop dx
		
		add bx, 03h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		add bx, 01h		
		
		ret
	m110:
		call analyzeMULbyte2
		push dx
		mov dx, offset rmp110
		call writeAddress
		pop dx
		
		add bx, 03h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		add bx, 01h			
		
		ret
	m111:
		call analyzeMULbyte2
		push dx
		mov dx, offset rmp111 
		call writeAddress
		pop dx
		
		add bx, 03h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		call writeBracket
		add bx, 01h			
		
		ret


;||||||||||writeREG isspausdina atitinkama registra pagal tai, kokia yra reg reiksme

writeREGw0:
	mov dl, [bx]
	and dl, 38h
	cmp dl, 00h
	je regi000
	cmp dl, 08h
	je regi001
	cmp dl, 10h
	je regi010
	cmp dl, 18h
	je regi011
	cmp dl, 20h
	je regi100
	cmp dl, 28h
	je regi101
	cmp dl, 30h
	je regi110
	cmp dl, 38h
	je regi111
	
	regi000:
		push dx
		mov dx, offset w000
		call writeAddress
		pop dx
		
		ret
	regi001:
		push dx
		mov dx, offset w001
		call writeAddress
		pop dx
		
		ret
	regi010:
		push dx
		mov dx, offset w010
		call writeAddress
		pop dx
		
		ret
	regi011:
		push dx
		mov dx, offset w011
		call writeAddress
		pop dx
		
		ret
	regi100:
		push dx
		mov dx, offset w100
		call writeAddress
		pop dx
		
		ret
	regi101:
		push dx
		mov dx, offset w101
		call writeAddress
		pop dx
		
		ret
	regi110:
		push dx
		mov dx, offset w110
		call writeAddress
		pop dx
		
		ret
	regi111:
		
		push dx
		mov dx, offset w111
		call writeAddress
		pop dx
		
		ret
	
	
writeREGw1:
	mov dl, [bx]
	and dl, 38h
	cmp dl, 00h
	je regis000
	cmp dl, 08h
	je regis001
	cmp dl, 10h
	je regis010
	cmp dl, 18h
	je regis011
	cmp dl, 20h
	je regis100
	cmp dl, 28h
	je regis101
	cmp dl, 30h
	je regis110
	cmp dl, 38h
	je regis111
	
	regis000:
		push dx
		mov dx, offset wm000
		call writeAddress
		pop dx
		
		ret
	regis001:
		push dx
		mov dx, offset wm001
		call writeAddress
		pop dx
		
		ret
	regis010:
		push dx
		mov dx, offset wm010
		call writeAddress
		pop dx
		
		ret
	regis011:
		push dx
		mov dx, offset wm011
		call writeAddress
		pop dx
		
		ret
	regis100:
		push dx
		mov dx, offset wm100
		call writeAddress
		pop dx
		
		ret
	regis101:
		push dx
		mov dx, offset wm101
		call writeAddress
		pop dx
		
		ret
	regis110:
		push dx
		mov dx, offset wm110
		call writeAddress
		pop dx
		
		ret
	regis111:
		
		push dx
		mov dx, offset wm111
		call writeAddress
		pop dx
		
		ret


;||||||||||writeR/M isspausdina atitinkama r/m pagal tai, kokia yra r/m reiksme

writeRM00:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je w0rm000
	cmp dl, 01h
	je w0rm001
	cmp dl, 02h
	je w0rm010
	cmp dl, 03h
	je w0rm011
	cmp dl, 04h
	je w0rm100
	cmp dl, 05h
	je w0rm101
	cmp dl, 06h
	je w0rm110
	cmp dl, 07h
	je w0rm111
	
	w0rm000:
		push dx
		mov dx, offset rm000
		call writeAddress
		pop dx
		
		ret
	w0rm001:
		push dx
		mov dx, offset rm001
		call writeAddress
		pop dx
		
		ret
	w0rm010:
		push dx
		mov dx, offset rm010
		call writeAddress
		pop dx
		
		ret
	w0rm011:
		push dx
		mov dx, offset rm011
		call writeAddress
		pop dx
		
		ret
	w0rm100:
		push dx
		mov dx, offset rm100
		call writeAddress
		pop dx
		
		ret
	w0rm101:
		push dx
		mov dx, offset rm101
		call writeAddress
		pop dx
		
		ret
	w0rm110:
		push dx
		add ax, 02h
		sub cx, 02h
		add bx, 02h
		call convertByte
		call writeSeek
		dec bx
		call convertByte
		call writeSeek
		inc bx
		pop dx
		
		ret
	w0rm111:
		push dx
		mov dx, offset rm111
		call writeAddress
		pop dx
		
		ret
		
		
		
writeRM0110:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je w1rm000
	cmp dl, 01h
	je w1rm001
	cmp dl, 02h
	je w1rm010
	cmp dl, 03h
	je w1rm011
	cmp dl, 04h
	je w1rm100
	cmp dl, 05h
	je w1rm101
	cmp dl, 06h
	je w1rm110
	cmp dl, 07h
	je w1rm111
	
	w1rm000:
		push dx
		mov dx, offset rmp000
		call writeAddress
		pop dx
		
		ret
	w1rm001:
		push dx
		mov dx, offset rmp001
		call writeAddress
		pop dx
		
		ret
	w1rm010:
		push dx
		mov dx, offset rmp010
		call writeAddress
		pop dx
		
		ret
	w1rm011:
		push dx
		mov dx, offset rmp011
		call writeAddress
		pop dx
		
		ret
	w1rm100:
		push dx
		mov dx, offset rmp100
		call writeAddress
		pop dx
		
		ret
	w1rm101:
		push dx
		mov dx, offset rmp101
		call writeAddress
		pop dx
		
		ret
	w1rm110:
		push dx
		mov dx, offset rmp110
		call writeAddress
		pop dx
		
		ret
	w1rm111:
		push dx
		mov dx, offset rmp111
		call writeAddress
		pop dx
		
		ret
		
		
		
writeW0RM11:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je w2rm000
	cmp dl, 01h
	je w2rm001
	cmp dl, 02h
	je w2rm010
	cmp dl, 03h
	je w2rm011
	cmp dl, 04h
	je w2rm100
	cmp dl, 05h
	je w2rm101
	cmp dl, 06h
	je w2rm110
	cmp dl, 07h
	je w2rm111
	
	w2rm000:
		push dx
		mov dx, offset w000
		call writeAddress
		pop dx
		
		ret
	w2rm001:
		push dx
		mov dx, offset w001
		call writeAddress
		pop dx
		
		ret
	w2rm010:
		push dx
		mov dx, offset w010
		call writeAddress
		pop dx
		
		ret
	w2rm011:
		push dx
		mov dx, offset w011
		call writeAddress
		pop dx
		
		ret
	w2rm100:
		push dx
		mov dx, offset w100
		call writeAddress
		pop dx
		
		ret
	w2rm101:
		push dx
		mov dx, offset w101
		call writeAddress
		pop dx
		
		ret
	w2rm110:
		push dx
		mov dx, offset w110
		call writeAddress
		pop dx
		
		ret
	w2rm111:
		push dx
		mov dx, offset w111
		call writeAddress
		pop dx
		
		ret
		
		
		
writeW1RM11:
	mov dl, [bx]
	and dl, 07h
	cmp dl, 00h
	je w3rm000
	cmp dl, 01h
	je w3rm001
	cmp dl, 02h
	je w3rm010
	cmp dl, 03h
	je w3rm011
	cmp dl, 04h
	je w3rm100
	cmp dl, 05h
	je w3rm101
	cmp dl, 06h
	je w3rm110
	cmp dl, 07h
	je w3rm111
	
	w3rm000:
		push dx
		mov dx, offset wm000
		call writeAddress
		pop dx
		
		ret
	w3rm001:
		push dx
		mov dx, offset wm001
		call writeAddress
		pop dx
		
		ret
	w3rm010:
		push dx
		mov dx, offset wm010
		call writeAddress
		pop dx
		
		ret
	w3rm011:
		push dx
		mov dx, offset wm011
		call writeAddress
		pop dx
		
		ret
	w3rm100:
		push dx
		mov dx, offset wm100
		call writeAddress
		pop dx
		
		ret
	w3rm101:
		push dx
		mov dx, offset wm101
		call writeAddress
		pop dx
		
		ret
	w3rm110:
		push dx
		mov dx, offset wm110
		call writeAddress
		pop dx
		
		ret
	w3rm111:
		push dx
		mov dx, offset wm111
		call writeAddress
		pop dx
		
		ret


include commands.asm

end start