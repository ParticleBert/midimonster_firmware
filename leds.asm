;---- verwendete register
; r16 - temp
; r17 - beinhaltet clock (f8)
; r18 - beinhaltet start (fa)
; r19 - beinahlete stop (fc)
; r20 - ticks hochzählen
; r21 - beats
; r22 - beinhaltet ticks_max (24)
; r23 - beinhaltet beats_max (4)
; r28 - beats hochzählen
; r31 - flags


.include "macros.asm"


;reload compare low = r0
;reload compare high= r1

.def bpm_alt		= r2
.def bpm_rechts     = r3
.def bpm_mitte 		= r4
.def bpm_links		= r5
.def beats_max 		= r6
.def ticks_max 		= r7
.def ascii_null		= r12
.def clock 			= r13
.def start 			= r14
.def stop 			= r15

.def temp 			= r16
.def flags			= r17
.def anim			= r18
.def bpm			= r19
.def ticks 			= r20
.def beats 			= r21
.def LSD			= r22
.def MSD			= r23


.def beats_digit 	= r24
.def zaehldummy     = r25

;xl wird benutzt	= r26	als...
;xh wird benutzt	= r27   ...tabellen-sicherungs-zeiger

;yl wird benutzt	= r28    als
;yh wird benutzt	= r29    ... animationszeiger

;zl wird benutzt    = r30   als ...
;zh wird benutzt    = r31   ..... arbeitszeiger auf die tabelle

.equ schalter = 6

.equ and1 = 0
.equ and0 = 4

.equ write = 7

.equ a0 = 5
.equ a1 = 6


.include "2313def.inc"       ;Definitionsdatei einbinden,
                             
.org 0x00
 	 	 rjmp main        ; Reset Handler
         rjmp i0service   ; IRQ0 Handler
         rjmp i1service   ; IRQ1 Handler
         reti             ; Timer1 Capture Handler
         rjmp clock       ; Timer1 compare Handler
         reti             ; Timer1 Overflow Handler
         rjmp timer0_overflow             ; Timer0 Overflow Handler
         reti             ; UART RX Complete Handler
         reti             ; UDR Empty Handler
         reti             ; UART TX Complete Handler
         reti             ; Analog Comparator Handler

main:           

	ldi	temp,RAMEND			;stackpointer
	out	SPL,temp			;einrichten

;Konstanten definieren	


	ldi	temp,$f8			;midi clock definieren
	mov	clock,temp

	ldi temp,$fa			;midi start
	mov	start,temp

	ldi	temp,$fc			;midi stop
	mov	stop,temp


	ldi temp,24				;ticks_max definieren
	mov ticks_max,temp

	ldi temp,4
	mov beats_max,temp		;beats_max definieren

	ldi	temp,$20			;ascii-null definieren
	mov	ascii_null,temp

	clr yh				;yh löschen
	ldi	yl,$60			;zeiger für animation auf anfang SRAM
	
	ldi anim,$2d		;5 fetzige asciis
	st y+,anim			;ins sram

	ldi anim,$2b
	st y+,anim

	ldi anim,$2a
	st y+,anim
	
	ldi anim,$30
	st y,anim			;  bis hierher!

	ldi	temp,135			;135 als init-bpm
	mov	bpm,temp

;Ports definieren	
	ldi	temp,$ff
	out	ddrd,temp			;port d als ausgang
	
	ldi	temp,0b10111111
	out	ddrb,temp			;port b nicht alles als ausgang

	ldi temp,$ff
	out portd,temp
	
;UART einstellen
	ldi	temp,$7			
	out UBRR,temp			;7 in das ubrr schreiben, entspricht 31.250 bit/s bei 4 mhz
		
	sbi	ucr,TXEN			;uart darf senden


;TIMER einstellen	
	
	ldi temp,(1<<CTC1) | (1<<CS11)				;clock select bit 1 AN
												; -> 8fach teilung des taktes
												;clear timer bei compare match
	out	tccr1b,temp			


	ldi	zl,low(tabelle)							;zeiger auf tabelle setzen
	ldi zh,high(tabelle)						;.....

	adiw zl,55									;bpm-init auf 135
												;in der tabelle 55 plätze nach vorne

	mov	xl,zl									;zeiger in xl sichern
	mov	xh,zh									;zeiger in xh sichern



	sec											;carry setzen										
	rol	zl										;zl nach links rollen, carry (1) fällt an bit 0
	rol zh										;zh nach links rollen

	lpm											;high-byte laden
	mov	r1,r0									;high-byte liegt in r1
	cbr zl,1									;bit 0 löschen
	lpm											;low-byte laden

	
	
	out	OCR1AH,r1								;...comparewert
	out	OCR1AL,r0								;laden
	

	
	ldi	temp,(1<<OCIE1A) | (1<<TOIE0)			;timer 1 interrupt register
	out	timsk,temp								;enable timer 1 compare interrupt, enable timer0 overflow interrupt

	ldi temp, (1<<CS00) | (1<<CS02)				;tccr0/timer0 teilung auf clc/1024
	out tccr0,temp



	ldi temp,(1<<int1) | (1<<int0)
	out gimsk,temp			;externer interrupt 0 und 1 AN

	ldi temp,$a
	out mcucr,temp			;ext. int 0 und 1 low-flanken empfindlich

	clr	ticks				;ticks-register löschen
	clr	beats				;beats-register löschen

	clr flags				;flags-register löschen
	sei						;interrupts global aktivieren


	
spring:
	rjmp	spring	
	
