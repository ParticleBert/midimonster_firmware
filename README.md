# midimonster_firmware

**A blast from the past - the old firmware for the first midimonster back in 2002.**

I don't know why I have written this in assembler. I don't even know the processor type anymore.

This processor had one UART. To be able to control two MIDI-Outputs I used two AND-Gates to drive the MIDI-Ports and control the output via this AND-Gate.

The math to calculate between BPM and Time-Between-Ticks was too difficult for me and the small processor, so I used a conversion table.

I also don't know the type of the display any more.

