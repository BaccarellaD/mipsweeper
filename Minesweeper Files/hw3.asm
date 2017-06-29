##############################################################
# Homework #3
# name: MY_NAME
# sbuid: MY_SBU_ID
##############################################################


.eqv YELLOWGRAY 0Xb7
.eqv REDWHITE   0X9F
.eqv BLACKGRAY	0x70

.eqv BLACK 			0x0
.eqv RED			0x1
.eqv GREEN			0x2
.eqv BROWN			0x3
.eqv BLUE			0x4
.eqv MAGENTA		0x5
.eqv CYAN			0x6
.eqv GRAY			0x7
.eqv DARK_GRAY  	0x8
.eqv BRIGHT_RED 	0x9
.eqv BRIGHT_GREEN	0xA
.eqv YELLOW			0xB
.eqv BRIGHT_BLUE	0xC
.eqv BRIGHT_MAGENTA 0xD
.eqv BRIGHT_CYAN	0xE
.eqv WHITE			0xF


.macro reveal_cell_mac($row, $col, $cell_array)	#safe -> Returns $v0 [1 = blank cell, 0 = occupied]
	
	addi $sp, $sp, -4
	sw   $ra,  ($sp)
	
	add $a0, $row, $0			#loads row
	add $a1, $col, $0			#loads col
	add $a2, $cell_array, $0	#loads cell_array
	
	jal reveal_cell
	
	lw   $ra,  ($sp)	#restores return address
	addi $sp, $sp, 4

.end_macro

.macro set_cell_mac($row, $col, $icon, $fg, $bg) #register, register, im, im, im
	
	sw $row, row_store
	#sb $col, col_store
	
	addi $sp, $sp, -24	#5 words + 2 registers for saving
	sw   $row, ($sp)
	sw   $col, 4($sp)
	li   $row, $icon	#icon is put in row register
	sw   $row, 8($sp)
	li   $row, $fg		#fg is put in row register
	sw   $row, 12($sp)
	li   $row, $bg		#bg is put in row register
	sw   $row, 16($sp)
	sw   $ra,  20($sp)	#stores return address
	
	
	lw   $row, row_store	#restores $row register
	
	jal set_cell			#calls set cell function
	
	lw  $ra, 20($sp)		
	addi $sp, $sp, 24
	
.end_macro

.macro changeBox($row, $column, $icon, $color) #color in background - foreground
	addi $sp, $sp, -16
	sw   $s1,  ($sp)
	sw   $s2,  4($sp)
	sw   $s3,  8($sp)
	sw   $s4, 12($sp)
	
	li  $s1, $row
	li  $s4, 20
	mul $s2, $s1, $s4
	li  $s1, $column
	li  $s4, 2
	mul $s3, $s1, $s4
	
	li $s1, 0xFFFF0000
	
	add  $s1, $s1, $s2
	add  $s1, $s1, $s3
	addi $s2, $s1, 1
	
	li   $s3, $icon
	sb   $s3,  ($s1)
	li   $s3, $color
	sb   $s3, ($s2)
	
	lw   $s1,  ($sp)
	lw   $s2,  4($sp)
	lw   $s3,  8($sp)
	lw   $s4, 12($sp)
	addi $sp, $sp, 16
.end_macro

.macro setAll($icon, $color)
	
	addi $sp, $sp, -16
	sw   $s1,  ($sp)
	sw   $s2,  4($sp)
	sw   $s3,  8($sp)
	sw   $s4, 12($sp)
	
	li $s1, 0
	li $s2, 0xFFFF0000
	
	setAllLoop:
		beq $s1, 100 doneSetAllLoop
		
		li   $s3, $icon
		sb   $s3,  ($s2)
		addi $s2, $s2, 1
		li   $s3, $color
		sb   $s3, ($s2)
		addi $s2, $s2, 1
		
		addi $s1, $s1, 1
		j setAllLoop
	doneSetAllLoop:
	
	
	lw   $s1,  ($sp)
	lw   $s2,  4($sp)
	lw   $s3,  8($sp)
	lw   $s4, 12($sp)
	addi $sp, $sp, 16


.end_macro



.text

##############################
# PART 1 FUNCTIONS
##############################

smiley:
    #Define your code here
    
    setAll('\0', 0x0F)
    
    
    
    changeBox(2, 3, 'b', YELLOWGRAY)
    changeBox(3, 3, 'b', YELLOWGRAY)
    changeBox(2, 6, 'b', YELLOWGRAY)
    changeBox(3, 6, 'b', YELLOWGRAY)
    
    changeBox(6, 2, 'e', REDWHITE)
    changeBox(7, 3, 'e', REDWHITE)
    changeBox(8, 4, 'e', REDWHITE)
    changeBox(8, 5, 'e', REDWHITE)
    changeBox(7, 6, 'e', REDWHITE)
    changeBox(6, 7, 'e', REDWHITE)
   	
    
	jr $ra

##############################
# PART 2 FUNCTIONS
##############################

open_file: #(int fileName)
    #Define your code here
    
    #a0 is file name, sent in, keep it there
    li $a1, 0        # Open for reading
	li $a2, 0
	li $v0, 13
	syscall 	#returns -1 for error in $v0
    
    jr $ra

close_file: #(int fileName)
    #Define your code here
    li $v0, 16
    syscall 	#returns -1 for error in $v0
    jr $ra

