
# makefile helper for building fpga images (for xilinx)

.if exists(${.CURDIR}/../Makefile.inc)
.include "${.CURDIR}/../Makefile.inc"
.endif

.include <bsd.own.mk>

XXX?=/home/Xilinx/11.1/ISE/bin/lin/unwrapped/
XST?=${XXX}/xst
XNETGEN?=${XXX}/netgen
XNGBUILD?=${XXX}/ngdbuild
XNGBOPTS?=-nt on -p ${XFPGA} -uc ${.CURDIR}/${XARCH}.ucf
XMAP?=${XXX}/map
XMAPOPTS?=-pr b
XPAR?=${XXX}/par
XPAROPTS?=-w -ol high
XTRCE?=${XXX}/trce
XTRCEOPTS?=-v 10 -fastpaths
XBITGEN?=${XXX}/bitgen

XUPLOAD?=xc3sprog

.if empty(XFPGA)
.error "must define XFPGA"
.endif

.if empty(XARCH)
.error "must define XARCH"
.endif

.if defined(PROG)
SRCS?=${PROG}.vhd
.endif

CLEANFILES+=${PROG}.prj ${PROG}.xst ${PROG}.ncd ${PROG}.ngd ${PROG}.pcf
CLEANFILES+=${PROG}.ngc ${PROG}.srp ${PROG}.bld ${PROG}.bit ${PROG}.bgn
CLEANFILES+=${PROG}.drc ${PROG}.map ${PROG}.mrp ${PROG}.msk ${PROG}.ngm
CLEANFILES+=${PROG}.pad ${PROG}.par ${PROG}.twr ${PROG}.twx ${PROG}.xpi
CLEANFILES+=${PROG}.ll ${PROG}.ptwx ${PROG}.unroutes

all: ${PROG}.bit

.if !target(clean)
clean: _SUBDIRUSE
	rm -f *.xrpt *.lst ${CLEANFILES}
.endif

${PROG}.prj: ${SRCS}
	for i in ${SRCS}; do echo verilog work ${.CURDIR}/$$i; done > ${PROG}.prj

${PROG}.xst: ${PROG}.prj
	printf "run\n-top %s\n-ifn %s\n-ifmt %s\n-ofn %s\n-ofmt NGC\n-p %s\n-opt_mode Area\n-opt_level 2" ${PROG} ${PROG}.prj MIXED ${PROG}.ngc ${XFPGA} > ${PROG}.xst

${PROG}.srp: ${PROG}.xst
	${XST} -ifn ${PROG}.xst -ofn ${PROG}.srp -intstyle xflow

${PROG}.ncd: ${PROG}.srp ${.CURDIR}/${XARCH}.ucf
	${XNGBUILD} ${XNGBOPTS} ${PROG}.ngc ${PROG}.ngd
	${XMAP} ${XMAPOPTS} -o ${PROG}.ncd ${PROG}.ngd ${PROG}.pcf
	${XPAR} ${XPAROPTS} ${PROG}.ncd ${PROG}.ncd ${PROG}.pcf
	${XTRCE} ${XTRCEOPTS} -o ${PROG}.twr ${PROG}.ncd ${PROG}.pcf

${PROG}.bit: ${PROG}.ncd
	${XBITGEN} -w -l -m -t ${PROG}.ncd

upload:
	${XUPLOAD} ${PROG}.bit

.include <bsd.obj.mk>
.include <bsd.subdir.mk>
.include <bsd.sys.mk>
