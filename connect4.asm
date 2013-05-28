; Author  : Sabarinath N P
; Roll No : CS10B020

;;;;;;Below Code Implements the CONNECT 4 Game using assembly language. Check out the 'ReadMe' for the instruction on how to run and;;;;;
;;;;;;;;;;;;;;;Play it and also for the command format. This uses the naive Brute Force method to solve the Win Logic. ;;;;;;;;;;;;;;;;;;

.MODEL SMALL
.STACK 400h

.DATA

;;;;;;;;;;;;;;;;;;Strings to specify the current status of the Game and also Input Prompts;;;;;;;;;;;;;;;;;;;;
	Message db 0dh,"Enter the Command : $"
	Win1 db 0dh,"Player1 Won :) Press any key to return to Command Line..$"
	Win2 db 0dh,"Player2 Won :) Press any key to return to Command Line..$"
	Message2 db 0dh,"Game ended in a Draw.. :-| Press any key to return to Command Line..$"
	BodyTitle db "CONNECT 4$"
	Invalid db 0dh,"Invalid Command $"
	player1 db 0dh,"Player1's Turn (Blue)$"
	player2 db 0dh,"Player2's Turn (Green)$"

;;;;;;;;;;;;;;;;;;;Current Came status;;;;;;;;;;;;;;;;;;;
	gameMatrix db 36 dup(0)
	current_player db 1
	next_player db 2
	temp dw 1
	sec_temp dw 1
	colToclear db 0
	colcount db 6 dup(0)

;;;;;;;;;;;;;;;;;;;;;;Input by user;;;;;;;;;;;;;;;;;;;;;;
	player_col db 1
	player_input db 0
	player_row db 1
	command db 50 dup('$')



.CODE

START:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MACROS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;;;;;;;;;;;;;Setting the Background and Foreground colors and also the left and right co-ordinates;;;;;;;;;;;;;
	SetPageProp macro screen_size, background, top_left, bottom_right
		
		push ax
		push bx
		push cx
		push dx
		
		mov ax, screen_size
		mov bh, background
		mov cx, top_left
		mov dx, bottom_right
		int 10h
		
		pop dx
		pop cx
		pop bx
		pop ax
		
	ENDM
	
;;;;;;;;;;;;;;;;;To set a box type blinking cursor position at the specified row and col;;;;;;;;;;;;;;;;;;
	SetCursor macro row, col, page_no
	
		push dx
		push bx
		push ax
		push cx
		
		mov ch,6
		mov cl,7
		mov ah,1
		int 10h
		
		mov dh, row
		mov dl, col
		mov bh, page_no
		mov ah, 2
		int 10h
		
		pop cx
		pop ax
		pop bx
		pop dx
		
	ENDM
	
;;;;;;;;;;;;;;;;;;;;;;;To Print String prompts and messages;;;;;;;;;;;;;;;;;;;;;;
	PromptString macro prompt
		
		push dx
		push ax
		
		lea dx, prompt
		mov ah, 09h
		int 21h
		
		pop ax
		pop dx
		
	ENDM
	
;;;;;;;;;;;;;;;;;;;For Getting the user input;;;;;;;;;;;;;;;;;;;;;
	GetString macro variable
	
		push dx
		push ax
		
		lea dx, variable
		mov ah, 0ah
		int 21h
		
		pop ax
		pop dx
		
	ENDM
	
;;;;;;;;;;;;;;;;;;;For coloring a single pixel at the required location;;;;;;;;;;;;;;;;;;;;
	ColorPixel macro row, col, color
		push ax
		push dx
		push cx
		
		mov al, color
		mov cx, col
		mov dx, row
		mov ah, 0ch
		int 10h
		
		pop cx
		pop dx
		pop ax
		
	ENDM
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; The Main Code ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;Moving the DATA into data Segment;;;;;;;;;;;;;;
	mov ax,@data 
	mov ds,ax

;;;;;;;;;;;;;;;;;;;;;;The Initial Setup includes the page coloring, drawing the grids and array initialization;;;;;;;;;;;;;;;;;;;;;;
	StartGame :
	    
	    CALL ScreenSetup
	;;; rows : 207 cols: 319	
		CALL GridAndLineColoring
		CALL ArrIni

