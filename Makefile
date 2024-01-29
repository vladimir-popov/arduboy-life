#==================================================	
#             Required variables
#==================================================	

# The follow variables should be specified according 
# to your file system:

# The title of the project:
# (it would be better to avoid using space symbols, 
# because this variable will be used as a name of the
# final binary files)
TITLE=life

# Path to the arduino installation:
ARDUINO_DIR=$(HOME)/Library/Arduino15/packages/arduino

# Path to the directory with already installed arduino libraries:
ARDUINO_LIBS_DIR=$(HOME)/Projects/Arduino/libraries

#==================================================	
#             Optional variables
#==================================================	

LOCAL_TEST=true

# Path to the sources of a test library:
# (optional. If not set, then the target `test` will be unavailable)
TEST_FRAMEWORK_DIR=$(HOME)/Projects/Arduino/Unity

# Path to the ArdensPlayer - arduboy emmulator, to run the final *.hex file.
# (optional. If not set, then the target `emulate` will be unavailable)
ARDENS=$(HOME)/Projects/Arduino/Ardens/Ardens

#==================================================	
#             Relative paths
#==================================================	

# Please, verify version of the libs and tools.
# They may be out of date!

# Path to the directory with avr binaries:
AVR_DIR=$(ARDUINO_DIR)/tools/avr-gcc/7.3.0-atmel3.6.1-arduino7

# Path to the directory with hardware libs:
ARDUINO_HARDWARE_DIR=$(ARDUINO_DIR)/hardware/avr/1.8.6

# Path to the directory with core lib sources:
ARDUINO_CORE_DIR=$(ARDUINO_HARDWARE_DIR)/cores/arduino

# Path to the directory with EEPROM lib sources:
ARDUINO_EEPROM=$(ARDUINO_HARDWARE_DIR)/libraries/EEPROM/src

# Path to the directory with Arduboy2 sources:
ARDUBOY2_DIR=$(ARDUINO_LIBS_DIR)/Arduboy2/src

# A target to show variables:
# Example: make print-ARDUINO_DIR
print-%  : ; @echo $* = $($*)

#==================================================	
#                 Project structure
#==================================================	


# The current working directory:
CWD=$(shell pwd)

SRC_DIR=src
TEST_DIR=test
OUTPUT_DIR=output
OUTPUT_AVR=$(OUTPUT_DIR)/avr
OUTPUT_DEV=$(OUTPUT_DIR)/dev

# Prepare the project:
# - validate variables;
# - create the symbolic links;
.PHONY: init
init:
ifndef ARDUINO_DIR
	$(error 'Variable ARDUINO_DIR must be specified.')
endif
ifndef ARDUINO_LIBS_DIR
	$(error 'Variable ARDUINO_LIBS_DIR must be specified.')
endif
	@[ -d $(OUTPUT_DIR) ] 			|| mkdir -p $(OUTPUT_DIR)
	@touch $(OUTPUT_DIR)/compile_commands.objs
	@[ -d $(CWD)/libs ] 			|| mkdir $(CWD)/libs
	@[ -d $(CWD)/libs/arduino ] 		|| ln -s $(ARDUINO_CORE_DIR) 	$(CWD)/libs/arduino
	@[ -d $(CWD)/libs/arduboy2 ] 		|| ln -s $(ARDUBOY2_DIR) 	$(CWD)/libs/arduboy2
ifdef TEST_FRAMEWORK_DIR
	@[ -d $(CWD)/libs/test_framework ] 	|| ln -s $(TEST_FRAMEWORK_DIR) 	$(CWD)/libs/test_framework
endif

#==================================================	
#        Compilation and build settings
#==================================================	

# The c compiler
CC=$(AVR_DIR)/bin/avr-gcc

# The c++ compiler
CPP=$(AVR_DIR)/bin/avr-g++

ifdef LOCAL_TEST
# Compilers to build local tests:
GCC=gcc
GCPP=g++
endif

# Tool to build *.hex files:
OBJCPY=$(AVR_DIR)/bin/avr-objcopy

# Tool to get size of the result:
AVR_SIZE=$(AVR_DIR)/bin/avr-size

# From: $(ARDUINO_DIR)/packages/arduino/hardware/avr/1.8.6/boards.txt
# leonardo.upload.maximum_size=28672
# leonardo.upload.maximum_data_size=2560
MAXIMUM_SIZE=28672
MAXIMUM_DATA_SIZE=2560


