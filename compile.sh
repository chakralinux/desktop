#!/bin/bash
cd $1
../makepkg -frs --noconfirm
sudo rm -rf pkg src *.pkg.*
cd ..
