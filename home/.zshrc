# pass * if globbing fails (etc)
unsetopt NOMATCH

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

typeset -U path
path=(~/bin /usr/local/bin /usr/local/share/npm/bin $path)

# TERM TYPE Inside screen/tmux, it should be screen-256color -- this is
# configured in .tmux.conf.  Outside, it's up to you to make sure your terminal
# is configured to provide the correct, 256 color terminal type. For putty,
# it's putty-256color (which fixes a lot of things) and otherwise it's probably
# something like xterm-256color. Most, if not all off the terminals I use
# support 256 colors, so it's safe to force it as a last resort, but warn.
if [[ -z $TMUX ]] && test 0$(tput colors 2>/dev/null) -ne 256; then
	echo -e "\e[00;31m> TERM '$TERM' is not a 256 colour type! Overriding to xterm-256color. Please set. EG: Putty should have putty-256color.\e[00m"
	export TERM=xterm-256color
fi

HISTSIZE=9000
SAVEHIST=9000
HISTFILE=~/.bash_history
setopt HIST_IGNORE_DUPS
unsetopt EXTENDED_HISTORY # just commands plskthx so bash_history is compatible
setopt INC_APPEND_HISTORY # immediate sharing of history

# auto rehash to discover execs in path
setopt nohashdirs

# with arrow keys
zstyle ':completion:*' menu select

setopt completealiases

# MOAR PROMPT

function __p4_ps1 {
	[ $P4CLIENT ] || return
	echo -n " ($P4CLIENT) "
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

PROMPT="\$(__exit_warn)
%F{75}%n@%M:\$PWD%f \$(git_super_status)\$(__p4_ps1) %F{239}\$(date +%T)%f
$ "

# vim -X = don't look for X server, which can be slow
export EDITOR='vim -X'
export PAGER=~/bin/vimpager

# zsh will use vi bindings if you have vim as the editor. I want emacs.
# zsh does not use gnu readline, but zle
bindkey -e

# Completion
autoload -U compinit compinit

# Syntax highlighting
#git@github.com:zsh-users/zsh-syntax-highlighting.git
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# history search by substring like fish and bash (with inputrc)
# git@github.com:zsh-users/zsh-history-substring-search.git
# must be loaded after syntax highlighting
source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh

# bind UP and DOWN arrow keys
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# case insensitive completion
zstyle ':completion:*' '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# sometimes TMUX can get confused about whether unicode is supported to draw
# lines or not. tmux may draw x and q instead, or default to - and | which is
# ascii. This also allows other programs to use nice UTF-8 symbols, such as
# NERDtree in vim. So very awesome.
# Use locale-gen en_GB.UTF-8 to install
export LANG=en_GB.UTF-8

# mac bc read the conf file to allow floating point maths
# and load the standard library
export BC_ENV_ARGS="$HOME/.bcrc -l"
# also, copy the fish bc wrapper
math() {
	echo "$@" | bc
}

# On some machines, hostname is not set. Using $(hostname) to do this is slow,
# so just read from /etc/hostname)
[ $HOSTNAME ] || HOSTNAME=$(cat /etc/hostname 2>/dev/null || hostname)
export HOSTNAME

# if you call a different shell, this does not happen automatically. WTF?
export SHELL=$(which zsh)

# available since 4.8.0
export GCC_COLORS=1

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
		LABEL=$(echo $PWD | sed 's/[^a-zA-Z0-9\/]/-/g' | grep -oE '[^\/]+$')

		# do the correct escape codes. BTW terminal title is always set to hostname
		echo -ne "\\033k$LABEL\\033\\\\"
	fi
}

precmd() {
	# reload history to get immediate update because my computer is fast, yo.
	fc -R
}

# aliases shared between fish and bash
source ~/.aliases

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

[ -x /usr/bin/keychain ] && [ -r ~/.ssh/id_rsa ] && eval `keychain --nogui --quiet --eval ~/.ssh/id_rsa`
test -x /usr/bin/dircolors && eval $(dircolors ~/.dir_colors)

# Disable stupid flow control. Ctrl+S can disable the terminal, requiring
# Ctrl+Q to restore. It can result in an apparent hung terminal, if
# accidentally pressed.
stty -ixon -ixoff

# ls is the first thing I normally do when I log in. Let's hope it's not annoying
echo "Files in $PWD are:"
echo
# neat ls with fixed width
COLUMNS=80 ls

echo -e "\n> zsh, dotfiles version $(cat ~/.naggie-dotfiles-version)"
echo '>' $(uptime)

