#!/bin/bash

# Demo de Múltiples Instancias de Warp Terminal
# Muestra cómo usar las nuevas características

set -e

echo "🚀 Demo de Múltiples Instancias de Warp Terminal"
echo "================================================="
echo

echo "1. Mostrando ayuda del nuevo sistema:"
./warp.sh --help
echo

read -p "Presiona Enter para continuar..."
echo

echo "2. Verificando instancias activas (debería estar vacío):"
./warp.sh list
echo

read -p "Presiona Enter para continuar..."
echo

echo "3. Para abrir múltiples instancias, puedes usar:"
echo "   ./warp.sh          # Primera instancia"
echo "   ./warp.sh &        # Segunda instancia en background"
echo "   ./warp.sh &        # Tercera instancia en background"
echo

echo "4. Para gestionar las instancias:"
echo "   ./warp.sh list     # Ver todas las instancias"
echo "   ./warp.sh kill-all # Cerrar todas"
echo "   ./warp.sh kill <ID> # Cerrar una específica"
echo

echo "5. ¿Quieres probar abriendo una instancia? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Ejecutando: ./warp.sh"
    echo "Nota: Esto abrirá Warp Terminal. Ciérralo para continuar."
    ./warp.sh
fi

echo
echo "¡Demo completado! 🎉"
echo "Ahora puedes usar ./warp.sh para abrir múltiples instancias de Warp Terminal."
