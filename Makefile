DO_COVERAGE=1
RELEASE=release
UGLIFY=uglifyjs

SRC    := $(shell find src -name '*.js')
OBJS   := $(patsubst %.js,%.jc,$(SRC))

%.jc : %.js
	-mkdir -p $(RELEASE)/$(@D)
	$(UGLIFY) -o $(RELEASE)/$(*D)/$(*F).js $<

CHECKSTYLE=checkstyle
STYLE  := $(patsubst %.js,%.xml,$(SRC))
%.xml : %.js
	-mkdir -p $(CHECKSTYLE)/$(@D)
	-jscheckstyle --checkstyle $< > $(CHECKSTYLE)/$(*D)/$(*F).xml

JSLINT=jslint
JSL  := $(patsubst %.js,%.jslint,$(SRC))
%.jslint : %.js
	-mkdir -p $(JSLINT)/$(@D)
	./hudson_jslint.pl $< > $(JSLINT)/$(*D)/$(*F).jslint

prod: unit_tests $(OBJS) $(STYLE) $(JSL)

jslint: $(JSL)

pre:
ifdef WORKSPACE
	npm config set jute:docRoot '$(WORKSPACE)'
	npm restart jute
	npm config list jute
endif

server_side_unit_tests: pre
	cd test && find server_side -name '*.js' -exec echo "{}?do_coverage=$(DO_COVERAGE)" \; | jute_submit_test --v8 --test -

client_side_unit_tests: pre
	cd test && find client_side -name '*.html' -exec echo "{}?do_coverage=$(DO_COVERAGE)" \; | jute_submit_test --v8 --test -

unit_tests: server_side_unit_tests client_side_unit_tests make_total_lcov

OUTPUT_DIR=output
TOTAL_LCOV_FILE=$(OUTPUT_DIR)/lcov.info
make_total_lcov:
	@echo "OUTPUT DIR: ${OUTPUT_DIR}"
	@echo "TOTAL LCOV FILE: ${TOTAL_LCOV_FILE}"
	/bin/rm -f /tmp/lcov.info ${TOTAL_LCOV_FILE}
	find $(OUTPUT_DIR) -name lcov.info -exec echo '-a {}' \;  | xargs lcov > /tmp/lcov.info
	cp /tmp/lcov.info ${TOTAL_LCOV_FILE}
	/bin/rm -rf $(OUTPUT_DIR)/lcov-report
	genhtml -o $(OUTPUT_DIR)/lcov-report $(TOTAL_LCOV_FILE)
	python ./conv.py $(TOTAL_LCOV_FILE) -b . -o output/cob.xml

.PHONY: server_side_unit_tests client_side_unit_tests unit_tests pre make_total_lcov
