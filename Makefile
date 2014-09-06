ROOT=.
OUTDIR=${ROOT}/bin
PROJECT=blink
PART=LM4F232H5BB
INC_PATHS=tivaware \
					src

all: ${OUTDIR}
all: ${OUTDIR}/${PROJECT}.axf

${OUTDIR}:
	@mkdir -p ${OUTDIR}

${OUTDIR}/${PROJECT}.axf: src/${PROJECT}.o
${OUTDIR}/${PROJECT}.axf: ${ROOT}/tivaware/startup.o
# Comment this out to make the driverlib .o's yourself
${OUTDIR}/${PROJECT}.axf: ${OUTDIR}/driverlib.a
# ${OUTDIR}/${PROJECT}.axf: ${ROOT}/tivaware/driverlib/gpio.o
# ${OUTDIR}/${PROJECT}.axf: ${ROOT}/tivaware/driverlib/sysctl.o
${OUTDIR}/${PROJECT}.axf: ${ROOT}/tivaware/project.ld

debug:
	@VERBOSE=1 DEBUG=1 make all
	${GDB} -tui ${OUTDIR}/${PROJECT}.axf

clean:
	@rm -rf bin/* $(shell find . -type f -name '*.o' -o -name '*.d')

vpath %.c src

# Compiler binaries
PREFIX=arm-none-eabi
CC=${PREFIX}-gcc
GDB=${PREFIX}-gdb
AR=${PREFIX}-ar
LD=${PREFIX}-ld
OBJCOPY=${PREFIX}-objcopy

# Settings
ENTRY_POINT=ResetISR
CPU=-mcpu=cortex-m4
FPU=-mfpu=fpv4-sp-d16 \
		-mfloat-abi=softfp

# Assembler flags
AFLAGS=-mthumb \
			 -Dgcc \
			 ${CPU} \
			 ${FPU} \
			 -MD
AFLAGS+=${patsubst %,-I%,${subst :, ,${INC_PATHS}}}

# Compiler flags
CFLAGS=-mthumb \
			 -Dgcc \
       ${CPU} \
       ${FPU} \
       -ffunction-sections \
       -fdata-sections \
       -MD \
       -std=c99 \
       -Wall \
       -pedantic \
       -DPART_${PART} \
       -DTARGET_IS_BLIZZARD_RA3 \
       -c
CFLAGS+=${patsubst %,-I%,${subst :, ,${INC_PATHS}}}

ifdef DEBUG
CFLAGS+=-g \
			  -DDEBUG \
			  -O0
else
CFLAGS+=-Os
endif

# Linker flags
LDFLAGS=--gc-sections

# Library files
LIBGCC:=${shell ${CC} ${CFLAGS} -print-libgcc-file-name}
LIBC:=${shell ${CC} ${CFLAGS} -print-file-name=libc.a}
LIBM:=${shell ${CC} ${CFLAGS} -print-file-name=libm.a}

#
# The rule for building the object file from each C source file.
#
%.o: %.c
	@if [ 'x${VERBOSE}' = x ]; \
	then \
	  echo "  CC    ${<}"; \
	else \
	  echo ${CC} ${CFLAGS} -o ${@} ${<}; \
  fi
	@${CC} ${CFLAGS} -o ${@} ${<}

#
# The rule for building the object file from each assembly source file.
#
${OUTDIR}/%.o: %.S
	@if [ 'x${VERBOSE}' = x ]; \
	then \
		echo "  AS    ${<}"; \
	else \
		echo ${CC} ${AFLAGS} -o ${@} -c ${<}; \
	fi
	@${CC} ${AFLAGS} -o ${@} -c ${<}

#
# The rule for creating an object library.
#
DRIVERLIBSRC = ${wildcard tivaware/driverlib/*.c}
${OUTDIR}/driverlib.a: ${DRIVERLIBSRC:.c=.o}
	@if [ 'x${VERBOSE}' = x ]; \
	then \
		echo "  AR    ${@}"; \
	else \
		echo ${AR} -cr ${@} ${^}; \
	fi
	@${AR} -cr ${@} ${^}

#
# The rule for linking the application.
#
${OUTDIR}/%.axf:
	@ldname="${ROOT}/tivaware/project.ld"; \
	if [ 'x${VERBOSE}' = x ]; \
	then \
		echo "  LD    ${@} ${LNK_SCP}"; \
	else \
		echo ${LD} -T $${ldname} \
			--entry  ${ENTRY_POINT} \
			${LDFLAGS} -o ${@} $(filter %.o %.a, ${^}) \
			'${LIBM}' '${LIBC}' '${LIBGCC}'; \
	fi; \
	${LD} -T $${ldname} \
		--entry  ${ENTRY_POINT} \
		${LDFLAGS} -o ${@} $(filter %.o %.a, ${^}) \
		'${LIBM}' '${LIBC}' '${LIBGCC}'
	@${OBJCOPY} -O binary ${@} ${@:.axf=.bin}
	@${OBJCOPY} -O ihex ${@} ${@:.axf=.hex}
