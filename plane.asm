datas segment
	plane_pos dw 150,180		;飞机位置存储
	smile_pos db 10,3,12,4,15,2,19,4,21,1,25,5,28,3,30,1,9,2,7,5,1,2,33,3,35,2,0,0		;笑脸位置存储(y,x)
	destroy	  db 0			;是否有目标
	delay_timer db 0
	timecontrol db 18		;用于控制速度快慢
	message db 'Your score:','$'
	score db 3 dup('0'),'$';分数的ASCII码，用于显示
    	score_b db 00h;分数的二进制码，用于运算
	;用于画游戏开始菜单
    	message_welcome db '*************** welcome ***************','$'
    	message_operation db "how to play:",'$'
    	message_operation1 db "move:left right up and down",'$'
    	message_operation2 db 'shoot:space bar','$'
		message_operation3 db 'score: hit(+1) escape(-5) collide(GameOver)','$'
    	message_operation4 db 'Now,you can:','$'
    	start_button db "press 'Enter' to start the game$"
    	end_button db "press 'Esc' to quit(also in the game).$"
    	message_end db '********13349152 Zhang Huajian*********','$'
	message_easy db "1.easy",'$'
	message_mid db "2.middle",'$'
	message_hard db "3.hard",'$'
	message_veryhard db "4.veryhard",'$'
	message_choose db "please choose:",'$'
	    message_over1 db '****************************','$'
		message_over2 db '*******   GAME OVER  *******','$'
    	message_over3 db '****************************','$'
datas ends

codes segment
	assume cs:codes,ds:datas


start:
    	mov al,34h   ; 设控制字值 
    	out 43h,al   ; 写控制字到控制字寄存器 
    	mov ax,0ffffh ; 中断时间设置
    	out 40h,al   ; 写计数器 0 的低字节 
    	mov al,ah    ; AL=AH 
    	out 40h,al   ; 写计数器 0 的高字节 

	mov ax,datas
	mov ds,ax
    	call help_view       
	call choose_view

	xor ax,ax			; AX = 0
	mov ds,ax			; DS = 0
	mov word ptr ds:[20h],offset Timer	; 设置时钟中断向量的偏移地址
	mov ax,cs 
	mov word ptr ds:[22h],ax		; 设置时钟中断向量的段地址=CS
		   
	mov ax,datas
	mov ds,ax  
		 
        mov ah,00H		;设置显示方式为320*200彩色图形方式
        mov al,04H
        int 10H 
        
		mov ah,02;显示分数提示
		mov bh,00
		mov dh,0
		mov dl,0
		int 10h
		mov ah,09
		mov dx,offset message
		int 21h
		
        mov bx,150   ;设置飞机初始水平位置
       	mov bp,180   ;设置飞机初始垂直位置
        mov [plane_pos],bx
        mov [plane_pos+2],bp      
		call play_smile		;画笑脸
lop3: 
      	call play_plane1	;擦除飞机轨迹
      	call play_plane		;画飞机		
      	mov cx,bx
      	mov dx,bp
again:		
		mov ah,01      ;检测是否有按键，没有的话循环检测
		int 16h
		jz again		;没有按键，显示移动，再次检测
        ;从键盘读入字符          
      	mov ah,0H	
      	int 16H
	 	  
        ;判断字符
      	cmp ah,72
      	je up
      	cmp ah,80
      	je down
      	cmp ah,75
      	je left
      	cmp ah,77
      	je right
	cmp ah,57	;空格
	je shoot
      	cmp ah,16	;Q退出
      	je quite
      	jmp lop3

up: 	sub bp,3
      	jmp lop3
down: 	add bp,3
      	jmp lop3
left: 	sub bx,3 
       	jmp lop3
right: 	add bx,3
        jmp lop3   

shoot:
	call shoot_plane
	jmp lop3

;退出程序
quite:   
	mov ah,4ch
	int 21h
    


Timer:
	push ax
	mov al,byte ptr ds:[timecontrol]
	cmp byte ptr ds:[delay_timer],al
	pop ax
	jnz	goout
	mov byte ptr ds:[delay_timer],0
	call move_smile
	;call delay2
	call play_smile		;画笑脸
goout:
	inc byte ptr [delay_timer]
	push ax
	mov al,20h			; AL = EOI
	out 20h,al			; 发送EOI到主8529A
	out 0A0h,al			; 发送EOI到从8529A
	pop ax
	iret			; 从中断返回


    
;//////////////////////////////////////
;//画玩家飞机子程序 传入参数bx设置飞机的水平位置 BP设置飞机的垂直位置   BX,BP记录飞机的位置
play_plane proc    
	push cx
	push dx
	push es
	push si
	push di
	push ax
	jmp sk

