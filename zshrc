#export TERM=linux
export PATH=$HOME/bin:$HOME/.tfenv/bin:/usr/local/bin:$HOME/.local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="jonathan"

# Show timestamps in history (format: yyyy-mm-dd HH:MM:SS)
HIST_STAMPS="yyyy-mm-dd %H:%M:%S"

# Minimal plugins for speed - disabled most heavy ones
plugins=(
  sudo
  git
  fast-syntax-highlighting
  docker
  docker-compose
  kubectl
  helm
)

source $ZSH/oh-my-zsh.sh

# Enable kubectl completions for short aliases (zsh style)
compdef k=kubectl
compdef k8=kubectl
compdef k8s=kubectl

# ============================================================
# OPTIMIZED FANCY PROMPT with smart caching
# ============================================================

# Kubernetes cache variables
_KUBE_CTX_CACHE=""
_KUBE_NS_CACHE=""
_KUBE_LAST_CHECK=0
_KUBE_CHECK_INTERVAL=10  # Only refresh every 10 seconds

# Smart kubernetes cache - reads from file for context, uses cached kubectl for namespace
_get_kube_info_smart() {
  local kubeconfig="${KUBECONFIG:-$HOME/.kube/config}"
  local now=$EPOCHSECONDS

  # Only refresh every N seconds (instant response between checks)
  if (( now - _KUBE_LAST_CHECK > _KUBE_CHECK_INTERVAL )) || [[ -z "$_KUBE_CTX_CACHE" ]]; then
    [[ ! -f "$kubeconfig" ]] && return

    # Read context from file (instant - ~2ms)
    _KUBE_CTX_CACHE=$(grep '^current-context:' "$kubeconfig" 2>/dev/null | sed 's/^current-context: *//' | tr -d '\n')

    # Get namespace using kubectl (runs in background to not block prompt)
    if [[ -n "$_KUBE_CTX_CACHE" ]]; then
      # Try to get namespace from kubectl config
      _KUBE_NS_CACHE=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
      [[ -z "$_KUBE_NS_CACHE" ]] && _KUBE_NS_CACHE="default"
    fi

    _KUBE_LAST_CHECK=$now
  fi

  echo "$_KUBE_CTX_CACHE|$_KUBE_NS_CACHE"
}

# Hook to invalidate cache when switching contexts
kubectl() {
  command kubectl "$@"
  local ret=$?
  # Invalidate cache if context/namespace changed
  if [[ "$1" == "config" ]] && [[ "$2" == "use-context" || "$2" == "set-context" ]]; then
    _KUBE_LAST_CHECK=0
  fi
  return $ret
}

