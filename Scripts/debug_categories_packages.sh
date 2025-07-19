#!/bin/bash

# Script para depurar la lista de categorías y paquetes
readonly PACKAGES_JSON="/home/deivi/dotfiles-dev/Scripts/packages.json"

if [[ ! -f "$PACKAGES_JSON" ]]; then
    echo "Error: Archivo packages.json no encontrado en $PACKAGES_JSON"
    exit 1
fi

# Verificar si jq puede procesar el archivo
if ! jq empty "$PACKAGES_JSON" 2>/dev/null; then
    echo "Error: El archivo packages.json no es válido"
    exit 1
fi

# Generar lista de categorías y paquetes
categories=$(jq -c '.categories[] | {id: .id, packages: [.packages[] | {name: .name, repo: .repo, optional: .optional}]}' "$PACKAGES_JSON")

if [[ -z "$categories" ]]; then
    echo "Error: No se pudieron generar las categorías y paquetes desde el JSON"
    exit 1
fi

# Mostrar la lista generada
echo "Lista de categorías y paquetes generada correctamente:"
echo "$categories" | jq '.'

exit 0
