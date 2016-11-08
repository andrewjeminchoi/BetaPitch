

.equ JTAG_UART, 0x10001020
.equ TIMER, 0xFF202000
.equ PERIOD, 100000000  
.equ TERMINAL, 0xFF201000

.data
	thechar:    .byte ' '
.data 
	sensorValue: .byte ''
	
.text
	
.global main

main:

	movia sp, 0x03FFFFFC

	#Timer ----
	movia r8, TIMER

	movui r9, %lo(PERIOD)
	movui r10, %hi(PERIOD) 
	
	
	stwio r9, 8(r8)                          /* Set the period to be 100000000  clock cycles */
	stwio r10, 12(r8)
	
	movui r11, 0b0111
	stwio r11, 4(r8)
	
	#End of Timer ----
	
	movi r12, 0b100000001
	wrctl ctl3, r12
	
	movi r12, 1
	wrctl ctl0, r12
	
	movia r8, TERMINAL
	movi r12, 1
	
	stwio r12, 4(r8)
	
LOOP:

	call ReadSensorAndSpeed
	
	mov r18, r2 #Sensor
	mov r19, r3 #speed
	
	movi r8, 0x1f
	beq r2, r8, STEERSTRAIGHT
	
	movi r8, 0x0f
	beq r2, r8, STEERLEFT
	
	movi r8, 0x1e
	beq r2, r8, STEERRIGHT
	
	movi r8, 0x07
	beq r2, r8, STEERHARDLEFT
	
	movi r8, 0x1c
	beq r2, r8, STEERHARDRIGHT
	
	br LOOP
		
STEERSTRAIGHT:

	movi r4, 46
	blt r4, r3, GOSTRAIGHT
	
	movi r4, 100
	call CHANGEACCELERATION
	
	movi r4, 0
	call STEER
	
	br LOOP

GOSTRAIGHT:	

	movi r4, -100
	call CHANGEACCELERATION
	
	movi r4, 0
	call STEER
	
	br LOOP
	
STEERLEFT: 

	movi r4, 50
	blt r4, r3, GOLEFT

	movi r4, 0
	call CHANGEACCELERATION

	movi r4, -100
	call STEER
	
	br LOOP
	
GOLEFT:

	movi r4, 0
	call CHANGEACCELERATION
	
	movi r4, -100
	call STEER
	
	br LOOP
	
STEERRIGHT:
	
	
	movi r4, 50
	blt r4, r3, GORIGHT
	
	movi r4, 20
	call CHANGEACCELERATION
	
	movi r4, 100
	call STEER
	
	br LOOP
	
GORIGHT:

	movi r4, 0
	call CHANGEACCELERATION

	movi r4, 100
	call STEER
	
	br LOOP
	
STEERHARDLEFT:

	movi r4, 50
	blt r4, r3, GOHARDLEFT

	movi r4, -120
	call CHANGEACCELERATION
	
	movi r4, -120
	call STEER
	
	br LOOP
	
GOHARDLEFT:

	movi r4, 0
	call CHANGEACCELERATION

	movi r4, -120
	call STEER
	
	br LOOP
	
STEERHARDRIGHT:


	movi r4, 50
	blt r4, r3, GOHARDRIGHT

	movi r4, -120
	call CHANGEACCELERATION
	
	movi r4, 120
	call STEER
	
	br LOOP

GOHARDRIGHT:	

	movi r4, 0
	call CHANGEACCELERATION
	
	movi r4, 120
	call STEER
	
	br LOOP

STEER:

	movia r7, JTAG_UART
	
	movi r5, 0x05 
	stbio r5, 0(r7) #set it to "store steering"
	
	ldwio r3, 4(r7) /* Load from the JTAG */
	srli  r3, r3, 16 /* Check only the write available bits */
	beq   r3, r0, STEER /* If this is 0 (branch true), data cannot be sent */
	
	stbio r4, 0(r7) #set the tire angle to go straight
	
	ret
	
	
CHANGEACCELERATION:

	movia r7, JTAG_UART
	
	ldwio r3, 4(r7) /* Load from the JTAG */
	srli  r3, r3, 16 /* Check only the write available bits */
	beq   r3, r0, CHANGEACCELERATION /* If this is 0 (branch true), data cannot be sent */
	
	movi r5, 0x04 
	stbio r5, 0(r7) #set it to "store acceleration"
	
	
	
LOADACCELERATION:

	ldwio r3, 4(r7) /* Load from the JTAG */
	srli  r3, r3, 16 /* Check only the write available bits */
	beq   r3, r0, LOADACCELERATION /* If this is 0 (branch true), data cannot be sent */

	stbio r4, 0(r7) #set the tire angle to go straight
	
	ret

ReadSensorAndSpeed:
	
	movia r7, JTAG_UART
	movi r5, 0x02 
	stbio r5, 0(r7) #pull the second packet, which has data of sensor and speed
	
	movi r6, 0 #counter for how many packets have been recieved
	
ReadReady:
		
	ldwio r4, 0(r7) #load from JTAG_UART
	
	
	
	andi  r9, r4, 0x8000 /* Mask other bits */
	beq   r9, r0, ReadReady /* If this is 0 (branch true), data is not valid */
	
	
	#ldbio r4, 0(r7)
	
	#andi  r4, r4, 0x00FF
	
	beq r6, r0, FirstByte #when it is first byte
	
	movi r8, 1 
	beq r6, r8, SecondByte
	
	movi r8, 2
	beq r6, r8, ThirdByte
	
