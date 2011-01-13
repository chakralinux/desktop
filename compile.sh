#!/bin/bash
cd $1
../makepkg -sr --noconfirm
rm -rf pkg src *.pkg.*
cd ..