# The compilers options:

# Arduboy is equal to Arduino Leaonardo, which is atmega32u4;
MCU=-mmcu=atmega32u4

# CPU speed for Leonardo is:
CPU_SPEED=-DF_CPU=16000000UL

# List of arduino specific options:
DARDUINO=-DARDUINO=10607 -DARDUINO_AVR_LEONARDO -DARDUINO_ARCH_AVR

# List of USB specific options:
DUSB=-DUSB_VID=0x2341 -DUSB_PID=0x8036

# Add directories with headers:
INCLUDE=-I$(AVR_DIR)/avr/include 			\
	-I$(ARDUINO_HARDWARE_DIR)/variants/leonardo 	\
	-I$(ARDUINO_EEPROM) 				\
	-I$(ARDUINO_CORE_DIR)   			\
	-I$(ARDUBOY2_DIR) 				\
	-I$(SRC_DIR)

ifdef TEST_FRAMEWORK_DIR
INCLUDE_TEST_FRAMEWORK=-I$(TEST_FRAMEWORK_DIR)
endif

# The common for gcc and  g++ compilers flags:
# -Os 				- Optimize for size;
# -MMD				- Instead of outputting the result of preprocessing, output a rule 
#  				  suitable for make describing the dependencies of the header file.
# -flto				- This option runs the standard link-time optimizer. When invoked with 
#  				  source code, it generates GIMPLE (one of GCC’s internal representations)
#  				  and writes it to special ELF sections in the object file. When the 
#  				  object files are linked together, all the function bodies are read from 
#  				  these ELF sections and instantiated as if they had been part of the same 
#  				  translation unit.
# -ffunction-sections 		- Generates a separate ELF section for each function in the source file. 
#  				  The unused section elimination feature of the linker can then remove 
#  				  unused functions at link time.
# -fdata-sections		  Enables the generation of one ELF section for each variable in the 
#  				  source file.
CFLAGS= -g -Os -MMD -flto 		\
	-ffunction-sections 	\
	-fdata-sections 	\
	$(MCU) 			\
	$(CPU_SPEED) 		\
	$(DARDUINO) 		\
	$(DUSB) 		\
	$(INCLUDE)

# C++ specified flags:
# -fno-threadsafe-statics 	- Do not emit the extra code to use the routines specified in 
#  			     	  the C++ ABI for thread-safe initialization of local statics;
# -fno-exceptions 		- We're not going to handle errors, so, let's
#  				  turn it off;
# -fpermissive 			- Downgrade some diagnostics about nonconformant code from 
#  				  errors to warnings;
CPPFLAGS = $(CFLAGS) \
	   -fno-threadsafe-statics \
	   -fno-exceptions \
	   -fpermissive \

# The linker options:
# -mmcu 	      - It is important to specify the MCU type when linking. The compiler uses the -mmcu option 
# 		  	to choose start-up files and run-time libraries that get linked together. If this option 
# 		  	isn't specified, the compiler defaults to the 8515 processor environment, which is most 
# 		  	certainly what you didn't want.
# -Wl,--gc-sections   - This will perform a garbage collection of code and data never referenced. 
#  			See https://gcc.gnu.org/onlinedocs/gnat_ugn/Compilation-options.html for more details.
LDFLAGS = -fuse-linker-plugin $(MCU) -Os -flto -Wl,--gc-sections

# Arduino core has assembler files, so, we have to be ready to compile them:
ASM=-xassembler-with-cpp

ifdef LOCAL_TEST
# Flags to check memory on test:
ASANFLAGS  = 	-fsanitize=address \
		-fno-common \
		-fno-omit-frame-pointer
endif

# The function to run compiler, generate a command object, 
# and append it to the $(OUTPUT_DIR)/compile_commands.objs file
# only if it doesn't contain a record about the source file.
# Arguments:
# 1 - a source file
# 2 - output file
# 3 - compiler
# 4 - compiler's flags
# How it works:
# - The first grep checks is the file already contains a command for the source
#   file;
# - If not, the record about compilation command is inserted to the file;
# - Then compilation is run.
compile=(grep -qF '"file": "$1"' $(OUTPUT_DIR)/compile_commands.objs || \
	echo '{ "directory": "$(PWD)", "file": "$1", "output": "$2", "command": "$3 $4" }' \
	>> $(OUTPUT_DIR)/compile_commands.objs) \
	&& $3 $4 -c -o $2 $1

