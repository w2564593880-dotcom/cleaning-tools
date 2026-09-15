$root = 'd:\cleaning-tools'
$out  = Join-Path $root '.tmp_dbg\diag2.txt'
$L = New-Object System.Collections.Generic.List[string]
function W($s){ $L.Add([string]$s) }

# --- 1. main.aux bytes
$aux = Join-Path $root 'main.aux'
if (Test-Path $aux) {
  $fi = Get-Item $aux
  W ("aux_len_bytes=" + $fi.Length + " mtime=" + $fi.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))
  $b = [IO.File]::ReadAllBytes($aux)
  $nl = New-Object System.Collections.Generic.List[int]
  for($i=0;$i -lt $b.Length;$i++){ if($b[$i] -eq 10){ $nl.Add($i) } }
  W ("aux_line_count=" + ($nl.Count+1))
  $s = 0; if($nl.Count -ge 72){ $s = $nl[71]+1 }
  $e = $b.Length-1; if($nl.Count -ge 73){ $e = $nl[72]-1 }
  if($e -ge $s){
    $seg = $b[$s..$e]
    W ("line73_start=$s line73_len=" + $seg.Length)
    $sb = New-Object System.Text.StringBuilder
    $nHi = 0; $nCtl = 0
    $lim = [Math]::Min($seg.Length, 1500)
    for($i=0;$i -lt $lim;$i++){
      $c = $seg[$i]
      if($c -eq 32){ [void]$sb.Append('.') }
      elseif($c -ge 33 -and $c -le 126){ [void]$sb.Append([char]$c) }
      elseif($c -ge 128){ [void]$sb.Append('{H' + $c.ToString('x2') + '}'); $nHi++ }
      else { [void]$sb.Append('{C' + $c.ToString('x2') + '}'); $nCtl++ }
    }
    W ("line73_hi_bytes=$nHi line73_ctl_bytes=$nCtl")
    W ("line73_map=" + $sb.ToString())
  }
  $ctl = New-Object System.Collections.Generic.List[string]
  for($i=0;$i -lt $b.Length;$i++){ $c=$b[$i]; if(($c -lt 9) -or (($c -gt 13) -and ($c -lt 32)) -or ($c -eq 127)){ $ctl.Add("${i}:" + $c.ToString('x2')) } }
  W ("aux_bad_byte_count=" + $ctl.Count)
  if($ctl.Count -gt 0){ W ("aux_bad_bytes_first20=" + (($ctl | Select-Object -First 20) -join ' ')) }
} else { W "aux_missing" }

# --- 2. log grep
$log = Join-Path $root 'main.log'
if (Test-Path $log) {
  $li = Get-Item $log
  W ("log_len_bytes=" + $li.Length + " mtime=" + $li.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))
  $hits = Select-String -Path $log -Pattern 'invalid character' -SimpleMatch
  W ("log_invalid_character_hits=" + @($hits).Count)
  foreach($h in (@($hits) | Select-Object -First 3)){ W ("hit_line=" + $h.LineNumber + " text=" + $h.Line) }
  W "---- log_tail_start ----"
  foreach($t in (Get-Content $log -Tail 25)){ W $t }
  W "---- log_tail_end ----"
} else { W "log_missing" }

# --- 3. running processes
W "---- processes ----"
Get-Process | Where-Object { $_.ProcessName -match 'pdflatex|xelatex|lualatex|latexmk|bibtex|perl' } | ForEach-Object { W ($_.Id.ToString() + ' ' + $_.ProcessName + ' start=' + $_.StartTime.ToString('HH:mm:ss')) }

# --- 4. tmp_dbg listing + c3
W "---- tmp_dbg ----"
Get-ChildItem (Join-Path $root '.tmp_dbg') | Sort-Object LastWriteTime | ForEach-Object { W ($_.Name + ' len=' + $_.Length + ' mtime=' + $_.LastWriteTime.ToString('HH:mm:ss')) }
$c3 = Join-Path $root '.tmp_dbg\c3.txt'
if (Test-Path $c3) { W ("c3_exists=1 content=" + ((Get-Content $c3) -join ' | ')) } else { W "c3_exists=0" }

# --- 5. artifact timestamps
W "---- artifacts ----"
foreach($n in @('main.aux','main.log','main.pdf','main.toc','main.out','main.fls','main.fdb_latexmk')){
  $p = Join-Path $root $n
  if(Test-Path $p){ $f=Get-Item $p; W ($n + ' len=' + $f.Length + ' mtime=' + $f.LastWriteTime.ToString('HH:mm:ss')) } else { W ($n + ' missing') }
}

Set-Content -Path $out -Value ($L -join "`r`n") -Encoding UTF8
Write-Output ("diag2 done -> " + $out)
