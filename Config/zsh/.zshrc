# ==========================
# Zinit Setup
# ==========================
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Check if Zinit is installed, if not, install it.
if ! command -v zinit &> /dev/null; then
  [ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
  [ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Initialize Zinit
source "$ZINIT_HOME/zinit.zsh"

# ==========================
# Plugin Management
# ==========================

# Core plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab

# Oh My Zsh Snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::command-not-found
zinit snippet OMZP::kitty
# zinit snippet OMZP::tmux
zinit snippet OMZP::zoxide

# ==========================
# Completion System
# ==========================
autoload -U compinit && compinit
zinit cdreplay -q

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf—tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ==========================
# Shell Integrations
# ==========================
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git "
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"

# fzf preview settings
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"
export FZF_TMUX_OPTS=" -p90%,70% "

# Alias for fman
alias fman="print -rl -- ${(k)commands} | fzf | xargs man"

# ==========================
# Handy Aliases
# ==========================
# Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# Directory listing with eza
alias l='eza -lh  --icons=auto' # Long list
alias ls='eza -1   --icons=auto' # Short list
# alias ls='eza -la --no-filesize --grid --color=always --icons=always --no-user'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # Long list all
alias ld='eza -lhD --icons=auto' # Long list dirs
alias lt='eza --icons=auto --tree' # Tree view

# Tree command aliases
alias tree="tree -L 3 -a -I '.git' --charset X "
alias dtree="tree -L 3 -a -d -I '.git' --charset X "

# Git aliases
alias gt="git"
alias ga="git add ."
alias gs="git status -s"
alias gc='git commit -m'
alias glog='git log --oneline --graph --all'

# Other handy aliases
alias mkdir='mkdir -p'
alias c='clear'
alias vc='code'
alias nvim='nvim'
alias kth='kitty-theme'
alias doom-zig='cd terminal-doom/ && zig-out/bin/terminal-doom'
alias fast='fastfetch'

# Clean temp stuff
alias cl_system='sudo pacman -Scc --noconfirm && yay -Sc --noconfirm && sudo rm -rf /tmp/*'
alias cl_packages='sudo pacman -Rns $(pacman -Qtdq) --noconfirm'
alias cl_clipboard='rm -rf ~/.cache/cliphist/*'

# ==========================
# Package Management
# ==========================
# Detect the AUR wrapper
if pacman -Qi yay &>/dev/null ; then
   aurhelper="yay"
elif pacman -Qi paru &>/dev/null ; then
   aurhelper="paru"
fi

# Install packages (Arch and AUR)
function in {
    local -a inPkg=("$@")
    local -a arch=()
    local -a aur=()

    for pkg in "${inPkg[@]}"; do
        if pacman -Si "${pkg}" &>/dev/null ; then
            arch+=("${pkg}")
        else 
            aur+=("${pkg}")
        fi
    done

    if [[ ${#arch[@]} -gt 0 ]]; then
        sudo pacman -S "${arch[@]}"
    fi

    if [[ ${#aur[@]} -gt 0 ]]; then
        ${aurhelper} -S "${aur[@]}"
    fi
}

alias un='$aurhelper -Rns' # Uninstall package
alias up='$aurhelper -Syu' # Update system/packages
alias pl='$aurhelper -Qs' # List installed packages
alias pa='$aurhelper -Ss' # Search for packages
alias pc='$aurhelper -Sc' # Clear cache
alias po='$aurhelper -Qtdq | $aurhelper -Rns -' # Remove unused packages

# ==========================
# History Management
# ==========================
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_find_no_dups

# ==========================
# Handle Command Not Found
# ==========================
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=( ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"} )
    if (( ${#entries[@]} )) ; then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}" ; do
            local fields=( ${(0)entry} )
            if [[ "$pkg" != "${fields[2]}" ]] ; then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            fi
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
    fi
    return 127
}

# ==========================
# Final Touches
# ==========================
# Display Pokemon
pokemon-colorscripts --no-title -r 1,3,6

export PATH=$HOME/.local/bin:$PATH
export PATH=$PATH:/home/deivi/.spicetify

