# ─────────────────────────────────────────────────────────────────────────────
# SMAClite value 벤치마크 — 노트북용 (Windows / GPU 3050 Ti)
#   IQL + VDN + QMIX × SMAClite-MMM × seed 1..5 = 15 run
#   (RWARE value 15런은 맥북에서 완료됨. SMAClite는 맥 CPU-only가 너무 느려 노트북으로 이관.)
#   하이퍼파라미터: docs/benchmark_match_config.md (Papoudakis 2021 매칭) — SMAClite=GRU/128.
#
# 사용(백그라운드 권장, 세션 종료에도 살아남게 detached):
#   Start-Process powershell -ArgumentList "-NoProfile -File scripts\run_value_laptop.ps1" -WindowStyle Hidden
# 스모크(1런·2만스텝·W&B off):  $env:SMOKE="1"; $env:SEEDS="1"; powershell -NoProfile -File scripts\run_value_laptop.ps1
# override:  $env:MAX_PARALLEL="2"; $env:SEEDS="1 2 3"
# ─────────────────────────────────────────────────────────────────────────────
$ErrorActionPreference = "Stop"

$REPO = "C:\Users\user\Desktop\MARL\epymarl"
$PY   = "C:\Users\user\miniconda3\envs\marl\python.exe"
$env:PYTHONUTF8 = "1"   # Windows cp949 크래시 방지

$MAX = 3
if ($env:MAX_PARALLEL) { $MAX = [int]$env:MAX_PARALLEL }
$SEEDS = @("1","2","3","4","5")
if ($env:SEEDS) { $SEEDS = $env:SEEDS -split '\s+' }
$SMOKE = ($env:SMOKE -eq "1")

$DATE   = "2026_06_25"
$TMAX   = "4000000"
$WANDB  = "use_wandb=True wandb_mode=online wandb_project=marl-bench wandb_team=launcher1423-"
if ($SMOKE) {
  $TMAX  = "20000"
  $WANDB = "use_wandb=False"
}
$LOGDIR = "C:\Users\user\Desktop\MARL\logs\value_smaclite_$DATE"
New-Item -ItemType Directory -Force -Path $LOGDIR | Out-Null

$COMMON = "use_cuda=True common_reward=True save_model=True save_best_model=True $WANDB"
$ENVC   = "--env-config=smaclite with env_args.map_name=MMM"

# SMAClite 열(매칭): hidden=128, use_rnn=True(GRU), eval_eps=0.05, anneal=50000, target=200(hard)
# std: IQL=False / VDN·QMIX=True (benchmark_match_config.md)
$CFGS = @("iql","vdn","qmix")
$STD  = @{ iql="False"; vdn="True"; qmix="True" }

Write-Output "총 $($CFGS.Count * $SEEDS.Count)런 | 동시 $MAX | SMOKE=$SMOKE | t_max=$TMAX | 로그: $LOGDIR"

$running = @()
foreach ($cfg in $CFGS) {
  foreach ($s in $SEEDS) {
    while ((@($running | Where-Object { -not $_.HasExited })).Count -ge $MAX) {
      Start-Sleep -Seconds 30
    }
    $running = @($running | Where-Object { -not $_.HasExited })

    $name = $cfg + "_smaclite_seed" + $s + "_" + $DATE
    $env:WANDB_NAME = $name
    $HP = "t_max=$TMAX hidden_dim=128 lr=0.0005 standardise_rewards=" + $STD[$cfg] + " use_rnn=True evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=200"
    $argline = "src/main.py --config=$cfg $ENVC seed=$s $HP $COMMON"
    $outlog = Join-Path $LOGDIR ($name + ".log")
    $errlog = Join-Path $LOGDIR ($name + ".err")

    $p = Start-Process -FilePath $PY -ArgumentList $argline -WorkingDirectory $REPO -RedirectStandardOutput $outlog -RedirectStandardError $errlog -NoNewWindow -PassThru
    $running += $p
    Write-Output ("[" + (Get-Date -Format HH:mm:ss) + "] launch " + $name + " (pid " + $p.Id + ")")
    Start-Sleep -Seconds 5
  }
}
$running | ForEach-Object { $_.WaitForExit() }
Write-Output ("[" + (Get-Date -Format HH:mm:ss) + "] 전체 완료. 집계: python scripts/aggregate_seeds.py --reduce peak --envs smaclite")
