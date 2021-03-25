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
	msgHelp    db "Programa atlieka duoto failo sesioliktaini dump", 13, 10, "$"
	
	zero db 0
	varNum1 db 48
	varNum2 db 48
	
	buffer db 200h dup(0)
	positionBuffer db 13, 10, 4 dup(48), 32
	hexBuffer db 48 dup(32)
	asciiBuffer db 16 dup(0)
.code

start:
    mov dx, @data
    mov ds, dx  
	
	mov bx, 81h
	
check:
	;help simbolio /? ieskojimas, jei jis yra
	mov ax, es:[bx]
	inc bx
	
	cmp al, 13 
	je furtherStdin
	cmp al, 20h 
	je check
	cmp ax, "?/" 
	jne parameters ;sokam i parametru ieskojima
	mov ax, es:[bx] 
	cmp ah, 13
	je help ;jei newline tai isvedam pagalbos pranesima, jei ne, tai atidarom failus ir bus isvestas klaidos pranesimas
	jmp further
	
parameters:
	;iskvieciam parametru parsinimo procedura
	call readWord
	jmp further
	
help:
	mov dx, offset msgHelp ;pagalbos zinute
	mov ah, 09h
	int 21h
	
	jmp exit

furtherStdin:
	;JEIGU STANDARTINE IVESTIS
	mov dx, offset msg1 
	mov ah, 09h
	int 21h
	
	mov dx, offset SfileIn 
	mov ah, 0Ah
	int 21h
	mov bx, offset SfileIn
	call fixFile ;sutaisome failo varda kad gale butu 0
	
	mov dx, offset msg2 
	mov ah, 09h
	int 21h
	
	mov dx, offset SfileOut 
	mov ah, 0Ah
	int 21h
	mov bx, offset SfileOut
	call fixFile ;sutaisome failo varda kad gale butu 0
	
	mov ax, 3D00h ;atidarom duom faila
	mov dx, offset SfileIn + 2 
	int 21h
	jc klaida ;jei negalima atidaryti arba klaida cf=1
	mov fhIn, ax 
	
	mov ax, 3C00h ;atidarom rez faila
	xor cx, cx
	mov dx, offset SfileOut + 2 
	int 21h
	jc klaida 
	mov fhOut, ax 
	jmp beginRead

further:
	;JEIGU PER KOMANDINIUS PARAMETRUS
	mov ax, 3D00h ;atidarom duom faila
	mov dx, offset fileIn 
	int 21h
	jc klaida 
	mov fhIn, ax 
	
	mov ax, 3C00h ;atidarom rez faila
	xor cx, cx
	mov dx, offset fileOut 
	int 21h
	jc klaida 
	mov fhOut, ax 
	
	xor di, di
	jmp beginRead
klaida:
	mov ah, 09h 
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
	mov cx, 200h 
	mov dx, offset buffer
	int 21h
	mov cx, ax ;ciklui
	cmp cx, 0
	jz endRead 
	
	;;;;;;;;;ALGORITMO PRADZIA;;;;;;;;;
	mov bx, 0010h ;dalinimui
	mov ax, cx 
	xor dx, dx
	div bx ; ax/bx
	mov cx, ax 
	
	xor ax, ax
	cmp dl, 0 ;jei liekana lygi 0, tai nereik papildomos eilutes
	je loopLine
	inc cx
