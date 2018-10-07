# common env. Fish needs an export polyfil. No dynamic stuff here (thanks, fish)
export GOPATH=~/gocode
export PATH=~/local/bin:~/bin:/usr/local/bin:/snap/bin:/usr/local/sbin:/usr/local/share/npm/bin:$GOPATH/bin:/usr/local/go/bin:$PATH
export EDITOR=vim
export PAGER='less -R'
export LANG=en_GB.UTF-8
export BC_ENV_ARGS="~/.bcrc -l"
export GCC_COLORS=1
# note that ~ does not expand in .ripgreprc
export FZF_DEFAULT_COMMAND="rg --files --hidden --ignore-file=~/.rgignore"
export FZF_CTRL_T_COMMAND="rg --files --hidden --ignore-file=~/.rgignore"
export RIPGREP_CONFIG_PATH=~/.ripgreprc