FirstByte:

	addi r6, r6, 1
	br ReadReady
	
SecondByte:

	addi r6, r6, 1
	
	#mov r2, r4
	
	andi  r2, r4, 0x00FF /* Data read is now in r2 */
	
	br ReadReady
	
	

ThirdByte:
	
	andi  r3, r4, 0x00FF /* Data read is now in r3 */
	
	#mov r3, r4
	
	ret
	
	
.section .exceptions, "ax"

ISR:
	addi sp, sp, -24
	
	stw r18, 0(sp)
	stw r19, 4(sp)
	stw r20, 8(sp)
	stw r21, 12(sp)
	stw r22, 16(sp)
	stw r23, 20(sp)
	


	rdctl et, ctl4
	andi et, et, 0b100000000 #check 8th bit (UART)
	bne et, r0, KEYINTERRUPT
	
	rdctl et, ctl4 #read the ipending to see which interrupts are active
	#movi et, 1
	andi et, et, 0x1
	bne et, r0, TIMERACTIVE #only branch if timer interrupts
	#br TIMERACTIVE
	
	
	br RETURNBACK

KEYINTERRUPT:
	movia r20, TERMINAL

	#read from UART
	ldwio et, 0(r20)
	#srli  r8, et, 16
	#mov r8, et
	#andi r8, r8, 0x1000 #check the valid bit and poll 
	#beq r8, r0, KEYINTERRUPT
	
	andi et, et, 0xFF #only read the first 8 bits
	
	movi r21, 's'
	movi r22, 'r'
	
	beq et, r21, SET_SPEED_STATE
	
	beq et, r22, SET_SENSOR_STATE
	
	
	br RETURNBACK
	
	
SET_SPEED_STATE:
	#movi r21, 0x0 #Show speed state
	movia r21, thechar 
	
	stbio r0, 0(r21)
	
	br RETURNBACK
	
	
	#convert hex to ASCII

	
	

SET_SENSOR_STATE:
	#movi r21, 0x1 #show sensor state
	
	movia r21, thechar 
	movi r22, 1
	
	stbio r22, 0(r21)
	
	br RETURNBACK

	
TIMERACTIVE:

	movia r20, TIMER
	
	stwio r0, 0(r20) #set flag back down
	
	movia r21, thechar
	ldbio r22, 0(r21)
	
	beq r22, r0, SHOW_SPEED
	
	br SHOW_SENSOR
	
SHOW_SPEED:

	

	movia et, TERMINAL
	
	# #erase the entire line
	movi r23, 0x1b #<ESC> in ascii
	stwio r23, 0(et)
	
	movi r23, '['
	stwio r23, 0(et)

	movi r23, '2'
	stwio r23, 0(et)	
	
	movi r23, 'K'
	stwio r23, 0(et)
	
	
	# #move the cursor back to the start position
	movi r23, 0x1b #<ESC> in ascii
	stwio r23, 0(et)
	
	movi r23, '['
	stwio r23, 0(et)
	
	movi r23, 'H'
	stwio r23, 0(et)

	andi r23, r19, 0b11110000 #get the second hex digit\
	srli r23, r23, 4
	
	addi r23, r23, 0x30
	stwio r23, 0(et) #r18
	
	#movi r23, 0x34 # number 4 in ascii
	
	#andi r23, r19, 0b11110000 #get the second hex digit
	#addi r23, r23, 0x30
	#stwio r23, 0(et) #r19
	
	
	
	andi r23, r19, 0b00001111 
	
	movi et, 9
	
	blt et, r23, ADD7
	
	movia et, TERMINAL
	addi r23, r23, 0x30
	stwio r23, 0(et) 
	
	br RETURNBACK
	


SHOW_SENSOR:


	movia et, TERMINAL
	
	#erase the entire line
	movi r23, 0x1b #<ESC> in ascii
	stwio r23, 0(et)
	
	movi r23, '['
	stwio r23, 0(et)

	movi r23, '2'
	stwio r23, 0(et)	
	
	movi r23, 'K'
	stwio r23, 0(et)
	
	
	# #move the cursor back to the start position
	movi r23, 0x1b #<ESC> in ascii
	stwio r23, 0(et)
	
	movi r23, '['
	stwio r23, 0(et)
	
	movi r23, 'H'
	stwio r23, 0(et)

	
	
	andi r23, r18, 0b11110000 #get the second hex digit\
	srli r23, r23, 4
	
	addi r23, r23, 0x30
	stwio r23, 0(et) #r18
	
	
	
	andi r23, r18, 0b00001111  #get the first hex digit
	movi et, 9
	
	blt et, r23, ADD7
	
WRITETOJTAG:

	movia et, TERMINAL
	addi r23, r23, 0x30
	stwio r23, 0(et) 
	
	#movi r23, 0x35 # number 4
	#stwio r23, 0(et) #r18

	
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
	
	
ADD7:

	addi r23, r23, 7
	
	br WRITETOJTAG
	