# Compile assembler *.S files for avr platform:
$(OUTPUT_AVR)/%.S.o: $(CWD)/%.S
	@mkdir -p $(@D)
	@$(call compile,$<,$@,$(CC),$(MCU) $(ASM))
	@echo '$< has been compiled'

# Compile *.c files for avr platform:
$(OUTPUT_AVR)/%.c.o: $(CWD)/%.c 
	@mkdir -p $(@D)
	@$(call compile,$<,$@,$(CC),$(CFLAGS))
	@echo '$< has been compiled'

# Compile *.cpp files for avr platform:
$(OUTPUT_AVR)/%.cpp.o: $(CWD)/%.cpp
	@mkdir -p $(@D)
	@$(call compile,$<,$@,$(CPP),$(CPPFLAGS))
	@echo '$< has been compiled'

$(OUTPUT_AVR)/%.d: $(OUTPUT_AVR)/%.o


ifdef LOCAL_TEST
# Compile *.c files for tests:
$(OUTPUT_DEV)/%.c.o: $(CWD)/%.c 
	@mkdir -p $(@D)
	@$(call compile,$<,$@,$(GCC),-g $(INCLUDE_TEST_FRAMEWORK) -I$(SRC_DIR))
	@echo '$< has been recompiled for test'

# Compile *.cpp files for tests:
$(OUTPUT_DEV)/%.cpp.o: $(CWD)/%.cpp
	@mkdir -p $(@D)
	@$(call compile,$<,$@,$(GCPP),-g $(INCLUDE_TEST_FRAMEWORK) -I$(SRC_DIR))
	@echo '$< has been recompiled for test'
endif

#==================================================	
#              Compile core library
#==================================================	

# Arduino core sources includes c, c++ and asm files:
ARDUINO_CORE_SRC:=$(shell cd $(ARDUINO_CORE_DIR); find . -name '*.cpp' -or -name '*.c')

# List of object files:
ARDUINO_CORE_OBJS=$(ARDUINO_CORE_SRC:./%=$(OUTPUT_AVR)/libs/arduino/%.o)

.PHONY: arduino
arduino: OUTPUT_DIR:=$(OUTPUT_AVR)/libs/arduino
arduino: clean $(ARDUINO_CORE_OBJS)
	@echo 'Arduino core has been compiled successfully'

#==================================================	
#                Compile Arduboy2
#==================================================	

# Sources of the Arduboy2 library (arduboy2 uses only *.cpp files):
ARDUBOY2_SRC:=$(shell cd $(ARDUBOY2_DIR); find . -name '*.cpp' -or -name '*.c')

# List of object files:
ARDUBOY2_OBJS=$(ARDUBOY2_SRC:./%=$(OUTPUT_AVR)/libs/arduboy2/%.o)

.PHONY: arduboy2
arduboy2: OUTPUT_DIR:=$(OUTPUT_AVR)/libs/arduboy2
arduboy2: clean $(ARDUBOY2_OBJS)
	@echo 'Arduboy2 has been compiled successfully'

#==================================================	
#                Build project
#==================================================	

# Sources:
# here we use `find` instead of wildcard to find all files 
# including files in sub directories:
SRC=$(shell cd $(SRC_DIR); find . -name '*.cpp' -or -name '*.c')

# List of all object files:
SRC_OBJS=$(SRC:./%=$(OUTPUT_AVR)/src/%.o)

OBJS=$(ARDUINO_CORE_OBJS) $(ARDUBOY2_OBJS) $(SRC_OBJS)

# Convert the file with compile objects to the valid compile database file:
compile_commands.json: init $(OBJS)
	@rm -f compile_commands.json
	@cp $(OUTPUT_DIR)/compile_commands.objs $(OUTPUT_DIR)/compile_commands.objs.tmp
	@# Add a comma to the end of every line except the last one:
	@sed  -i'' -e '$!s/$$/,/' $(OUTPUT_DIR)/compile_commands.objs.tmp
	@# Open array declaration:
	@sed  -i'' -e '1s/^/[\n/' $(OUTPUT_DIR)/compile_commands.objs.tmp
	@# Close array declaration:
	@echo ']' >> $(OUTPUT_DIR)/compile_commands.objs.tmp
	@# Move the completed compile_commands.json to the cwd:
	@mv $(OUTPUT_DIR)/compile_commands.objs.tmp compile_commands.json
	@echo 'The file compile_commands.json has been updated'