# Optimized fancy prompt with all the visual elements
function build_prompt() {
  local exit_code=$?
  local term_width=${COLUMNS:-$(tput cols)}

  # Get path (fast, built-in)
  local path_str="${(%):-%~}"

  # Git branch - only check if in a git repo (fast)
  local branch=""
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  fi

  # Get kubernetes info with smart caching (only refreshes when config file changes)
  local kube_info=$(_get_kube_info_smart)
  local ctx="${kube_info%%|*}"
  local ns="${kube_info##*|}"

  # Exit code display (show only if non-zero)
  local exit_str=""
  if [[ $exit_code -ne 0 ]]; then
    exit_str=" %{$fg[red]%}✗ ${exit_code}%{$reset_color%}"
  fi

  # Calculate lengths for separator
  local time_len=10  # [HH:MM:SS] is always 10 chars
  local path_len=${#path_str}
  local git_len=0
  [[ -n "$branch" ]] && git_len=$((${#branch} + 3))

  local exit_len=0
  [[ $exit_code -ne 0 ]] && exit_len=$((${#exit_code} + 4))

  local kube_len=0
  [[ -n "$ctx" ]] && kube_len=$((${#ctx} + ${#ns} + 4))

  # Calculate separator length
  local left_len=$((time_len + 1 + path_len + git_len))
  local right_len=$((exit_len + kube_len))
  local separator_len=$((term_width - left_len - right_len - 2))
  [[ $separator_len -lt 3 ]] && separator_len=3

  # Build separator with yellow straight line
  local sep=$(printf '━%.0s' {1..$separator_len})

  # Build the fancy prompt
  local prompt_line="%{$fg[cyan]%}[%*]%{$reset_color%} %{$fg[blue]%}%~%{$reset_color%}"
  [[ -n "$branch" ]] && prompt_line="${prompt_line} %{$fg[magenta]%} ${branch}%{$reset_color%}"
  prompt_line="${prompt_line} %{$fg[yellow]%}${sep}%{$reset_color%}"
  [[ $exit_code -ne 0 ]] && prompt_line="${prompt_line}${exit_str}"
  [[ -n "$ctx" ]] && prompt_line="${prompt_line} %{$fg[cyan]%}☸ %{$fg[red]%}${ctx}%{$reset_color%}:%{$fg[green]%}${ns}%{$reset_color%}"

  echo "${prompt_line}"
}

setopt PROMPT_SUBST
PROMPT='
$(build_prompt)
%{$fg[yellow]%}➜%{$reset_color%} '

RPROMPT=''

export EDITOR=vim

alias oplogin='eval $(op signin)'

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
alias k="kubectl"
alias kp="title Pods; kubectl get pods"
alias kpa="title 'All Pods'; kubectl get pods -A | grep -v 'kube-system\|longhorn-system'"
alias kd="title Deployments; kubectl get deployment -A --field-selector=metadata.namespace!=kube-system"
alias ks="title Services; kubectl get svc -A --field-selector=metadata.namespace!=kube-system"
alias kn="title Nodes; kubectl get nodes -o wide"
alias ke="title Nodes; kubectl get events -A"
alias kl="kubectl logs -f --tail 100"
alias ki="title Ingress; kubectl get ingress -A; kubectl-ingressroute-hosts;"
alias kubectl-ingressroute-hosts='title IngressRoute;kubectl get ingressroute -A -o jsonpath="{range .items[*]}{.metadata.namespace} {.metadata.name} {.spec.routes[*].match}{\"\n\"}{end}" | awk "{printf \"%-40s %-40s %-40s\n\", \$1, \$2, \$3}"'
alias kimage="title Image; kp -o jsonpath=\"{.items[*].spec.containers[*].image}\" | tr -s '[[:space:]]' '\n' | sort | uniq -c"
alias kpod="kubectl describe pod"
alias kdep="kubectl describe deployment"
alias ksvc="kubectl describe service"
alias ksec='() {
  if [ -z "$2" ]; then
    kubectl get secret/$1 -o go-template="{{range \$k,\$v := .data}}{{printf \"%s: \" \$k}}{{if not \$v}}{{\$v}}{{else}}{{\$v | base64decode}}{{end}}{{\"\n\"}}{{end}}"
  else
    kubectl get secret/$1 -n $2 -o go-template="{{range \$k,\$v := .data}}{{printf \"%s: \" \$k}}{{if not \$v}}{{\$v}}{{else}}{{\$v | base64decode}}{{end}}{{\"\n\"}}{{end}}"
  fi
}'
alias kpv="kubectl get pv"
alias kpvc="kubectl get pvc --all-namespaces"
alias kpvcd="kubectl describe pvc"
alias kexec='function _kexec(){ kubectl exec -it $1 -n $2 -- bash; }; _kexec'
alias kctx='kubectl-ctx'
alias kns='kubectl-ns'

# alias kctx="kubectl config get-contexts"
alias kprod="kubectl config use-context prod"
alias kstg="kubectl config use-context stg"
alias kdebug="kubectl run debug-pod --image=ubuntu:latest --restart=Never --command -- sleep infinity && sleep 5 && kubectl exec -it debug-pod -- bash"

alias kclean='kubectl get pods --all-namespaces \
  | grep -E "ContainerStatusUnknown|Error" \
  | awk "{print \$1, \$2}" \
  | xargs -n2 sh -c "kubectl delete pod \$1 -n \$0"'


_kpg() {
  local pattern=${1:-ContainerCreating}
  local minage=${2:-0}
  local now=$(date -u +%s)

  # Colors
  local RED="\033[0;31m"
  local GREEN="\033[0;32m"
  local YELLOW="\033[1;33m"
  local BLUE="\033[0;34m"
  local CYAN="\033[0;36m"
  local NC="\033[0m"

  echo "Searching for pods matching: $pattern (min age: ${minage}s)"

  kubectl get pods --all-namespaces \
    -o custom-columns="NS:.metadata.namespace,NAME:.metadata.name,PHASE:.status.phase,REASON:.status.containerStatuses[*].state.waiting.reason,CREATED:.metadata.creationTimestamp" \
  | awk -v now="$now" -v minage="$minage" -v pattern="$pattern" \
        -v RED="$RED" -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v BLUE="$BLUE" -v CYAN="$CYAN" -v NC="$NC" '
      NR>1 {
        # Skip if timestamp field is empty or header row
        if ($5 == "" || $5 == "CREATED") next

        # Check if line matches pattern (namespace, pod name, or reason)
        if (tolower($0) !~ tolower(pattern)) next

        # Parse timestamp
        cmd = "date -u -j -f \"%Y-%m-%dT%H:%M:%SZ\" \"" $5 "\" +%s 2>/dev/null"
        result = (cmd | getline t)
        close(cmd)

        if (result <= 0) {
          # Try alternative format without Z
          timestamp = $5
          gsub(/Z$/, "", timestamp)
          cmd = "date -u -j -f \"%Y-%m-%dT%H:%M:%S\" \"" timestamp "\" +%s 2>/dev/null"
          result = (cmd | getline t)
          close(cmd)

          if (result <= 0) {
            print "Warning: Could not parse timestamp: " $5 > "/dev/stderr"
            next
          }
        }

        age = now - t
        if (age >= minage) {
          if ($3 == "Running") {
            phase_color = GREEN
          } else if ($3 == "Pending") {
            phase_color = YELLOW
          } else {
            phase_color = RED
          }

          reason_display = ($4 == "<none>") ? "N/A" : $4

          printf "%s%s/%s%s  %sPHASE=%s%s  %sREASON=%s%s  %sAGE=%ds%s\n", \
            CYAN, $1, $2, NC, \
            phase_color, $3, NC, \
            BLUE, reason_display, NC, \
            YELLOW, age, NC
        }
      }'
}

alias kpg=_kpg

kreport() {
  local minage=${1:-0}
  local now=$(date -u +%s)

  # Colors
  local RED="\033[0;31m"
  local GREEN="\033[0;32m"
  local YELLOW="\033[1;33m"
  local BLUE="\033[0;34m"
  local CYAN="\033[0;36m"
  local BOLD="\033[1m"
  local NC="\033[0m"

  echo "📊 Kubernetes Namespace Report (min age: ${minage}s)"
  echo "=================================================================="
  echo "Legend: ${GREEN}RUN${NC}=Running pods, ${YELLOW}CREATE${NC}=Creating/Pending pods, ${RED}FAIL${NC}=Failed/Error pods, ${BLUE}OTHER${NC}=Other statuses, ${CYAN}TOTAL${NC}=All pods"
  echo ""

  kubectl get pods --all-namespaces \
    -o custom-columns="NS:.metadata.namespace,NAME:.metadata.namespace,PHASE:.status.phase,REASON:.status.containerStatuses[*].state.waiting.reason,CREATED:.metadata.creationTimestamp" \
  | awk -v now="$now" -v minage="$minage" \
        -v RED="$RED" -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v BLUE="$BLUE" -v CYAN="$CYAN" -v BOLD="$BOLD" -v NC="$NC" '
      NR>1 {
        # Skip if timestamp or namespace field is empty
        if ($5 == "" || $5 == "CREATED" || $1 == "") next

        # Parse timestamp for age filtering
        cmd = "date -u -j -f \"%Y-%m-%dT%H:%M:%SZ\" \"" $5 "\" +%s 2>/dev/null"
        result = (cmd | getline t)
        close(cmd)

        if (result <= 0) {
          timestamp = $5
          gsub(/Z$/, "", timestamp)
          cmd = "date -u -j -f \"%Y-%m-%dT%H:%M:%S\" \"" timestamp "\" +%s 2>/dev/null"
          result = (cmd | getline t)
          close(cmd)
          if (result <= 0) next
        }

        age = now - t
        if (age < minage) next

        ns = $1
        phase = $3
        reason = $4

        # Count by namespace and status
        if (phase == "Running") {
          running[ns]++
        } else if (phase == "Pending" || reason == "ContainerCreating" || reason == "PodInitializing") {
          creating[ns]++
        } else if (phase == "Failed" || phase == "CrashLoopBackOff" || reason == "ImagePullBackOff" || reason == "ErrImagePull") {
          failed[ns]++
        } else {
          other[ns]++
        }
        total[ns]++
      }
      END {
        # Print header
        printf "%s%-45s %sRUN %sCREATE %sFAIL %sOTHER %sTOTAL%s\n", \
          BOLD, "NAMESPACE", GREEN, YELLOW, RED, BLUE, CYAN, NC
        printf "=================================================================="

        # Collect namespaces with running counts for sorting
        for (ns in total) {
          run_count = running[ns] + 0
          printf "\n%03d|%-50s %s%3d%s   %s%3d%s   %s%3d%s   %s%3d%s   %s%3d%s", \
            run_count, ns, \
            GREEN, run_count, NC, \
            YELLOW, creating[ns] + 0, NC, \
            RED, failed[ns] + 0, NC, \
            BLUE, other[ns] + 0, NC, \
            CYAN, total[ns] + 0, NC
        }
        print ""
      }' \
  | tail -n +4 \
  | sort -nr \
  | sed 's/^[0-9]*|//'
}

kdig() {
  local action=$1
  local ns_pod=$2

  if [[ -z "$action" || -z "$ns_pod" ]]; then
    echo "Usage: kdig {shell|log|pod} namespace/pod"
    return 1
  fi

  # Split "ns/pod"
  local ns="${ns_pod%%/*}"
  local pod="${ns_pod##*/}"

  case "$action" in
    shell)
      echo "➡️  Exec into pod: $ns/$pod"
      kubectl exec -it -n "$ns" "$pod" -- /bin/sh || \
      kubectl exec -it -n "$ns" "$pod" -- /bin/bash
      ;;
    log|logs)
      echo "➡️  Logs for pod: $ns/$pod"
      kubectl logs -n "$ns" "$pod" --tail=200 -f
      ;;
    pod|describe)
      echo "➡️  Describe pod: $ns/$pod"
      kubectl describe pod -n "$ns" "$pod"
      ;;
    *)
      echo "Unknown action: $action"
      echo "Usage: kdig {shell|log|pod} namespace/pod"
      return 1
      ;;
  esac
}

#alias d='docker'
alias dps='title "Docker PS"; docker ps -a'
alias dim='title "Docker Images"; docker images'
alias dkill='docker kill $(docker ps -q)'
alias dclean='docker rmi -f $(docker images -aq)'

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
alias gsh='git stash'
alias gshp='git stash pop'
alias greset="git reset --hard HEAD"
alias gclean="git clean -f -d -x"

alias fmt='terraform fmt -recursive .'
alias fmtc='terraform fmt -recursive . && git add -A && git commit -m "FMT" && git push'

function tmux_start() {
  tmux new-session -d -s work
  tmux send-keys -t work:1 'cd ~/project/' C-m
  tmux new-window -t work:2 -n 'Home'
  tmux send-keys -t work:2 'cd ~/' C-m
  tmux new-window -t work:3 -n 'Downloads'
  tmux send-keys -t work:3 'cd ~/Downloads/' C-m
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

catclip() {
    bat --style=plain "$1" | xclip -sel clip
}

tclip() {
    local cmd="$@"
    local output
    output=$(eval "$cmd")
    echo "$output"
    {
        echo "$ $cmd"
        echo "$output"
    } | xclip -sel clip
}

aws_ec2_list() {
  aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].{ID: InstanceId, Name: Tags[?Key==`Name`]|[0].Value, Hostname: Tags[?Key==`hostname`]|[0].Value, PrivateIP: PrivateIpAddress, Status: State.Name}' \
    --output table
}

aws_ec2_ssm_connect() {
  if [ -z "$1" ]; then
    echo "Usage: aws_ec2_ssm_connect <instance-id>"
    return 1
  fi
  aws ssm start-session --target "$1"
}

aws_ec2_details() {
  if [ -z "$1" ]; then
    echo "Usage: aws_ec2_details <instance-id>"
    return 1
  fi

  aws ec2 describe-instances \
    --instance-ids "$1" \
    --query 'Reservations[].Instances[].{
      ID: InstanceId,
      Name: Tags[?Key==`Name`]|[0].Value,
      Hostname: Tags[?Key==`hostname`]|[0].Value,
      Type: InstanceType,
      State: State.Name,
      PrivateIP: PrivateIpAddress,
      PublicIP: PublicIpAddress,
      AZ: Placement.AvailabilityZone,
      LaunchTime: LaunchTime,
      KeyName: KeyName
    }' \
    --output json | jq -r '.[0] | to_entries[] | "\(.key): \(.value)"'
}

aws_s3_list() {
  aws s3 ls
}

aws_fsx_list() {
  aws fsx describe-file-systems --output table
}

aws_vpc_list() {
  aws ec2 describe-vpcs \
    --query 'Vpcs[*].{VPC_ID: VpcId, CIDR: CidrBlock}' \
    --output table
}

screencast () {
    # Ask user to select a rectangle; flameshot prints WxH+X+Y
    local selection
    selection=$(flameshot gui -g)
    if [ -z "$selection" ]; then
        echo "No selection made. Exiting."
        return 1
    fi

    # Parse geometry WxH+X+Y using a single awk call
    local width height x y
    read -r width height x y <<<"$(awk -F'[x+]' '{print $1, $2, $3, $4}' <<<"$selection")"

    # Countdown
    echo "Recording will start in 3 seconds..."
    sleep 1
    echo "2..."
    sleep 1
    echo "1..."
    sleep 1

    # Generate filename
    local filename
    filename="$(date +"%Y%m%d%H%M").mkv"

    # Use current X display, fall back to :0.0 just in case
    local display="${DISPLAY:-:0.0}"

    # Start recording with selected area
    # ffmpeg -f x11grab \
    #     -video_size "${width}x${height}" \
    #     -framerate 25 \
    #     -i "${display}+${x},${y}" \
    #     -f alsa -i default \
    #     -c:v libx264 -preset ultrafast \
    #     -c:a aac \
    #     "$filename"

    ffmpeg -f x11grab \
        -video_size "${width}x${height}" \
        -framerate 25 \
        -i "${display}+${x},${y}" \
        -c:v libx264 -preset ultrafast \
        -an \
        "$filename"
}


# Check if .zshrc.personal exists and source it
if [[ -f ~/.zshrc.personal ]]; then
    source ~/.zshrc.personal
fi

bindkey '\t' menu-complete "$terminfo[kcbt]" reverse-menu-complete

# ============================================================
# LAZY LOAD NVM (much faster shell startup)
# ============================================================
export NVM_DIR="$HOME/.nvm"

# Lazy load nvm - only load when actually needed
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

node() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  node "$@"
}

npm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  npm "$@"
}

npx() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  npx "$@"
}

export DATEBIN=gdate
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# eval "$(atuin init zsh)"
# export PATH=/usr/local/go/bin:$PATH