;;;;;;;;;;;;;;;;;;;;;The Initial Filtering of Commands Starts Here;;;;;;;;;;;;;;;;;;;;;
		Game :
		    
		    CALL StartUp							;;;;;;;;Displaying Input Prompt and other Messages;;;;;;
			FirstLayerCheck :						;;;;;;;;;Initial Filtering for special Commands;;;;;;;;;
			    
			    mov dl, 'N'
				cmp [si], dl
				jz StartGame

			    mov dl, '$'
        		cmp [si],dl
        		jz Game
        										
				mov dl, 'S'
				cmp [si],dl
				jz WaitForChar
				
				mov dl, 'E'
				cmp [si], dl
				jz Exit
				
				mov dl, command + 1
		        cmp dl, 5h
				jnz Game
				
;;;;;;;;;;;;;;;;;;The Validation of commands and the main Game Logic goes here;;;;;;;;;;;;;;;;;
		PlayGame :

			CALL StorageSetup						;;;;;;;;To Store the player inputs in memory;;;;;;;;
			
			CALL CheckRegex							;;;;;;;;To check whether input command satisfies the required RegEx;;;;;;;;
			cmp temp, 0h
			jz Game
			
			CALL Check_col							;;;;;;;;Checking each column's filled size;;;;;;;;;
			cmp temp, 0h							;;;;;;;;and modifying the values of colcount and gameMatrix elements;;;;;;;;;;
			jz Game
			
			CALL DrawWin							;;;;;;;;Drawing the 'X' lines and Checking for a Win;;;;;;;;;
			cmp temp, 01h
			jz WinWaitForChar
			
			CALL CheckforDraw						;;;;;;;;If a Winning case is not present, then Checking for a Draw;;;;;;;;;;
			cmp temp, 01h
			jz WaitForChar
			
			CALL changeplayer						;;;;;;;Modifying the Game variables;;;;;;;;
			
			jmp Game
					
		WinWaitForChar:								;;;;;;;To display the Win Message;;;;;;;;;
			
			SetCursor 2, 2, 0
			cmp current_player, 01h
			jz winplayer1
			
			PromptString Win2
			jmp WaitForChar
			
			winplayer1:
				PromptString Win1
				
		WaitForChar:								;;;;;;;Waiting for the user to press a key;;;;;;;;
			mov ah, 01h
			int 21h
	Exit :
		mov ax, 03h									;;;;;Back to Text Mode;;;;;
		int 10h
		
		mov ax,4c00h ;Returns control to DOS
		int 21h ;HAS TO BE HERE! Program will crash without it!
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;PROCEDURES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;;;;;;;;;;;;;Setting Screen Mode;;;;;;;;;;;;;;;;;;
	ScreenSetup PROC
	
		push ax
		
		mov ax, 013h
		int 10h
		
		pop ax
		
		RET
	ScreenSetup ENDP
	
;;;;;;;;;;;;;;;;;For Coloring the Whole Page and for Drawing the Grid;;;;;;;;;;;;;;;;;;;;;
	GridAndLineColoring PROC
	
		push cx
		push bx
		push dx
		
		SetPageProp 0600h, 19h, 0000h, 184fh
		
		;;;;;;;;;;;;;;;Coloring Whole Page;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;Total columns = cf ;; Total row = 13f;;;;;;;;;;;;;;;
		mov cx, 00cfh
		colorRow :
			mov dx, cx
			mov cx, 0013fh
			colorColumn :
				ColorPixel dx, cx, 00h
				loop colorColumn
			mov cx, dx
			loop colorRow
		
	;;;;;;;;;;;;;;;;;For Coloring the 7 Vertical Lines;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;Inital Column = af ; Col-difference = 10h ;; Row-range = 20h to 80h;;;;;;;;;;;;;;;;;;
		mov cx, 0007h
		mov dx, 00afh				; dx - col
		colorVerticalLine :
			push cx
			mov bx, 0020h			; bx - row
			colorVertical:
				ColorPixel bx, dx, 04h
				add bx, 1
				cmp bx, 0080h
				jle colorVertical
			add dx, 10h
			pop cx
			loop colorVerticalLine

	;;;;;;;;;;;;;;;;;For Coloring the 7 horizontal Lines;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;Initial Row = 20h Row-difference = 10h ;; Col-Range = af to 10f;;;;;;;;;;;;;;;;;;;;
		mov cx, 0007h
		mov dx, 0020h				; dx - row
		colorHorizontalLine :
			push cx
			mov bx, 00afh			; bx - col
			colorHorizontal:
				ColorPixel dx, bx, 04h
				add bx, 1
				cmp bx, 010fh
				jl colorHorizontal
			add dx, 10h
			pop cx
			loop colorHorizontalLine
		
		SetCursor 1, 15, 0
		PromptString BodyTitle

		pop dx
		pop bx
		pop cx
		
		RET
	GridAndLineColoring ENDP
	
