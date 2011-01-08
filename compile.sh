#!/bin/bash
cd $1
../makepkg -sr --noconfirm
rm -r pkg src *.pkg.*
cd ..
