#!/bin/bash

# kdeupdate.sh
#
# Copyright © 2018 Luca Giambonini <almack@chakralinux.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.

_script_name="kde update"

# load functions
for subroutine in $_needed_functions ; do
  source ~/bin/functions/$subroutine
done

# Get package information
function _package_info() {
    local package="${1}"
    local properties=("${@:2}")
    for property in "${properties[@]}"; do
        local -n nameref_property="${property}"
        nameref_property=($(
            #source "${package}/PKGBUILD"
            source "PKGBUILD"
            declare -n nameref_property="${property}"
            echo "${nameref_property[@]}"))
    done
}

build()
{
  while read -r pkg; do
    [[ $pkg =~ ^[:blank:]*$ ]] && continue

    local comment_re="^[:blank:]*#"
    [[ $pkg =~ $comment_re ]] && continue

    msg "Processing: '$pkg'"
    pushd "$pkg" &>/dev/null

        # update version
        sed -r "s|pkgver=.*|pkgver=$Version|g" -i PKGBUILD
        sed -r "s|pkgrel=.*|pkgrel=1|g" -i PKGBUILD
        sed -r 's|"extra-cmake-modules>=[^"]*"|"extra-cmake-modules>='${Version}'"|g' -i PKGBUILD

        # update source link
        sed -r "s|https://download.kde.org/.*stable/|https://download.kde.org/${Branch}/|g" -i PKGBUILD

        # update sha256 sums
        local  pkgver pkgname source _pkgname _pkgbase
        _package_info "$pkg" pkgver pkgname source _pkgname _pkgbase

        if [ ! -z "$_pkgname" ]; then
            pkgname=$_pkgname
        fi
        if [ ! -z "$_pkgbase" ]; then
            pkgname=$_pkgbase
        fi

        _url=$source
        if [ -z ${SumsFile} ]; then
            # variable is unset
            _sha256sum=$(curl "$_url.sha256" | cut -c-64)
        else
            _sha256sum=$(cat "../${2}.sums" |grep $pkgname  | cut -c-64 | tail -1)
        fi
        sed -r "s|sha256sums=.*|sha256sums=('$_sha256sum'|g" -i PKGBUILD
        echo $_sha256sum
        unset pkgver pkgname source _pkgname _pkgbase
        
        git add PKGBUILD

    popd &>/dev/null
  done < "$1"
}

title "$_script_name"

if [ ! -f $1.conf ]; then
    echo "$1.conf: File not found!"
    exit 1
fi

# load the configurations
source $1.conf

time build "$1.order" $1

