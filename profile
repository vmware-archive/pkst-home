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

export PATH="$HOME/workspace/pkst-home/bin:$PATH"

alias cat=lolcat
