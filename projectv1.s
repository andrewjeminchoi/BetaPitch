#Timer that has a period of 1000 clock cycles

.equ TIMER, 0xFF202000 
.equ PERIOD, 1000
.equ ADDR_JP1, 0xFF200060 #Lego Controller 

.global main
main:

	movia r8, ADDR_JP1                   /* r8 contains the base address for the Lego Controller */
	movia  r10, 0x07f557ff      /* set direction for motors and sensors to output and sensor data register to inputs */
    stwio  r10, 4(r8)
	
	#Timer ----
	movia r8, TIMER

	movui r12, %lo(PERIOD)
	movui r13, %hi(PERIOD) 
	
	
	stwio r12, 8(r8)                          /* Set the period to be 100000000  clock cycles */
	stwio r13, 12(r8)
	
	movui r11, 0b0111 #set start bit and continue bit.
	stwio r11, 4(r8)
	
	
	#End of Timer ----
	
	#enable interrupts on the processor
	#movi r14, 0b100000000001 #enable the LEGO controller on JP 1 (bit 11) and timer (bit 0)
	movi r14, 0b1
	wrctl ctl3, r14
	
	movi r14, 1 #enable interrupts globally
	wrctl ctl0, r14

	movi r14, 1  #enable interrupts on the timer
	stwio r14, 4(r8)
	#   ----
	
	movia r8, ADDR_JP1 
	
# sensing0:
	# movia	 r9, 0xFFFFFBFF       /* disable all motors, turn on sensor 0 -> set motor on */
	# stwio	 r9, 0(r8)
	
	# ldwio r5, 0(r8) #check for valid data in sensor 0
	# srli r5, r5, 11 #the 11th bit is the valid bit for sensor 0 -> shift it to the right
	# andi r5, r5, 0x1 #comparing the valid bit
	# bne r0, r5, sensing0 #make sure the valid bit is 0 so we can read it
	
# reading0:
	# ldwio r10, 0(r8) #read the bit into r10 
	# srli r10, r10, 27 #The sensor values are located from bit 31 to 27 so shift the bits by that much
	# #andi r10, r10, 0x0f #compare which bits are high
	# #movi r11, 0x0f
	# #bne r11, r10, moving0 #if the sensor is not at equilibrium, then move the motors
	# #br sensing0
	
# sensing1:
	# movia	 r9, 0xFFFFEFFF      /* disable all motors, turn on sensor 1 */
	# stwio	 r9, 0(r8)
	
	# ldwio r5, 0(r8) #check for valid data in sensor 1
	# srli r5, r5, 13 #the 13th bit is the valid bit for sensor 1 -> shift it to the right
	# andi r5, r5, 0x1 #comparing the valid bit
	# bne r0, r5, sensing1 #make sure the valid bit is 0 so we can read it
	
# reading1:
	# ldwio r12, 0(r8) #read the bit into r12 
	# srli r12, r12, 27 #The sensor values are located from bit 31 to 27 so shift the bits by that much
	# #andi r10, r10, r12 #compare which bits are high
	# blt r10, r12, moving0 #if the sensor is not at equilibrium, then move the motors
	# blt r12, r10, moving1
	# br sensing0 #go back to sensing if the sensors are in equilibrium
delay:
	
	br delay
	
	




timingDelay:
	movia	 r16, 0xfffffffc        /* motor0 enabled (bit0=0), direction set to forward (bit1=0) */
	stwio	 r16, 0(r8)
	
	movia r16, TIMER
	
	movui r17, %lo(PERIOD)
	stwio r17, 8(r16)
	
	movui r18, %hi(PERIOD)
	stwio r18, 12(r8)
	

	#turn motor on
	#use timer to delay for 196666 cycles
	
	#turn motor off for 196666 cycles
	
	
#Inturrept sequence
.section .exceptions, "ax"

ISR:
	addi sp, sp, -24
	
	stw r18, 0(sp)
	stw r19, 4(sp)
	stw r20, 8(sp)
	stw r21, 12(sp)
	stw r22, 16(sp)
	stw r23, 20(sp)
	


	# rdctl et, ctl4
	# andi et, et, 0b100000000 #check 8th bit (UART)
	# bne et, r0, KEYINTERRUPT
	
	rdctl et, ctl4 #read the ipending to see which interrupts are active
	#movi et, 1
	andi et, et, 0x1
	bne et, r0, TIMERACTIVE #only branch if timer interrupts
	
	
	br RETURNBACK

TIMERACTIVE:

	movia r20, TIMER
	
	stwio r0, 0(r20) #set flag back down
	
	
#moving0:
	# movia r20, ADDR_JP1 
	movia	 r21, 0xfffffffc        /* motor0 enabled (bit0=0), direction set to forward (bit1=0) */
	stwio	 r21, 0(r20)
	
	# movia r21, thechar
	# ldbio r22, 0(r21)
	
	# beq r22, r0, SHOW_SPEED

	
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
	
	
	
	