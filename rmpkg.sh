#!/bin/bash

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>
#
#   (c) 2010 - Manuel Tortosa <manutortosa[at]chakra-project[dot]org>

#
# global vars
#
_script_name="Remove Package(s)"
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_needed_functions="config_handling helpers messages"
_build_arch="$_arch"
_sarch="x32"
_args=`echo $1`
[[ ${_arch} = *x*64* ]] && _sarch="x64"

# helper functions
for subroutine in ${_needed_functions} ; do
	source _buildscripts/functions/${subroutine}
done

# Determine the sync folder
if [[ ${_cur_repo} = *-testing ]] && [[ ${_cur_repo} != lib32-testing ]] ; then
	_sync_folder="_testing-${_sarch}/"
elif [[ ${_cur_repo} = *-unstable ]] ; then
	_sync_folder="_unstable-${_sarch}/"
else
	_sync_folder="_repo/remote/"
fi


#
# main
#

exit_with_error()
{
	newline
	newline
	error "failed performing the current operation, aborting..."
	newline
	exit 1
}

sync_down()
{
	msg "syncing down"
	export RSYNC_PASSWORD=$(echo ${_rsync_pass})
	if [ "${_sync_folder}" = "_testing-${_sarch}/" ] ; then 
		rsync -avh --progress ${_rsync_user}@${_rsync_server}::dev/testing/$_build_arch/* ${_sync_folder} || exit_with_error
	elif [ "${_sync_folder}" = "_unstable-${_sarch}/" ] ; then 
		rsync -avh --progress ${_rsync_user}@${_rsync_server}::dev/unstable/$_build_arch/* ${_sync_folder} || exit_with_error
	else
		rsync -avh --progress ${_rsync_user}@${_rsync_server}::${_rsync_dir}/* ${_sync_folder} || exit_with_error
	fi
}

check_files()
{
	# Get the file list in the server
	export RSYNC_PASSWORD=$(echo ${_rsync_pass})
	if [ "${_sync_folder}" = "_testing-${_sarch}/" ] ; then 
		repo_files=`rsync -avh --list-only ${_rsync_user}@${_rsync_server}::dev/testing/$_arch/* | cut -d ":" -f 3 | cut -d " " -f 2`
	elif [ "${_sync_folder}" = "_unstable-${_sarch}/" ] ; then
		repo_files=`rsync -avh --list-only ${_rsync_user}@${_rsync_server}::dev/unstable/$_arch/* | cut -d ":" -f 3 | cut -d " " -f 2`
	else
		repo_files=`rsync -avh --list-only ${_rsync_user}@${_rsync_server}::${_rsync_dir}/* | cut -d ":" -f 3 | cut -d " " -f 2`
	fi

	# Get the file list in the sync folder
	if [ "${_sync_folder}" = "_testing-${_sarch}/" ] || [ "${_sync_folder}" = "_unstable-${_sarch}/" ] ; then 
		local_files=`ls -a ${_sync_folder}* | cut -d "/" -f 2`
	else
		local_files=`ls -a ${_sync_folder}* | cut -d "/" -f 3`
	fi
	remove_list=""

	for parse_file in ${local_files} ; do
		file_exist="false"
		for compare_file in ${repo_files} ; do
			if [ "${parse_file}" = "${compare_file}" ] ; then
				file_exist="true"
			fi
		done
		if [ "${file_exist}" = "false" ] ; then
			remove_list="${remove_list} ${parse_file}"
		fi
	done

	if [ "$remove_list" != "" ] ; then
		msg "The following packages in ${_sync_folder} don't exist in the sever:"
		newline
		echo "${remove_list}"
		newline
		question "Do you want to remove the package(s)? (y/n) "
		while true ; do
			read yn
			case ${yn} in
			[yY]* )
				newline ;
				remove_packages "${remove_list}" ;
				break
			;;
			[nN]* )
				newline ;
				title "The files will be keeped..." ;
				newline ;
				break
			;;
			* )
				echo "Enter (y)es or (n)o"
			;;
			esac
		done
	fi
}

remove_packages()
{
	# remove the package(s) from sync folder
	msg "removing the packages(s) from ${_sync_folder}"
	pushd $_sync_folder &>/dev/null
		rm -vrf $1
	popd &>/dev/null
}

sync_up()
{
	# create new pacman database
	msg "creating pacman database"
	rm -rf ${_sync_folder}*.db.tar.*
	pushd ${_sync_folder} &>/dev/null
		if [ "${_sync_folder}" = "_testing-${_sarch}/" ] ; then
			repo-add testing.db.tar.gz *.pkg.*
		elif [ "${_sync_folder}" = "_unstable-${_sarch}/" ] ; then 
			repo-add unstable.db.tar.gz *.pkg.*
		else
			repo-add ${_cur_repo}.db.tar.gz *.pkg.*
		fi
	popd &>/dev/null

	# sync local -> server, removing the packages
	msg "sync local -> server"
	if [ "${_sync_folder}" = "_testing-${_sarch}/" ] ; then 
		rsync -avh --progress --delay-updates --delete-after  ${_sync_folder} ${_rsync_user}@${_rsync_server}::dev/testing/$_arch/ || exit_with_error
	elif [ "${_sync_folder}" = "_unstable-${_sarch}/" ] ; then 
		rsync -avh --progress --delay-updates --delete-after  ${_sync_folder} ${_rsync_user}@${_rsync_server}::dev/unstable/$_arch/ || exit_with_error
	else
		rsync -avh --progress --delay-updates --delete-after  ${_sync_folder} ${_rsync_user}@${_rsync_server}::${_rsync_dir} || exit_with_error
	fi
}


#
# startup
#

clear

title "${_script_name} - $_cur_repo-$_build_arch"

if [ "${_args}" = "" ] ; then
	error " !! You need to specify a target to remove,"
	error "    single names like «attica» or wildcards (*) are allowed."
	newline
	exit 1
fi

check_configs
load_configs

check_rsync
check_accounts

# First get the actual packages from the repo
sync_down

# Check if there's any outdated file
msg "Searching removed files"
check_files

# Generate the list of packages to remove
newline
_args=${_args}*
if [ "${_sync_folder}" = "_testing-${_sarch}/" ] || [ "${_sync_folder}" = "_unstable-${_sarch}/" ] ; then  
	_pkgz_to_remove=`ls ${_sync_folder}${_args} | cut -d/ -f2`
else
	_pkgz_to_remove=`ls ${_sync_folder}${_args} | cut -d/ -f3`
fi

if [ "${_pkgz_to_remove}" = "" ] ; then
	exit
fi

warning "The following packages will be removed:"
newline
echo "${_pkgz_to_remove}"

newline
question "Do you really want to remove the package(s)? (y/n/q) "

while true ; do
	read yn
	case $yn in
		[yY]* )
			newline ;
			remove_packages "${_pkgz_to_remove}" ;
			sync_up ;
			newline ;
			title "All done" ;
			newline ;
			break
		;;

		[nN]* )
			exit
		;;

		q* )
			exit
		;;

		* )
			echo "Enter (y)es or (n)o"
		;;
	esac
done
