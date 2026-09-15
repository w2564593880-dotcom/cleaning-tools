# Add "% !TeX root = <rel>main.tex" magic comment to fragment .tex files (all except main.tex)
# Preserves: UTF-8 without BOM, CRLF line endings
$base = (Get-Location).Path
$enc = New-Object System.Text.UTF8Encoding($false)
$report = @()

$files = Get-ChildItem -Recurse -File -Include '*.tex' | Where-Object { $_.Name -ne 'main.tex' }
foreach ($f in $files) {
    $rel = $f.FullName.Substring($base.Length + 1)
    $segs = $rel.Split('\')
    $depth = $segs.Length - 1
    if ($depth -lt 1) { $report += "SKIP (root dir) : $rel"; continue }
    $up = ('../' * $depth)
    $magic = "% !TeX root = " + $up + "main.tex"

    $txt = [System.IO.File]::ReadAllText($f.FullName)
    if ($txt -match '!TeX\s+root') { $report += "SKIP (has magic): $rel"; continue }

    $firstLine = ($txt -split "`r`n", 2)[0]
    if ($firstLine -ne $magic) {
        $new = $magic + "`r`n" + $txt
        [System.IO.File]::WriteAllText($f.FullName, $new, $enc)
        $report += "ADDED : $rel  ->  $magic"
    }
    else {
        $report += "OK(already) : $rel"
    }
}
$report | Set-Content (Join-Path $base '.tmp_dbg\addroot_out.txt') -Encoding UTF8
