#!/bin/bash
cd $1
../makepkg -sr
rm -r pkg src *.pkg.*
cd ..
