alias grep='grep --color'
alias ls='ls --color'
alias ll='ls -la'
alias reload='source ~/.bashrc'
alias update='sudo aptget update && sudo apt-get upgrade -y && sudo apt-get autoremove && sudo apt-get autoclean'
alias upgrade='update'

function up() {
  times=${1:-1}
  while [ $times -gt 0 ]; do
    cd ..
    times=$(( $times - 1 ))
  done
}

function weather() {
  curl -s "wttr.in/$1?u1n"
}

function trump() {
  curl -s https://api.whatdoestrumpthink.com/api/v1/quotes/random | jq '.message'
}
