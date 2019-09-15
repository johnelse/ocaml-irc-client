all:
	dune build @install --profile release

doc:
	dune build @doc

clean:
	dune clean

test:
	dune runtest --force

install:
	dune install

uninstall:
	dune uninstall

watch:
	@dune build @all --watch

ARGS=

example1:
	dune exec examples/$@.exe --profile release -- $(ARGS)

example2:
	dune exec examples/$@.exe --profile release -- $(ARGS)

example2_unix:
	dune exec examples/$@.exe --profile release -- $(ARGS)

example_tls:
	dune exec examples/$@.exe --profile release -- $(ARGS)

.PHONY: example1 example2 example2_unix example_tls test