loopLine:
	push cx ;issaugom reiksme, kiek eiluciu is viso
	xor cx, cx 
	
	add ax, di ; pries printinant ir skaiciuojant offset pridedam absoliutu offset di
	call position 
	mov cl, 04 
	mov bx, offset positionBuffer + 2
	loopConvert:
		call convert ;iskvieciame procedura, kuri konvertuoja hex skaiciu i toki pati ascii atitikmeni
		inc bx
		loop loopConvert
	call positionPrint ;isprintinam offseto bufferi
	
	mov bx, offset buffer 
	sub ax, di 
	add bx, ax ; prie bx pridedam poslinki
	xor cx, cx
	mov cl, 16 ; ciklas vyks 16 kartu, nes hexDumpe eiluteje 16 baitu
	xor si, si
	loopParse:
		call charParse 
		inc bx
		add si, 03 ; 1 simbolis uzema 3 vietas (baitas yra 2 vietos + space simbolis)
		loop loopParse
	call hexStringPrint ; isprintinam baitu bufferi
	
	mov bx, offset buffer 
	add bx, ax ; prie bx pridedam poslinki
	xor cx, cx
	mov cl, 16 
	xor si, si
	loopWriting:
		push ax 
		mov al, [bx] ; i al idedam nuskaityta simboli
		push bx 
		mov bx, offset asciiBuffer 
		cmp al, 32 ;jei simbolis maziau nei 32 (t.y. "space" simbolis) mes i buferi nieko nedesim, nes sis simbolis neprintinamas
		jb loopWritingSkip
		mov [bx + si], al ;jei simbolis tinkamas tai i ascii bufferi idedam ta simboli
		jmp loopWritingEnd
	loopWritingSkip:
		mov al, 2Eh
		mov [bx + si], al ;idedam "."
	loopWritingEnd:
		pop bx
		pop ax
		inc bx
		inc si
		loop loopWriting
	call asciiPrint ;isprintinam gauta bufferi su ascii simboliais
	
	add ax, 0010h 
	pop cx 
	loop loopLine
	
	add di, 0200h ; jei sokam i kita bloka, tai offsetas bus ne nuo nulio o nuo +200h
	jmp beginRead 
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
	
	;;;Pavadinimo duom ir rez failu sutaisymas, kai naudojma stdin;;;
fixFile:
	push dx 
	
	xor dx, dx ;procedura padaro kad failo vardo gale butu 0
	mov dl, [bx + 1] ; baitu skaicius
	add bx, dx
	mov dx, 0
	mov [bx + 2], dx ; \n => 0	
	
	pop dx
	ret 
	
	;;;Komandines eilutes parsinimo procedura;;;
readWord:
	mov si, 81h ;pradedam nuo pirmo simbolio
	xor ax, ax
	
readStart:	
	mov ax, es:[si] 
	inc si
	
	cmp al, 20h ;ignoruojam space
	je readStart 
	
	mov bx, offset fileIn 
	
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
;;;algoritmo proceduros
position:
	push bx
	push ax ;ax saugo offset
	push cx
	push dx
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
	
	pop dx
	pop cx
	pop ax
	pop bx
	ret
	
convert:
	push bx ;si procedura tiesiog konvertuoja hex baita i ascii baita
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
	
positionPrint:
	push ax
	push bx
	push dx
	
	xor ax, ax ; si procedura isprintina offset bufferi
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov cl, 07h
	mov dx, offset positionBuffer
	int 21h
	
	pop dx
	pop bx
	pop ax
	ret
	
charParse:
	push ax
	push bx
	push dx
	push cx
	
	mov al, [bx] ;Kadangi bx buvo nuskaityto bufferio adresas, tai i al idedam 1 nuskaityta simboli
	xor bx, bx
	mov bx, offset hexBuffer 
	add bx, si ;pridedam tiek, kiek buvo baitu * 3
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
	
	pop cx
	pop dx
	pop bx
	pop ax
	ret
	
hexStringPrint:
	push ax
	push bx
	push dx
	
	xor ax, ax ;si procedura isprintina baitu bufferi
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov cl, 48
	mov dx, offset hexBuffer
	int 21h
	
	pop dx
	pop bx
	pop ax
	ret
	
asciiPrint:
	push ax
	push bx
	push dx
	
	xor ax, ax ;si procedura isprintina ascii bufferi
	mov ah, 40h
	mov bx, fhOut
	xor cx, cx
	mov cl, 16
	mov dx, offset asciiBuffer
	int 21h
	
	pop dx
	pop bx
	pop ax
	ret
	
end start