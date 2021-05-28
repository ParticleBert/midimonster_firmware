;--------------------------------------- timer1 compare isr ----------------------------------------------	
clock:
	sbi usr,txc				;TX-Flag L�SCHEN, zur sicherheit

	out	udr,clock			;clock-tick ans uart

	brtc kein_t_flag			;gehe weiter, wenn t nicht gesetzt ist
	out	OCR1AH,r1			;sonst lade neuen
	out	OCR1AL,r0			;comparewert
	clt						;und l�sche t-flag


kein_t_flag:
;
;	sbis usr,txc
;	rjmp nochmal

;	sbi usr,txc				;TX-Flag L�SCHEN!

	cp ticks,ticks_max		;hat ticks schon die max. anzahl erreicht?
	brne weg				;wenn nein, raus
	inc beats				;wenn ja, erh�he den BEAT
	clr	ticks				;und l�sche den TICKS-z�hler


dingsbums:
	cp beats, beats_max		;ist BEATS auch schon am maximum?
	brne weg				;wenn nein, weg



	clr	beats				;wenn ja, l�sche BEATS
	
							
					
	tst flags				;ist flags null?
	breq weg				;wenn ja -> weg


	rcall flag_warten		;wenn nein, warten bis CLOCK endg�ltig raus ist, da mind. ein START folgt

	
	asr flags				;flags einmal nach rechts shiften
	brcs weiter_testen		;wenn carry gesetzt (hei�t, int0 wurde angefordert) gehe zu weiter_testen
							;ansonsten mache hier weiter, das hei�t,
							;da� NUR int1 angefordert wurde.


	cbi portd,and0			;and0 l�schen

	out udr,stop			;stop rausschicken

	rcall flag_warten

	
	out udr,start			;start rausschicken

	rcall flag_warten

	sbi portd,and0			;and0 wieder setzen

	rjmp int_kill			;und raus

weiter_testen:

	asr flags				;flags nochmal shiften
	brcs start_an_beide		;wenn carry=1 wurden int0 und int1 angefordert
							;und es mu� einfach nur ein start raus, ohne gate zu setzen.

	cbi portd,and1			;ansonsten wurde nur int1 angefordert
	out udr,stop
	
	rcall flag_warten			;und es gibt den start...

	out udr,start

	rcall flag_warten
	sbi portd,and1
	rjmp int_kill
	
start_an_beide:		
	out udr,stop			;stop raus
	rcall flag_warten
	
	out udr,start			;start raus
	rcall flag_warten

;	clr flags

int_kill:
	clr	flags



weg:
	inc	ticks
	reti
