alias la='ls -AF'
alias l='ls -al'
alias ll='ls -al'
alias ls='ls -G'
alias cdgo="cd $GOPATH"
alias mygo="cd $GOPATH/src/github.com/sahilm"
alias remove_all_gems="gem uninstall -aIx"
alias hfix='history -n && history | sort -k2 -k1nr | uniq -f1 | sort -n | cut -c8- > ~/.tmp$$ && history -c && history -r ~/.tmp$$ && history -w && rm ~/.tmp$$'
alias realpath=grealpath

# Simple fn to http serve the $PWD
function serve() {
    local port=${1:-9000}
    ruby -run -e httpd . -p $port
}

# So that you can just type serve anywhere
export -f serve

# So that you can bootstrap from anywhere!
function bootstrap() {
    $HOME/src/dotfiles/machine_bootstrap.sh
}

export -f bootstrap

dcleanup(){
    docker rm -v $(docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
    docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2>/dev/null
}

export -f dcleanup
