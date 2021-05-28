;--------------------------------------- timer1 compare isr ----------------------------------------------	
clock:
	sbi usr,txc				;TX-Flag LÖSCHEN!
	out	udr,clock			;clock-tick ans uart

	brtc nochmal			;gehe weiter, wenn t nicht gesetzt ist
	out	OCR1AH,r1			;sonst lade neuen
	out	OCR1AL,r0			;comparewert
	clt						;und lösche t-flag


nochmal:
	sbis usr,txc
	rjmp nochmal

	sbi usr,txc				;TX-Flag LÖSCHEN!

	cp ticks,ticks_max		;hat ticks schon die max. anzahl erreicht?
	brne weg				;wenn nein, raus
	inc beats				;wenn ja, erhöhe den BEAT
	clr	ticks				;und lösche den TICKS-zähler

	mov		beats_digit,beats			;beat-zähl-anzeige vorbereiten
	cbr		beats_digit,0b11111100
	inc		beats_digit


	digit_0 beats_digit

	sbic	pinb,schalter	;wenn schalter = 0
	rjmp	dingsbums		;überspringe diese anweisung
							;dann bist Du im bpm-modus
	
	sbr		beats_digit,0b110000		;und auf ascii-niveau bringen
	
	digit_3 beats_digit

dingsbums:
	cp beats, beats_max		;ist BEATS auch schon am maximum?
	brne weg				;wenn nein, weg



	clr	beats				;wenn ja, lösche BEATS
	
							
					
	tst flags				;ist flags null?
	breq weg				;wenn ja -> weg

	asr flags					;wenn nicht, einmal nach rechts shiften
	brcs weiter_testen		;wenn carry gesetzt (heißt, int0 wurde angefortert) gehe zu weiter_testen
							;ansonten mache hier weiter, das heißt,
							;daß NUR int1 angefordert wurde.

	cbi portd,and0			;and0 löschen
	out udr,start			;start rausschicken
nochmal_1:					;warten..
	sbis usr,txc			;bis...
	rjmp nochmal_1			;fertig...
	sbi portd,and0			;and0 wieder setzen

	rjmp int_kill

weiter_testen:

	asr flags				;flags nochmal shiften
	brcs start_an_beide		;wenn carry=1 wurden int0 und int1 angefordert
							;und es muß einfach nur ein start raus, ohne gate zu setzen.

	cbi portd,and1			;ansonsten wurde nur int1 angefordert
	out udr,start			;und es gibt den start...
nochmal_3:					;nur..
	sbis usr,txc			;für
	rjmp nochmal_3			;int..
	sbi portd,and1			;1....

	rjmp int_kill
	
start_an_beide:		
	out udr,start			;start raus, und weg.

	clr flags

int_kill:
	clr	flags



weg:
	inc	ticks
	reti
