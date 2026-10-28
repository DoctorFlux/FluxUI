param(
    [string]$ReferenceRoot = (Join-Path $PSScriptRoot '..\..\..\__AddonsForRef'),
    [string]$TextureRoot = '',
    [string]$SiegeRoot = ''
)
# Optional offline rebuild tool; never loaded by WoW. All writes stay beside it.
Add-Type -AssemblyName System.Drawing
if (!$TextureRoot) { $TextureRoot = Join-Path $ReferenceRoot 'wow-ui-textures-live' }
if (!$SiegeRoot) { $SiegeRoot = Join-Path $ReferenceRoot 'SiegeUI_CastBar-0.28\SiegeUI_CastBar' }

function Export-Tga([string]$Source, [int[]]$Region, [string]$Name, [int]$Width, [int]$Height) {
    $inputImage = [System.Drawing.Image]::FromFile($Source)
    $resultImage = New-Object System.Drawing.Bitmap $Width,$Height
    $graphics = [System.Drawing.Graphics]::FromImage($resultImage)
    try {
        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $destRect = New-Object System.Drawing.Rectangle 0,0,$Width,$Height
        $sourceRect = New-Object System.Drawing.Rectangle $Region[0],$Region[1],$Region[2],$Region[3]
        $graphics.DrawImage($inputImage, $destRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
        $data = $resultImage.LockBits($destRect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $stream = [System.IO.File]::Create((Join-Path $PSScriptRoot ($Name+'.tga')))
        try {
            $header = New-Object byte[] 18
            $header[2] = 2 # uncompressed BGRA
            $header[12] = $Width -band 255; $header[13] = $Width -shr 8
            $header[14] = $Height -band 255; $header[15] = $Height -shr 8
            $header[16] = 32; $header[17] = 40 # 8 alpha bits, top-left origin
            $stream.Write($header,0,18)
            $row = New-Object byte[] ($Width*4)
            for ($y=0; $y -lt $Height; $y++) {
                [System.Runtime.InteropServices.Marshal]::Copy([IntPtr]::Add($data.Scan0,$y*$data.Stride),$row,0,$row.Length)
                $stream.Write($row,0,$row.Length)
            }
        } finally { $stream.Dispose(); $resultImage.UnlockBits($data) }
    } finally { $graphics.Dispose(); $inputImage.Dispose(); $resultImage.Dispose() }
}

foreach ($name in @('cast_dot','cast_flame','cast_leaf','cast_snow','cast_spark')) {
    Copy-Item -LiteralPath (Join-Path $SiegeRoot ('Media\'+$name+'.tga')) -Destination (Join-Path $PSScriptRoot ($name+'.tga'))
}
$headers = @{
    magearcane='ArtifactUIMageArcane'; paladin='ArtifactUIPaladin'; frost='ArtifactUIDeathKnightFrost'
    warlock='ArtifactUIWarlock'; priestshadow='ArtifactUIPriestShadow'; priest='ArtifactUIPriest'
    druid='ArtifactUIDruid'; shaman='ArtifactUIShaman'; hunter='ArtifactUIHunter'
}
$ends = @{magearcane=736; paladin=700; frost=734; warlock=706; priestshadow=716; priest=706; druid=754; shaman=708; hunter=686}
foreach ($name in $headers.Keys) {
    Export-Tga (Join-Path $TextureRoot ('Artifacts\'+$headers[$name]+'.PNG')) @(0,618,896,($ends[$name]-618)) ('backdrop_'+$name) 512 128
}
Export-Tga (Join-Path $TextureRoot 'Artifacts\ArtifactRunes.PNG') @(158,0,80,80) 'arcane_rune' 64 64
Export-Tga (Join-Path $TextureRoot 'PLAYERFRAME\ClassOverlayDeathKnightRunes.PNG') @(6,6,20,20) 'shadow_skull' 32 32
