
.include <bsd.own.mk>

AVRDUDE?=avrdude
AVRPROG?=avrisp
.if ${AVRPROG} == avrisp
AVRPORT?=/dev/ttyU0
AVRBR?=57600
AVRFLAGS?=-c ${AVRPROG} -p ${AVRMCU} -P ${AVRPORT} -b ${AVRBR} -v
.elif ${AVRPROG} == usbtiny
AVRPORT?=/dev/ugen0
AVRFLAGS?=-c ${AVRPROG} -p ${AVRMCU} -P ${AVRPORT}  -v
.else
.BEGIN:
	@echo bsd.avr.mk: ${AVRPROG} is invalid && false
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
CFLAGS +=-mmcu=${MCU} -Os -fno-builtin  -Wall -Werror

.if defined(PROG)
SRCS?=  ${PROG}.c
.  if !empty(SRCS:N*.h:N*.sh)
OBJS+=  ${SRCS:N*.h:N*.sh:R:S/$/.o/g}
.  endif
.endif

.SUFFIXES: .o .S .c

.c.o:
	${CC} ${CFLAGS} ${CPPFLAGS} -c ${.IMPSRC}
.S.o:
	${CC} ${AFLAGS} ${CPPFLAGS} -c ${.IMPSRC}
.s.o:
	${CC} ${AFLAGS} -c ${.IMPSRC}

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
