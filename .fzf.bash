# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/pivotal/.fzf/bin* ]]; then
  export PATH="$PATH:/Users/pivotal/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/pivotal/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/Users/pivotal/.fzf/shell/key-bindings.bash"

