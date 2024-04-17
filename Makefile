PROJECT_DIR := $(abspath .)
INC_DIR := $(PROJECT_DIR)/include
SRC_DIR := $(PROJECT_DIR)/src
OUT_DIR := $(PROJECT_DIR)/out
BUILD_DIR := $(OUT_DIR)/build
CONTAINER_DIR := $(OUT_DIR)/container
BIN_DIR := $(CONTAINER_DIR)/bin
COVERAGE := $(OUT_DIR)/coverage

# To get gcov to work after relocating the gcno files, we need to specify a
# new prefix path for where the gcno files will now be found, but we also
# need to tell gcov how many directory names to strip off the original
# location before applying the new prefix
export GCOV_PREFIX_STRIP = $(words $(subst /, ,$(BUILD_DIR)))
export GCOV_PREFIX = $(BIN_DIR)

APP_NAME := app.coverage
APP := $(BUILD_DIR)/$(APP_NAME)

CONTAINER_BUILT := $(CONTAINER_DIR)/.built
COVERAGE_FILE := $(COVERAGE)/coverage_report.html

.DEFAULT_GOAL := report-coverage

.PHONY: clean
clean:
	rm -rf $(OUT_DIR)

# Recipe for the app from source
$(APP): $(SRC_DIR)/main.c $(SRC_DIR)/lib.c
	mkdir -p $(dir $@)
	-rm $@*                     # Remove any remaining gcno and gcda files
	gcc --coverage -I $(INC_DIR) -o $@ $^     # Generate the app and gcno files

# Recipe for the docker image from the app
.PHONY: build-docker
build-docker: $(CONTAINER_BUILT)
$(CONTAINER_BUILT): $(APP)
	mkdir -p $(BIN_DIR)
	cp -a $<* $(BIN_DIR)        # Install app and gcno files in the container (note: ($< = $(APP)))
	touch $@                    # Create the stamp file as proof-of-work      (note: $@ = $(CONTAINER_BUILT))

# Recipe for a test run from a built docker image
.PHONY: run-test-in-docker
run-test-in-docker: $(CONTAINER_BUILT)
	cd $(CONTAINER_DIR) && bin/$(APP_NAME)

# Recipe for generating a coverage report from a test run
.PHONY: report-coverage $(COVERAGE_FILE)
report-coverage: $(COVERAGE_FILE)
$(COVERAGE_FILE): run-test-in-docker
	mkdir -p $(dir $@)
	gcovr \
		--root $(SRC_DIR) \
		$(BIN_DIR)
	gcovr \
		--root $(SRC_DIR) \
		--html --html-details -o $@ \
		$(BIN_DIR)
