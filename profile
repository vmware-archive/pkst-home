source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'


if [ -f $(brew --prefix)/etc/bash_completion.d/git-prompt.sh ]; then
  source $(brew --prefix)/etc/bash_completion.d/git-prompt.sh
fi

if  [ -f $(brew --prefix)/etc/profile.d/z.sh ]; then
  source $(brew --prefix)/etc/profile.d/z.sh
fi

# Show unstaged(*) and staged(+) changes
export GIT_PS1_SHOWDIRTYSTATE=1
# Show stashes($)
export GIT_PS1_SHOWSTASHSTATE=1
# Show untracked(%) files
export GIT_PS1_SHOWUNTRACKEDFILES=1
# Colorize the prompt
export GIT_PS1_SHOWCOLORHINTS=1
# Rotate git duet author
export GIT_DUET_ROTATE_AUTHOR=1

# Show our fancy prompt!
NC='\[\e[0m\]'
BLUE='\[\e[1;34m\]'
export PROMPT_COMMAND='__git_ps1 "$BLUE\W$NC" " \$ "'

# Enable direnv
eval "$(direnv hook $0)"

. /usr/local/etc/bash_completion

export RBENV_ROOT=$HOME/.rbenv
export GOPATH=$HOME/go
export PATH="$RBENV_ROOT/bin:$HOME/workspace/pkst-home/bin:$GOPATH/bin:$PATH"

export PAGER=less
export EDITOR=nvim
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

eval "$(rbenv init -)"
# docker-machine
if docker-machine status | grep -q 'Running'; then
    eval $(docker-machine env default)
fi
# Set tab width to 4
tabs -4

# setup fasd
eval "$(fasd --init auto)"

# Init fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# source all aliases
. $HOME/.bash_aliases

# Alias git to hub
eval "$(hub alias -s)"

export HISTCONTROL=ignoredups:erasedups
# Infinite history
# http://superuser.com/a/479727
export HISTSIZE=""
# export PROMPT_COMMAND="history -n; history -w; history -c; history -r; $PROMPT_COMMAND"

# clear dupes in history
hfix

shopt -s histappend
alias vim=nvim
alias vi=nvim
