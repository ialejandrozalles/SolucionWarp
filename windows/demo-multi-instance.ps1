#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Demo de Múltiples Instancias de Warp Terminal para Windows

.DESCRIPTION
    Muestra cómo usar las características de múltiples instancias
#>

Write-Host ""
Write-Host "🚀 Demo de Múltiples Instancias de Warp Terminal" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Mostrando ayuda del sistema:" -ForegroundColor Yellow
.\warp.ps1 help
Write-Host ""

Read-Host "Presiona Enter para continuar..."
Write-Host ""

Write-Host "2. Verificando instancias activas (debería estar vacío):" -ForegroundColor Yellow
.\warp.ps1 list
Write-Host ""

Read-Host "Presiona Enter para continuar..."
Write-Host ""

Write-Host "3. Para abrir múltiples instancias, puedes usar:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   .\warp.ps1                                    # Primera instancia"
Write-Host "   Start-Process pwsh -ArgumentList ""-NoExit"", ""-File"", "".\warp.ps1""  # Segunda instancia"
Write-Host "   Start-Process pwsh -ArgumentList ""-NoExit"", ""-File"", "".\warp.ps1""  # Tercera instancia"
Write-Host ""

Write-Host "4. Para gestionar las instancias:" -ForegroundColor Yellow
Write-Host "   .\warp.ps1 list       # Ver todas las instancias"
Write-Host "   .\warp.ps1 kill-all   # Cerrar todas"
Write-Host "   .\warp.ps1 kill <ID>  # Cerrar una específica"
Write-Host ""

$response = Read-Host "5. ¿Quieres probar abriendo una instancia? (s/n)"
if ($response -match '^[sS]') {
    Write-Host ""
    Write-Host "Ejecutando: .\warp.ps1" -ForegroundColor Green
    Write-Host "Nota: Esto abrirá Warp Terminal. Ciérralo para continuar." -ForegroundColor Yellow
    Write-Host ""
    .\warp.ps1
}

Write-Host ""
Write-Host "¡Demo completado! 🎉" -ForegroundColor Green
Write-Host "Ahora puedes usar .\warp.ps1 para abrir múltiples instancias de Warp Terminal." -ForegroundColor Cyan
Write-Host ""
