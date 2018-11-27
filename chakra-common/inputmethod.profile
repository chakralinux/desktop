# Default input framework for Chakra is fcitx
# If you want to use ibus as your input framework
# Change it to 'ibus' and relogin
_ime=fcitx

# Export environmental variables when login
export GTK_IM_MODULE=$_ime
export QT_IM_MODULE=$_ime
export XMODIFIERS="@im=$_ime"
