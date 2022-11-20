focus: focus.m
	 clang focus.m -framework Cocoa -o focus

app: focus.m
	clang focus.m -DFOCUS_APP -framework Cocoa -o focus_app
	sh appify.sh -s focus_app -n Focus

default: focus
all: focus app

.PHONY: default all focus app
