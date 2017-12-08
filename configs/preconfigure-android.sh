#!/bin/bash

LANG=C sed -i.bak -e 's|^bin_PROGRAMS = .*$|bin_PROGRAMS =|g' "src/Makefile.in"
