#
# Makefile
#

PROJECT_NAME        := Linuxtage2026GameboyHandson


# Define the RGBDS commands we need
RGBDS_GFX           := rgbgfx  # graphics tool
RGBDS_ASM           := rgbasm  # assembler
RGBDS_LINK          := rgblink  # linker
RGBDS_FIX           := rgbfix  # fixes the header such that the executable is valid

# Here, write the command for your emulator. We use gearboy in this hands-on workshop
EMULATOR            := gearboy
 
LINK_FLAGS          := 
FIX_FLAGS           := -v -p 0xFF

PROJECT_EXT         := gbc
SRC_DIR             := src
INC_DIR             := include
PNG_DIR             := res/png
BUILD_DIR           := build
RELEASE_DIR         := release
FINAL_TARGET        := $(RELEASE_DIR)/$(PROJECT_NAME)
 
$(info "Building : $(FINAL_TARGET).$(PROJECT_EXT)")
 
########################################
 
# list all .asm files in the source directory SRC_DIR, results in: src/main.asm src/player.asm
SOURCE_FILES        := $(wildcard $(SRC_DIR)/*.asm)
 
# list all .inc files in include directory INC_DIR, results in: -iinclude/hardware.inc -iinclude/temp.inc
INCLUDE_FILES       := $(addprefix -i, $(wildcard $(INC_DIR)/*.inc))

# list all tile data, results in: res/png/title.png
TILE_FILES          := $(wildcard $(PNG_DIR)/*.png)

# list all tile data as .2bpp, results in: res/tiles/title.2bpp
TILE_INPUT       := $(TILE_FILES:%.png=%.2bpp)

# list all tile data as .2bpp, results in: res/tiles/title.2bpp
TILE_OUTPUT       := $(addprefix $(BUILD_DIR)/, $(notdir $(TILE_FILES:%.png=/%.2bpp)))
 
# list all object files corresonding to source asm files, results in: src/main.o src/player.o
OBJECTS_INPUT       := $(SOURCE_FILES:%.asm=%.o)
 
# list all object files in the build folder, results in: build/main.o build/player.o
# note they are placed into the build folder by removing the previous directory
# using notdir, then the build directory BUILD_DIR is is prefixed
OBJECTS_OUTPUT      := $(addprefix $(BUILD_DIR)/, $(notdir $(SOURCE_FILES:%.asm=/%.o)))
 
$(info "SOURCE_FILES = $(SOURCE_FILES)")
$(info "INCLUDE_FILES = $(INCLUDE_FILES)")
$(info "TILE_FILES = $(TILE_FILES)")
$(info "OBJECTS_INPUT = $(OBJECTS_INPUT)")
$(info "OBJECTS_OUTPUT = $(OBJECTS_OUTPUT)")
 
########################################

%.2bpp : %.png
	$(RGBDS_GFX) -t $(BUILD_DIR)/$(notdir $(@:%.2bpp=%.tilemap)) -u -o $(BUILD_DIR)/$(notdir $@) $<
 
%.o : %.asm
	$(RGBDS_ASM) -o $(BUILD_DIR)/$(notdir $@) $<
 
$(FINAL_TARGET) : $(TILE_INPUT) $(OBJECTS_INPUT)
	@$(RGBDS_LINK) $(LINK_FLAGS) -o $@.$(PROJECT_EXT) -n $@.sym $(OBJECTS_OUTPUT)
	@$(RGBDS_FIX) $(FIX_FLAGS) $(FINAL_TARGET).$(PROJECT_EXT)
 
########################################
 
# create the release directory for the final executable and the build directory for the object files
prepare:
	mkdir -p $(RELEASE_DIR)
	mkdir -p $(BUILD_DIR)
 
all: $(FINAL_TARGET)
 
clean:
	rm -rf  $(RELEASE_DIR)/*.*
	rm -rf  $(BUILD_DIR)/*.*
 
run: all
	$(EMULATOR) $(FINAL_TARGET).$(PROJECT_EXT)
