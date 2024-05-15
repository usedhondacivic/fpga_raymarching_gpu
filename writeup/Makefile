SRC=../writeup
BUILD=../docs

STYLES=styles
FONTS=fonts

all: setup pages assets
	@echo "All done :)"

setup: $(wildcard STYLES/*) $(wildcard FONTS/*)
	@echo "Copying styles, fonts, global assets ect..."
	@mkdir -p "$(BUILD)/$(STYLES)"
	@cp -r -f "$(STYLES)" "$(BUILD)"
	@mkdir -p "$(BUILD)/$(FONTS)"
	@cp -r -f "$(FONTS)" "$(BUILD)"

pages: $(BUILD)/index.html $(PROJECT_PAGES)
	
$(BUILD)/index.html: $(SRC)/content.md templates/index.html $(wildcard $(SRC)/assets/*)
	@echo "Generating home page..."
	@mkdir -p "$(@D)"
	@touch "$@"
	@node generators/generate_article.js -i "$^" -o "$@"

ALL_SRC_ASSETS = $(wildcard $(SRC)/assets/*)
ALL_TARGET_ASSETS = $(subst $(SRC),$(BUILD),$(ALL_SRC_ASSETS))
CONVERT_ASSET_TARGETS = $(addsuffix .webp,$(basename $(filter %.png %.jpg %.jpeg, $(ALL_TARGET_ASSETS))))
COPY_ASSET_TARGETS = $(filter %.svg %.gif %.webp, $(ALL_TARGET_ASSETS))

assets: $(CONVERT_ASSET_TARGETS) $(COPY_ASSET_TARGETS)

define convert_image
	@echo "Optimizing asset $^..."
	@mkdir -p "$(@D)"
	@touch "$@"
	@node generators/image_conversion.js -i "$^" -o "$@" 
endef

$(BUILD)/%.webp: $(SRC)/%.png
	$(convert_image)

$(BUILD)/%.webp: $(SRC)/%.jpg
	$(convert_image)
	
$(BUILD)/%.webp: $(SRC)/%.jpeg
	$(convert_image)

define move_image
	@echo "Transfering asset $^..."
	@mkdir -p "$(@D)"
	@cp -f "$<" "$@"
endef

$(BUILD)/%.webp: $(SRC)/%.webp
	$(move_image)

$(BUILD)/%.svg: $(SRC)/%.svg
	$(move_image)

$(BUILD)/%.gif: $(SRC)/%.gif
	$(move_image)

clean:
	@rm -r $(BUILD)