play_plane_1: dw 6,1,1,5,2,3,5,3,3,5,4,3,4,5,5,3,6,7,1,7,11,1,8,11,4,9,5,5,10,3,4,11,5,3,12,7,4,13,2,7,13,2 ;X0,Y,长度

sk: 
	mov cx,ax
	mov ax,cs
	mov es,ax
	mov di,0
         
lop2: 
	mov cx,word ptr es:[play_plane_1+di]    ;x0
        add cx,bx
        mov dx,word ptr es:[play_plane_1+di+2]   ;y
        add dx,bp
        mov si,word ptr es:[play_plane_1+di+4]    ;长度
        
     	call sp_line
     	add di,6
     	cmp di,84
     	jne lop2
     	
	;更新飞机位置
	mov ds:[plane_pos],bx
        mov ds:[plane_pos+2],bp 

     	pop ax 
     	pop di
     	pop si
     	pop es
     	pop dx
     	pop CX
   
     	ret
play_plane endp
;//////////////////////      

    
play_plane1 proc ;擦除飞机轨迹子程序 传入参数CX,DX
     
      push si
      push di
   
      inc cx
      mov si,13
      
      mov di,0
lop5: inc di
      inc dx
      call sp_line1
      cmp di,14
      jne lop5
      pop di
      pop si

      ret
play_plane1 endp
;////////////////////////////////////////

;//画笑脸
play_smile proc
	push ax
	push bx
	push cx
	push dx
	push si
	push di

	mov si,offset smile_pos
	inc si
	mov di,offset smile_pos
show_smile:	
	;设置光标位置
	mov ah,02H
	mov bh,0
	mov dh,byte ptr [si]		;Y
	mov dl,byte ptr [di]		;X
	int 10H
	;显示笑脸
        mov ah,09H
        mov al,2
        mov bl,011111001b
        mov	cx,1
        int 10H
	inc si
	inc si
	inc di
	inc di
	cmp byte ptr [si],0
	jnz show_smile
	
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
play_smile endp

;//移动笑脸，包括修改笑脸的位置坐标，擦除笑脸，检测边界（执行扣分）操作
move_smile proc
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	;call delay2	
	mov si,offset smile_pos
	inc si
	mov di,offset smile_pos
erase_smile:	
	;设置光标位置
	mov ah,02H
	mov bh,0
	mov dh,byte ptr [si]		;行
	mov dl,byte ptr [di]		;列
	int 10H
	;擦除笑脸
        mov ah,09H
        mov al,2	
        mov bl,0	;黑色，擦除笑脸
        mov cx,1
        int 10H
		
	;检测碰撞	
	mov ax,word ptr [plane_pos]	;列
	mov bl,8
	div bl 			;ax为转换后的飞机坐标
	cmp al,dl
	jz  row 
	inc al
	cmp al,dl
	jz row	
	inc al
	cmp al,dl
	jnz notexit
row:
	mov ax,word ptr [plane_pos+2]	;行
	mov bl,8
	div bl 			;ax为转换后的飞机坐标
	cmp al,dh
	jz endthegame
notexit:		
	;移动笑脸坐标	
	inc byte ptr [si]
	cmp byte ptr [si],25
	jnz goon
	mov byte ptr [si],1	;碰到边界
	xor ax,ax
	mov al,byte ptr ds:[score_b]
	cmp al,5	
	jb	endthegame		;小于5，扣分后负数，游戏结束
	;扣分
	sub al,5
	mov byte ptr ds:[score_b],al	;一个扣5分	
	push ax
	push si
	push bx
	push dx	
	mov si,offset score
	call b2asc
	mov ah,02	;显示具体分数
    mov bh,00
    mov dh,0
    mov dl,11
    int 10h
    mov ah,09
    mov dx,offset score
    int 21h
	pop dx
	pop bx
	pop si
	pop ax
	
goon:
	inc si
	inc si
	inc di
	inc di
	cmp byte ptr [si],0
	jnz erase_smile
	
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
move_smile endp

;//////////////发射子弹子程序
;入口参数 玩家飞机发射口的坐标bx+5,bp
shoot_plane proc
	push ax
	push bx
	push cx
	push dx
	push si
	push bp
	mov cx,bx
 	add cx,5	;x坐标BX+5
	mov dx,bp	;y坐标	
	dec	dx
	push dx
	;检查这一列是否有射击目标
	mov si,offset smile_pos	
lop7:
	mov ax,0
	mov al,byte ptr [si]
	cmp ax,0
	jz next
	mov bl,8
	mul bl		;40*25转换
	mov dx,9
