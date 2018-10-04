# common env. Fish needs an export polyfil. No dynamic stuff here (thanks, fish)
export GOPATH=~/gocode
export PATH=~/local/bin:~/bin:/usr/local/bin:/snap/bin:/usr/local/sbin:/usr/local/share/npm/bin:$GOPATH/bin:/usr/local/go/bin:$PATH
export EDITOR=vim
export PAGER='less -R'
export LANG=en_GB.UTF-8
export BC_ENV_ARGS="$HOME/.bcrc -l"
export GCC_COLORS=1
export FZF_DEFAULT_COMMAND="ripgrep --files --hidden"
export FZF_CTRL_T_COMMAND="ripgrep --files --hidden"
