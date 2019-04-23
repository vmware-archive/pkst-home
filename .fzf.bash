# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/${USER}/.fzf/bin* ]]; then
  export PATH="${PATH:+${PATH}:}/Users/${USER}/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/${USER}/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/Users/${USER}/.fzf/shell/key-bindings.bash"
