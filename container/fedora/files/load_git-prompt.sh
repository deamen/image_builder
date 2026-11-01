if test -f ~/.config/git/git-prompt.sh
then
        . ~/.config/git/git-prompt.sh
else
        PS1='\[\033]0;$TITLEPREFIX:$PWD\007\]' # set window title
        PS1="$PS1"'\n'                 # new line
        PS1="$PS1"'\[\033[32m\]'       # change to green
        PS1="$PS1"'\u@\h '             # user@host<space>
        PS1="$PS1"'\[\033[35m\]'       # change to purple
        PS1="$PS1"'$MSYSTEM '          # show MSYSTEM
        PS1="$PS1"'\[\033[33m\]'       # change to brownish yellow
        PS1="$PS1"'\w'                 # current working directory
        # Fedora/RHEL ship git-prompt.sh in git-core, not under /usr/share/doc
        if [ -f /etc/redhat-release ]; then
            COMPLETION_PATH="/usr/share/git-core/contrib/completion"
        elif [ -f /etc/alpine-release ]; then
            COMPLETION_PATH="/usr/share/git-core"
        else
            COMPLETION_PATH="/usr/share/doc/git/contrib/completion"
        fi

        if test -f "$COMPLETION_PATH/git-prompt.sh"
        then
                if test -f /usr/share/bash-completion/completions/git
                then
                    . /usr/share/bash-completion/completions/git
                elif test -f "$COMPLETION_PATH/git-completion.bash"
                then
                    . "$COMPLETION_PATH/git-completion.bash"
                fi
                . "$COMPLETION_PATH/git-prompt.sh"
                PS1="$PS1"'\[\033[36m\]'  # change color to cyan
                PS1="$PS1"'`__git_ps1`'   # bash function
        fi

        PS1="$PS1"'\[\033[0m\]'        # change color
        PS1="$PS1"'\n'                 # new line
        PS1="$PS1"'$ '                 # prompt: always $
fi
