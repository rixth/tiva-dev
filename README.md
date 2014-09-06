# tiva-dev

This is a blank state for development for the Tiva TM4C123G microcontrollers from Texas Instruments. The TM4C123GH6PM is available on a [$15 Launchpad board](http://www.ti.com/tool/ek-tm4c123gxl).

Also bundled is TI's "Tivaware" software package. The `Makefile` is based off the one provided by TI.

## Programming

I have used OpenOCD for programming & debugging over the In-Circuit Debug Interface (ICDI).

1. Start openocd: `openocd -f /usr/local/share/openocd/scripts/board/ek-tm4c123gxl.cfg`
2. Start gdb: `arm-none-eabi-gdbtui gcc/blink.axf`

Starting gdb will automatically flash the device and restart it. If you want to modify this behaviour, edit `.gdbinit`.

If you want to debug symbols in your compiled `.axf`, set `DEBUG=1` when invoking `make`.