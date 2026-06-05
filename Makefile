APP_NAME = PhotoOrganizer-mac
BUILD_DIR = .build/release
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
RESOURCES_DIR = $(CONTENTS)/Resources
INSTALL_DIR = /Applications
BINARY_NAME = PhotoOrganizer

.PHONY: all build app clean run dev install uninstall test

all: app

build:
	swift build -c release

app: build
	mkdir -p $(MACOS_DIR) $(RESOURCES_DIR)
	cp $(BUILD_DIR)/$(BINARY_NAME) $(MACOS_DIR)/$(BINARY_NAME)
	cp Resources/Info.plist $(CONTENTS)/Info.plist
	cp config.json $(RESOURCES_DIR)/config.json
	@echo "Built: $(APP_BUNDLE)"

clean:
	swift package clean
	rm -rf $(BUILD_DIR)/$(APP_NAME).app

run: app
	open $(APP_BUNDLE)

dev: app
	pkill -x $(BINARY_NAME) 2>/dev/null || true
	sleep 1
	open $(APP_BUNDLE)

install: app
	cp -R $(APP_BUNDLE) $(INSTALL_DIR)/
	xattr -cr $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Installed to $(INSTALL_DIR)/$(APP_NAME).app"

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app
	@echo "Uninstalled $(APP_NAME) from $(INSTALL_DIR)"

test:
	swift test
