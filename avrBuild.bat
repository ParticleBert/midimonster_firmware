cd "C:\Programme\Atmel\AVR Tools\Midimonster\"
C:
del midimonster.map
del midimonster.lst
"C:\Programme\Atmel\AVR Tools\AvrAssembler\avrasm32.exe" -fI "C:\Programme\Atmel\AVR Tools\Midimonster\leds.asm" -o "midimonster.hex" -d "midimonster.obj" -e "midimonster.eep" -I "C:\Programme\Atmel\AVR Tools\Midimonster" -I "C:\Programme\Atmel\AVR Tools\AvrAssembler\AppNotes" -w 