# Build the binary file for arduboy:
.PHONY: compile
compile: compile_commands.json
	@$(CPP) $(LDFLAGS) -o $(OUTPUT_DIR)/$(TITLE).elf $(OBJS)
	@echo 'The project $(TITLE) has been built successfully'


#==================================================	
#            Compile and run tests
#==================================================	

ifdef LOCAL_TEST

TEST_SRC=$(shell cd $(TEST_DIR); find . -name '*.cpp' -or -name '*.c')

# List of objects with tests:
TEST_OBJS=$(TEST_SRC:./%=$(OUTPUT_DEV)/test/%.o)

ifdef TEST_FRAMEWORK_DIR
# Sources of the test framework.
TEST_FRAMEWORK_SRC:=$(shell cd $(TEST_FRAMEWORK_DIR); find . -name '*.cpp' -or -name '*.c')

# Plus list of test framework objects:
TEST_OBJS+=$(TEST_FRAMEWORK_SRC:./%=$(OUTPUT_DEV)/libs/test_framework/%.o)
endif

# We must be sure that for every source file a file with dependencies already
# generated:
DEPS_FILES=$($(OBJS):%.o=%.d)

# To run tests locally, we have to find all src files which are not depend on Arduino:
RECOMPILE_DEPS=$(shell grep --include=\*.d -R '$(OUTPUT_AVR)' -LRe 'arduino')

# Plus list of recompiled objects:
# (Here we create a list of object files inside DEV output directory.
# To build such files the different compilers will be used (not avr))
TEST_OBJS+=$(RECOMPILE_DEPS:$(OUTPUT_AVR)/%.d=$(OUTPUT_DEV)/%.o)

.PHONY: test
test: $(DEPS_FILES) $(TEST_OBJS) compile_commands.json
	@echo 'Run tests:'
	@$(GCPP) $(ASANFLAGS) -o $(OUTPUT_DEV)/test.out $(TEST_OBJS) -lm
	@$(OUTPUT_DEV)/test.out
	@echo 'Memory check and tests passed'
else

.PHONY: test
test:
	@echo 'You have to set the LOCAL_TEST variabe to run local tests.'
	@echo 'Note: test should not depends on arduino sources!'

endif


#==================================================	
#            Build and upload the hex file
#==================================================	

hex_size_percent=$(AVR_SIZE) -A $(OUTPUT_DIR)/$(TITLE).hex | grep Total |  \
		 awk '{ print "The size of the $(TITLE).hex is "$$2" bytes \
		 from maximum $(MAXIMUM_SIZE) bytes 			   \
		 ("int($$2 * 100 / $(MAXIMUM_SIZE)) "%)" }'

# Create the hex file:
# -j 	- Copy only the named section from the input file to the output file.
# -R 	- Remove any section named sectionname from the output file.
.PHONY: build
build: compile
	@$(OBJCPY) -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings \
		--change-section-lma .eeprom=0 $(OUTPUT_DIR)/$(TITLE).elf $(OUTPUT_DIR)/$(TITLE).eep
	$(OBJCPY) -O ihex -R .eeprom $(OUTPUT_DIR)/$(TITLE).elf $(OUTPUT_DIR)/$(TITLE).hex
	@$(call hex_size_percent)

size: build
	@$(AVR_SIZE) -A $(OUTPUT_DIR)/$(TITLE).elf $(OUTPUT_DIR)/$(TITLE).hex
	@echo 'Maximum binary size is $(MAXIMUM_SIZE)'
	@echo 'Maximum data size is $(MAXIMUM_DATA_SIZE)'

.PHONY: upload
upload: build
	@echo 'Not implemented yet'


#==================================================	
#                 Run in emulator
#==================================================	

.PHONY: emulate
ifdef ARDENS
# Run the final hex file in the emulator:
emulate: build
	$(ARDENS)$(ARDENS_MODE) file=$(OUTPUT_DIR)/$(TITLE).hex
else
emulate:
	@echo 'Please, specify the path to the ArdensPlayer.'
endif
#==================================================	

# Clean up the project:
.PHONY: clean
clean:
	rm -f compile_commands.json
	rm -rf $(OUTPUT_DIR)

.PHONY: all
all: clean init build

.DEFAULT_GOAL := all
