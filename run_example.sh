#!/usr/bin/env bash

WHICH=$1
shift 1

EXE=examples/example$WHICH.exe

echo "run example $EXE"
jbuilder exec "$EXE" -- $@