load_map: #(int flag)

	#allocate s registers
	addi $sp, $sp, -8
	sb   $s0,  ($sp)
	sb   $s1,  4($sp)
	
	add $s0, $a1, $0	 #put CELLS ARRAY location into $s0
	la  $s1, map_buffer  #put INPUT BUFFER into $s1
	
	li $v0, 14
	#a0 already good for descriptor
	add $a1, $s1, $0
	li  $a2, 999	#max 999 bytes read
	syscall
	
	bltz $v0, invalidFileError
	
	add $t0, $s1, $0	#stores start of buffer location into $t0
	
	#$t0 -> start of text buffer location
	#$t1 -> cur char

	li $t2, -1	#Cur Row

	bombInitializationLoop:
		lb   $t1, ($t0)
		beqz $t1, done_bombs_Ok				#char is null, done with iteration
		ble  $t1, ' ', iterate_place_bomb	#if less than or equal to space, white space char
		blt  $t1, '0', invalidFileError		#if less than 0 not valid
		bgt  $t1, '9', invalidFileError		#if greater than 9 not valid
			
			bne $t2, -1, placeInCol
				addi $t2, $t1, -48			#char - '0' 	#place cur char into row store
				j iterate_place_bomb		#and then iterate
			placeInCol:
			
				addi $t1, $t1, -48	#char - '0' (get numeric value)
				
				li  $t5, 10
				mul $t4, $t2, $t5	# offset = row * 10
				add $t4, $t4, $t1	# offset = offset + col

				add $t4, $t4, $s0	# cell_pos = offset + inital buffer location
				
				lb  $t5, ($t4)
				ori $t5, $t5, 0x20	#turns on bomb bit
				sb  $t5, ($t4)		#stores cell again

				li  $t2, -1
		
		iterate_place_bomb:
		
		addi $t0, $t0, 1	#iterate cell location
		j bombInitializationLoop
		
	done_bombs_Ok:

	#put check that both are -1

	beq $t2, -1, bomb_coordinates_ok	#if row is not -1, odd number of coordinates,  error
		j invalidFileError				#return with error
	bomb_coordinates_ok: #continue from here!
	
	###################################### FROM HERE OK #################################
	
	add $t0, $s0, $0	#loads start of CELL LOCATION into $t0
	li  $t1, 0			#ROW count = 0
	li  $t2, 0			#COL count = 0
	
	adjCellInitializationLoop:
		
		li $t3, 0			#num TOUCHING BOMBS = 0
		lb $t4, ($t0)		#gets CUR CELL
		
		#TOP LEFT CHECK
		beq $t1, 0, skipTopLeftCheck	#row 0
		beq $t2, 0, skipTopLeftCheck	#col 0
			addi $t5, $t0, -11			#CHECK CELL location
			lb   $t5, ($t5)				#CHECK CELL value
			andi $t5, $t5, 0x0020		#pull only bomb bit
			
			beqz $t5, skipTopLeftCheck	#if 0 in bomb bit, skip inc
				addi $t3, $t3, 1		#touchCount++
		skipTopLeftCheck:
		
		#TOP CHECK
		beq $t1, 0, skipTopCheck		#row 0
			addi $t5, $t0, -10			#CHECK CELL location
			lb   $t5, ($t5)				#CHECK CELL value
			andi $t5, $t5, 0x0020		#pull only bomb bit
			
			beqz $t5, skipTopCheck	#if 0 in bomb bit, skip inc
				addi $t3, $t3, 1		#touchCount++
		skipTopCheck:
		
		#TOP RIGHT
		beq $t1, 0, skipTopRightCheck	#row 0
		beq $t2, 9, skipTopRightCheck	#col 9
			addi $t5, $t0, -9			#CHECK CELL location
			lb   $t5, ($t5)				#CHECK CELL value
			andi $t5, $t5, 0x0020		#pull only bomb bit
			
			beqz $t5, skipTopRightCheck	#if 0 in bomb bit, skip inc
				addi $t3, $t3, 1		#touchCount++
		skipTopRightCheck:
		
		#RIGHT
		beq $t2, 9, skipRightCheck		#col 9
			addi $t5, $t0, 1			#CHECK CELL location
			lb   $t5, ($t5)				#CHECK CELL value
			andi $t5, $t5, 0x0020		#pull only bomb bit
			
			beqz $t5, skipRightCheck	#if 0 in bomb bit, skip inc
				addi $t3, $t3, 1		#touchCount++
		skipRightCheck:
		
		#BOTTOM RIGHT
		beq $t1, 9, skipBottomRightCheck	#row 9
		beq $t2, 9, skipBottomRightCheck	#col 9
			addi $t5, $t0, 11				#CHECK CELL location
			lb   $t5, ($t5)					#CHECK CELL value
			andi $t5, $t5, 0x0020			#pull only bomb bit
			
			beqz $t5, skipBottomRightCheck		#if 0 in bomb bit, skip inc
				addi $t3, $t3, 1			#touchCount++
		skipBottomRightCheck:
		
		#BOTTOM
		beq $t1, 9, skipBottomCheck			#row 9
			addi $t5, $t0, 10				#CHECK CELL location
			lb   $t5, ($t5)					#CHECK CELL value
			andi $t5, $t5, 0x0020			#pull only bomb bit
			
			beqz $t5, skipBottomCheck		#if 0 in bomb bit, skip inc
				addi $t3, $t3, 1			#touchCount++
		skipBottomCheck:
		
		#BOTTOM LEFT
		beq $t1, 9, skipBottomLeftCheck		#row 9
		beq $t2, 0, skipBottomLeftCheck		#col 0
			addi $t5, $t0, 9				#CHECK CELL location
			lb   $t5, ($t5)					#CHECK CELL value
			andi $t5, $t5, 0x0020			#pull only bomb bit
			
			beqz $t5, skipBottomLeftCheck	#if 0 in bomb bit, skip inc
				addi $t3, $t3, 1			#touchCount++
		skipBottomLeftCheck:
		
		#LEFT
		beq $t2, 0, skipLeftCheck			#col 0
			addi $t5, $t0, -1				#CHECK CELL location
			lb   $t5, ($t5)					#CHECK CELL value
			andi $t5, $t5, 0x0020			#pull only bomb bit
			
			beqz $t5, skipLeftCheck			#if 0 in bomb bit, skip inc
				addi $t3, $t3, 1			#touchCount++
		skipLeftCheck:
		
		#check if final loop
		bne $t1, 9, skipEndInitCheck		#row 9
		bne $t2, 9, skipEndInitCheck		#col 9
			or $t4, $t4, $t3				#append touchCount onto curcell
			sb $t4, ($t0)					#store appended val
			j endCellInitLoop
		skipEndInitCheck:
		
		#check if on last col
		bne $t2, 9, skipRowInc
			li   $t2, 0			#col is 0
			addi $t1, $t1, 1	#row is next row
			or $t4, $t4, $t3			#append touchCount onto curcell
			sb $t4, ($t0)				#store appended val
			addi $t0, $t0, 1			#increment cell array by 1
			j adjCellInitializationLoop
		skipRowInc:
			addi $t2, $t2, 1
			or $t4, $t4, $t3			#append touchCount onto curcell
			sb $t4, ($t0)				#store appended val
			addi $t0, $t0, 1			#increment cell array by 1
			j adjCellInitializationLoop
	endCellInitLoop:
	
	#restore s registers
	lb   $s0,  ($sp)
	lb   $s1,  4($sp)
	addi $sp, $sp, 8
	
	li $v0, 0	#sets $v0 to 0 just to be safe
	
    jr $ra
    
    invalidFileError:
    	#restore s registers
		lb   $s0,  ($sp)
		lb   $s1,  4($sp)
		addi $sp, $sp, 8
    	
    	li $v0, -1
    	jr $ra

##############################
# PART 3 FUNCTIONS
##############################

init_display:
    #Define your code here
    setAll(0, BLACKGRAY)
    changeBox(0, 0, 0, YELLOWGRAY)
    
    li $t0, 0				#set cursor postion to (0,0)
    sw $t0, cursor_row	
    sw $t0, cursor_col
    
    jr $ra

