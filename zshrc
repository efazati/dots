#export TERM=linux
export PATH=$HOME/bin:$HOME/.tfenv/bin:/usr/local/bin:$HOME/.local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="jonathan"

# Oh-My-Zsh optimizations - disable update checks for faster startup
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"

# Show timestamps in history (format: yyyy-mm-dd HH:MM:SS)
HIST_STAMPS="yyyy-mm-dd %H:%M:%S"

# kube-ps1 configuration (must be before plugins are loaded)
KUBE_PS1_SYMBOL_USE_IMG=true
KUBE_PS1_NS_ENABLE=true  # Show namespace
KUBE_PS1_PREFIX=""       # Remove opening parenthesis
KUBE_PS1_SUFFIX=""       # Remove closing parenthesis
KUBE_PS1_SEPARATOR=""    # Remove separator after symbol

# Minimal plugins for speed - disabled most heavy ones
plugins=(
  sudo
  git
  fast-syntax-highlighting
  docker
  docker-compose
  kubectl
  helm
  kube-ps1
)

source $ZSH/oh-my-zsh.sh

# Enable kubectl completions for short aliases (zsh style) — only if kubectl exists
if (( $+commands[kubectl] )); then
  compdef k=kubectl
  compdef k8=kubectl
  compdef k8s=kubectl
fi

