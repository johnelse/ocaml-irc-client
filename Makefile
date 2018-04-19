
all:
	jbuilder build @install

doc:
	jbuilder build @doc

clean:
	jbuilder clean

example1:
	./run_example.sh 1

example2:
	./run_example.sh 2

example2_unix:
	./run_example.sh 2_unix

example_tls:
	./run_example.sh _tls

.PHONY: example1 example2 example2_unix example_tls