;;;;;;;;;;;;;;;;;;;Initializing the Game Variables;;;;;;;;;;;;;;;;;;;
	ArrIni PROC
	
		push cx
		push dx
		push bx
		
		mov current_player, 01h
	    mov next_player, 02h

		mov cx, 0006h
		mov bx, 0000h
		mov dl, 00h
		initialize:
			mov colcount[bx], dl
			inc bx
			loop initialize
			
		mov cx, 0024h
		mov bx, 0000h
		ini:
			mov gameMatrix[bx], dl
			inc bx
			loop ini
			
		pop bx
		pop dx
		pop cx
	RET
	ArrIni ENDP
	
;;;;;;;;;;;;;;;;Displaying the Prompt Strings;;;;;;;;;;;;;;;;;
	StartUp PROC

		mov colToclear, 22
		CALL ClearLine
		mov colToclear, 19
		CALL ClearLine
		
		SetCursor 19, 2, 0
		cmp current_player, 01h
		jnz nextline
		PromptString player1
		jmp nextline1
		
		nextline:
			PromptString player2
		
		nextline1:
			SetCursor 22, 2, 0 
		PromptString Message
		SetCursor 22, 23, 0
		GetString command
		mov dx, offset command + 2
		mov si,dx
		
        RET
	StartUp ENDP
	
;;;;;;;;;;;;;;To Store the user inputs into Memory;;;;;;;;;;;;;;;;;
	StorageSetup PROC
	
		mov dx, offset command + 2
		mov si, dx
		CALL MoveIntoStorage
		mov si, dx
	
		RET
	StorageSetup ENDP
	
;;;;;;;;;;;;;;;To accomplish the above procedure;;;;;;;;;;;;;;;;;;
	MoveIntoStorage PROC
		push ax
		push dx
		push bx
		
		mov bx, 0000h
		inc si
		mov bl, [si]
		sub bl, 030h
		mov player_input, bl
		inc si
		inc si
		mov bx, 0000h
		mov bl, [si]
		sub bl, 060h
		mov player_row, bl
		inc si
		mov bx, 0000h
		mov bl, [si]
		sub bl, 030h
		mov player_col, bl
		
		pop bx
		pop dx
		pop ax
		
		RET
	MoveIntoStorage ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;Checking for the Regular Expression;;;;;;;;;;;;;;;;
	CheckRegex PROC
	
		push bx
		push dx
		push ax
		
		mov bx, 0000h
		mov dx, 0000h
		mov temp, 1
		mov bl, [si]
		cmp bl, 'p'
		jnz return_false
		
		inc si
		mov bl, [si]
		mov dl, current_player
		add dl, 030h
		cmp bl, dl
		jnz return_false
		
		inc si
		mov bl, [si]
		cmp bl, ' '
		jnz return_false
		
		inc si
		mov bl, [si]
		mov dl, 61h
		cmp bl, dl
		jl return_false
		mov dl, 66h
		cmp bl, dl
		jg return_false
		
		inc si
		mov bl, [si]
		mov dl, 031h
		cmp bl, dl
		jl return_false
		mov dl, 036h
		cmp bl, dl
		jg return_false
		
		
		jmp return_true
		
		return_false :
			CALL PrintInvalid
			mov temp, 0
		jmp return_Exit
		
		return_true:
			CALL RemoveInvalid
			
		return_Exit :
		    pop ax
		    pop dx
			pop bx
		
		RET
	CheckRegex ENDP
	
;;;;;;;;;;;;;;;;;;For Printing the Error Message;;;;;;;;;;;;;;;;;;
	PrintInvalid PROC
	
	    SetCursor 2, 2, 0
	    PromptString Invalid
	    
	    RET
	PrintInvalid ENDP
	
;;;;;;;;;;;;;;;;;For Removing the Error Message;;;;;;;;;;;;;;;;;;
	RemoveInvalid PROC
	
	    mov colToclear, 2
	    CALL ClearLine
	    
	    RET
	RemoveInvalid ENDP
	
;;;;;;;;;;;;;;;Checking each column for its filled size;;;;;;;;;;;;;;;
	Check_col PROC
	
		push cx
		push bx
		push ax
		push dx
		
		mov temp, 01h
		mov cx, 0000h
		mov ax, 0000h
		mov dx, ax
		mov bx, ax
		
		mov bl, player_col
		sub bx, 0001h
		mov dl, player_row
		mov cl, colcount[bx]
		add cl, 01h
		cmp dl, cl
		jnz check_false
		
		mov dx, 0000h
		mov dl, player_row
		mov colcount[bx], dl
		
		mov al, dl
		sub al, 01h
		mov dh, 06h
		mul dh
		add al, bl
		mov bx, 0000h
		mov bl, al
		mov al, current_player
		mov gameMatrix[bx], al
		
		jmp check_true
		
		check_false:
			CALL PrintInvalid
			mov temp, 00h
			jmp check_Exit
		check_true:
			CALL RemoveInvalid
		
		check_Exit:
		
		pop dx
		pop ax
		pop bx
		pop cx
		
		RET
	Check_col ENDP
	
