
.include <bsd.own.mk>

AVRDUDE?=avrdude

# calculate default mcu type for avrdude and cpp define
.if ${MCU} == attiny44
AVRMCU?=t44
CPPFLAGS+=-D__AVR_ATtiny44__
.elif ${MCU} == attiny45
AVRMCU?=t45
CPPFLAGS+=-D__AVR_ATtiny45__
.elif ${MCU} == attiny84
AVRMCU?=t84
CPPFLAGS+=-D__AVR_ATtiny84__
.elif ${MCU} == atmega168
AVRMCU?=m168
CPPFLAGS+=-D__AVR_ATmega168__
.elif ${MCU} == atmega328p
AVRMCU?=m328p
CPPFLAGS+=-D__AVR_ATmega328P__
.elif ${MCU} == atmega1280
AVRMCU?=m1280
CPPFLAGS+=-D__AVR_ATmega1280__
.elif ${MCU} == atmega2561
AVRMCU?=m2561
CPPFLAGS+=-D__AVR_ATmega2561__
.else
.BEGIN::
	@echo bsd.avr.mk: MCU=${MCU} is invalid && false
.endif

AVRPROG?=avrisp
.if ${AVRPROG} == avrisp
AVRPORT?=/dev/ttyU0
AVRBR?=57600
AVRFLAGS?=-c ${AVRPROG} -p ${AVRMCU} -P ${AVRPORT} -b ${AVRBR} -v
.elif ${AVRPROG} == usbtiny
AVRPORT?=/dev/ugen0
AVRFLAGS?=-c ${AVRPROG} -p ${AVRMCU} -P ${AVRPORT}  -v
.else
.BEGIN::
	@echo bsd.avr.mk: AVRPROG=${AVRPROG} is invalid && false
.endif

SHELL	= sh
SUDO	= sudo
AS	= avr-as
CC	= avr-gcc
OBJCOPY	= avr-objcopy
OBJDUMP	= avr-objdump
SIZE	= size
CPPFLAGS+= -DF_CPU=${FREQ}
MKDEP  += -I/usr/local/avr/include
CFLAGS += -mmcu=${MCU} -Os -fno-builtin  -Wall -Werror
CFLAGS += -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
AFLAGS += -mmcu=${MCU}

.SUFFIXES: .o .S .c

.c.o:
	${CC} ${CFLAGS} ${CPPFLAGS} -c ${.IMPSRC}
.S.o:
	${CC} ${AFLAGS} ${CPPFLAGS} -c ${.IMPSRC}
.s.o:
	${CC} ${AFLAGS} -c ${.IMPSRC}

.if defined(PROG)
.  if !defined(SRCS) || empty(SRCS)
.    if exists(${PROG}.c)
SRCS?=  ${PROG}.c
.    elif exists(${PROG}.S)
SRCS?=  ${PROG}.S
.    elif exists(${PROG}.s)
SRCS?=  ${PROG}.s
.    endif
.  endif
.  if !empty(SRCS:N*.h:N*.Sh)
OBJS+=  ${SRCS:N*.h:N*.Sh:R:S/$/.o/g}
.  endif
.endif

CLEANFILES+=${PROG}.eep ${PROG}.hex ${PROG}.lss

${PROG}: ${OBJS}
	${CC} ${CFLAGS} ${LDFLAGS} -o ${PROG} ${OBJS} ${LDADD}
	@$(OBJDUMP) -h -S ${PROG} > ${PROG}.lss
	@${SIZE} ${PROG}

${PROG}.hex: ${PROG}
	${OBJCOPY} -Oihex -R .eeprom ${PROG} ${PROG}.hex

${PROG}.eep: ${PROG}
	${OBJCOPY} -j .eeprom --set-section-flags=.eeprom="alloc,load" \
	  --change-section-lma .eeprom=0 --no-change-warnings \
	  -O ihex ${PROG} ${PROG}.eep

all: ${PROG}.hex ${PROG}.eep

fuse:
	${AVRDUDE} ${AVRFLAGS} -B 100 -U hfuse:w:0xd0:m
	${AVRDUDE} ${AVRFLAGS} -B 100 -U lfuse:w:0xe7:m
	${AVRDUDE} ${AVRFLAGS} -B 100 -U efuse:w:0xfd:m

burn: ${PROG}.hex ${PROG}.eep
	${AVRDUDE} ${AVRFLAGS} -B 10 -U flash:w:${PROG}.hex -U eeprom:w:${PROG}.eep

clean cleandir:
	rm -f a.out [Ee]rrs mklog core *.core ${PROG} ${OBJS} ${CLEANFILES}

.include <bsd.obj.mk>
.include <bsd.dep.mk>
.include <bsd.subdir.mk>
.include <bsd.sys.mk>
