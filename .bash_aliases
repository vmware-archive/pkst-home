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

run_sqlline() {
  query=$1

  JDBC_URL=${JDBC_URL:-$(lpass show "Shared-PKS Telemetry/JDBC Telemetry" --notes)}
  JDBC_USERNAME=${JDBC_USERNAME:-$(lpass show "Shared-PKS Telemetry/JDBC Telemetry" --username)}
  JDBC_PASSWORD=${JDBC_PASSWORD:-$(lpass show "Shared-PKS Telemetry/JDBC Telemetry" --password)}

  java -cp ".:$HOME/workspace/pkst-home/bin/*" sqlline.SqlLine \
	  -u $JDBC_URL \
	  -n $JDBC_USERNAME -p $JDBC_PASSWORD \
	  --fastConnect=true --incremental=true --isolation=TRANSACTION_READ_UNCOMMITTED --outputformat=json \
	  -e "${query}"
}

export -f run_sqlline
