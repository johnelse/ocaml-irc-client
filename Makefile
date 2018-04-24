
all:
	jbuilder build @install

doc:
	jbuilder build @doc

clean:
	jbuilder clean

test:
	jbuilder runtest --force

install:
	jbuilder install

uninstall:
	jbuilder uninstall

ARGS=

example1:
	jbuilder exec examples/$@.exe -- $(ARGS)

example2:
	jbuilder exec examples/$@.exe -- $(ARGS)

example2_unix:
	jbuilder exec examples/$@.exe -- $(ARGS)

example_tls:
	jbuilder exec examples/$@.exe -- $(ARGS)

.PHONY: example1 example2 example2_unix example_tls test
