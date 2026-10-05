#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Off-policy(value) 벤치마크 30개 일괄 실행 — 맥북용 베이스 템플릿
#   IQL + VDN + QMIX × {SMAClite-MMM, RWARE-tiny-2ag} × seed 1..5  = 30 run
#   하이퍼파라미터: docs/benchmark_match_config.md (Papoudakis 2021 매칭) 그대로.
#
# ⚠️ 이 파일은 "베이스"입니다. 맥북 Claude Code가 아래 [수정 필요] 항목을
#    그 맥북 사양에 맞춰 고치세요:
#    1) REPO / PY 경로  (맥 conda 환경 경로로)
#    2) MAX_PARALLEL    (코어수·발열 기준. 코어수: sysctl -n hw.ncpu)
#                        - MacBook Pro(팬O): 코어수의 절반~2/3 권장 (예: 8코어→4)
#                        - MacBook Air(팬X, 발열 심함): 2~3으로 낮추기
#    3) 맥은 CUDA 없음 → use_cuda=False (이미 반영됨). MPS는 EPyMARL 미지원 → CPU 사용.
#    4) 맥은 기본 UTF-8 → PYTHONUTF8 불필요(있어도 무해).
#
# 사용:  bash scripts/run_value_mac.sh
#   또는 nohup bash scripts/run_value_mac.sh >/dev/null 2>&1 &   (장시간이라 권장)
# override: MAX_PARALLEL=3 SEEDS="1 2 3" bash scripts/run_value_mac.sh
# ─────────────────────────────────────────────────────────────────────────────
set -u

# ── [수정 필요 1] 경로 ───────────────────────────────────────────────────────
REPO="$HOME/MARL-bench"                       # repo clone 위치
PY="$HOME/miniconda3/envs/marl/bin/python"    # marl 환경 python (맥 경로로)
cd "$REPO/epymarl" || { echo "epymarl 디렉터리 없음: $REPO/epymarl"; exit 1; }

export PYTHONUTF8=1   # 맥에선 무해

# ── [수정 필요 2] 동시 실행 개수 ──────────────────────────────────────────────
# value run은 각 CPU 1코어+α (episode runner). GPU 거의 안 씀 → CPU 코어가 제한.
# 맥 코어수 확인: sysctl -n hw.ncpu   (Pro면 절반~2/3, Air면 2~3)
MAX_PARALLEL="${MAX_PARALLEL:-4}"
SEEDS="${SEEDS:-1 2 3 4 5}"

STAMP=$(date +%Y%m%d_%H%M%S)
LOGDIR="$REPO/logs/value_$STAMP"
mkdir -p "$LOGDIR"

# 5시드를 W&B 한 그룹으로 묶으려면 seed 외 모든 플래그가 동일해야 함(그룹 해시는 seed만 제외).
COMMON="use_cuda=False common_reward=True save_model=True save_best_model=True use_wandb=True wandb_mode=online wandb_project=marl-bench wandb_team=launcher1423-"

declare -A CFG ENVC HP

# ── SMAClite (MMM) = 논문 SMAC 열 : use_rnn=True(GRU), hidden=128, target=200(hard) ──
CFG[iql_smaclite]=iql;   ENVC[iql_smaclite]="--env-config=smaclite with env_args.map_name=MMM"
HP[iql_smaclite]="t_max=4000000 hidden_dim=128 lr=0.0005 standardise_rewards=False use_rnn=True evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=200"

CFG[vdn_smaclite]=vdn;   ENVC[vdn_smaclite]="--env-config=smaclite with env_args.map_name=MMM"
HP[vdn_smaclite]="t_max=4000000 hidden_dim=128 lr=0.0005 standardise_rewards=True use_rnn=True evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=200"

CFG[qmix_smaclite]=qmix; ENVC[qmix_smaclite]="--env-config=smaclite with env_args.map_name=MMM"
HP[qmix_smaclite]="t_max=4000000 hidden_dim=128 lr=0.0005 standardise_rewards=True use_rnn=True evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=200"

# ── RWARE (tiny-2ag) = 논문 RWARE 열 : use_rnn=False(FC), hidden=64, target=0.01(soft) ──
CFG[iql_rware]=iql;   ENVC[iql_rware]="--env-config=gymma with env_args.time_limit=500 env_args.key=rware:rware-tiny-2ag-v2"
HP[iql_rware]="t_max=4000000 hidden_dim=64 lr=0.0005 standardise_rewards=True use_rnn=False evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=0.01"

CFG[vdn_rware]=vdn;   ENVC[vdn_rware]="--env-config=gymma with env_args.time_limit=500 env_args.key=rware:rware-tiny-2ag-v2"
HP[vdn_rware]="t_max=4000000 hidden_dim=64 lr=0.0005 standardise_rewards=True use_rnn=False evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=0.01"

CFG[qmix_rware]=qmix; ENVC[qmix_rware]="--env-config=gymma with env_args.time_limit=500 env_args.key=rware:rware-tiny-2ag-v2"
HP[qmix_rware]="t_max=4000000 hidden_dim=64 lr=0.0005 standardise_rewards=True use_rnn=False evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=0.01"

# RWARE(가벼움)를 먼저 → 빨리 결과 확보. SMAClite(무거움) 나중.
JOBS=(iql_rware vdn_rware qmix_rware iql_smaclite vdn_smaclite qmix_smaclite)

TOTAL=$(( ${#JOBS[@]} * $(echo $SEEDS | wc -w) ))
echo "총 ${TOTAL}개 | 동시 ${MAX_PARALLEL}개 | 로그: $LOGDIR"
echo "모니터: tail -f $LOGDIR/<name>.log    중단: pkill -f 'src/main.py'"
echo "─────────────────────────────────────────────"

launch () {
  local key="$1" seed="$2"
  local name="${key}_seed${seed}"
  echo "[$(date +%H:%M:%S)] launch $name"
  WANDB_NAME="$name" $PY src/main.py --config=${CFG[$key]} ${ENVC[$key]} \
    seed=$seed ${HP[$key]} $COMMON > "$LOGDIR/${name}.log" 2>&1 &
}

# ★ 동시 실행 게이트: 실행 중 job이 MAX_PARALLEL 이상이면 하나 끝날 때까지 대기.
#   (전체 30개를 그룹 배리어 없이 MAX_PARALLEL개씩 흘려보냄 → 대기손실 최소)
for key in "${JOBS[@]}"; do
  for s in $SEEDS; do
    while (( $(jobs -rp | wc -l) >= MAX_PARALLEL )); do wait -n; done
    launch "$key" "$s"
  done
done
wait
echo "[$(date +%H:%M:%S)] 전체 ${TOTAL}개 완료. 집계: python scripts/aggregate_seeds.py --reduce peak"