;;;;;;;;;;;;;;;;;;Drawing the 'X's and Checking for the Win Logic;;;;;;;;;;;;;;;;
	DrawWin PROC
	
		CALL DrawLine
		;CALL printArray
		CALL WinLogic

		RET
	DrawWin ENDP
	
;;;;;;;;;;;;;;;Three cases possible for a win :  1. Column connect , 2. Row Connect , 3. Diagonal Connect ( Major or Minor );;;;;;;;;;;;
	WinLogic PROC
	
		mov temp, 01h
		
		CALL ColumnWin
		cmp sec_temp, 01h
		jz Endisfound
		
		CALL RowWin
		cmp sec_temp, 01h
		jz Endisfound
		
		CALL DiaWin
		cmp sec_temp, 01h
		jz Endisfound
		
		mov temp, 00h
		Endisfound:
			mov colToclear, 19
			CALL ClearLine
		RET
	WinLogic ENDP
 
;;;;;;;;;;;;;;;;Checking for the Connect along the Row;;;;;;;;;;;;;;;
	RowWin PROC
	
		push bx
		push cx
		push dx
		push ax
		mov ax, 0000h
		mov bx, ax
		mov dx, ax
		mov cx, ax
		mov sec_temp, 01h
		mov dl, player_col
		mov dh, player_row
		mov al, dh
		sub al, 01h
		mov cl, 06h
		mul cl
		mov dh, al
		
		add al, dl
		sub al, 01h
		mov bl, al
		mov dl, dh
		add dl, 05h
		mov ch, bl
		sub bl, 01h
		mov bh, 00h
		mov ax, 0000h
		mov cl, current_player
		loopleft:
			cmp bl, dh
			jl strtloopright
			cmp cl, gameMatrix[bx]
			jnz strtloopright
			inc ax
			dec bx
			jmp loopleft
			
		strtloopright:	
		mov bx, 0000h
		mov bl, ch
		add bl, 01h
		loopright:
			cmp bl, dl
			jg loopexit
			cmp cl, gameMatrix[bx]
			jnz loopexit
			inc ax
			inc bx
			jmp loopright
			
		loopexit:
			cmp ax, 03h
			jge rowsuccess
			mov sec_temp, 00h
		rowsuccess:
		
		pop ax
		pop dx
		pop cx
		pop bx
		RET
	RowWin ENDP
	
;;;;;;;;;;;;;;;Checking for the Connect along the Major and Minor Diagonals;;;;;;;;;;;;;;;;
	DiaWin PROC
	
		push dx
		push bx
		push ax
		push cx
		push di
		
		mov ax, 0000h
		mov bx, ax
		mov dx, ax
		mov cx, ax
		mov di, ax
		
		mov sec_temp, 01h
		mov dl, player_col
		mov dh, player_row
		sub dh, 01h
		sub dl, 01h
		mov al, dh
		mov bl, 06h
		mul bl
		add al, dl
		mov bl, al
		
		mov cl, dl
		mov ch, dh
		mov ah, bl
		mov al, current_player
		mov di, 0000h
		
		major_diagonal:
			M_upds:
				cmp al, gameMatrix[bx]
				jnz M_dowds
				add bx, 07h
				inc dl
				inc dh
				inc di
				cmp dl, 05h
				jg M_dowds
				cmp dh, 05h
				jg M_dowds
				jmp M_upds
			M_dowds:
				mov dl, cl
				mov dh, ch
				mov bl, ah
				mov bh, 00h
			M_dowdStart:
				cmp al, gameMatrix[bx]
				jnz Up_check
				sub bx, 07h
				dec dl
				dec dh
				inc di
				cmp dl, 00h
				jl Up_check
				cmp dh, 00h
				jl Up_check
				jmp M_dowdStart
				
		Up_check:
			cmp di, 05h
			jge SolutionFound
			mov dl, cl
			mov dh, ch
			mov bl, ah
			mov bh, 00h
			mov di, 0000h
			
		minor_diagonal:
			m_upwards:
				cmp al, gameMatrix[bx]
				jnz m_downwards
				add bx, 05h
				inc dh
				dec dl
				inc di
				cmp dh, 05h
				jg m_downwards
				cmp dl, 00h
				jl m_downwards
				jmp m_upwards
			
			m_downwards:
				mov dl, cl
				mov dh, ch
				mov bl, ah
				mov bh, 00h
				m_downwardsStart:
					cmp al, gameMatrix[bx]
					jnz Down_check
					sub bx, 05h
					dec dh
					inc dl
					inc di
					cmp dh, 00h
					jl Down_check
					cmp dl, 05h
					jg Down_check
					jmp m_downwardsStart
				
			Down_check:
				cmp di, 05h
				jge SolutionFound
				mov sec_temp, 00h
				
				SolutionFound:				
			
		pop di
		pop cx
		pop ax
		pop bx
		pop dx
		RET
	DiaWin ENDP
	
