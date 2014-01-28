#!/bin/bash

function symlink {
	[[ ! $1 ]] && help symlink
	local castle=$1
	castle_exists "$castle"
	local repo="$repos/$castle"
	if [[ ! -d $repo/home ]]; then
		ignore 'ignored' "$castle"
		return $EX_SUCCESS
	fi
	oldIFS=$IFS
	IFS=$'\n'
	for remote in $(find "$repo/home" -mindepth 1 -name .git -prune -o -print); do
		IFS=$oldIFS
		filename=${remote#$repo/home/}
		local=$HOME/$filename

		if [[ -e $local || -L $local ]]; then
			# $local exists (but may be a dead symlink)
			if [[ -L $local && $(readlink "$local") == $remote ]]; then
				# $local symlinks to $remote.
				if [[ -d $remote && ! -L $remote ]]; then
					# If $remote is a directory -> legacy handling.
					rm "$local"
				else
					# $local points at $remote and $remote is not a directory
					ignore 'identical' "$filename"
					continue
				fi
			else
				# $local does not symlink to $remote
				if [[ -d $local && -d $remote && ! -L $remote ]]; then
					# $remote is a real directory while
					# $local is a directory or a symlinked directory
					# we do not take any action regardless of which it is.
					ignore 'identical' "$filename"
					continue
				fi
				if $SKIP; then
					ignore 'exists' "$filename"
					continue
				fi
				if ! $FORCE; then
					prompt_no 'conflict' "$filename exists" "overwrite?" || continue
				fi
				# Delete $local. If $remote is a real directory,
				# $local must be a file (because of all the previous checks)
				rm -rf "$local"
			fi
		fi

		if [[ ! -d $remote || -L $remote ]]; then
			# $remote is not a real directory so we create a symlink to it
			pending 'symlink' "$filename"
			ln -s "$remote" "$local"
		else
			pending 'directory' "$filename"
			mkdir "$local"
		fi

		success
	done
	return $EX_SUCCESS
}

function unredact {
        [[ ! $1 ]] && help unredact
        local castle=$1
        castle_exists $castle
        local repo="$repos/$castle"
        if [[ ! -d $repo/home ]]; then
                ignore 'ignored' "$castle"
                return $EX_SUCCESS
        fi

        load_secrets

        for filepath in $(find $repo/home -mindepth 1 -type f -iname "*.redacted"); do
                file=${filepath#$repo/home/}
                unredacted=${file%.redacted}

                if [[ -e $HOME/$unredacted ]]; then
                        if $SKIP; then
                                ignore 'exists' $file
                                continue
                        fi
                        if ! $FORCE; then
                                prompt_no 'conflict' "$unredacted exists" "overwrite?"
                                if [[ $? != 0 ]]; then
                                        continue
                                fi
                        fi
                        rm -rf "$HOME/$unredacted"
                fi

                populate_placeholders "$repo/home/$file" "$HOME/$unredacted"

                success
        done
        return $EX_SUCCESS
}

function redact {
        [[ ! $1 || ! $2 ]] && help redact
        local castle=$1
        local filename=$(readlink -f $2 2> /dev/null || realpath $2)
        local redacted="$filename.redacted"
        if [[ $filename != $HOME/* ]]; then
                err $EX_ERR "The file $filename must be in your home directory."
        fi
        if [[ $redacted == $repos/* ]]; then
                err $EX_ERR "The file $redacted is already being tracked."
        fi

        local repo="$repos/$castle"
        local newfile="$repo/home/${redacted#$HOME/}"

        pending "redacting" "$filename to $newfile"
        home_exists 'redact' $castle
        if [[ ! -e $filename ]]; then
                err $EX_ERR "The file $filename does not exist."
        fi
        if [[ -e $newfile && $FORCE = false ]]; then
                err $EX_ERR "The file $filename already exists in the castle $castle."
        fi
        if [[ ! -f $filename ]]; then
                err $EX_ERR "The file $filename must be a regular file."
        fi

        mkdir -p $(dirname $newfile)

        echo '!! Edit the file below, replacing any sensitive information to turn this:
!!
!!   password: superSecretPassword
!!
!! Into:
!!
!!   password: # briefcase(password)
!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' >> $newfile
        cat $filename >> $newfile
        "${EDITOR:-vim}" $newfile
        sed -i -e '/^!!.*$/d' $newfile

        parse_secrets $filename $newfile

        (cd $repo; git add "$newfile")
        success
}

function track {
	[[ ! $1 || ! $2 ]] && help track
	local castle=$1
	local filename=$(abs_path "$2")
	if [[ $filename != $HOME/* ]]; then
		err $EX_ERR "The file $filename must be in your home directory."
	fi
	if [[ $filename == $repos/* ]]; then
		err $EX_ERR "The file $filename is already being tracked."
	fi

	local repo="$repos/$castle"
	local newfile="$repo/home/${filename#$HOME/}"
	pending 'symlink' "$newfile to $filename"
	home_exists 'track' "$castle"
	if [[ ! -e $filename ]]; then
		err $EX_ERR "The file $filename does not exist."
	fi
	if [[ -e $newfile && $FORCE = false ]]; then
		err $EX_ERR "The file $filename already exists in the castle $castle."
	fi
	if [[ ! -f $filename ]]; then
		err $EX_ERR "The file $filename must be a regular file."
	fi
	local newfolder=$(dirname "$newfile")
	mkdir -p "$newfolder"
	mv -f "$filename" "$newfile"
	ln -s "$newfile" "$filename"
	(cd "$repo"; git add "$newfile")
	success
}

function castle_exists {
	local action=$1
	local castle=$2
	local repo="$repos/$castle"
	if [[ ! -d $repo ]]; then
		err $EX_ERR "Could not $action $castle, expected $repo to exist"
	fi
}

function home_exists {
	local action=$1
	local castle=$2
	local repo="$repos/$castle"
	if [[ ! -d $repo/home ]]; then
		err $EX_ERR "Could not $action $castle, expected $repo to contain a home folder"
	fi
}

function abs_path {
	(cd "${1%/*}" &>/dev/null; printf "%s/%s" "$(pwd)" "${1##*/}")
}
