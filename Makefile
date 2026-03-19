TYP_FILES := $(shell find . -type f -name '*.typ' \
	! -name 'template.typ' \
	! -name 'config.typ')

PDF_NAMES := $(notdir $(TYP_FILES:.typ=.pdf))
OUTPUTS := $(addprefix public/,$(PDF_NAMES))

all: $(OUTPUTS)

public/%.pdf:
	@mkdir -p public
	typst compile $(shell find . -type f -name '$*.typ' | grep -v 'template.typ' | grep -v 'config.typ' | head -n 1) $@

clean:
	rm -rf public

.PHONY: all clean
