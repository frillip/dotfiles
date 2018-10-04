source ~/.env.sh

# pass * if globbing fails (etc)
unsetopt NOMATCH

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# only on new shell, fail silently. Must be non-invasive.
[ ! $TMUX ] && ~/bin/server-splash 2>/dev/null

HISTSIZE=9000
SAVEHIST=9000
# Change default as unconfigured bash could clobber history. Bash can run
# unconfigured if CTRL+C is hit during initialisation.
HISTFILE=~/.history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
unsetopt EXTENDED_HISTORY # just commands plskthx so bash_history is compatible
setopt INC_APPEND_HISTORY # immediate sharing of history

# fix annoying accidental commits and amends
# and other dangerous commands, yubikey OTP
export HISTORY_IGNORE='(git*--amend*|ls|cd|cccccc*|*reboot*|*halt*|0*|task*)'

# auto rehash to discover execs in path
setopt nohashdirs

# with arrow keys
zstyle ':completion:*' menu select

setopt completealiases

# SSH wrapper to magically LOCK tmux title to hostname, if tmux is running
# prefer clear terminal after SSH, on success only
# now with MOAR agent forwarding
function ssh {
	if test $TMUX; then
		# find host from array (in a dumb way) by getting last argument
		# It uses the fact that for implicitly loops over the arguments
		# if you don't tell it what to loop over, and the fact that for
		# loop variables aren't scoped: they keep the last value they
		# were set to
		# http://stackoverflow.com/questions/1853946/getting-the-last-argument-passed-to-a-shell-script
		for host; do true; done

        old_window_name=$(tmux display-message -p '#W')

		printf "\\033k%s\\033\\\\" $host
		command ssh -A "$@"
		printf "\\033k%s\\033\\\\" $old_window_name

	else
		command ssh -A "$@"
	fi
}

# MOAR PROMPT
function __p4_ps1 {
	[ $P4CLIENT ] || return
	echo -n " ($P4CLIENT) "
}

function __sa_ps1 {
    # is SSH agent wired in?
    test $SSH_AUTH_SOCK || return
    test -e $SSH_AUTH_SOCK && echo -ne "\e[32m[A]\e[90m "
}

function __exit_warn {
	# test status of last command without affecting it
	stat=$?
	test $stat -ne 0 \
		&& printf "\n\33[31mExited with status %s\33[m" $stat
}
setopt PROMPT_SUBST
autoload -U colors && colors

# git
# git@github.com:olivierverdier/zsh-git-prompt.git
ZSH_THEME_GIT_PROMPT_CACHE=1
source ~/.zsh/zsh-git-prompt/zshrc.sh

# zsh will use vi bindings if you have vim as the editor. I want emacs.
# zsh does not use gnu readline, but zle
bindkey -e

# Completion
autoload -U compinit && compinit

# Syntax highlighting
#git@github.com:zsh-users/zsh-syntax-highlighting.git
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# history search by substring like fish and bash (with inputrc)
# git@github.com:zsh-users/zsh-history-substring-search.git
# must be loaded after syntax highlighting
source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh

# bind UP and DOWN arrow keys
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
# https://github.com/zsh-users/zsh-history-substring-search
# both methods are necessary
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# case insensitive completion
# http://stackoverflow.com/questions/24226685/have-zsh-return-case-insensitive-auto-complete-matches-but-prefer-exact-matches
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

function _tmux_update_env {
    # when an SSH connection is re-established, so is the agent connection.
    # Reload it automatically.
    [ $TMUX ] && eval $(tmux show-env | grep 'SSH_AUTH_SOCK=\|DISPLAY=' | sed 's/^/export /g')
}

# Sometimes not set or fully qualified; simple name preferred.
export HOSTNAME=$(hostname -s)

# set from hostname
export SYSTEM_COLOUR=$(~/bin/system-colour.py $HOSTNAME)
[ $TMUX ] && tmux set -g status-left-bg colour${SYSTEM_COLOUR} &>/dev/null


