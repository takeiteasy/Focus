#!/bin/sh
clang -fobjc-arc -lobjc \
	-framework AppKit \
	-framework Metal \
	-framework MetalKit \
	-framework Foundation \
	*.m -DNO_XCODE -DRES_PATH="\"$(pwd)\""
./a.out
rm a.out
