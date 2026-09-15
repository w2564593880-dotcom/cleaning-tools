$root='d:\cleaning-tools'
$o=Join-Path $root '.tmp_dbg\diag4.txt'
$L=New-Object System.Collections.Generic.List[string]
function W($s){ $L.Add([string]$s) }

W '### grep 2020/03/25 and L3 programming layer in repo text files'
$exts = @('.tex','.aux','.log','.toc','.lof','.lot','.out','.bbl','.blg','.sty','.cls','.bib','.json','.txt','.cfg','.def')
$files = Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $exts -contains $_.Extension.ToLower() -and $_.FullName -notmatch '\\\.tmp_dbg\\' -and $_.FullName -notmatch '\\\.git\\' }
W ('scanned_files=' + $files.Count)
foreach($f in $files){
  $hit = @(Select-String -Path $f.FullName -Pattern '2020/03/25' -SimpleMatch -ErrorAction SilentlyContinue)
  if($hit.Count -gt 0){ W ('HIT ' + $f.FullName.Substring($root.Length+1) + ' n=' + $hit.Count + ' first_line=' + $hit[0].LineNumber + ' :: ' + $hit[0].Line) }
  $hit2 = @(Select-String -Path $f.FullName -Pattern 'L3 programming layer' -SimpleMatch -ErrorAction SilentlyContinue)
  if($hit2.Count -gt 0){ W ('L3HIT ' + $f.FullName.Substring($root.Length+1) + ' n=' + $hit2.Count + ' first_line=' + $hit2[0].LineNumber + ' :: ' + $hit2[0].Line) }
}

W '### stray build artifacts in repo (outside root)'
$arts = Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(aux|log|synctex\.gz|fdb_latexmk|fls|toc|lof|lot|out|bbl|blg|nav|snm|vrb|xdv)$' -and $_.DirectoryName -ne $root }
foreach($a in ($arts | Sort-Object FullName)){ W ($a.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') + ' ' + $a.Length + ' ' + $a.FullName.Substring($root.Length+1)) }
W ('stray_artifact_count=' + $arts.Count)

W '### pdfs whose basename matches a sibling .tex (possible stray fragment builds)'
$texs = Get-ChildItem $root -Recurse -File -Filter *.tex -ErrorAction SilentlyContinue
foreach($t in $texs){
  $p = [IO.Path]::Combine($t.DirectoryName, [IO.Path]::GetFileNameWithoutExtension($t.Name) + '.pdf')
  if(Test-Path $p){ $f=Get-Item $p; W ($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') + ' ' + $f.Length + ' ' + $f.FullName.Substring($root.Length+1)) }
}

W '### xelatex resolution'
$xc = Get-Command xelatex -ErrorAction SilentlyContinue
if($xc){ W ('xelatex -> ' + $xc.Source) } else { W 'xelatex not on PATH' }
W 'PATH entries mentioning tex:'
$env:PATH.Split(';') | Where-Object { $_ -match 'texlive|miktex' } | ForEach-Object { W ('  ' + $_) }
foreach($d in @('d:\','c:\','c:\texlive','d:\texlive')){ if(Test-Path $d){ Get-ChildItem $d -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'texlive|miktex' } | ForEach-Object { W ('DIR ' + $_.FullName) } } }

W '### global vscode settings (latex-workshop / xelatex)'
$g = Join-Path $env:APPDATA 'Code\User\settings.json'
if(Test-Path $g){ W ('global_settings=' + $g); Select-String -Path $g -Pattern 'latex-workshop','xelatex' | ForEach-Object { W ($_.LineNumber.ToString() + '| ' + $_.Line) } } else { W 'no global settings' }

W '### c1/c2 log fingerprints'
foreach($p in @((Join-Path $root '.tmp_dbg\c1.log'),(Join-Path $root '.tmp_dbg\c2.log'))){
  if(Test-Path $p){
    $h=(Get-FileHash $p).Hash
    $c=Get-Content $p
    W ($p + ' hash=' + $h + ' lines=' + $c.Count)
    W '  -- head --'
    $c[0..([Math]::Min(14,$c.Count-1))] | ForEach-Object { W ('  ' + $_) }
    W '  -- tail --'
    $c[[Math]::Max(0,$c.Count-10)..($c.Count-1)] | ForEach-Object { W ('  ' + $_) }
    W ('  invalid_char_hits=' + @(Select-String -Path $p -Pattern 'invalid character' -SimpleMatch).Count)
  } else { W ($p + ' missing') }
}
Set-Content -Path $o -Value ($L -join "`r`n") -Encoding UTF8
Write-Output 'diag4 done'
