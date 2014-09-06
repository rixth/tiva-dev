ROOT=./
PROJECT=blink
COMPILER=gcc
PART=LM4F232H5BB
INC_PATHS=tivaware \
					src

#
# The default rule, which causes the project example to be built.
#
all: ${COMPILER}
all: ${COMPILER}/${PROJECT}.axf

${COMPILER}:
	@mkdir -p ${COMPILER}

${COMPILER}/${PROJECT}.axf: ${COMPILER}/${PROJECT}.o
${COMPILER}/${PROJECT}.axf: ${ROOT}/tivaware/startup_${COMPILER}.o
${COMPILER}/${PROJECT}.axf: ${ROOT}/tivaware/driverlib/${COMPILER}/libdriver.a
${COMPILER}/${PROJECT}.axf: ${ROOT}/tivaware/project.ld

clean:
	@rm -rf ${COMPILER} ${wildcard *~}

vpath %.c src

# Compiler binaries
PREFIX=arm-none-eabi
CC=${PREFIX}-gcc
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
			 ${CPU} \
			 ${FPU} \
			 -MD
AFLAGS+=${patsubst %,-I%,${subst :, ,${INC_PATHS}}}

# Compiler flags
CFLAGS=-mthumb \
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
			  -D DEBUG \
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
${COMPILER}${SUFFIX}/%.o: %.c
	@if [ 'x${VERBOSE}' = x ]; \
	then \
	  echo "  CC    ${<}"; \
	else \
	  echo ${CC} ${CFLAGS} -D${COMPILER} -o ${@} ${<}; \
  fi
	@${CC} ${CFLAGS} -D${COMPILER} -o ${@} ${<}

#
# The rule for building the object file from each assembly source file.
#
${COMPILER}${SUFFIX}/%.o: %.S
	@if [ 'x${VERBOSE}' = x ]; \
	then \
		echo "  AS    ${<}"; \
	else \
		echo ${CC} ${AFLAGS} -D${COMPILER} -o ${@} -c ${<}; \
	fi
	@${CC} ${AFLAGS} -D${COMPILER} -o ${@} -c ${<}

#
# The rule for creating an object library.
#
${COMPILER}${SUFFIX}/%.a:
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
${COMPILER}${SUFFIX}/%.axf:
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