set_cell: #uses 5 args, puts on stack (row, col, char, fg color, bg color)
									  #starts at 16
    
    addi $sp, $sp, -16
	sw   $s1,  ($sp)
	sw   $s2,  4($sp)
	sw   $s3,  8($sp)
	sw   $s4, 12($sp)
	
	lb  $s1, 16($sp)			#row inv check
	blt $s1, 0, invalidCellArg
	bgt $s1, 9, invalidCellArg
	
	lb  $s1, 20($sp)			#col inv check
	blt $s1, 0, invalidCellArg
	bgt $s1, 9, invalidCellArg
	
	lb  $s1, 28($sp)			#fg inv check
	blt $s1, 0, invalidCellArg
	bgt $s1, 15, invalidCellArg
	
	lb  $s1, 32($sp)			#bg inv check
	blt $s1, 0, invalidCellArg
	bgt $s1, 15, invalidCellArg
	
	
	lb  $s1, 16($sp)	#loads row into s1	
	li  $s4, 20			#row offset by x20
	mul $s2, $s1, $s4
	lb  $s1, 20($sp)	#loads col into s1
	li  $s4, 2			#col offset x2
	mul $s3, $s1, $s4
	
	li $s1, 0xFFFF0000	#mimo start address
	
	add  $s1, $s1, $s2	#address = start address + row offset
	add  $s1, $s1, $s3  #address = address + col offset [FOR CHAR]
	addi $s2, $s1, 1	#adress + 1 [FOR COLOR]
	
	lb   $s3, 24($sp)	#loads char into s3
	sb   $s3,  ($s1)	#stores char byte

	lb	 $s3, 32($sp)	#loads background color into $s3
	sll  $s3, $s3, 4	#makes room for foreground color
	lb	 $s1, 28($sp)	#loads foreground color into $s1
	or	 $s3, $s3, $s1	#appends $s3 with $s1
	sb   $s3, ($s2)		#stores color byte
	
	li $v0, 0	#argurments valid
	
	j skipInvalidSetCell
		invalidCellArg:
		li $v0, -1
	skipInvalidSetCell:
	
	
	lw   $s1,  ($sp)
	lw   $s2,  4($sp)
	lw   $s3,  8($sp)
	lw   $s4, 12($sp)
	addi $sp, $sp, 16
    
    
    jr $ra

reveal_map: #(int game_status, byte[] cell_array)
    #Define your code here
    addi $sp, $sp, -12	#store s0, s1, $ra
    sw   $s0, 0($sp)
    sw   $s1, 4($sp)
    sw   $ra, 8($sp)
    
    add  $s0, $a0, $0	#s0 is now GAME STATUS
    add  $s1, $a1, $0   #s1 is now START OF CELL ARRAY LOCATION
    
    beqz $s0, revealFinished	#game is still ongoing, just return
    bne  $s0, 1, gameNotWon		#if status is not 1, then game is lost
    	jal smiley					#display smily
    	j revealFinished			#done son
    gameNotWon:
    #if made it to here, then game lost
    
    li $t0, 0	#start at row 0, ROW
    li $t1, 0	#start at col 0, COL
    
    add $t2, $s1, $0	#move start_cell location to $t2, CURCELL_LOCATION
    
    revealLoop:
    	
    	reveal_cell_mac($t0, $t1, $s1)	#row, col, cell_array_start
    	
    	bne $t0, 9, skipEndCheck	#skip check if row or col != 9
		bne $t1, 9, skipEndCheck
			j endRevealLoop
		skipEndCheck:
	
		bne $t1, 9, skipNextRowInc	#if($col != 9)
			li   $t1, 0 		#$col == 0
			addi $t0, $t0, 1	#$row++
			addi $t2, $t2, 1	#$curCellLocation++
			j revealLoop
		
		skipNextRowInc:
			addi $t1, $t1, 1	#$col++
			addi $t2, $t2, 1	#$curCellLocation++
			j revealLoop
    
	#loop End -------------
    endRevealLoop:
    
    #just set exploded
    lw $t0, cursor_row	#load row and column for current cursor pos
    lw $t1, cursor_col
    set_cell_mac($t0, $t1, 'E', WHITE, BRIGHT_RED) #set cursor exploded
    
    revealFinished:
    lw   $s0, 0($sp) #restore
    lw   $s1, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    
    jr $ra


##############################
# PART 4 FUNCTIONS
##############################

# a0 - cells array
# a1 - char input
#return v0 (0 valid, -1 invalid)