;--------------------------- timer 1 compare isr ------------------------------------------------
.include "t1isr.asm"
;---------------------------------------------- ext0 isr ----------------------------------------
i0service:

	sbis pinb,schalter		;wenn schalter=0
	rjmp i0_flags			;springe NICHT zum flag-setzen
		
	mov	zl,xl				;sicheren tabellenpointer
	mov zh,xh				;in z kopieren

	inc bpm					;bpm erhöhen
	adiw xl,1				;tabelle eins nach oben

	sec						;carry setzen
	rol	zl					;zl nach links rollen, carry fällt rein wg. high-byte
	rol	zh					;zh nach links rollen
	lpm						;high-byte holen

	tst r0
	breq tabellenende_dec
	mov r1,r0				;high-byte in r1
	cbr zl,1				;bit0 löschen wg. low-byte
	lpm						;low-byte holen
	set						;t-flag setzen

 	clr temp				;ext. interrupts aus...
	out gimsk,temp			;...machen

	rjmp i0_raus

tabellenende_dec:
	dec bpm					;erhöhten bpm-zähler korrigieren
	sbiw xl,1				;tabelle wieder einen runter
	clt						;t_flag wieder löschen
	

	sbis pinb,schalter
i0_flags:
	sbr flags,1									

i0_raus:
	reti
;---------------------------------------------- ext1 isr ----------------------------------------
;i1 ist linker taster
i1service:

	sbis pinb,schalter		;wenn schalterbit null
	rjmp i1_flags			;springe zur flageinstellung

	mov	zl,xl				;sicheren tabellenpointer
	mov zh,xh				;in z kopieren

	dec bpm					;bpm erniedrigen
	sbiw xl,1				;tabelle eins nach unten

	sec						;carry setzen
	rol	zl					;zl nach links rollen, carry fällt rein wg. high-byte
	rol	zh					;zh nach links rollen
	lpm						;high-byte holen

	tst r0
	breq tabellenende_inc
	mov r1,r0				;high-byte in r1
	cbr zl,1				;bit0 löschen wg. low-byte
	lpm						;low-byte holen
	set						;t-flag setzen


	clr temp				;ext. interrupts aus...
	out gimsk,temp			;...machen
	
	rjmp i1_raus

tabellenende_inc:
	inc bpm					;erniedrigten bpm-zähler korrigieren
	adiw xl,1				;tabelle wieder einen hoch
	clt						;t_flag wieder löschen


	sbis pinb,schalter
i1_flags:
	sbr flags,2									

i1_raus:
	reti


;-------------------------------------------------- timer0 ISR -----------------------------------
;wenn pinb.6 = 1 -> bpm
;wenn pinb.6 = 0 -> tick
timer0_overflow:

;	cbr zaehldummy,0b11111110
;	tst zaehldummy				;wenn der dummy nicht null
;	brne timer0_raus			;

	mov		beats_digit,beats			;immer
	cbr		beats_digit,0b11111100		;rotierenden
	inc		beats_digit					;pfeil
	digit_0 beats_digit					;anzeigen!

	inc  zaehldummy						;immer den zaehldummy erhöhen

	sbis	pinb,schalter		;wenn schalter = 1 (tick-modus)
	rjmp 	tick_modus			;gehe NICHT raus sondern mach weiter

	

	mov lsd,bpm
	rcall bin2bcd8
	ascii LSD					;lsd in ascii wandeln
	mov bpm_rechts,LSD
	mov LSD,MSD
	rcall bin2bcd8
	ascii lsd
	mov bpm_mitte, LSD
	ascii msd
	mov bpm_links, MSD

	digit_1 bpm_rechts
	digit_2 bpm_mitte
	digit_3 bpm_links

	mov bpm_alt,bpm				;sichere bpm-wert in bpm_alt

nur_ints_an:
	sbr temp,0b11000000
	out gifr,temp
	ldi temp,0b11000000
	out gimsk,temp
	rjmp timer0_raus

tick_modus:

	andi yl,$3					;letzten beiden bits stehenlassen
	ori yl,$60					;auf sram-groesse bringen

	ld anim,y+

	tst flags							;flags testen
	breq mitte_nullen					;wenn null, gib nullen in der mitte aus
;flag 1 ist rechter taster, rechte anim, int0
;flag 2 ist linker taster, linke anim, int1

	sbrc flags,0						;wenn flag1 nicht gesetzt ist
	rcall anim_rechts					;gib anim rechts auch nicht aus

	digit_2 anim						;aber flag2 muss gesetzt sein, also linke anim ausgeben
	rjmp dreh_eins						;und zur eins


mitte_nullen:
	digit_1 ascii_null
	digit_2 ascii_null





dreh_eins:
	sbr		beats_digit,0b110000		;drehende eins links generieren
	digit_3 beats_digit					;und raus

	
	
	
timer0_raus:
	reti



anim_rechts:
	digit_1 anim						;rechte anim ausgeben
	sbrc flags,1						;wenn flag 2 nicht gesetzt ist
	ret									;spring nicht zurück, wo Du flag 2 ausgeben müßtest

	in temp,spl								;sondern korrigiere den stack
	inc temp
	inc temp
	out spl,temp
	rjmp dreh_eins						;und springe zur dreh_eins





; ------------------------- bin 2 bcd-wandlung ----------------------------------------------
bin2bcd8:
	clr	MSD		;clear result MSD

bBCD8_1:
	subi	LSD,10		;input = input - 10
	brcs	bBCD8_2		;abort if carry set
	inc	MSD		;inc MSD
	rjmp	bBCD8_1		;loop again

bBCD8_2:
	subi	LSD,-10	;compensate extra subtraction
	ret





;----------------------------------------- beat-nachlade-tabelle ---------------------------------

.include "tabelle.asm"