if [ $USER == root ]; then
    PROMPT_COLOUR=160 # red
else
    PROMPT_COLOUR=$SYSTEM_COLOUR
fi


PROMPT="\$(__exit_warn)
%F{${PROMPT_COLOUR}}%n@%M:\$PWD%f \$(git_super_status)\$(__p4_ps1)\$(__sa_ps1)%F{239}\$(date +%T)%f
$ "

# if you call a different shell, this does not happen automatically. WTF?
export SHELL=$(which zsh)

echo "\nWelcome to $HOSTNAME, $USER! "

# AUTOMATIC TMUX
# must not launch tmux inside tmux (no memes please)
# must be installed/single session/no clients
# term must be sufficiently wide
test -z "$TMUX" \
	&& which tmux &> /dev/null \
	&& test $(tmux list-sessions 2> /dev/null | wc -l) -eq 1 \
	&& test $(tmux list-clients 2> /dev/null | wc -l) -eq 0 \
	&& test $(tput cols) -gt 120 \
	&& tmux attach

# Useful title for ssh
printf "\033]0;%s\007" $HOSTNAME

# only auto set title based on initial pane
# this detects if the pane is the first in a new window
test $TMUX \
	&& test $(tmux list-panes | wc -l) -eq 1 \
	&& TMUX_PRIMARY_PANE=set

# Update TMUX title with path using hook
# Other hooks: http://zsh.sourceforge.net/Doc/Release/Functions.html
chpwd() {
	# only if TMUX is running, and it's safe to assume the user wants to have the tab automatically named
	if [ -n "$TMUX" ] && [ $TMUX_PRIMARY_PANE ]; then

		# to a clever shorthand representation of the current dir
		LABEL=$(echo $PWD | sed 's/[^a-zA-Z0-9\.\/]/-/g' | grep -oE '[^\/]+$')

        tmux rename-window "$LABEL"
	fi
}

precmd() {
	# reload history to get immediate update because my computer is fast, yo.
	fc -R

    # reset the terminal, in case something (such as cat-ing a binary file or
    # failed SSH) sets a strange mode
    stty sane
}

preexec() {
    # no need for another prompt before
    _tmux_update_env
}

# aliases shared between fish and bash
source ~/.aliases

# nvim? override
if which nvim > /dev/null; then
    alias vim="nvim -p"
    export EDITOR=nvim
fi

# zsh uses zle, not readine so .inputrc is not used. Match bindings here:

# Launch FXF vim plugin outside of vim
bindkey -s '\C-p' "\C-k \C-u vim -c FZF\n"

# sudo-ize command
bindkey -s '\C-s' "\C-asudo \C-e"


# get new or steal existing tmux
function tm {
	# must not already be inside tmux
	test ! $TMUX || return
	# detach any other clients
	# attach or make new if there isn't one
	tmux attach -d || tmux
}

# patches for Mac OS X
PLATFORM=$(uname)
if [[ "$PLATFORM" == 'Darwin' ]]; then
	#alias ls='ls -G'
	unalias ls
	export CLICOLOR=1
	export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx
fi

# cd then ls
function cd {
	builtin cd "$@" && ls
}

[ -x /usr/bin/keychain ] && [ -r ~/.ssh/id_rsa ] && eval `keychain --nogui --quiet --eval --inherit any ~/.ssh/id_rsa`
test -x /usr/bin/dircolors && eval $(dircolors ~/.dir_colors)

# Disable stupid flow control. Ctrl+S can disable the terminal, requiring
# Ctrl+Q to restore. It can result in an apparent hung terminal, if
# accidentally pressed.
stty -ixon -ixoff
# https://superuser.com/questions/385175/how-to-reclaim-s-in-zsh
stty stop undef
stty start undef

# fix gpg-agent ncurses passphrase prompt
# https://www.gnupg.org/documentation/manuals/gnupg/Common-Problems.html
export GPG_TTY=$(tty)

uptime

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