perform_action:
    addi $sp, $sp, -16		#allocate 4 words
    sw	 $s0, ($sp)
    sw	 $s1, 4($sp)
    sw	 $s2, 8($sp)
    sw	 $ra, 12($sp)
    
    add $s0, $a0, $0	# $s0 is CELL ARRAY START LOCATION
    add $s1, $a1, $0	# $s1 is CHAR INPUT
    
    li $v0, 0			# safe $v0 return
    
    lw $t0, cursor_row
    lw $t1, cursor_col
    
    beq $s1, 'f', pa_flag_toggle
    beq $s1, 'F', pa_flag_toggle
    
    beq $s1, 'r', pa_reveal
    beq $s1, 'R', pa_reveal
    
    beq $s1, 'w', pa_move_up
    beq $s1, 'W', pa_move_up
    
    beq $s1, 'a', pa_move_left
    beq $s1, 'A', pa_move_left
    
    beq $s1, 'd', pa_move_right
    beq $s1, 'D', pa_move_right
    
    beq $s1, 's', pa_move_down
    beq $s1, 'S', pa_move_down
    
    j return_with_error_pa #at this point is invalid input, return with error
    
    #FLAG
    
    pa_flag_toggle:
    	
    	li  $t3, 10			#t2 is TOTAL OFFSET
    	mul $t2, $t0, $t3	#mult row by 10
    	add $t2, $t2, $t1	#add row offset + col
    	add $t2, $t2, $s0	#add total offset to start of cell array to get CELL LOCATION
    	lb  $t3, ($t2)		#get CELL
    	
    	andi $t4, $t3, 0x40						#pulls REVEAL BIT
    	beq	 $t4, 0x40, return_with_error_pa	#cell already revealed, can't put flag down
    	andi $t4, $t3, 0x10						#pulls $t4 FLAG BIT
    	bne  $t4, 0x10,	pa_flag_off				#if equal flag is on, otherwise branch -> turn off
    		#FLAG IS ON -> TURN OFF
    		
    		andi $t4, $t3, 0x40										#pulls REVEAL BIT
    		bne	 $t4, 0x40, flag_toggle_place_sqaure				#cell not already revealed, replace with square
    			#cell has been revealed already, reveal again!
    			reveal_cell_mac($t0, $t1, $s0)
    			j turn_flag_bit_off
    			
    		flag_toggle_place_sqaure:
    			#cell has NOT been revealed already, put blank sqaure!	
    			set_cell_mac($t0, $t1, 0, BLACK, GRAY)	#puts blank sqaure
    			
    		turn_flag_bit_off:
    		andi $t3, $t3, 0xEF							#and flag bit with 1110 1111
    		sb	 $t3, ($t2)								#store new byte
    		j 	return_from_perform_action				#done -> return		
    	pa_flag_off:
    		#FLAG IS OFF -> TURN ON
    		set_cell_mac($t0, $t1, 'F', BRIGHT_BLUE, YELLOW)	#updates display
    		ori  $t3, $t3, 0x10						#or flag bit with 0001 0000
    		sb	 $t3, ($t2)							#store new byte
    		j return_from_perform_action			#done -> return
    
    # Reveal
    pa_reveal:
    
    	li  $t3, 10			#t2 is TOTAL OFFSET
    	mul $t2, $t0, $t3	#mult row by 10
    	add $t2, $t2, $t1	#add row offset + col
    	add $t2, $t2, $s0	#add total offset to start of cell array to get CELL LOCATION
    	lb  $t3, ($t2)		#get CELL
    	
    	andi $t4, $t3, 0x10								#pulls $t4 FLAG BIT
    	beq  $t4, 0x10,	return_with_error_pa			#if flag bit is on, can't reveal, invalid
    	
    	andi $t4, $t3, 0x40								#pulls REVEAL BIT
    	beq	 $t4, 0x40, return_with_error_pa			#cell already revealed, can't reveal again
    	
    	
    		reveal_cell_mac($t0, $t1, $s0)
    		beqz $v0, notEmptyCell
    		
    			add  $a0, $s0, $0	#load cell_array
    			add  $a1, $t2, $0	#load cell_location (USE THIS I THINK)
    			jal search_cells
    		
    		j return_from_perform_action
    		
    	notEmptyCell:
    			
    		j return_from_perform_action
    		
    # Move up
    pa_move_up:
    	beq $t0, 0, return_with_error_pa	#if at top, return with error
    	
    	li  $t3, 10			#t2 is TOTAL OFFSET
    	mul $t2, $t0, $t3	#mult row by 10
    	add $t2, $t2, $t1	#add row offset + col
    	add $t2, $t2, $s0	#add total offset to start of cell array to get CELL LOCATION
    	lb  $t3, ($t2)		#get CELL
    	
    	andi $t4, $t3, 0x10								#pulls $t4 FLAG BIT
    	beq  $t4, 0x10,	replace_move_up_with_flag		#if flag bit is on, replace with flag
    	
    	andi $t4, $t3, 0x40								#pulls REVEAL BIT
    	bne	 $t4, 0x40, replace_move_up_with_square		#cell not already revealed, replace with square
    	
    		reveal_cell_mac($t0, $t1, $s0)		#otherwise reveal cell
    		j shift_cursor_up
    		
    	replace_move_up_with_square:
    		
    		set_cell_mac($t0, $t1, 0, BLACK, GRAY)	#replace with standard background box
    		j shift_cursor_up
    		
    	replace_move_up_with_flag:
    		set_cell_mac($t0, $t1, 'F', BRIGHT_BLUE, GRAY)	#places flag
    		j shift_cursor_up
    		
    	shift_cursor_up:
    	
    	addi $t0, $t0, -1		#move cursor up a row
    	sw	 $t0, cursor_row	#store moved cursor
    	
    	set_cell_mac($t0, $t1, 0, GRAY, YELLOW)
    	
    	j return_from_perform_action
    	
    # Move left	
    pa_move_left:
    	beq $t1, 0, return_with_error_pa	#if at far left, return with error
    	
    	li  $t3, 10			#t2 is TOTAL OFFSET
    	mul $t2, $t0, $t3	#mult row by 10
    	add $t2, $t2, $t1	#add row offset + col
    	add $t2, $t2, $s0	#add total offset to start of cell array to get CELL LOCATION
    	lb  $t3, ($t2)		#get CELL
    	
    	andi $t4, $t3, 0x10								#pulls $t4 FLAG BIT
    	beq  $t4, 0x10,	replace_move_left_with_flag		#if flag bit is on, replace with flag
    	
    	andi $t4, $t3, 0x40									#pulls REVEAL BIT
    	bne	 $t4, 0x40, replace_move_left_with_square		#cell not already revealed, replace with square
    	
    	
    		reveal_cell_mac($t0, $t1, $s0)		#otherwise reveal cell
    		j shift_cursor_left
    		
    	replace_move_left_with_square:
    		
    		set_cell_mac($t0, $t1, 0, BLACK, GRAY)	#replace with standard background box
    		j shift_cursor_left
    		
    	replace_move_left_with_flag:
    		set_cell_mac($t0, $t1, 'F', BRIGHT_BLUE, GRAY)	#places flag
    		j shift_cursor_left
    		
    	shift_cursor_left:
    	
    	addi $t1, $t1, -1		#move left a col
    	sw	 $t1, cursor_col	#store moved cursor
    	
    	set_cell_mac($t0, $t1, 0, GRAY, YELLOW)
    	
    	j return_from_perform_action
    
    #Move right
    pa_move_right:
    	beq $t1, 9, return_with_error_pa	#if at far right, return with error
    	
    	li  $t3, 10			#t2 is TOTAL OFFSET
    	mul $t2, $t0, $t3	#mult row by 10
    	add $t2, $t2, $t1	#add row offset + col
    	add $t2, $t2, $s0	#add total offset to start of cell array to get CELL LOCATION
    	lb  $t3, ($t2)		#get CELL
    	
    	andi $t4, $t3, 0x10								#pulls $t4 FLAG BIT
    	beq  $t4, 0x10,	replace_move_right_with_flag	#if flag bit is on, replace with flag
    	
    	andi $t4, $t3, 0x40									#pulls REVEAL BIT
    	bne	 $t4, 0x40, replace_move_right_with_square		#cell not already revealed, replace with square
    	
    	
    		reveal_cell_mac($t0, $t1, $s0)		#otherwise reveal cell
    		j shift_cursor_right
    		
    	replace_move_right_with_square:
    		
    		set_cell_mac($t0, $t1, 0, BLACK, GRAY)	#replace with standard background box
    		j shift_cursor_right
    		
    	replace_move_right_with_flag:
    		set_cell_mac($t0, $t1, 'F', BRIGHT_BLUE, GRAY)	#places flag
    		j shift_cursor_right
    		
    	shift_cursor_right:
    	
    	addi $t1, $t1, 1		#move right a col
    	sw	 $t1, cursor_col	#store moved cursor
    	
    	set_cell_mac($t0, $t1, 0, GRAY, YELLOW)
    	
    	j return_from_perform_action
    
    #Move down
    pa_move_down:
    	beq $t0, 9, return_with_error_pa	#if at bottom, return with error
    	
    	li  $t3, 10			#t2 is TOTAL OFFSET
    	mul $t2, $t0, $t3	#mult row by 10
    	add $t2, $t2, $t1	#add row offset + col
    	add $t2, $t2, $s0	#add total offset to start of cell array to get CELL LOCATION
    	lb  $t3, ($t2)		#get CELL
    	
    	andi $t4, $t3, 0x10								#pulls $t4 FLAG BIT
    	beq  $t4, 0x10,	replace_move_down_with_flag		#if flag bit is on, replace with flag
    	
    	andi $t4, $t3, 0x40								#pulls REVEAL BIT
    	bne	 $t4, 0x40, replace_move_down_with_square		#cell not already revealed, replace with square
    	
    		reveal_cell_mac($t0, $t1, $s0)		#otherwise reveal cell
    		j shift_cursor_down
    		
    	replace_move_down_with_square:
    		
    		set_cell_mac($t0, $t1, 0, BLACK, GRAY)	#replace with standard background box
    		j shift_cursor_down
    		
    	replace_move_down_with_flag:
    		set_cell_mac($t0, $t1, 'F', BRIGHT_BLUE, GRAY)	#places flag
    		j shift_cursor_down
    		
    	shift_cursor_down:
    	
    	addi $t0, $t0, 1		#move cursor down a row
    	sw	 $t0, cursor_row	#store moved cursor
    	
    	set_cell_mac($t0, $t1, 0, GRAY, YELLOW)
    	
    	j return_from_perform_action
    
    #DONE WITH ALL CHECK-----------------------------
    
    
    return_from_perform_action:
    	li $v0, 0	#puts 0 into $v0, ok return
    	j return_pa_final
    return_with_error_pa:
    	li $v0, -1	#puts -1 into $v0
	return_pa_final:
	
	#SETS CURSOR --------------------
		
		add $t5, $v0, $0	#stores $v0 for later use
		
		lw $t0, cursor_row
    	lw $t1, cursor_col
    	
    	li  $t3, 10
    	mul $t3, $t3, $t0
    	add $t3, $t3, $t1	#total offset
    	
    	add $t3, $t3, $s0	#is LOCATION of CELL with CURSOR
    	lb  $t3, ($t3)		#is cell with cursor
    	
		
		andi $t4, $t3, 0x10								#pulls $t4 FLAG BIT
    	beq  $t4, 0x10,	place_flag_down					#if flag bit is on, replace with flag
    	
    	andi $t4, $t3, 0x40								#pulls REVEAL BIT
    	bne	 $t4, 0x40, place_only_yellow_sqaure		#cell not already revealed, replace with square
    	andi $t4, $t3, 0x0F								#pulls numbers
    	beqz $t4,       place_only_yellow_sqaure		#if no numbers, just put 0
    		bne $t4, 1, notOneB
				set_cell_mac($t0, $t1, '1', BRIGHT_MAGENTA, YELLOW)
				j return_from_pa_after_cursor_change
			notOneB:
			bne $t4, 2, notTwoB
				set_cell_mac($t0, $t1, '2', BRIGHT_MAGENTA, YELLOW)
				j return_from_pa_after_cursor_change
			notTwoB:
			bne $t4, 3, notThreeB
				set_cell_mac($t0, $t1, '3', BRIGHT_MAGENTA, YELLOW)
				j return_from_pa_after_cursor_change
			notThreeB:
			bne $t4, 4, notFourB
				set_cell_mac($t0, $t1, '4', BRIGHT_MAGENTA, YELLOW)
				j return_from_pa_after_cursor_change
			notFourB:
			bne $t4, 5, notFiveB
				set_cell_mac($t0, $t1, '5', BRIGHT_MAGENTA, YELLOW)
				j return_from_pa_after_cursor_change
			notFiveB:
			bne $t4, 6, notSixB
				set_cell_mac($t0, $t1, '6', BRIGHT_MAGENTA, YELLOW)
				j return_from_pa_after_cursor_change
			notSixB:
			bne $t4, 7, notSevenB
				set_cell_mac($t0, $t1, '7', BRIGHT_MAGENTA, YELLOW)
				j return_from_pa_after_cursor_change
			notSevenB:
			bne $t4, 8, notEightB
				set_cell_mac($t0, $t1, '8', BRIGHT_MAGENTA, YELLOW)
				j return_from_pa_after_cursor_change
			notEightB:
			set_cell_mac($t0, $t1, '0', YELLOW, RED) #some number wut!, ERROR SON
			j return_from_pa_after_cursor_change	
		
		place_only_yellow_sqaure:
			
			set_cell_mac($t0, $t1, 0, GRAY, YELLOW)
			j return_from_pa_after_cursor_change
			
		place_flag_down:
			
			set_cell_mac($t0, $t1, 'F', BRIGHT_BLUE, YELLOW)
			
		
    return_from_pa_after_cursor_change:
    
    add $v0, $t5, $0	#restores $v0 from before
    
    lw	 $s0, ($sp)
    lw	 $s1, 4($sp)
    lw	 $s2, 8($sp)
    lw	 $ra, 12($sp)
    addi $sp, $sp, 16		#restore words
		
    jr $ra

