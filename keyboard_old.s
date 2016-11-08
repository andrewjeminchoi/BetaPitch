/*
Lego Sensors State mode
Works on the online compiler
Note that currently the interrupt is triggered when the value is lower than the threshold (seems to be 0x6).
The value seems to be 0 when it is below the threshold
*/

.equ PS2_ADDR, 0xFF200100
.equ JP1, 0xFF200060

.equ TIMER, 0xFF202000
.equ PERIOD,  50000000  #100000000  

.equ TIMER2, 0xFF202020 
.equ PERIOD2, 100000000

.equ JP1_IRQ, 0b100000000000 #IRQ line 11 for Lego
.equ PS2_IRQ, 0b010000000 #IRQ 7 for PS/2

.equ ADDR_JP1_Edge, 0xff20006C      /* address Edge Capture register GPIO JP1 */

#global counter
score:
	.byte 0


/*
#VGA
.equ VGA, 0x08000000

.section .data

RECTANGLE:
	.incbin "rectangle.bin"
*/
.section .text

.global main

main:
	#initialize stack pointer
	movia sp, 0x03FFFFFC
	
	movia r8, JP1
	movia  r9, 0x07f557ff        /* set direction for motors to all output */
	stwio  r9, 4(r8)
	
	#set motor direction register
	movia r20, 0xFFFFFFFC
	# stwio r20, 0(r8)

	#enable intrrupt for ps2 ----
	movia r8, PS2_ADDR
	movi r9, 1 
	stwio r9, 4(r8)
	#----------------------------
	
	#Timer 1 --------------------
	movia r8, TIMER
	movui r9, %lo(PERIOD)
	movui r10, %hi(PERIOD) 

	stwio r9, 8(r8)                          /* Set the period to be 100000000  clock cycles */
	stwio r10, 12(r8)
	
	movui r11, 0b0101 #set the start bit, and interrupt bit. Don't continue the clock after interrupt is enabled
	stwio r11, 4(r8)
	#----------------------------
	
	#Timer 2 ---------------------
	movia r8, TIMER2
	movui r9, %lo(PERIOD2)
	movui r10, %hi(PERIOD2)
	
	stwio r9, 8(r8)
	stwio r10, 12(r8)
	
	movui r11, 0b0100 #disable the interrupt for TIMER 2 for now. Also do not continue clock after the interrupt
	stwio r11, 4(r8)
	#----------------------------
	
	#Input the LEGO threshold values in value mode here -------
	movia r12, JP1  #set load bit (bit 22) to 0 in value mode
    
	#load threshold of 8, set load bit to 0, stay in value mode, turn on sensor 0
	movia r13, 0xFC2FFBFF
	stwio r13, 0(r12)
    
    #load threshold of 8, set load to 0, stay in value mode, turn on sensor 1
    movia r13, 0xFC2FEFFF 
	stwio r13, 0(r12)
    
	#set load bit back to 1 and enable state mode
	movia r13, 0xffdfffff 
	stwio r13, 0(r12)
	
	#enable interrupts only for sensors 1 and 2 (to enable all, write 0xf8000000)
	movia r13, 0x18000000 
	stwio r13, 8(r12)
	
	#NOT USED --------------------------------
	#change to state mode
	# movia r13, 0xFFDFFFFF
	# stwio r13, 0(r12)
	#NOT USED --------------------------------
	
	# ----------------------------
	
	
	#Interrupt Enable -------------
	#enable the interrupts via IRQ lines
	movui r12, 0b100010000000 #bit 0 enables timer, 7 is keyboard, 11 is sensors in state mode
	wrctl ctl3, r12
	
	movi r12, 1
	wrctl ctl0, r12
	# -----------------------------
	
	#VGA TEST--------------------------------------------------
	
	mov r10, r0 #counter for drawing x pixels
	mov r11, r0 #counter for drawing y pixels
	mov r17, r0 #counter for the whole loop
	
/*
VGALOOP:

	#--------------------Boundary Check----------------------#
	#check if at the end of the screen
	movi r12, 319
	movi r13, 239
	
	#check if x position has reached its end
	cmpeq r14, r10, r12
	
	#check if y position has reached its end
	cmpeq r15, r11, r13
	
	#check if both x and y reached the end
	and r15, r14, r15
	
	#if r15 does not contain 0 (i.e. reached the end) exit the loop
	bne r15, r0, LOOP
	
	#-----------------End of Boundary Check-----------------------#
	
	#-----------------Draw the pixels-----------------------------#
	
	#calculate the offset for x and store it to r8
	muli r8, r10, 2
	
	#calculate the offset for y and store it to t9
	muli r9, r11, 1024
	
	#add the offsets and store it to r8
	add r8, r8, r9
	
	#add the offset to the base address
	movia r9, VGA
	add r9, r8, r9
	
	#get the colour of the pixel
	movia r9, RECTANGLE
	add r18, r9, r17
	ldwio r8, 0(r18)  
	
	movia r8, 0xFFFF
	
	#store the colour to the pixel
	stwio r8, 0(r9)
	
	
	#-------------------------incrementing the counters-----------------------------#
	
	#if the counter x counter reached the end
	movi r12, 319
	beq r10, r12, INCREMENTXANDY
	
	#increment only the x counter
	addi r10, r10, 1
	addi r17, r17, 1
	
	br VGALOOP
	
INCREMENTXANDY:
	
	#reset the x counter
	mov r10, r0
	
	#increment the y counter
	addi r11, r11, 1
	addi r17, r17, 1
	
	br VGALOOP
	
*/
LOOP:
	br LOOP
	



