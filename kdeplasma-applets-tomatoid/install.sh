## arg 1:  the new package version
post_install() {
  update-desktop-database -q
}

## arg 1:  the new package version
## arg 2:  the old package version
post_upgrade() {
  update-desktop-database -q
}

## arg 1:  the old package version
post_remove() {
  update-desktop-database -q
}
