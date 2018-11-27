# The locales which require a more dedicated input framework
_locale=(ja_JP ko_KR zh_CN zh_HK zh_TW)

# Default input framework for Chakra is fcitx
# If you want to use ibus as your input framework
# Change it to 'ibus' and relogin
_ime=fcitx

# Export environmental variables when login
for lang in $_locale[@]; do
  if [[ $LANG == $lang.UTF-8 ]]; then
    export GTK_IM_MODULE=$_ime
    export QT_IM_MODULE=$_ime
    export XMODIFIERS="@im=$_ime"
  fi
done
