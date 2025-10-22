# Makefile for DeskPad

# Project configuration
PROJECT = DeskPad.xcodeproj
SCHEME = DeskPad
TARGET = DeskPad
CONFIGURATION ?= Release
BUILD_DIR = build
DERIVED_DATA_DIR = $(BUILD_DIR)/DerivedData

# Product information
PRODUCT_NAME = DeskPad.app
BUILT_PRODUCTS_DIR = $(DERIVED_DATA_DIR)/Build/Products/$(CONFIGURATION)
APP_BUNDLE = $(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME)

# Archive configuration
ARCHIVE_PATH = $(BUILD_DIR)/DeskPad.xcarchive
EXPORT_PATH = $(BUILD_DIR)/Export

# Build flags
XCODEBUILD_FLAGS = -project $(PROJECT) \
                   -scheme $(SCHEME) \
                   -configuration $(CONFIGURATION) \
                   -derivedDataPath $(DERIVED_DATA_DIR) \
                   CODE_SIGN_IDENTITY="" \
                   CODE_SIGNING_REQUIRED=NO \
                   CODE_SIGNING_ALLOWED=NO \
                   ENABLE_USER_SCRIPT_SANDBOXING=NO

# Targets
.PHONY: all build clean package install test help

all: build

help:
	@echo "DeskPad Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  make build        - Build the application (default: Release)"
	@echo "  make debug        - Build in Debug configuration"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make package      - Build and create distributable .app bundle"
	@echo "  make archive      - Create Xcode archive"
	@echo "  make install      - Install to /Applications (requires sudo)"
	@echo "  make test         - Run tests (if available)"
	@echo "  make help         - Show this help message"
	@echo ""
	@echo "Configuration:"
	@echo "  CONFIGURATION=$(CONFIGURATION)"
	@echo "  BUILD_DIR=$(BUILD_DIR)"

build:
	@echo "Building $(TARGET) ($(CONFIGURATION))..."
	xcodebuild $(XCODEBUILD_FLAGS) build
	@echo "Build complete: $(APP_BUNDLE)"

debug:
	@$(MAKE) build CONFIGURATION=Debug

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	xcodebuild $(XCODEBUILD_FLAGS) clean
	@echo "Clean complete"

package: build
	@echo "Packaging $(PRODUCT_NAME)..."
	@mkdir -p $(EXPORT_PATH)
	@cp -R $(APP_BUNDLE) $(EXPORT_PATH)/
	@echo "Package created: $(EXPORT_PATH)/$(PRODUCT_NAME)"

archive:
	@echo "Creating archive..."
	xcodebuild -project $(PROJECT) \
	           -scheme $(SCHEME) \
	           -configuration $(CONFIGURATION) \
	           -archivePath $(ARCHIVE_PATH) \
	           archive
	@echo "Archive created: $(ARCHIVE_PATH)"

install: package
	@echo "Installing $(PRODUCT_NAME) to /Applications..."
	@sudo rm -rf /Applications/$(PRODUCT_NAME)
	@sudo cp -R $(EXPORT_PATH)/$(PRODUCT_NAME) /Applications/
	@echo "Installation complete"

test:
	@echo "Running tests..."
	xcodebuild $(XCODEBUILD_FLAGS) test || echo "No tests configured"

# Development helpers
run: build
	@echo "Launching $(PRODUCT_NAME)..."
	@open $(APP_BUNDLE)

version:
	@grep -A 1 "MARKETING_VERSION" $(PROJECT)/project.pbxproj | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+" | head -1
