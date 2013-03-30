dist/build/lib-irc-client/irc-client.cmxa:
	obuild configure
	obuild build

install:
	ocamlfind install irc-client lib/META $(wildcard dist/build/lib-irc-client/*)
	ocamlfind install irc-client.lwt lwt/META $(wildcard dist/build/lib-irc-client.lwt/*)
	ocamlfind install irc-client.unix unix/META $(wildcard dist/build/lib-irc-client.unix/*)

uninstall:
	ocamlfind remove irc-client irc-client.lwt irc-client.unix

.PHONY: clean
clean:
	rm -rf dist
