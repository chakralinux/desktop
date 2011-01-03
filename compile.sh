#!/bin/bash
cd $1
../makepkg -frs
sudo rm -rf pkg src *.pkg.*
cd ..
