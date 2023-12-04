#export TERM=linux
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="jonathan"
plugins=(git)

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

alias pm='sudo pacman' 
alias p='paru'
alias clip="xclip -sel clip"


alias k="kubectl"
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
alias ksvc="kubectl describe service"
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


function tmux_start() {
  tmux new-session -d -s work

  # Change to the directory you want in each window
  tmux send-keys -t work:1 'cd ~/project/' C-m

  tmux new-window -t work:2 -n 'elmeas'
  tmux send-keys -t work:2 'cd ~/project/elmeas/' C-m


  tmux new-window -t work:3 -n 'elmeas_adminplane'
  tmux send-keys -t work:3 'cd ~/project/elmeas/adminplane' C-m

  tmux new-window -t work:4 -n 'outmin'
  tmux send-keys -t work:4 'cd ~/project/outmin/' C-m

  # Attach to the session
  tmux attach-session -t work
}

export NNN_PLUG='f:finder;o:fzopen;p:preview-tabbed;d:diffs;t:nmount;v:imgview;s:suedit;j:autojump;g:gitroot;s:!bash -i*'
${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd
export NNN_FIFO=/tmp/nnn.fifo

nnn-preview ()
{
    # Block nesting of nnn in subshells
    if [ -n "$NNNLVL" ] && [ "${NNNLVL:-0}" -ge 1 ]; then
        echo "nnn is already running"
        return
    fi

    # The default behaviour is to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to see.
    # To cd on quit only on ^G, remove the "export" and set NNN_TMPFILE *exactly* as this:
    #     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # This will create a fifo where all nnn selections will be written to
    NNN_FIFO="$(mktemp --suffix=-nnn -u)"
    export NNN_FIFO
    (umask 077; mkfifo "$NNN_FIFO")

    # Preview command
    preview_cmd="/path/to/preview_cmd.sh"

    # Use `tmux` split as preview
    if [ -e "${TMUX%%,*}" ]; then
        tmux split-window -e "NNN_FIFO=$NNN_FIFO" -dh "$preview_cmd"

    # Use `xterm` as a preview window
    elif (which xterm &> /dev/null); then
        urxvt -e "$preview_cmd" &

    # Unable to find a program to use as a preview window
    else
        echo "unable to open preview, please install tmux or xterm"
    fi

    nnn "$@"

    rm -f "$NNN_FIFO"
}

export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
. /etc/profile.d/autojump.sh
