# sml-uri build
MLTON      ?= mlton
BIN        := bin
LIBDIR     := lib/github.com/sjqtentacles/sml-uri
TEST_MLB   := test/sources.mlb
CLI_MLB    := bin/uri.mlb
SRCS       := $(wildcard $(LIBDIR)/*.sml $(LIBDIR)/*.sig) $(wildcard test/*.sml) $(TEST_MLB) $(LIBDIR)/sources.mlb

.PHONY: all test poly test-poly verify-identical all-tests cli example clean example-poly

all: $(BIN)/test-mlton

$(BIN)/test-mlton: $(SRCS) | $(BIN)
	$(MLTON) -output $@ $(TEST_MLB)

test: $(BIN)/test-mlton
	$(BIN)/test-mlton

poly: $(BIN)/test-poly

$(BIN)/test-poly: $(SRCS) tools/polybuild | $(BIN)
	sh tools/polybuild -o $@ $(TEST_MLB)

test-poly: $(BIN)/test-poly
	$(BIN)/test-poly

all-tests: test test-poly verify-identical

# Demos are top-level scripts; run them under Poly/ML via use-loading.
example-poly:
	sh tools/polybuild -r examples/sources.mlb

example: $(BIN)/demo
	./$(BIN)/demo

$(BIN)/demo: $(SRCS) examples/demo.sml examples/sources.mlb | $(BIN)
	$(MLTON) -output $@ examples/sources.mlb

cli: $(BIN)/uri

$(BIN)/uri: $(SRCS) bin/uri.sml $(CLI_MLB) | $(BIN)
	$(MLTON) -output $@ $(CLI_MLB)

$(BIN):
	mkdir -p $(BIN)

clean:
	rm -f $(BIN)/test-mlton $(BIN)/test-poly $(BIN)/uri
	rm -f *.o

# The dual-compiler contract: both suites must print byte-identical output.
# Recursive make -s captures the raw suite stdout regardless of poly strategy.
verify-identical:
	$(MAKE) -s test > $(BIN)/out-mlton.txt
	$(MAKE) -s test-poly > $(BIN)/out-poly.txt
	diff $(BIN)/out-mlton.txt $(BIN)/out-poly.txt
	@echo "byte-identical: OK"
