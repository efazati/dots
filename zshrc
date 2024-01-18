#export TERM=linux
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="jonathan"
plugins=(
  sudo
  git
  git-auto-fetch
  # zsh-autosuggestions
  zsh-syntax-highlighting
  fast-syntax-highlighting
  zsh-autocomplete
  docker
  docker-compose
  kubectl
  helm
)

source $ZSH/oh-my-zsh.sh

export EDITOR=vim

alias line="printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -"
alias title="bash -c 'printf \"%30s\\n\" \"\" | tr \" \" - && echo -e \"\\e[1m\$1\\e[0m\" && printf \"%30s\\n\" \"\" | tr \" \" -' bash"
alias showline="bash -c 'printf \"%*s\\n\" \"\${COLUMNS:-\$(tput cols)}\" \"\" | tr \" \" - && echo -e \"\\e[1m\$1\\e[0m\" && printf \"%*s\\n\" \"\${COLUMNS:-\$(tput cols)}\" \"\" | tr \" \" -' bash"
alias s='sudo'
alias vi='vim'
alias sl='ls'
alias v='vagrant'
alias cat='bat'
alias catt='bat --style=plain'
alias less='bat'
alias nano='vim'
alias wget='wget -c'
alias tailf='tail -f'
alias apt='sudo apt'
alias h='history -i'
alias hs='history | grep'
alias psa='ps aux | grep'

alias pm='sudo pacman' 
alias p='paru'
alias clip="xclip -sel clip"


alias k8="kubectl"
alias k8s="kubectl"
alias kp="title Pods; kubectl get pods -A --field-selector=metadata.namespace!=kube-system"
alias kd="title Deployments; kubectl get deployment -A --field-selector=metadata.namespace!=kube-system"
alias ks="title Services; kubectl get svc -A --field-selector=metadata.namespace!=kube-system"
alias kl="kubectl logs -f --tail 100"
alias ki="title Ingress; kubectl get ingress -A; kubectl-ingressroute-hosts;"
alias kubectl-ingressroute-hosts='title IngressRoute;kubectl get ingressroute -A -o jsonpath="{range .items[*]}{.metadata.namespace} {.metadata.name} {.spec.routes[*].match}{\"\n\"}{end}" | awk "{printf \"%-40s %-40s %-40s\n\", \$1, \$2, \$3}"'
alias kimage="title Image; kp -o jsonpath=\"{.items[*].spec.containers[*].image}\" | tr -s '[[:space:]]' '\n' | sort | uniq -c"
alias kpod="kubectl describe pod"
alias kdep="kubectl describe deployment"
alias ksvc="kubectl describe service"
alias ksec='() { kubectl get secret/$1 -o go-template='"'"'{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'"'"' ; }'
alias kctx="kubectl config get-contexts"
alias kprod="kubectl config use-context prod"
alias kstg="kubectl config use-context stg"


#alias d='docker'
alias dps='title "Docker PS"; docker ps -a'
alias dim='title "Docker Images"; docker images'
alias dkill='docker kill (docker ps -q)'


#alias g='git'
alias gc='git clone'
alias gst='git status'
alias gdiff='git diff'
alias gaa='git add --all'
alias gca='git add --all; git commit'
alias gcaa='git add --all; git commit --amend'
alias gpul='git pull'
alias gpu='git push'
alias gpf='git push -f'
alias glog='git log --oneline --decorate --color'
alias gch='git checkout'
alias gchb='git checkout -'
alias gdev='git checkout dev'
alias gmain='git checkout main'
alias gmaster='git checkout master'
alias gempty='git commit --allow-empty -m "Empty-Commit"'
alias fmt='terraform fmt -recursive . && git add -A && git commit -m "FMT" && git push'

function tmux_start() {
  tmux new-session -d -s work

  # Change to the directory you want in each window
  tmux send-keys -t work:1 'cd ~/project/' C-m

  tmux new-window -t work:2 -n 'Home'
  tmux send-keys -t work:2 'cd ~/' C-m


  tmux new-window -t work:3 -n 'Downloads'
  tmux send-keys -t work:3 'cd ~/Downloads/' C-m

  # Attach to the session
  tmux attach-session -t work
}

smash () {
    local T_PROC=$1
    local T_PIDS=($(pgrep -i "$T_PROC"))
    if [[ "${#T_PIDS[@]}" -ge 1 ]]; then
        echo "Found the following processes:"
        for pid in "${T_PIDS[@]}"; do
            echo "$pid" "$(ps -p "$pid" -o comm= | awk -F'/' '{print $NF}')" | column -t
            echo "Killing ${pid}..."
            ( kill -15 "$pid" ) && continue
            sleep 2
            ( kill -2 "$pid" ) && continue
            sleep 2
            ( kill -1 "$pid" ) && continue
            echo "What the hell is this thing?" >&2 && return 1
        done
    else
        echo "No processes found for: $1" >&2 && return 1
    fi
}


# Check if .zshrc.personal exists and source it
if [[ -f ~/.zshrc.personal ]]; then
    source ~/.zshrc.personal
fi

export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. /usr/share/autojump/autojump.zsh
