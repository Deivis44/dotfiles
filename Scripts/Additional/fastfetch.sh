#!/bin/bash

# Ruta de la carpeta de configuraciones personalizadas (ajustada para que sea dinámica y utilice "fastfetch_themes")
CONFIG_DIR="$HOME/dotfiles/Scripts/Additional/fastfetch_themes"

# Ruta de la configuración de Fastfetch en .config
FASTFETCH_CONFIG_DIR="$HOME/.config/fastfetch"
FASTFETCH_CONFIG_FILE="$FASTFETCH_CONFIG_DIR/config.jsonc"

# Verificar si la carpeta de configuraciones personalizadas existe
if [ ! -d "$CONFIG_DIR" ]; then
    echo "La carpeta de temas personalizados no existe: $CONFIG_DIR"
    exit 1
fi

# Crear la carpeta de configuración de Fastfetch si no existe
if [ ! -d "$FASTFETCH_CONFIG_DIR" ]; then
    echo "Creando la carpeta de configuración de Fastfetch en $FASTFETCH_CONFIG_DIR"
    mkdir -p "$FASTFETCH_CONFIG_DIR"
fi

# Generar el archivo de configuración predeterminado si no existe
if [ ! -f "$FASTFETCH_CONFIG_FILE" ]; then
    echo "Generando archivo de configuración predeterminado de Fastfetch"
    fastfetch --gen-config
fi

# Listar los temas disponibles en la carpeta de configuraciones personalizadas
echo "Temas disponibles:"
themes=("$CONFIG_DIR"/*.jsonc)
for i in "${!themes[@]}"; do
    theme_name=$(basename "${themes[$i]}")
    echo "$((i + 1)). $theme_name"
done

# Solicitar al usuario que seleccione un tema
read -p "Seleccione el número del tema que desea aplicar: " selection

# Validar la selección del usuario
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#themes[@]}" ]; then
    echo "Selección inválida. Por favor, ingrese un número entre 1 y ${#themes[@]}."
    exit 1
fi

# Copiar el tema seleccionado a la configuración de Fastfetch
selected_theme="${themes[$((selection - 1))]}"
echo "Aplicando el tema: $(basename "$selected_theme")"
cp "$selected_theme" "$FASTFETCH_CONFIG_FILE"

echo "Tema aplicado con éxito."