;;;;;;;;;;;;;;;;Checking for the Connect down the column;;;;;;;;;;;;;;;
	ColumnWin PROC
	
		push bx
		push cx
		push dx
		push ax
		
		mov sec_temp, 01h
		mov cx, 0000h
		mov bx, 0000h
		mov bl, player_col
		sub bl, 01h

		mov dl, colcount[bx]
		mov cl, 04h
		cmp dl, cl
		jl Exit_NoWin
		
		mov al, player_row
		sub al, 01h
		mov bh, 06h
		mul bh
		add al, bl
		
		mov bx, 0000h
		mov bl, al
		mov ax, 0000h
		mov dl, current_player
		mov cx, 0004h
		CheckcolWin:
			mov al, gameMatrix[bx]
			cmp al, dl
			jnz Exit_NoWin
			sub bx, 0006h
			loop CheckcolWin
		jmp foundWin
			
		Exit_NoWin:
			mov sec_temp, 00h
		foundWin :
		
		pop ax
		pop dx
		pop cx
		pop bx
		RET
	ColumnWin ENDP
	
;;;;;;;;;;;;;;;;;;;;;;;;;For Drawing the 'X's;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	DrawLine PROC
		push bx
		push ax
		push cx
		push di
		push dx
		
		mov ax, 0000h
		mov bl, player_col
		sub bl, 01h
		mov al, bl
		mov bl, 10h
		mul bl
		
		add ax, 00afh
		mov dx, ax
		mov di, ax ;; ax is not working in the loop thats why
		
		add dx, 0010h
		mov cx, 0011h
		
		push dx
		push ax
		
		mov bx, 0080h           ;; put 080h - (row -1)* 010h in bx
		mov ax, 0000h			
		mov al, player_row
		sub al, 0001h
		mov dl, 10h
		mul dl
		sub bx, ax
		
		pop ax
		pop dx
		
		mov al, 0000h
		mov al, current_player
		
		col_vary:
			ColorPixel bx, di, al
			ColorPixel bx, dx, al
			add di, 01h
			sub dx, 01h
			sub bx, 01h
			loop col_vary
			
		pop dx
		pop di
		pop cx
		pop ax
		pop bx
		RET
	DrawLine ENDP
	
;;;;;;;;;;;;;;;;Checking for the Draw ( checking whether the Last row is filled without a Win);;;;;;;;;;;;;;;;;;;;
	CheckforDraw PROC
		push cx
		push bx
		push ax
		
		mov cx, 0024h
		mov bx, 001eh
		mov temp, 01h
		mov al, 00h
		check_loop:
			cmp al, gameMatrix[bx]
			jz NoDraw
			inc bx
			loop check_loop
		SetCursor 2, 2, 0
		PromptString Message2
		jmp DrawEnd
			
		NoDraw:
			mov temp, 00h
		DrawEnd:
		pop ax
		pop bx
		pop cx
		RET
	CheckforDraw ENDP
	
;;;;;;;;;;;;;;;Changing the player turn after every successful move;;;;;;;;;;;;;;;;;
	Changeplayer PROC
	
		mov bl, current_player
		mov cl, next_player
		mov current_player, cl
		mov next_player, bl
		RET
	Changeplayer ENDP

;;;;;;;;;;;;;;To clear a particular line as specified by the 'colToclear' variable;;;;;;;;;;;;;;;;
	ClearLine PROC
		
		push ax
		push cx
		push dx
		
		SetCursor colToclear, 0, 0
		mov cx, 39
		Clear:
			mov dx, 0020h
			mov ah, 02h
			int 21h
			loop Clear
			
		pop dx
		pop cx
		pop ax
		
		RET
	ClearLine ENDP
		
	END START