# ============================================================
# FANCY PROMPT with kube-ps1 plugin
# ============================================================
# Description: Builds a custom prompt showing time, path, git branch, kubernetes context, and exit codes
# Features: Full-width separator line, color-coded elements, kubernetes integration
# Auto-called by PROMPT variable - no manual usage needed
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

  # Update and get kubernetes context from kube-ps1 plugin
  _kube_ps1_prompt_update 2>/dev/null
  local kube_info=$(kube_ps1)

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

  # Get visible length of kube_info (calculate directly from variables)
  local kube_len=0
  if [[ -n "$KUBE_PS1_CONTEXT" ]] && [[ "$KUBE_PS1_CONTEXT" != "N/A" ]]; then
    # Visible: symbol(1) + context + : + namespace
    kube_len=$((1 + ${#KUBE_PS1_CONTEXT} + 1 + ${#KUBE_PS1_NAMESPACE} + 1))  # +1 for space before
  fi

  # Calculate separator length
  # Environment badge — set PROMPT_ENV per node (e.g. in ~/.zshrc.personal: PROMPT_ENV="prod").
  # Auto-colored so prod screams at you. Hidden entirely when PROMPT_ENV is unset.
  local env_badge="" env_len=0
  if [[ -n "$PROMPT_ENV" ]]; then
    local env_color
    case "${PROMPT_ENV:l}" in
      prod*|prd|live)     env_color="$bg[red]$fg[white]" ;;
      stg*|stag*|uat)     env_color="$bg[yellow]$fg[black]" ;;
      dev*|local*|test*)  env_color="$bg[green]$fg[black]" ;;
      *)                  env_color="$bg[blue]$fg[white]" ;;
    esac
    env_badge="%{$env_color%} ${PROMPT_ENV} %{$reset_color%} "
    env_len=$(( ${#PROMPT_ENV} + 3 ))   # 2 padding spaces + 1 trailing space
  fi

  local left_len=$((env_len + time_len + 1 + path_len + git_len))
  local right_len=$((exit_len + kube_len))
  local separator_len=$((term_width - left_len - right_len - 2))
  [[ $separator_len -lt 3 ]] && separator_len=3

  # Build separator with yellow straight line
  local sep=$(printf '━%.0s' {1..$separator_len})

  # Build the fancy prompt
  local prompt_line="${env_badge}%{$fg[cyan]%}[%*]%{$reset_color%} %{$fg[green]%}%~%{$reset_color%}"
  [[ -n "$branch" ]] && prompt_line="${prompt_line} %{$fg[magenta]%} ${branch}%{$reset_color%}"
  prompt_line="${prompt_line} %{$fg[yellow]%}${sep}%{$reset_color%}"
  [[ $exit_code -ne 0 ]] && prompt_line="${prompt_line}${exit_str}"
  [[ -n "$kube_info" ]] && prompt_line="${prompt_line} ${kube_info}"

  echo "${prompt_line}"
}

setopt PROMPT_SUBST
PROMPT='$(build_prompt)
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
# Debian/Ubuntu ship bat as `batcat`; alias it back to `bat` when needed
if ! (( $+commands[bat] )) && (( $+commands[batcat] )); then
  alias bat='batcat'
fi
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
alias kctx='kubectx'
alias kns='kubens'

# alias kctx="kubectl config get-contexts"
alias kprod="kubectl config use-context prod"
alias kstg="kubectl config use-context stg"
alias kdebug="kubectl run debug-pod --image=ubuntu:latest --restart=Never --command -- sleep infinity && sleep 5 && kubectl exec -it debug-pod -- bash"

alias kclean='kubectl get pods --all-namespaces \
  | grep -E "ContainerStatusUnknown|Error" \
  | awk "{print \$1, \$2}" \
  | xargs -n2 sh -c "kubectl delete pod \$1 -n \$0"'


# Description: Search and filter Kubernetes pods by pattern and age with color-coded output
# Usage: kpg [pattern] [min_age_seconds]
# Example: kpg ContainerCreating 300  # Find pods creating for >5min
# Example: kpg Error                   # Find all pods with Error status
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

# Description: Generate a summary report of pod counts by namespace with status breakdown
# Usage: kreport [min_age_seconds]
# Example: kreport       # All pods
# Example: kreport 600   # Only pods older than 10 minutes
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

# Description: Quick kubectl action on a pod using namespace/pod format
# Usage: kdig {shell|log|pod} namespace/podname
# Example: kdig shell default/nginx-abc123     # Open shell in pod
# Example: kdig log monitoring/prometheus-xyz  # Stream logs
# Example: kdig pod kube-system/coredns-123   # Describe pod
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

# Description: Start a tmux session with pre-configured windows for work, home, and downloads
# Usage: tmux_start
# Example: tmux_start   # Creates 'work' session with 3 windows
function tmux_start() {
  tmux new-session -d -s work
  tmux send-keys -t work:1 'cd ~/project/' C-m
  tmux new-window -t work:2 -n 'Home'
  tmux send-keys -t work:2 'cd ~/' C-m
  tmux new-window -t work:3 -n 'Downloads'
  tmux send-keys -t work:3 'cd ~/Downloads/' C-m
  tmux attach-session -t work
}

# Description: Gracefully kill processes by name with escalating signals (SIGTERM, SIGINT, SIGHUP)
# Usage: smash <process_name>
# Example: smash chrome      # Kill all chrome processes
# Example: smash python      # Kill all python processes
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

# Description: Copy file contents to clipboard (using bat for syntax highlighting)
# Usage: catclip <filename>
# Example: catclip config.yaml    # Copy file to clipboard
# Example: catclip script.sh      # Copy script to clipboard
catclip() {
    bat --style=plain "$1" | xclip -sel clip
}

# Description: Run a command, display output, and copy both command and output to clipboard
# Usage: tclip <command>
# Example: tclip kubectl get pods           # Run and copy to clipboard
# Example: tclip aws ec2 describe-instances # Run and copy output
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

# Description: List all EC2 instances with key information in table format
# Usage: aws_ec2_list
# Example: aws_ec2_list   # Show all EC2 instances with ID, Name, IP, Status
aws_ec2_list() {
  aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].{ID: InstanceId, Name: Tags[?Key==`Name`]|[0].Value, Hostname: Tags[?Key==`hostname`]|[0].Value, PrivateIP: PrivateIpAddress, Status: State.Name}' \
    --output table
}

# Description: Connect to EC2 instance via AWS Systems Manager Session Manager
# Usage: aws_ec2_ssm_connect <instance-id>
# Example: aws_ec2_ssm_connect i-1234567890abcdef0
aws_ec2_ssm_connect() {
  if [ -z "$1" ]; then
    echo "Usage: aws_ec2_ssm_connect <instance-id>"
    return 1
  fi
  aws ssm start-session --target "$1"
}

# Description: Show detailed information about a specific EC2 instance in JSON format
# Usage: aws_ec2_details <instance-id>
# Example: aws_ec2_details i-1234567890abcdef0
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

# Description: List all S3 buckets in your AWS account
# Usage: aws_s3_list
# Example: aws_s3_list   # Show all S3 buckets
aws_s3_list() {
  aws s3 ls
}

# Description: List all FSx file systems in table format
# Usage: aws_fsx_list
# Example: aws_fsx_list   # Show all FSx file systems
aws_fsx_list() {
  aws fsx describe-file-systems --output table
}

# Description: List all VPCs with their CIDR blocks in table format
# Usage: aws_vpc_list
# Example: aws_vpc_list   # Show all VPCs and their CIDR blocks
aws_vpc_list() {
  aws ec2 describe-vpcs \
    --query 'Vpcs[*].{VPC_ID: VpcId, CIDR: CidrBlock}' \
    --output table
}

# Description: Record a screencast of a selected area using flameshot and ffmpeg
# Usage: screencast
# Example: screencast   # Opens selection tool, then records selected area to .mkv file
# Note: Requires flameshot and ffmpeg installed
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

# Tab completion with menu - fix for empty terminfo[kcbt]
bindkey '\t' menu-complete
[[ -n "$terminfo[kcbt]" ]] && bindkey "$terminfo[kcbt]" reverse-menu-complete

# ============================================================
# LAZY LOAD NVM (much faster shell startup)
# ============================================================
# These functions defer loading NVM until first use, significantly speeding up shell startup
# NVM adds ~400ms to shell startup if loaded immediately, this makes it instant
export NVM_DIR="$HOME/.nvm"

# Description: Lazy-load wrapper for nvm - loads NVM on first use
# Usage: nvm <command>
# Example: nvm install 18   # First call loads NVM, then runs command
nvm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}

# Description: Lazy-load wrapper for node - loads NVM on first node usage
# Usage: node <args>
# Example: node script.js   # First call loads NVM, then runs node
node() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  node "$@"
}

# Description: Lazy-load wrapper for npm - loads NVM on first npm usage
# Usage: npm <command>
# Example: npm install      # First call loads NVM, then runs npm
npm() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  npm "$@"
}

# Description: Lazy-load wrapper for npx - loads NVM on first npx usage
# Usage: npx <package>
# Example: npx cowsay hi    # First call loads NVM, then runs npx
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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