game_status: #(cells_array)

    add $t0, $a0, $0	#load cells_array
	li  $t5, 0			#set up counter
	
	li $v0, 1			#game set to win, if not flipped
	
	game_status_loop:
		beq $t5, 100, exit_game_status_loop		#break at 100
		lb  $t1, ($t0)							# $t1 is CUR_CELL
		
		andi $t2, $t1, 0x10			#pulls $t2 FLAG BIT
		andi $t3, $t1, 0x40			#pulls $t3 REVEAL BIT
		andi $t4, $t1, 0x20			#pulls $t4 BOMB BIT
		
		#checking if cell is bomb and cell is revealed
		
		bne $t4, 0x20, game_not_over_yet	#branch if not bomb
		bne $t3, 0x40, game_not_over_yet	#branch if not revealed
			li $v0, -1 	#game is over
			jr $ra		#return
		game_not_over_yet:
		
		#checking if cell is bomb and cell is not flagged
		
		bne $t4, 0x20, win_possible_1 #branch if not bomb
		beq $t2, 0x10, win_possible_1 #branch if flagged
			li $v0, 0	#game is on-going
		win_possible_1:
		
		#checking if cell is flagged and cell is not bomb
		
		bne $t2, 0x10, win_possible_2	#branch if is not flagged
		beq $t4, 0x20, win_possible_2	#branch if is bomb
			li $v0, 0	#game is on-going
		win_possible_2:
		
		addi $t5, $t5, 1	#increment count by 1
		addi $t0, $t0, 1	#increment cell array location by 1
		
		j game_status_loop
		
	exit_game_status_loop:	
		
	jr $ra	#return with solution

