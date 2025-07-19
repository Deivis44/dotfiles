#!/bin/bash

PACKAGES_YAML="./packages.yaml"

echo "🔍 Probando lectura de categorías con yq..."
echo

echo "Categorías disponibles:"
yq '.categories[] | .id + " - " + .description' "$PACKAGES_YAML"

echo
echo "Primer paquete de cada categoría:"
yq '.categories[] | .id as $cat | .packages[0].name as $pkg | "\($cat): \($pkg)"' "$PACKAGES_YAML"

echo
echo "Conteo total de paquetes:"
yq '[.categories[].packages | length] | add' "$PACKAGES_YAML"

echo
echo "Paquetes obligatorios:"
yq '[.categories[].packages[] | select(.optional == false or .optional == null)] | length' "$PACKAGES_YAML"

echo
echo "Paquetes opcionales:"
yq '[.categories[].packages[] | select(.optional == true)] | length' "$PACKAGES_YAML"