.section .exceptions, "ax"

ISR:
	addi sp, sp, -24
	
	stw r18, 0(sp)
	stw r19, 4(sp)
	stw r20, 8(sp)
	stw r21, 12(sp)
	stw r22, 16(sp)
	stw r23, 20(sp)
	


	rdctl et, ctl4 #store the interrupt IRQ
	andi r18, et, PS2_IRQ #check 7th bit (PS2)
	bne r18, r0, KEYINTERRUPT
	
	andi r18, et, JP1_IRQ #check 11th bit (LEGO sensors)
	bne r18, r0, SENSOR_INT
	
	andi r19, et, 1
	
	#bne r19, r0, TIMER_INT
	
	br RETURNBACK
	
SENSOR_INT:
	#------------------------------------------
	movia r18, ADDR_JP1_Edge
	
	#acknowledge the interrupt
	movia r19, 0xffffffff #clear the edge capture register with 1s
	
	stwio r19, 0(r18)
	
	#-----------------------------------------
	# Read the sensors and determine if it is over threshold
	movia r18, JP1
	ldwio r19, 0(r18)
	srli r19, r19, 27 #sensor values are from the 27th bit to 31st bit
	andi r19, r19, 0b11 #only check the first two sensors (lower 2 bits)
	#cmpeqi r20, r19, 0b11
	#bne r20, r0, RETURNBACK #false interrupt
	
	#hard coded for two sensors here -> if both are below threshold, then no interrupt
    movi r21, 0
    beq r19, r21, RETURNBACK #false interrupt
	
	
	#If the sensor 1 is above the threshold, start the timer.
	#Else, just return back
    movi r21, 1
	beq r21, r19, TIMER_INT #if sensor 1 is above the threshold (0b01)
	
	#If sensor 2 is above threshold, then increase the counter by 1
    movi r21, 2
	beq r21, r19, INCREASE_POINT #if sensor 2 is above threshold (0b10)
	
	br RETURNBACK
	
	
SENSOR_REACT1:
	br TURNONMOTOR
	
	
SENSOR_REACT2:
	br TURNOFFMOTOR
	
#increase the score counter (global variable) by 1
INCREASE_POINT:
	movia r22, score
	ldw et, 0(r22)
	addi et, et, 1
	stw et, 0(r22)
	br RETURNBACK
	
	
#Start the timer if the ball is detected by the LEGO sensor
#
TIMER_INT:

	movia r18, TIMER
	
	stwio r0, 0(r18) #acknowledge the interrupt
	
	movia r21, JP1 #Address of lego
	
	ldwio r22, 0(r21) #see if the motor is on. If it is, then turn it off
	
	andi r22, r22, 0b010
	
	#beq r0, r22, TURNOFFMOTOR
	
	bne r0, r22, TURNONMOTOR
	
	br RETURNBACK
	
TIMER2_INT:
	movia r18, TIMER2
		
	stwio r0, 0(r18)
	
	movia r21, JP1
	
	ldwio r22, 0(r21)
	
	andi r22, r22, 0b010
	
	beq r0, r22, TURNOFFMOTOR
	
	#bne r0, r22, TURNONMOTOR
	
	br RETURNBACK
	
TURNONMOTOR:

	movia r21, JP1
	movia r20, 0xFFFFFFF0
	stwio r20, 0(r21)	
	
	
	br RETURNBACK
	
TURNOFFMOTOR:

	movia r21, JP1
	movia r20, 0xFFFFFFFF
	stwio r20, 0(r21)
	
	br RETURNBACK
	
	
KEYINTERRUPT:
	movia et, PS2_ADDR
	
	ldwio et, 0(et) #get the data to see which key was pressed
	
	andi r18, et, 0b011111111  #mask non-data bits
	
	#if (et == leftarrow)
		#branch to leftarrow
	#else if (et == rightarrow)'
		#branch to right arrow
	#else if (et == uparrow)
		#branch to up arrow
	#else if (et === downarrow)
		#branch to down arrow
	
	
	br RETURNBACK

	
	
RETURNBACK:

	ldw r18, 0(sp)
	ldw r19, 4(sp)
	ldw r20, 8(sp)
	ldw r21, 12(sp)
	ldw r22, 16(sp)
	ldw r23, 20(sp)
	
	addi sp, sp, 24
	subi ea, ea, 4
	eret
	
	
	
	
	
	
