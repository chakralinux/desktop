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
_script_name="Move Package(s)"
_ver="0.1"
_args=$(echo $1)
_dest_repo=$(echo $2)
_dest=$(echo "${_dest_repo}" | cut -d- -f2)
_cur_repo=$(pwd | awk -F '/' '{print $NF}')
_needed_functions="config_handling helpers messages"
_build_arch="$_arch"
_sarch="x32"
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
# Functions
#

exit_with_error()
{
	newline
	newline
	error "failed performing the current operation, aborting..."
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
	msg "Searching removed files"
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
		question "Do you want to remove the package(s)? (y/n)"
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

get_source_repo()
{
	unset _source_repo
	_source_repo=$(tar xf ${_sync_folder}${1} .PKGINFO -O | grep 'gitrepo' | cut -d ' ' -f3 | cut -d- -f1)
}

sync_source()
{
	# create new pacman database
	newline
	msg "creating «$(echo "${_cur_repo}" | cut -d- -f2)» database"
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
	newline
	msg "syncing «$(echo "${_cur_repo}" | cut -d- -f2)»"
	if [ "${_sync_folder}" = "_testing-${_sarch}/" ] ; then 
		rsync -avh --progress --delay-updates --delete-after ${_sync_folder} ${_rsync_user}@${_rsync_server}::dev/testing/$_arch/ || exit_with_error
	elif [ "${_sync_folder}" = "_unstable-${_sarch}/" ] ; then 
		rsync -avh --progress --delay-updates --delete-after ${_sync_folder} ${_rsync_user}@${_rsync_server}::dev/unstable/$_arch/ || exit_with_error
	else
		rsync -avh --progress --delay-updates --delete-after ${_sync_folder} ${_rsync_user}@${_rsync_server}::${_rsync_dir} || exit_with_error
	fi
}

upload_to_target()
{
	newline
	msg "uploading to «${final_dest}»"
	rsync -avh --progress --delay-updates _temp/ ${_rsync_user}@${_rsync_server}::dev/${final_dest}/$_arch/ || exit_with_error
}

recreate_target_db()
{
	newline
	msg "performing remote operations in the server, this will take a bit, please wait ..."
	curl "http://chakra-project.org/packages/recreate-database.php?r=${final_dest}&a=${_arch}&u=${_rsync_user}&p=${_rsync_pass}"
	newline
}

clean_temp_folder()
{
	newline
	msg "cleanning the _temp folder"
	pushd _temp &>/dev/null
		rm -rf *
	popd &>/dev/null
}

move_and_recreate_db()
{
	clean_temp_folder
	
	newline
	msg "moving packages to _temp"
	mv -v ${_sync_folder}${_pkgz_to_move} _temp

	sync_source
	upload_to_target
	recreate_target_db
	clean_temp_folder
}

move_packages()
{
	# Move the packages to a proper repo
	unset numb_packages
	for np in ${_pkgz_to_move} ; do
		((numb_packages++))
	done
      
	if [ "${_dest}" != "" ] ; then
		unset repo_exist
		for _repo_check in games apps desktop platform core lib32 lib32-testing testing unstable; do
			if [ "${_repo_check}" == "${_dest}" ] ; then 
				repo_exist="yes"
			fi
		done
		if [ "${repo_exist}" != "yes" ] ; then
			newline
			error "the target repo «${_dest}» it is unknown, aborting..."
			newline
			exit 1
		fi
	fi

	if [[ $numb_packages > 1 ]] ; then
		if [ "${_dest}" = "" ] ; then
			newline
			error "if you want to move more than one package at once you should specify the target repo, aborting..."
			newline
			exit 1
		fi
		final_dest=${_dest}
	else

		status_start "checking if the package contains target data"
			get_source_repo "${_pkgz_to_move}"
		if [ "${_source_repo}" == "" ] ; then 
			status_fail
			if [ "${_dest}" == "" ] ; then
				newline
				error "this package does not contain the needed info for move it"
				error "automatically, you should specify the target repo, aborting..."
				newline
				exit 1
			else
				final_dest=${_dest}
			fi
		else
			status_ok
			if [ "${_dest}" != "" ] ; then 
				if [ "${_dest}" != "${_source_repo}" ] ; then 
					msg "you supplied «${_dest}» as target repo but this script detected it should go to: «${_source_repo}»"
					final_dest=${_dest}
				else
					msg "you supplied «${_dest}» as target repo, this script detected this is the proper place"
					final_dest=${_dest}
				fi
			else
				final_dest=${_source_repo}
			fi
		fi
	fi

	if [ "${final_dest}" == "$(echo "${_cur_repo}" | cut -d- -f2)" ] ; then 
		newline
		error "this package it is already in ${final_dest}!"
		newline
		exit 1
	fi

	newline 
	msg "moving to target repo: «${final_dest}»"

	newline
	question "Do you really want to move the package(s)? (y/n) "

	while true ; do
	read yn
		case $yn in
			[yY]* )
				move_and_recreate_db ;
				break ;
            
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

}

#
# startup
#

clear
title "${_script_name} v${_ver} - $_cur_repo-$_build_arch"

if [ "${_args}" = "" ] ; then
	error " !! You need to specify a target to move,"
	error "    single names like «attica» or wildcards (*) are allowed."
	newline
	exit 1
fi

check_configs
load_configs

check_rsync
check_accounts

sync_down
check_files

# Generate the list of packages to move
if [ "${_sync_folder}" = "_testing-${_sarch}/" ] || [ "${_sync_folder}" = "_unstable-${_sarch}/" ] ; then  
	_pkgz_to_move=`ls ${_sync_folder}${_args}* | cut -d/ -f2`
else
	_pkgz_to_move=`ls ${_sync_folder}${_args}* | cut -d/ -f3`
fi

if [ "${_pkgz_to_move}" = "" ] ; then
	exit
fi

newline
warning "The following packages will be moved:"
newline
echo "${_pkgz_to_move}"

move_packages "${_pkgz_to_move}" 

newline 
title "All done"
newline
