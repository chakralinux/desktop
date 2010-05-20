#!/bin/bash

fix_configs() {
	echo -e  -n " > Adjusting paths in config files ..."
	KDE_dir=".kdemod4"
	pushd ~/$KDE_dir/share/config/ &> /dev/null
	find ./ -type f -exec sed -i "s/\/.kde4/\/.kdemod4/g" {} \; &> /dev/null
	popd &> /dev/null
	echo " DONE"
}

