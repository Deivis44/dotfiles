#!/bin/bash

# Función para mostrar un mensaje de información
show_info() {
    local message=$1
    echo -e "\e[1;33m$message\e[0m"
}

# Función para mostrar un mensaje de error
show_error() {
    local message=$1
    echo -e "\e[1;31m$message\e[0m"
}

# Función para preguntar si se desea instalar un paquete
ask_install() {
    local pkg=$1
    while true; do
        read -p "¿Quieres instalar $pkg? [s/n]: " yn
        case $yn in
            [Ss]* ) return 0;;  # Sí
            [Nn]* ) return 1;;  # No
            * ) echo "Por favor, responde con s/n.";;
        esac
    done
}

# Función para instalar paquetes
install_packages() {
    local errors=()
    local install_all=$1

    # Grupo 1: Herramientas de gestión de dotfiles
    local dotfiles_tools=(
        "stow"  # Utilizado para gestionar dotfiles con enlaces simbólicos
        "git"   # Sistema de control de versiones para manejar dotfiles
    )

    # Grupo 2: Utilidades básicas del sistema
    local system_utilities=(
        "curl"           # Herramienta para transferir datos con URLs
        "unzip"          # Utilidad para descomprimir archivos ZIP
        "tree"           # Visualizacion del path en la terminal
        "ranger"
        "spotify-launcher"
        "syncthing"
        "starship"       # Prompt de shell personalizable
        "zathura"        # Visor de PDF ligero
        "zathura-pdf-mupdf"  # Motor para visualizar archivos PDF en Zathura
        "telegram-desktop"  # Cliente de Telegram
        "session-desktop"   # Cliente de mensajería Session (AUR)
        "torbrowser-launcher"  # Navegador Tor
        "openvpn"        # Requerido para ProtonVPN
        "protonvpn-cli-ng"  # Cliente CLI de ProtonVPN (AUR)
        "virtualbox"        # Aplicación de VirtualBox
        "virtualbox-host-modules-arch"  # Módulos del kernel para VirtualBox
        "virtualbox-guest-iso"  # Guest Additions ISO para máquinas virtuales
        "obs-studio"     # Software para grabación y transmisión de video
    )

    # Grupo 3: Herramientas de desarrollo y Python
    local dev_tools=(
        "neovim"          # Editor de texto extensible
        "python"          # Lenguaje de programación Python
        "python-pynvim"   # Integración de Python con Neovim
        "npm"             # Gestor de paquetes para Node.js
        "python-virtualenv" # Herramienta para crear entornos virtuales de Python
        "pyright"         # LSP para Python
        "debugpy"         # Depurador para Python
        "go"              # Lenguaje de programación Go
        "base-devel"      # Herramientas de desarrollo esenciales para compilación
        "gcc"             # Compilador de C necesario para algunos plugins
    )

    # Grupo 4: Tmux y gestores de plugins
    local tmux_tools=(
        "tmux"  # Multiplexor de terminales
        "bc"  # Para el widget de velocidad de red y git en Tmux
        "jq"  # Utilidad para trabajar con JSON en la línea de comandos
        "gh"  # GitHub CLI
        "glab"  # GitLab CLI
        "playerctl"  # Controlador de reproducción multimedia
    )

    # Grupo 5: Terminal y Shell
    local terminal_shell_tools=(
        "kitty"  # Emulador de terminal
        "zsh"    # Shell
    )

    # Grupo 6: Fuentes y símbolos
    local fonts_symbols=(
        "noto-fonts"  # Fuentes Noto
        "noto-fonts-extra"  # Fuentes Noto adicionales
        "noto-fonts-emoji"  # Emojis Noto
        "ttf-nerd-fonts-symbols"  # Nerd Fonts Symbols
        "ttf-nerd-fonts-symbols-mono"  # Nerd Fonts Symbols Mono
    )

    # Instalación de paquetes en cada grupo
    for group in dotfiles_tools system_utilities dev_tools tmux_tools terminal_shell_tools fonts_symbols; do
        local packages=("${!group}")
        for pkg in "${packages[@]}"; do
            if ! pacman -Qs $pkg > /dev/null; then
                if [ "$install_all" = true ] || ask_install "$pkg"; then
                    show_info "$pkg no está instalado. Instalando $pkg..."
                    if ! sudo pacman -Syu --noconfirm $pkg; then
                        show_error "Error al instalar $pkg."
                        errors+=("$pkg: Falló la instalación.")
                    fi
                else
                    show_info "$pkg omitido por el usuario."
                fi
            else
                show_info "$pkg ya está instalado."
            fi
        done
    done

    # Instalación de Tmux Plugin Manager (tpm)
    show_info "Instalando Tmux Plugin Manager (tpm)..."
    if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
        if [ $? -ne 0 ]; then
            show_error "Error al instalar tmux plugin manager (tpm)."
            errors+=("tpm: Falló la instalación.")
        else
            show_info "Tmux Plugin Manager instalado con éxito."
        fi
    else
        show_info "Tmux Plugin Manager ya está instalado."
    fi

    # Instalación de NvChad
    show_info "Instalando NvChad..."
    if [ ! -d "$HOME/.config/nvim" ]; then
        git clone https://github.com/NvChad/starter ~/.config/nvim
        if [ $? -ne 0 ]; then
            show_error "Error al instalar NvChad."
            errors+=("NvChad: Falló la instalación.")
        else
            show_info "NvChad instalado con éxito."
        fi
    else
        show_info "NvChad ya está instalado."
    fi

    # Instalación de Starship
    show_info "Instalando Starship..."
    if ! command -v starship > /dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
        if [ $? -ne 0 ]; then
            show_error "Error al instalar Starship."
            errors+=("Starship: Falló la instalación.")
        else
            show_info "Starship instalado con éxito."
        fi
    else
        show_info "Starship ya está instalado."
    fi

    # Instalación de Oh My Zsh
    show_info "Instalando Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        if [ $? -ne 0 ]; then
            show_error "Error al instalar Oh My Zsh."
            errors+=("Oh My Zsh: Falló la instalación.")
        else
            show_info "Oh My Zsh instalado con éxito."
        fi
    else
        show_info "Oh My Zsh ya está instalado."
    fi

    # Resumen de errores
    if [ ${#errors[@]} -ne 0 ]; then
        show_error "Resumen de paquetes con errores:"
        for err in "${errors[@]}"; do
            show_error "$err"
        done
    else
        show_info "Todos los paquetes fueron instalados con éxito."
    fi

    # Instrucciones post-instalación
    show_info "Recuerda: Después de ejecutar el script de enlaces, abre tmux y usa Ctrl + Space + Shift + I para instalar los plugins descritos en el archivo tmux.conf."
}

# Preguntar si se desea instalar todo de una vez o uno por uno
read -p "¿Quieres instalar todos los paquetes de corrido? [s/n]: " install_all
if [[ $install_all =~ ^[Ss]$ ]]; then
    install_packages true
else
    install_packages false
fi