##############################
# PART 5 FUNCTIONS
##############################

search_cells:
    # s0 - Start Cell Array
	# s1 - Current Cell Location
	# s2 - Current Cell	| Current Surrounding Cell 
	# s3 - Row
	# s4 - Col
	# s5 - Surrounding Cell Location
	# s6 - FLAG BIT
	# s7 - REVEAL BIT
	
	addi $sp, $sp, -32	#allocate 8 words
	sw	$s0,   ($sp)
	sw	$s1,  4($sp)
	sw	$s2,  8($sp)
	sw  $s3, 12($sp)
	sw	$s4, 16($sp)
	sw  $s5, 20($sp)
	sw	$s6, 24($sp)
	sw	$s7, 28($sp)
	
	add $s0, $a0, $0	#Move Start of Cell_Array
	add $s1, $a1, $0	#Move CURRENT CELL LOCATION to $s0
	
	add $fp, $sp, $0	#Set stack pointer and frame pointer equal
	
	search_cell_loop:
		
		sub  $s3, $s1, $s0		# Cur Cell Location - Start Location = Distance
		li	 $s4, 10			#immediate loaded for division
		div	 $s3, $s4			#divide distance by 10 to get [Quotient = row; Remainder = col]
		
		mflo  $s3 				#get quotient -> s3 is ROW
		mfhi  $s4				#get remainder -> s4 is COL
		
		reveal_cell_mac($s3, $s4, $s0)	#reveal popped cell
		
		#################################################################
		
		#TOP LEFT Check_2
		beq $s3, 0, skipTopLeftCheck_2		#row 0
		beq $s4, 0, skipTopLeftCheck_2		#col 0
			addi $s5, $s1, -11			#current location - offset
			lb   $s2, ($s5)				#TOP CELL CONTENTS
			
			andi $s6, $s2, 0x10			#pulls $s6 FLAG BIT
			andi $s7, $s2, 0x40			#pulls $s7 REVEAL BIT
			andi $s2, $s2, 0x0F			#gets only Bomb numbers in $s2
			
			beq $s7, 0x40, skipTopLeftPush	#dont push if it is revealed
			beq $s6, 0x10, skipTopLeftPush	#dont push if it is a flag
			bne $s2, 0	   skipTopLeftPush	#dont push if it has numbers
				addi $sp, $sp, -4	#allocate word for register
				sw	 $s5, ($sp)		#put cell location into stack
			skipTopLeftPush:
			
			beq $s7, 0x40, skipTopLeftReveal	#dont push if it is revealed
			beq $s6, 0x10, skipTopLeftReveal	#dont push if it is a flag
				
				sub  $s6, $s5, $s0		# Cur Cell Location - Start Location = Distance
				li	 $s7, 10			#immediate loaded for division
				div	 $s6, $s7			#divide distance by 10 to get [Quotient = row; Remainder = col]
		
				mflo $s6				#get quotient -> s6 is ROW
				mfhi $s7				#get remainder -> s7 is COL
			
				reveal_cell_mac($s6, $s7, $s0)
				
			skipTopLeftReveal:
			#if it gets to this point, don't do anything
			
		skipTopLeftCheck_2:
		
		#TOP Check_2	
		beq $s3, 0, skipTopCheck_2			#row 0
			
			addi $s5, $s1, -10			#current location - offset
			lb   $s2, ($s5)				#TOP CELL CONTENTS
			
			andi $s6, $s2, 0x10			#pulls $s6 FLAG BIT
			andi $s7, $s2, 0x40			#pulls $s7 REVEAL BIT
			andi $s2, $s2, 0x0F			#gets only Bomb numbers in $s2
			
			beq $s7, 0x40, skipTopPush	#dont push if it is revealed
			beq $s6, 0x10, skipTopPush	#dont push if it is a flag
			bne $s2, 0	   skipTopPush	#dont push if it has numbers
				addi $sp, $sp, -4	#allocate word for register
				sw	 $s5, ($sp)		#put cell location into stack
			skipTopPush:
			
			beq $s7, 0x40, skipTopReveal	#dont push if it is revealed
			beq $s6, 0x10, skipTopReveal	#dont push if it is a flag
				
				sub  $s6, $s5, $s0		# Cur Cell Location - Start Location = Distance
				li	 $s7, 10			#immediate loaded for division
				div	 $s6, $s7			#divide distance by 10 to get [Quotient = row; Remainder = col]
		
				mflo $s6				#get quotient -> s6 is ROW
				mfhi $s7				#get remainder -> s7 is COL
			
				reveal_cell_mac($s6, $s7, $s0)
				
			skipTopReveal:
			#if it gets to this point, don't do anything
			
		skipTopCheck_2:
		
		#TOP RIGHT
		beq $s3, 0, skipTopRightCheck_2		#row 0
		beq $s4, 9, skipTopRightCheck_2		#col 9
			
			addi $s5, $s1, -9			#current location - offset
			lb   $s2, ($s5)				#TopRight CELL CONTENTS
			
			andi $s6, $s2, 0x10			#pulls $s6 FLAG BIT
			andi $s7, $s2, 0x40			#pulls $s7 REVEAL BIT
			andi $s2, $s2, 0x0F			#gets only Bomb numbers in $s2
			
			beq $s7, 0x40, skipTopRightPush	#dont push if it is revealed
			beq $s6, 0x10, skipTopRightPush	#dont push if it is a flag
			bne $s2, 0	   skipTopRightPush	#dont push if it has numbers
				addi $sp, $sp, -4	#allocate word for register
				sw	 $s5, ($sp)		#put cell location into stack
			skipTopRightPush:
			
			beq $s7, 0x40, skipTopRightReveal	#dont push if it is revealed
			beq $s6, 0x10, skipTopRightReveal	#dont push if it is a flag
				
				sub  $s6, $s5, $s0		# Cur Cell Location - Start Location = Distance
				li	 $s7, 10			#immediate loaded for division
				div	 $s6, $s7			#divide distance by 10 to get [Quotient = row; Remainder = col]
		
				mflo $s6				#get quotient -> s6 is ROW
				mfhi $s7				#get remainder -> s7 is COL
			
				reveal_cell_mac($s6, $s7, $s0)
				
			skipTopRightReveal:
			#if it gets to this point, don't do anything
			
		skipTopRightCheck_2:
		
		#RIGHT
		beq $s4, 9, skipRightCheck_2			#col 9
			
			addi $s5, $s1, 1			#current location - offset
			lb   $s2, ($s5)				#Right CELL CONTENTS
			
			andi $s6, $s2, 0x10			#pulls $s6 FLAG BIT
			andi $s7, $s2, 0x40			#pulls $s7 REVEAL BIT
			andi $s2, $s2, 0x0F			#gets only Bomb numbers in $s2
			
			beq $s7, 0x40, skipRightPush	#dont push if it is revealed
			beq $s6, 0x10, skipRightPush	#dont push if it is a flag
			bne $s2, 0	   skipRightPush	#dont push if it has numbers
				addi $sp, $sp, -4	#allocate word for register
				sw	 $s5, ($sp)		#put cell location into stack
			skipRightPush:
			
			beq $s7, 0x40, skipRightReveal	#dont push if it is revealed
			beq $s6, 0x10, skipRightReveal	#dont push if it is a flag
				
				sub  $s6, $s5, $s0		# Cur Cell Location - Start Location = Distance
				li	 $s7, 10			#immediate loaded for division
				div	 $s6, $s7			#divide distance by 10 to get [Quotient = row; Remainder = col]
		
				mflo $s6				#get quotient -> s6 is ROW
				mfhi $s7				#get remainder -> s7 is COL
			
				reveal_cell_mac($s6, $s7, $s0)
				
			skipRightReveal:
			#if it gets to this point, don't do anything
			
		skipRightCheck_2:
		
		#BOTTOM RIGHT
		beq $s3, 9, skipBottomRightCheck_2	#row 9
		beq $s4, 9, skipBottomRightCheck_2	#col 9
		
			addi $s5, $s1, 11			#current location - offset
			lb   $s2, ($s5)				#BottomRight CELL CONTENTS
			
			andi $s6, $s2, 0x10			#pulls $s6 FLAG BIT
			andi $s7, $s2, 0x40			#pulls $s7 REVEAL BIT
			andi $s2, $s2, 0x0F			#gets only Bomb numbers in $s2
			
			beq $s7, 0x40, skipBottomRightPush	#dont push if it is revealed
			beq $s6, 0x10, skipBottomRightPush	#dont push if it is a flag
			bne $s2, 0	   skipBottomRightPush	#dont push if it has numbers
				addi $sp, $sp, -4	#allocate word for register
				sw	 $s5, ($sp)		#put cell location into stack
			skipBottomRightPush:
			
			beq $s7, 0x40, skipBottomRightReveal	#dont push if it is revealed
			beq $s6, 0x10, skipBottomRightReveal	#dont push if it is a flag
				
				sub  $s6, $s5, $s0		# Cur Cell Location - Start Location = Distance
				li	 $s7, 10			#immediate loaded for division
				div	 $s6, $s7			#divide distance by 10 to get [Quotient = row; Remainder = col]
		
				mflo $s6				#get quotient -> s6 is ROW
				mfhi $s7				#get remainder -> s7 is COL
			
				reveal_cell_mac($s6, $s7, $s0)
				
			skipBottomRightReveal:
			#if it gets to this point, don't do anything
			
		skipBottomRightCheck_2:
		
		#BOTTOM
		beq $s3, 9, skipBottomCheck_2			#row 9
		
			addi $s5, $s1, 10			#current location - offset
			lb   $s2, ($s5)				#Bottom CELL CONTENTS
			
			andi $s6, $s2, 0x10			#pulls $s6 FLAG BIT
			andi $s7, $s2, 0x40			#pulls $s7 REVEAL BIT
			andi $s2, $s2, 0x0F			#gets only Bomb numbers in $s2
			
			beq $s7, 0x40, skipBottomPush	#dont push if it is revealed
			beq $s6, 0x10, skipBottomPush	#dont push if it is a flag
			bne $s2, 0	   skipBottomPush	#dont push if it has numbers
				addi $sp, $sp, -4	#allocate word for register
				sw	 $s5, ($sp)		#put cell location into stack
			skipBottomPush:
			
			beq $s7, 0x40, skipBottomReveal	#dont push if it is revealed
			beq $s6, 0x10, skipBottomReveal	#dont push if it is a flag
				
				sub  $s6, $s5, $s0		# Cur Cell Location - Start Location = Distance
				li	 $s7, 10			#immediate loaded for division
				div	 $s6, $s7			#divide distance by 10 to get [Quotient = row; Remainder = col]
		
				mflo $s6				#get quotient -> s6 is ROW
				mfhi $s7				#get remainder -> s7 is COL
			
				reveal_cell_mac($s6, $s7, $s0)
				
			skipBottomReveal:
			#if it gets to this point, don't do anything
			
		skipBottomCheck_2:
		
		#BOTTOM LEFT
		beq $s3, 9, skipBottomLeftCheck_2		#row 9
		beq $s4, 0, skipBottomLeftCheck_2		#col 0
		
			addi $s5, $s1, 9			#current location - offset
			lb   $s2, ($s5)				#BottomLeft CELL CONTENTS
			
			andi $s6, $s2, 0x10			#pulls $s6 FLAG BIT
			andi $s7, $s2, 0x40			#pulls $s7 REVEAL BIT
			andi $s2, $s2, 0x0F			#gets only Bomb numbers in $s2
			
			beq $s7, 0x40, skipBottomLeftPush	#dont push if it is revealed
			beq $s6, 0x10, skipBottomLeftPush	#dont push if it is a flag
			bne $s2, 0	   skipBottomLeftPush	#dont push if it has numbers
				addi $sp, $sp, -4	#allocate word for register
				sw	 $s5, ($sp)		#put cell location into stack
			skipBottomLeftPush:
			
			beq $s7, 0x40, skipBottomLeftReveal	#dont push if it is revealed
			beq $s6, 0x10, skipBottomLeftReveal	#dont push if it is a flag
				
				sub  $s6, $s5, $s0		# Cur Cell Location - Start Location = Distance
				li	 $s7, 10			#immediate loaded for division
				div	 $s6, $s7			#divide distance by 10 to get [Quotient = row; Remainder = col]
		
				mflo $s6				#get quotient -> s6 is ROW
				mfhi $s7				#get remainder -> s7 is COL
			
				reveal_cell_mac($s6, $s7, $s0)
				
			skipBottomLeftReveal:
			#if it gets to this point, don't do anything
			
			
			
		skipBottomLeftCheck_2:
		
		#LEFT
		beq $s4, 0, skipLeftCheck_2			#col 0
		
			addi $s5, $s1, -1			#current location - offset
			lb   $s2, ($s5)				#Left CELL CONTENTS
			
			andi $s6, $s2, 0x10			#pulls $s6 FLAG BIT
			andi $s7, $s2, 0x40			#pulls $s7 REVEAL BIT
			andi $s2, $s2, 0x0F			#gets only Bomb numbers in $s2
			
			beq $s7, 0x40, skipLeftPush	#dont push if it is revealed
			beq $s6, 0x10, skipLeftPush	#dont push if it is a flag
			bne $s2, 0	   skipLeftPush	#dont push if it has numbers
				addi $sp, $sp, -4	#allocate word for register
				sw	 $s5, ($sp)		#put cell location into stack
			skipLeftPush:
			
			beq $s7, 0x40, skipLeftReveal	#dont push if it is revealed
			beq $s6, 0x10, skipLeftReveal	#dont push if it is a flag
				
				sub  $s6, $s5, $s0		# Cur Cell Location - Start Location = Distance
				li	 $s7, 10			#immediate loaded for division
				div	 $s6, $s7			#divide distance by 10 to get [Quotient = row; Remainder = col]
		
				mflo $s6				#get quotient -> s6 is ROW
				mfhi $s7				#get remainder -> s7 is COL
			
				reveal_cell_mac($s6, $s7, $s0)
				
			skipLeftReveal:
			#if it gets to this point, don't do anything
			
		skipLeftCheck_2:

		#ITERATE
		
		beq  $sp, $fp, end_search_cell_loop		#when stack pointer = frame pointer, out of items on stack
		lw   $s1, ($sp)							#pop item from stack pointer
		addi $sp, $sp, 4						#restore 1 word
		
	j search_cell_loop
	
	end_search_cell_loop:
	
	
	lw	$s0,   ($sp)
	lw	$s1,  4($sp)
	lw	$s2,  8($sp)
	lw  $s3, 12($sp)
	lw	$s4, 16($sp)
	lw  $s5, 20($sp)
	lw	$s6, 24($sp)
	lw	$s7, 28($sp)
	addi $sp, $sp, 32
		
	jr $ra


###########################################################
# My Functions
##########################################################

reveal_cell:	#(row, col, cell_array)
		
		addi $sp, $sp, -20	#allocate 5 words
		sw $s0,   ($sp)
		sw $s1,  4($sp)
		sw $s2,  8($sp)
		sw $s3, 12($sp)
		sw $s4, 16($sp)
		
		# t0 - is row
		# t1 - is col
		# t2 - is cur cell position  -> previously start of cell array location
		# t3 - is cur cell
		# t4 - is working bit
		
		#return in $v0 [ 1 = Blank Box, 0 = Box Occupied]
		
		add $s0, $a0, $0	#loads ROW
		add $s1, $a1, $0	#loads COL
		add $s2, $a2, $0	#loads CELL_ARRAY
		
		# $s3 is OFFSET TOTAL
		li   $s4, 10		#loads 10
		mul  $s3, $s0, $s4	# OFFSET_TOTAL = ROW x 10
		add  $s3, $s3, $s1  	# OFFSET_TOTAL = OFFSET_TOTAL + COL
		add  $s2, $s2, $s3  #CUR_CELL_LOCATION = OFFSET_TOTAL + START_CELL_ARRAY_LOCATION
		
		li $v0, 0	#set to not blank box by default

	   	lb $s3, ($s2)	#$s3 is CUR_CELL
	   	
	   	ori $s3, $s3, 0x40	#cell revealed bit inserted
	   	sb  $s3, ($s2)		#cell placed back into spot
    	
    	# $s4, IS IMPORTANT BIT
    	#---------- Flag -----------
    	andi $s4, $s3, 0x10		#mask with flag bit
    	bne  $s4, 0x10, notFlag
    		andi $s4, $s3, 0x20		#mask with bomb bit
    		beq $s4, 0x20, isBombFlag
				set_cell_mac($s0, $s1, 'f', BRIGHT_BLUE, BRIGHT_RED) #is not bomb
				j done_reveal_return
			isBombFlag:
				set_cell_mac($s0, $s1, 'f', BRIGHT_BLUE, BRIGHT_GREEN)
				j done_reveal_return
    	notFlag:
    	#---------- Bomb -----------
    	andi $s4, $s3, 0x20		#filter for bomb
    	bne $s4, 0x20, isNotBomb
			set_cell_mac($s0, $s1, 'b', GRAY, BLACK)
			j done_reveal_return
		isNotBomb:
		#--------- Number ----------
    	andi $s4, $s3, 0xF	#filters number bits
    	beqz $s4, noNums	#not number if filtered is 0
    		bne $s4, 1, notOne
				set_cell_mac($s0, $s1, '1', BRIGHT_MAGENTA, BLACK)
				j done_reveal_return
			notOne:
			bne $s4, 2, notTwo
				set_cell_mac($s0, $s1, '2', BRIGHT_MAGENTA, BLACK)
				j done_reveal_return
			notTwo:
			bne $s4, 3, notThree
				set_cell_mac($s0, $s1, '3', BRIGHT_MAGENTA, BLACK)
				j done_reveal_return
			notThree:
			bne $s4, 4, notFour
				set_cell_mac($s0, $s1, '4', BRIGHT_MAGENTA, BLACK)
				j done_reveal_return
			notFour:
			bne $s4, 5, notFive
				set_cell_mac($s0, $s1, '5', BRIGHT_MAGENTA, BLACK)
				j done_reveal_return
			notFive:
			bne $s4, 6, notSix
				set_cell_mac($s0, $s1, '6', BRIGHT_MAGENTA, BLACK)
				j done_reveal_return
			notSix:
			bne $s4, 7, notSeven
				set_cell_mac($s0, $s1, '7', BRIGHT_MAGENTA, BLACK)
				j done_reveal_return
			notSeven:
			bne $s4, 8, notEight
				set_cell_mac($s0, $s1, '8', BRIGHT_MAGENTA, BLACK)
				j done_reveal_return
			notEight:
			set_cell_mac($s0, $s1, '0', YELLOW, RED) #some number wut!, ERROR SON
			j done_reveal_return	
    	noNums:
    	
    	set_cell_mac($s0, $s1, 0, WHITE, BLACK)	#if none of the others, just set black box
    	li $v0, 1	#returns 1 since box is blank
    	
    	done_reveal_return:
    	# -------- Done with checks -----
    	
		lw $s0,   ($sp)
		lw $s1,  4($sp)
		lw $s2,  8($sp)
		lw $s3, 12($sp)
		lw $s4, 16($sp)
		addi $sp, $sp, 20	#restore registers
		
		jr $ra	#return from reveal cell

#################################################################
# Student defined data section
#################################################################
.data
.align 2  # Align next items to word boundary
cursor_row: .word -1
cursor_col: .word -1

#place any additional data declarations here


row_store: .word 0	#these are for use in the set_cell macro call, to make them safe to use no hassel
col_store: .word 0

map_buffer: .space 1000