lop8:
	cmp ax,cx	;是否同一列
	jz same
	inc ax
	dec dx
	jnz lop8
	inc si 
	inc si
	jmp lop7

same:	
	;这一列有目标,消灭
	mov byte ptr ds:[destroy],1
	push ax
	push si
	push bx
	push dx
	xor ax,ax
	mov al,byte ptr ds:[score_b]
	add al,1
	mov byte ptr ds:[score_b],al
	mov si,offset score
	call b2asc
	mov ah,02;显示具体分数
    mov bh,00
    mov dh,0
    mov dl,11
    int 10h
    mov ah,09
    mov dx,offset score
    int 21h
	pop dx
	pop bx
	pop si
	pop ax
	jmp next

next:	
	pop dx
a0: 
	;擦除炮弹轨迹，移动炮弹
	MOV BX,2	;宽度
	INC DX
a1:	MOV AH,0CH	;在绘图模式显示一点
	MOV AL,0	;颜色	
	INT 10H
	INC CX
	DEC BX
	JNZ a1		;擦除炮弹宽度
 	SUB CX,2
	MOV BX,2
	DEC DX
	
a2:	MOV AH,0CH	;在绘图模式显示一点
	MOV AL,11	;颜色	
	INT 10H
	INC CX
	DEC BX
	JNZ a2		;画出炮弹宽度
 	SUB CX,2
	CALL delay
	DEC DX
	CMP DX,6	;循环画炮弹,到顶端才停止
	JA a0
	cmp byte ptr ds:[destroy],0
	jz notdes

	;设置光标位置
	MOV AH,02H
	MOV BH,0
	MOV DH,byte ptr [si+1]		
	MOV DL,byte ptr [si]
	INT 10H
	;擦除笑脸
    MOV AH,09H
    MOV AL,2	
    MOV BL,0	;黑色，擦除笑脸
    MOV CX,1
    INT 10H
	mov byte ptr [si+1],1	;从顶端重新出现
	mov byte ptr ds:[destroy],0
notdes:	
	;最后一次擦除
	mov bp,sp
	mov cx,word ptr ss:[bp+8]
	add cx,5
	mov dx,7
	MOV AH,0CH	;在绘图模式显示一点
	MOV AL,0	;颜色	
	INT 10H
	inc cx
	MOV AH,0CH	;在绘图模式显示一点
	MOV AL,0	;颜色	
	INT 10H
	pop bp
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
shoot_plane endp

;画水平直线
;入口参数 CX相当于X0 DX相当于Y0,Y1 si图像长度 BL像素

sp_line proc
         pusH ax
         pusH bx
         MOV BL,2    ;飞机的颜色
         MOV AH,0cH
         MOV AL,BL
lop:   	 INT 10H
         inc CX
         dec si
         
         jnz lop
         pop bx
         pop ax
         ret
sp_line endp
;/////////////////////////////


;画水平直线
;入口参数 CX相当于X0 DX相当于Y0,Y1 si图像长度 BL像素
sp_line1 proc
         pusH ax
         pusH bx
         pusH bp
         pusH di
     	 MOV bp,CX
      
         MOV di,11
         MOV BL,0    ;飞机的颜色 用来擦除原来的飞机
         MOV AH,0cH
         MOV AL,BL
lop1: 	 INT 10H
         inc CX
         dec di
         
         jnz lop1
         MOV CX,bp
         
         pop di
         pop bp
         pop bx
         pop ax
         ret
sp_line1 endp
;/////////////////////////////
        

;画垂直直线
;入口参数 CX相当于X0 DX相当于y0 si图像长度 BL像素

sp_line2 proc
         pusH ax   
         MOV AH,0cH
         MOV AL,BL
lop6:   INT 10H
         inc dx
         dec si
         jnz lop6
         pop ax
         ret
sp_line2 endp
;/////////////////////////////




;/////////////////延时
delay proc 
	pusH dx
	pusH CX

	MOV CX,02H
sleep2:
	MOV dx,02f0H ;让程序暂停一段时间

sleep1: 
	dec dx
	CMP dx,0
	jne sleep1

	dec CX
	CMP CX,0
	jne sleep2

	pop CX
	pop dx
	ret
delay endp
;//////////////////

;/////////////////延时
delay2 proc 
	push dx
	push cx

	MOV CX,20H
sleep4:
	MOV dx,0ffffH ;让程序暂停一段时间

sleep3: 
	dec dx
	CMP dx,0
	jne sleep3

	dec CX
	CMP CX,0
	jne sleep4

	pop cx
	pop dx
	ret
delay2 endp
;//////////////////

help_view proc  ;显示开始菜单
     call clearscreen ;清屏
	 mov ah,02
	 mov bh,00
	 mov dh,04
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_welcome
	 int 21h	 
	 mov ah,02
	 mov bh,00
	 mov dh,06
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_operation
	 int 21h	 
	 mov ah,02
	 mov bh,00
	 mov dh,08
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_operation1
	 int 21h	 
	  mov ah,02
	 mov bh,00
	  mov dh,10
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_operation2
	 int 21h	 
	  mov ah,02
	 mov bh,00
	  mov dh,12
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_operation3
	 int 21h
	  mov ah,02
	 mov bh,00
	  mov dh,14
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_operation4
	 int 21h
	  mov ah,02
	 mov bh,00
	  mov dh,16
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset start_button
	 int 21h
	  mov ah,02
	 mov bh,00
	  mov dh,18
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset end_button
	 int 21h 
	  mov ah,02
	 mov bh,00
	  mov dh,20
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_end
	 int 21h
	 ;检查是否有键被按下
checkbutton:
	 mov ah,01
	 int 16h
	 jz checkbutton
	 mov ah,0
	 int 16h
	 cmp ah,1ch;回车键
	 je startthegame
	 cmp ah,01h;Esc键
	 je endthegame
	 jmp checkbutton
startthegame:
     call clearscreen ;清屏
	 ret
help_view endp
;-------------------------------------------------------------------

choose_view proc  ;显示难度选择菜单
	 mov ah,02
	 mov bh,00
	 mov dh,04
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_easy
	 int 21h	 
	 mov ah,02
	 mov bh,00
	 mov dh,06
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_mid
	 int 21h	 
	 mov ah,02
	 mov bh,00
	 mov dh,08
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_hard
	 int 21h	 
	  mov ah,02
	 mov bh,00
	  mov dh,10
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_veryhard
	 int 21h
	  mov ah,02
	 mov bh,00
	  mov dh,12
	 mov dl,23
	 int 10h
	 mov ah,09
	 mov dx,offset message_choose
	 int 21h	 
	 ;检查是否有键被按下
checkbutton2:
	 mov ah,01
	 int 16h
	 jz checkbutton2
	 mov ah,0
	 int 16h
	 cmp al,'1'
	 je easy
	 cmp al,'2'
	 je middle
	 cmp al,'3'
	 je hard
	 cmp al,'4'
	 je veryhard
	 jmp checkbutton2

easy:
	mov byte ptr [smile_pos+12],0
	mov byte ptr [smile_pos+13],0
	mov byte ptr [timecontrol],18
	jmp sta
middle:
	mov byte ptr [smile_pos+18],0
	mov byte ptr [smile_pos+19],0	 
	mov byte ptr [timecontrol],15 
	jmp sta
hard:
	mov byte ptr [timecontrol],11 
	jmp sta
veryhard:
	mov byte ptr [timecontrol],2
sta:    
	call clearscreen ;清屏
	ret
choose_view endp
;-------------------------------------------------------------------



;-------------------------------------------------------------------
clearscreen proc;清屏
	push ax
	push bx
	push cx
	push dx
	mov ah,06
	mov al,00
	mov bh,07
	mov ch,00
	mov cl,00
	mov dh,24
	mov dl,79
	int 10h
	pop dx
	pop cx
	pop bx
	pop ax
	ret
clearscreen endp
;----------------------------------------------------------------------
;-----------------------------------------------------------------------
b2asc proc ;二进制码转化为ascii码
	pushf
	push bx
	push dx
	mov bx,10
	mov byte ptr [si],'0'
	inc si
	mov byte ptr [si],'0'
	inc si
	mov byte ptr [si],'0'
	;add si,2 ;这个视有几个ASCII码而定，显示三位时定为二
 b2a_loop:
     xor dx,dx
     div bx
     or dx,30h
     mov [si],dl
     dec si
     cmp ax,0
     ja b2a_loop
     pop dx
     pop bx
     popf
     ret
b2asc endp


endthegame:
	 call delay2
	 mov ah,00
	 mov al,00
	 int 10h
	 call clearscreen ;清屏
	 mov ah,02
	 mov bh,00
	 mov dh,9
	 mov dl,6
	 int 10h
	 mov ah,09
	 mov dx,offset message_over1
	 int 21h	 
	 mov ah,02
	 mov bh,00
	 mov dh,11
	 mov dl,6
	 int 10h
	 mov ah,09
	 mov dx,offset message_over2
	 int 21h	 
	 mov ah,02
	 mov bh,00
	 mov dh,13
	 mov dl,6
	 int 10h
	 mov ah,09
	 mov dx,offset message_over3
	 int 21h	 


CODES ends
end START
