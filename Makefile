ocamlfind_check=$(shell ocamlfind query $(1) > /dev/null 2> /dev/null && echo "true")

LWT=$(call ocamlfind_check,lwt)
ifeq ($(LWT), true)
	LWT_FLAG=--flag lwt
endif

dist/build/lib-irc-client/irc-client.cmxa:
	obuild configure --enable-tests $(LWT_FLAG)
	obuild build

install:
	ocamlfind install irc-client lib/META \
		$(wildcard dist/build/lib-irc_client/*) \
		$(wildcard dist/build/lib-irc_client.lwt/*) \
		$(wildcard dist/build/lib-irc_client.unix/*)

uninstall:
	ocamlfind remove irc-client

.PHONY: clean test
clean:
	rm -rf dist

test:
	obuild test --output
