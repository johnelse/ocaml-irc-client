dist/build/lib-irc-client/irc-client.cmxa:
	obuild configure --enable-tests
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
	obuild test
