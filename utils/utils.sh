function homesick_export()
{
    local castle
    local castle_path
    local git_url

    pushd . >/dev/null
    for castle_path in ~/.homesick/repos/*
    do
        castle=$(basename $castle_path)
        cd $castle_path
        git_url=$(git config --get remote.origin.url)
        echo ""
        echo -e "${SOL_EMPH}# ${SOL_GREEN}$castle${NO_COLOUR}"
        echo homesick clone $git_url; echo homesick symlink $castle
    done
    popd >/dev/null
}


function homesick_local_changes()
{
    local verbose=0

    if [[ $# -eq 1 && "$1" == "-v" ]]; then
        verbose=1
    else
        if [[ $# -gt 0 ]]; then
            echo 'usage homesick_local_changes [-v]'
            return
        fi
    fi

    echo Looking for local modifications in your castles...

    local castle
    local castle_path
    local -i untracked
    local -i changed
    local -i local_commits

    pushd . >/dev/null
    for castle_path in ~/.homesick/repos/*
    do
        castle=$(basename $castle_path)
        cd $castle_path
        echo -e "${SOL_EMPH}* ${SOL_GREEN}$castle${NO_COLOUR}"

        # dirty
        if [[ $verbose -eq 1 ]]; then
            git diff-files 2>&1;
        fi
        git diff-files --quiet >/dev/null 2>&1; changed=$?

        if [ $changed -eq 0 ]; then
           # nothing to do
           :
        else
             if [ $changed -eq 1 ]; then
                echo -e "${SOL_COMMENT}- there are some ${SOL_EMPH}changed ${SOL_COMMENT}files.${NO_COLOUR}"
            else
                echo -e "${SOL_RED}- error from git diff-files\!${NO_COLOUR}"
            fi
        fi

        # untracked
        if [ $verbose -eq 0 ]; then
            git ls-files --other --exclude-standard --error-unmatch . >/dev/null 2>&1; untracked=$?
        else
            git ls-files --other --exclude-standard --error-unmatch .  2>/dev/null; untracked=$?
        fi

        if [ $untracked -eq 1 ]; then
           # nothing to do
           :
        else
            if [ $untracked -eq 0 ]; then
                echo -e "${SOL_COMMENT}- there are some ${SOL_EMPH}untracked ${SOL_COMMENT}files.${NO_COLOUR}"
            else
                echo -e "${SOL_RED}- error from ls-files\!${NO_COLOUR}"
            fi
        fi

        # local commits
        local_commits=0
        [ ! $(git rev-parse HEAD) == $(git rev-parse origin/master) ] && local_commits=1

        if [[ $verbose -eq 1 && $local_commits -eq 1 ]]; then
            git log origin/master..HEAD --oneline
        fi

        if [ $local_commits = 1 ]; then
            echo -e "${SOL_COMMENT}- there are some ${SOL_EMPH}unpushed ${SOL_COMMENT}commits.${NO_COLOUR}"
        fi
    done
    popd >/dev/null
}