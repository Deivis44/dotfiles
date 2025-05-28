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
# Zsh Basic Options
# ==========================
setopt autocd                # cd automático al escribir nombre de directorio
setopt interactivecomments   # permite usar comentarios con # en la línea de comandos
setopt magicequalsubst       # expande rutas en argumentos como var=~/carpeta
setopt nonomatch             # no lanza error si un glob no tiene coincidencias
setopt numericglobsort       # ordena numéricamente: 1 2 10 20 en lugar de 1 10 2 20
setopt promptsubst           # permite usar $(...) en PROMPT
# setopt correct             # (opcional) autocorrección de comandos mal escritos
setopt notify              # (opcional) muestra cuándo termina un job en background


# ==========================
# Environment Variables
# ==========================
export EDITOR=nvim              # Editor por defecto para consola
export VISUAL=nvim              # Editor visual (para visudo, git, etc)
export SUDO_EDITOR=nvim         # Editor cuando usas sudoedit o visudo
export FCEDIT=nvim              # Editor para 'fc' y otros
export TERMINAL=kitty           # Terminal por defecto
export BROWSER=zen.desktop      # Navegador por defecto


# ==========================
# Plugin Management
# ==========================

# Core plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab

# Oh My Zsh Snippets
zinit snippet OMZP::git # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git
zinit snippet OMZP::sudo # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/sudo
zinit snippet OMZP::archlinux # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/archlinux
zinit snippet OMZP::command-not-found # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/command-not-found
zinit snippet OMZP::kitty # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/kitty
# zinit snippet OMZP::tmux
zinit snippet OMZP::zoxide # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/zoxide
#zinit snippet OMZP::web-search
zinit snippet OMZP::python

# Define clipcopy como función global (para plugins)
function clipcopy() {
  command wl-copy "$@"
}

zinit snippet OMZP::copybuffer
zinit snippet OMZP::vi-mode


# ==========================
# vi-mode configuration
# ==========================
# Indicadores visuales de modo (usados en el prompt)
export VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
export VI_MODE_SET_CURSOR=true

# Personalización del cursor según el modo
export VI_MODE_CURSOR_NORMAL=2     # Bloque sólido
export VI_MODE_CURSOR_INSERT=6     # Línea sólida
export VI_MODE_CURSOR_VISUAL=6     # Línea sólida
export VI_MODE_CURSOR_OPPEND=0     # Bloque parpadeante

# Indicadores en el prompt
export MODE_INDICATOR="%F{red}<<<%f"          # Modo normal
export INSERT_MODE_INDICATOR="%F{green}>>>%f" # Modo inserción

# Timeout para teclas como `vv`
export KEYTIMEOUT=20

# Mostrar indicador en el prompt izquierdo
PROMPT="$PROMPT\$(vi_mode_prompt_info)"

# Alternativa: indicador en el prompt derecho
# RPROMPT="\$(vi_mode_prompt_info)$RPROMPT"


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

# ==========================
# FZF Configuration
# ==========================

# Comando base para FZF (archivos ocultos, sin .git)
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Estilo visual de FZF
export FZF_DEFAULT_OPTS="--height 50% --layout=default --border --color=hl:#2dd4bf"

# Preview interactivo para archivos y carpetas
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"
export FZF_TMUX_OPTS="-p90%,70%"

# ==========================
# FZF Keybinding Overrides
# ==========================
# Reasignación de atajos:
# Ctrl+F → buscar archivos (antes: Ctrl+T)
# Alt+D  → navegar directorios (antes: Alt+C)
bindkey '^F' fzf-file-widget   # Ctrl+F
bindkey '^[d' fzf-cd-widget    # Alt+D


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

# lazygit
alias lg="lazygit"

# Other handy aliases
alias mkdir='mkdir -p'
alias c='clear'
alias q='exit'
alias vc='code'
alias nvim='nvim'
alias kth='kitty-theme'
alias doom-zig='cd terminal-doom/ && zig-out/bin/terminal-doom'
alias fast='fastfetch'
alias synct='systemctl --user start syncthing.service'
alias uptgrub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

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
#export PATH=$PATH:/home/deivi/.spicetify

# ==========================
# SSH Agent Setup (robusto)
# ==========================
if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi


