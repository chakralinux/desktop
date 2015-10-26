pkgname=toohardforyou

post_install() {
if [ -e /usr/share/$pkgname/data/HighScores.dat ]; then
if [ -e /usr/share/$pkgname/data/config.dat ]; then
echo "Highscores and config files will be keeped"
else
  touch /usr/share/$pkgname/data/config.dat
  touch /usr/share/$pkgname/data/HighScores.dat
  chmod 777 /usr/share/$pkgname/data/{config.dat,HighScores.dat}
fi
else
  touch /usr/share/$pkgname/data/config.dat
  touch /usr/share/$pkgname/data/HighScores.dat
  chmod 777 /usr/share/$pkgname/data/{config.dat,HighScores.dat}
fi
}

post_upgrade() {
  post_install $1
}


post_remove() {
  cp /usr/share/share/$pkgname/data/config.dat /usr/share/share/$pkgname/data/config.dat.back
  cp /usr/share/share/$pkgname/data/HighScores.dat /usr/share/share/$pkgname/data/HighScores.dat.back
}
