dist/build/lib-irc-client/irc-client.cmxa:
	obuild configure
	obuild build

install:
	ocamlfind install irc-client lib/META \
		$(wildcard dist/build/lib-irc_client/*) \
		$(wildcard dist/build/lib-irc_client.lwt/*) \
		$(wildcard dist/build/lib-irc_client.unix/*)

uninstall:
	ocamlfind remove irc-client

.PHONY: clean
clean:
	rm -rf dist
