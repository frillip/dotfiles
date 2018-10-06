for i in (grep '^export' ~/.env.sh | cut -c 8-)
    set arr (string split -m1 = $i)
    set key $arr[1]
    set value $arr[2]

    ## convert path to array, emulating interpolation of $PATH
    if test $key = PATH
        set value (echo $value | tr : '\n' | grep -v PATH) $PATH
    end

    set -gx $key $value
end

status --is-interactive; or exit 0

# only on new shell, fail silently. Must be non-invasive.
test ! $TMUX; and ~/bin/server-splash ^/dev/null

function tmux_update_env --on-event fish_preexec
    # when an SSH connection is re-established, so is the agent connection.
    # Reload it automatically.
    # export is supported in later fish releases.
    test -z $TMUX; and eval (tmux show-env -s | grep 'SSH_AUTH_SOCK=\|DISPLAY=' | sed 's/^/export /g')
end

# Sometimes not set or fully qualified; simple name preferred.
set -x HOSTNAME (hostname -s)

# taken from hostname
set -x SYSTEM_COLOUR (python ~/bin/system-colour.py $HOSTNAME)
test $TMUX; and tmux set -g status-left-bg colour{$SYSTEM_COLOUR} ^/dev/null >/dev/null

if test $USER = root
    set PROMPT_COLOUR 160 # red
else
    set PROMPT_COLOUR $SYSTEM_COLOUR
end

# AUTOMATIC TMUX
# must not launch tmux inside tmux (no memes please)
test -z $TMUX
	# installed?
	and which tmux > /dev/null ^&1
	# only attach if single session
	and test (tmux list-sessions 2>/dev/null | wc -l) -eq 1
	# don't attach if already attached elsewhere
	and test (tmux list-clients 2>/dev/null | wc -l) -eq 0
	# terminal must be wide enough
	and test (tput cols) -gt 119
	# only then is is safe to assume it's OK to jump in
	and tmux attach


# if you call a different shell, this does not happen automatically. WTF?
set -x SHELL (which fish)

# alias is just a wrapper for creating a function
# aliases shared between fish and bash
. ~/.aliases

# nvim? override
if which nvim > /dev/null
    alias vim="nvim -p"
    set -x EDITOR nvim
end

# Very long-winded in fish...
function _prependsudo
	commandline -C 0
	commandline -i 'sudo '
	commandline -f end-of-line
end

# binds must be in this wrapper or dedicated file
function fish_user_key_bindings
	bind \cs _prependsudo

	# Launch FZF vim plugin outside of vim
	bind \cp 'vim -c FZF'
end

# get new or steal existing tmux
function tm
	# must not already be inside tmux
	test ! $TMUX; or return
	# detach any other clients
	# attach or make new if there isn't one
	tmux attach -d; or tmux
end

# patches for Mac OS X
set PLATFORM (uname)
if test "$PLATFORM" = 'Darwin'
	alias ls='ls -G'
	#unalias ls
	# unalias is broken...
	#alias ls=ls
	set -x CLICOLOR 1
	set -x LSCOLORS gxBxhxDxfxhxhxhxhxcxcx
end

function cd
	builtin cd $argv
	and ls
end

test -x /usr/bin/keychain
	and test -r ~/.ssh/id_rsa
	and keychain --nogui --quiet --eval --inherit any ~/.ssh/id_rsa | .

# these functions are too small to warrant a separate file
function fish_greeting
	echo \nWelcome to $HOSTNAME, $USER!
    uptime
end


function fish_title --description 'Set terminal (not tmux) title'
	# title of terminal
	echo $HOSTNAME
end

# only auto set title based on initial pane
# this detects if the pane is the first in a new window (probably)
test $TMUX
	and test (tmux list-panes | wc -l) -eq 1
	and set -x TMUX_PRIMARY_PANE set

function fish_set_tmux_title --description "Sets tmux pane title to output of fish_tmux_title, with padding" --on-variable PWD
    if test $TMUX; and test $TMUX_PRIMARY_PANE
        set LABEL (echo $PWD | sed 's/[^a-zA-Z0-9\.\/]/-/g' | grep -oE '[^\/]+$')
        tmux rename-window "$LABEL"
    end
end

function __fish_p4_prompt
	test $P4CLIENT; or return
	echo -n " ($P4CLIENT) "
end

function __sa_prompt
    # is SSH agent wired in?
    test $SSH_AUTH_SOCK; or return
    test -e $SSH_AUTH_SOCK; and echo -ne "\033[32m[A]\033[90m "
end

function fish_prompt --description 'Write out the prompt'
	# test status of last command without affecting it by using 'or' which tests and forwards
	or printf "\n\33[31mExited with status %s\33[m" $status

	printf "\n\33[38;5;%sm%s@%s:%s\33[90m %s %s %s\33[0m\n\$ " \
        $PROMPT_COLOUR $USER $HOSTNAME $PWD (__fish_git_prompt) (__fish_p4_prompt) (__sa_prompt)(date +%T)
end

# SSH wrapper to magically LOCK tmux title to hostname, if tmux is running
# prefer clear terminal after SSH, on success only
# now with MOAR agent forwarding
function ssh --description 'SSH wrapper to magically LOCK tmux title to hostname, if tmux is running'
	if test $TMUX
		# find host from array (in a dumb way)
		set host $argv[-1]

        set old_window_name (tmux display-message -p '#W')
		printf "\\033k%s\\033\\\\" $host
		command ssh -A $argv
		printf "\\033k%s\\033\\\\" $old_window_name
	else
		command ssh -A $argv
	end
end

# initially set title
fish_set_tmux_title

# fix gpg-agent ncurses passphrase prompt
# https://www.gnupg.org/documentation/manuals/gnupg/Common-Problems.html
set GPG_TTY (tty)
