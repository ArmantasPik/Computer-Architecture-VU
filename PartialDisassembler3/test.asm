.model tiny

.data
.code
org 100h

start:
	
	mul byte ptr [bx+si]
	mul dh
	mul byte ptr [BX]
	mul byte ptr [BP+di+50h]
	mul byte ptr [BX+5000h]
	
	mul word ptr es:[BP+di+50h]
	mul word ptr [BX+5000h]
	mul dx
	
	imul ah
	imul dl
	imul byte ptr[BP+di]
	imul byte ptr[BX]
	
	imul word ptr[BP+di+50h]
	imul word ptr[BX+5000h]
	imul cx
	imul dx
	
	shl al, 01h
	shl ax, 01h
	shl byte ptr[DI], 01h
	shl word ptr[bx], 01h
	
	mov cx, 0005h
	shl al, cl
	shl ax, cl
	shl byte ptr cs:[DI], cl
	shl word ptr es:[bx], cl
	shl byte ptr[DI + 5680h], cl
	shl word ptr[bx + 68h], cl
	
	or al, 05h
	or ax, 6482h
	or byte ptr [bx+si+50h], 0E5h
	or es:[81h], ax
	or ss:[bx], dl
	or ds:[bp+di+5025h], dl
	or ax, [bx+si+7851h]
	or ss:[81h], al
	
	pushf
	clc
	stc
	cmc
	cld
	std
	cli
	
	ret 0101h
	retf 0101h
	ret
	retf
label1:
	popf
	

end start
	