.macro digit_0
	cbi portd,a0
	cbi	portd,a1
	out	portb,@0
	cbi	portb,write
	sbi	portb,write
.endm

.macro digit_1
	sbi portd,a0
	cbi	portd,a1
	out	portb,@0
	cbi	portb,write
	sbi	portb,write
.endm

.macro digit_2
	cbi portd,a0
	sbi	portd,a1
	out	portb,@0
	cbi	portb,write
	sbi	portb,write
.endm

.macro digit_3
	sbi portd,a0
	sbi	portd,a1
	out	portb,@0
	cbi	portb,write
	sbi	portb,write
.endm

.macro ascii
	sbr	@0,0b110000
.endm
