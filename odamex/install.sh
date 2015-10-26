instructions() {   
    echo "You need a DOOM .wad file to play this game."
    echo "For example, try installing the ‘freedom’ package."
}

post_install() {
    instructions
}

post_upgrade() {
    instructions
}
