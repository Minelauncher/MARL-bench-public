#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# On-policy 벤치마크 20개 일괄 실행 (MAPPO + COMA × {SMAClite-MMM, RWARE-tiny-2ag} × seed 1..5)
# 하이퍼파라미터: docs/benchmark_match_config.md (Papoudakis 2021 매칭) 그대로.
# 이 PC(i7-13700F 24스레드 / RTX 3060 8GB) 기준 동시 2개 = parallel runner(batch_size_run=10)
# 의 env 워커 20개로 CPU 거의 포화 = 스위트스폿. 더 늘려도 총 처리량은 안 늘고 RAM만 압박.
#
# 사용:  tmux new -s onp                       # 세션 안에서 돌리길 권장(주 단위 실행)
#        bash scripts/run_onpolicy_20.sh
#   또는 nohup bash scripts/run_onpolicy_20.sh >/dev/null 2>&1 &
#
# 동시성 = 그룹당 시드 수. 줄이려면 SEEDS override:  SEEDS="1 2 3" bash scripts/run_onpolicy_20.sh
# ─────────────────────────────────────────────────────────────────────────────
set -u

REPO=/home/link/MARL-bench
PY=/home/link/miniconda3/envs/marl/bin/python
cd "$REPO/epymarl" || { echo "epymarl 디렉터리 없음"; exit 1; }

export PYTHONUTF8=1   # 리눅스에선 무해, 윈도우 cp949 방지용으로 문서와 통일

SEEDS="${SEEDS:-1 2 3 4 5}"   # 그룹당 동시 실행되는 시드 = 사실상 동시성 손잡이

STAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y_%m_%d)          # run naming 규칙: {algo}_{env}_seed{N}_{YYYY}_{MM}_{DD}
LOGDIR="$REPO/logs/onpolicy_$STAMP"
mkdir -p "$LOGDIR"

# 5시드를 W&B 한 그룹으로 묶으려면 seed 외 모든 플래그가 동일해야 함(그룹 해시가 seed만 제외).
COMMON="use_cuda=True common_reward=True save_model=True save_best_model=True use_wandb=True wandb_mode=online wandb_project=marl-bench wandb_team=launcher1423-"

declare -A CFG ENVC HP

# ── SMAClite (MMM) = 논문 SMAC 열 ──
CFG[coma_smaclite]=coma
ENVC[coma_smaclite]="--env-config=smaclite with env_args.map_name=MMM"
HP[coma_smaclite]="t_max=40000000 hidden_dim=128 lr=0.0005 standardise_rewards=True use_rnn=False entropy_coef=0.01 q_nstep=5 target_update_interval_or_tau=0.01"

CFG[mappo_smaclite]=mappo
ENVC[mappo_smaclite]="--env-config=smaclite with env_args.map_name=MMM"
HP[mappo_smaclite]="t_max=40000000 hidden_dim=64 lr=0.0005 standardise_rewards=False use_rnn=True entropy_coef=0.001 q_nstep=10 target_update_interval_or_tau=0.01"

# ── RWARE (tiny-2ag) = 논문 RWARE 열 (둘 다 FC) ──
CFG[coma_rware]=coma
ENVC[coma_rware]="--env-config=gymma with env_args.time_limit=500 env_args.key=rware:rware-tiny-2ag-v2"
HP[coma_rware]="t_max=40000000 hidden_dim=64 lr=0.0005 standardise_rewards=True use_rnn=False entropy_coef=0.01 q_nstep=5 target_update_interval_or_tau=0.01"

CFG[mappo_rware]=mappo
ENVC[mappo_rware]="--env-config=gymma with env_args.time_limit=500 env_args.key=rware:rware-tiny-2ag-v2"
HP[mappo_rware]="t_max=40000000 hidden_dim=128 lr=0.0005 standardise_rewards=False use_rnn=False entropy_coef=0.001 q_nstep=10 target_update_interval_or_tau=0.01"

JOBS=(coma_smaclite mappo_smaclite coma_rware mappo_rware)

echo "총 $(( ${#JOBS[@]} * $(echo $SEEDS | wc -w) ))개 | 그룹당 시드 동시 실행 | 로그: $LOGDIR"
echo "모니터:  tail -f $LOGDIR/<name>.log"
echo "중단:    pkill -f 'src/main.py'   (또는 이 스크립트 PID에 kill)"
echo "─────────────────────────────────────────────"

launch () {
  local key="$1" seed="$2"
  # key=algo_env (예: coma_smaclite) → {algo}_{env}_seed{N}_{YYYY}_{MM}_{DD}
  local name="${key}_seed${seed}_${DATE}"
  echo "[$(date +%H:%M:%S)] launch $name"
  WANDB_NAME="$name" $PY src/main.py --config=${CFG[$key]} ${ENVC[$key]} \
    seed=$seed ${HP[$key]} $COMMON > "$LOGDIR/${name}.log" 2>&1 &
}

# 그룹(알고리즘×환경) 단위로 5시드를 한꺼번에 띄우고, 그룹이 다 끝나면 다음 그룹.
# → W&B에서 한 그룹(5시드)이 통째로 같이 완주. 같은 그룹은 seed만 다르니 런타임도 비슷해 대기 손실 적음.
for key in "${JOBS[@]}"; do
  echo "═══ 그룹 시작: $key (seeds: $SEEDS) ═══"
  for s in $SEEDS; do
    launch "$key" "$s"
  done
  wait     # 이 그룹 5시드가 전부 끝날 때까지 대기 (그룹 단위 배리어)
  echo "═══ 그룹 완료: $key ═══"
done
echo "[$(date +%H:%M:%S)] 전체 20개 완료. 집계: python scripts/aggregate_seeds.py --reduce peak"
