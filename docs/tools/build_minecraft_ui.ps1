# Builds local-only FluxUI textures from the player's own Minecraft Java 1.20.1 jar.
# Mojang's original texture pixels are intentionally not committed to this repository.
param(
    [string]$JarPath = (Join-Path $env:APPDATA '.minecraft\versions\1.20.1\1.20.1.jar'),
    [string]$OutputDir = (Join-Path $PSScriptRoot '..\..\Texture')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$jar = [System.IO.Compression.ZipFile]::OpenRead($JarPath)
function Read-Png([string]$entryName) {
    $entry = $jar.GetEntry($entryName)
    if (-not $entry) { throw "Missing Minecraft asset: $entryName" }
    $source = $entry.Open()
    $memory = [System.IO.MemoryStream]::new()
    try { $source.CopyTo($memory) } finally { $source.Dispose() }
    $memory.Position = 0
    $bitmap = [System.Drawing.Bitmap]::new($memory)
    return @{ Bitmap = $bitmap; Memory = $memory }
}

function Copy-Nearest($source, $target, [int]$sx, [int]$sy, [int]$sw, [int]$sh,
    [int]$dx, [int]$dy, [int]$dw, [int]$dh, [bool]$ringOnly = $false) {
    for ($y = 0; $y -lt $dh; $y++) {
        $sampleY = [Math]::Min($sh - 1, [int][Math]::Floor(($y + 0.5) * $sh / $dh))
        for ($x = 0; $x -lt $dw; $x++) {
            $sampleX = [Math]::Min($sw - 1, [int][Math]::Floor(($x + 0.5) * $sw / $dw))
            if ($ringOnly -and $sampleX -ge 2 -and $sampleX -lt ($sw - 2) -and
                $sampleY -ge 2 -and $sampleY -lt ($sh - 2)) { continue }
            $target.SetPixel($dx + $x, $dy + $y, $source.GetPixel($sx + $sampleX, $sy + $sampleY))
        }
    }
}

function Write-Tga($bitmap, [string]$path) {
    $stream = [System.IO.File]::Create($path)
    $writer = [System.IO.BinaryWriter]::new($stream)
    try {
        # Uncompressed BGRA32, top-left origin. WoW clients read TGA without PNG support.
        $writer.Write([byte[]]@(0,0,2,0,0,0,0,0,0,0,0,0))
        $writer.Write([uint16]$bitmap.Width)
        $writer.Write([uint16]$bitmap.Height)
        $writer.Write([byte]32)
        $writer.Write([byte]0x28)
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                $c = $bitmap.GetPixel($x, $y)
                $writer.Write([byte[]]@($c.B,$c.G,$c.R,$c.A))
            }
        }
    } finally {
        $writer.Dispose()
    }
}

try {
    $panel = Read-Png 'assets/minecraft/textures/gui/container/inventory.png'
    $widgets = Read-Png 'assets/minecraft/textures/gui/widgets.png'
    if ($panel.Bitmap.Width -ne 256 -or $panel.Bitmap.Height -ne 256 -or
        $widgets.Bitmap.Width -ne 256 -or $widgets.Bitmap.Height -ne 256) {
        throw 'Expected Minecraft Java 1.20.1 256x256 GUI sheets.'
    }
    $out = [System.IO.Path]::GetFullPath($OutputDir)
    [System.IO.Directory]::CreateDirectory($out) | Out-Null

    # Destination rectangles exactly match FluxBorder.LEGACY_COORDS on its 256x256 atlas.
    # Source rectangles are the unmodified outer bevel of inventory.png.
    $atlas = [System.Drawing.Bitmap]::new(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    Copy-Nearest $panel.Bitmap $atlas 0 0 7 7 211 1 16 17
    Copy-Nearest $panel.Bitmap $atlas 169 0 7 7 229 1 16 17
    Copy-Nearest $panel.Bitmap $atlas 0 159 7 7 211 20 16 16
    Copy-Nearest $panel.Bitmap $atlas 169 159 7 7 229 20 16 16
    Copy-Nearest $panel.Bitmap $atlas 20 0 136 7 1 1 208 17
    Copy-Nearest $panel.Bitmap $atlas 20 159 136 7 1 20 208 16
    Copy-Nearest $panel.Bitmap $atlas 0 20 7 126 1 38 16 134
    Copy-Nearest $panel.Bitmap $atlas 169 20 7 126 19 38 16 134
    Write-Tga $atlas (Join-Path $out 'MinecraftFluxBorder.tga')

    # Vanilla inventory slot (7,7)-(24,24); transparent center preserves WoW icons.
    $slot = [System.Drawing.Bitmap]::new(32, 32, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    Copy-Nearest $panel.Bitmap $slot 7 7 18 18 0 0 32 32 $true
    Write-Tga $slot (Join-Path $out 'MinecraftFluxSlot.tga')
    $slotFill = [System.Drawing.Bitmap]::new(32, 32, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    Copy-Nearest $panel.Bitmap $slotFill 7 7 18 18 0 0 32 32
    Write-Tga $slotFill (Join-Path $out 'MinecraftFluxSlotFill.tga')

    # Vanilla widgets.png normal button at (0,66), 200x20; transparent padding to 256x32.
    $button = [System.Drawing.Bitmap]::new(256, 32, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    Copy-Nearest $widgets.Bitmap $button 0 66 200 20 0 0 200 20
    Write-Tga $button (Join-Path $out 'MinecraftFluxButton.tga')
    $buttonHover = [System.Drawing.Bitmap]::new(256, 32, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    Copy-Nearest $widgets.Bitmap $buttonHover 0 86 200 20 0 0 200 20
    Write-Tga $buttonHover (Join-Path $out 'MinecraftFluxButtonHover.tga')
    Write-Output "Source jar: $JarPath"
    Get-FileHash -LiteralPath $JarPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    foreach ($name in 'MinecraftFluxBorder.tga','MinecraftFluxSlot.tga','MinecraftFluxSlotFill.tga','MinecraftFluxButton.tga','MinecraftFluxButtonHover.tga') {
        $path = Join-Path $out $name
        Write-Output "$name $((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash)"
    }
} finally {
    if ($atlas) { $atlas.Dispose() }
    if ($slot) { $slot.Dispose() }
    if ($slotFill) { $slotFill.Dispose() }
    if ($button) { $button.Dispose() }
    if ($buttonHover) { $buttonHover.Dispose() }
    if ($panel) { $panel.Bitmap.Dispose(); $panel.Memory.Dispose() }
    if ($widgets) { $widgets.Bitmap.Dispose(); $widgets.Memory.Dispose() }
    $jar.Dispose()
}
