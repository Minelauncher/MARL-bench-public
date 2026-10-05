# 논문 매칭 학습 config (다른 PC 학습용)

> Papoudakis 2021 부록 표 기준, 5종 × 2환경 하이퍼파라미터 + 공통 구현 + 예산.
> 코드는 EPyMARL(vendored) 동일 → 표 필드만 환경별 오버라이드, 나머지는 EPyMARL 기본.
> ⚠️ 우리 맵(SMAClite **MMM**, RWARE **tiny-2ag**)은 논문 튜닝 태스크(SMAC **3s5z**, RWARE **Tiny 4p**)와
> 다름 → 논문 수치와 1:1 비교는 불가, **경향 비교**용. config 자체는 아래대로 = "논문 설정 적용".

EPyMARL 필드 매핑: network GRU→`use_rnn=True`/FC→`use_rnn=False`,
reward std→`standardise_rewards`, eval ε→`evaluation_epsilon`, ε anneal→`epsilon_anneal_time`,
target 200(hard)→`target_update_interval_or_tau=200`/0.01(soft)→`=0.01`,
entropy→`entropy_coef`, n-step→`q_nstep`.

---

## 1. SMAClite (= 논문 SMAC 열)

| Algo | hidden | lr | reward std | network | eval ε | ε anneal | target update | entropy | n-step |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IQL | 128 | 0.0005 | False | GRU | 0.05 | 50,000 | 200 (hard) | - | - |
| VDN | 128 | 0.0005 | True | GRU | 0.05 | 50,000 | 200 (hard) | - | - |
| QMIX | 128 | **0.0005** | True | GRU | 0.05 | 50,000 | 200 (hard) | - | - |
| COMA | 128 | 0.0005 | True | FC | - | - | 0.01 (soft) | 0.01 | 5 |
| MAPPO | 64 | 0.0005 | False | GRU | - | - | 0.01 (soft) | 0.001 | 10 |

> **QMIX lr**: 논문 appendix(공유)엔 `0.005`로 적혀 있으나 **오타로 판단** → `0.0005` 사용.
> 근거: 다른 모든 QMIX 값이 0.0001~0.0005이고, QMIX **비공유** SMAC도 0.0005.

## 2. RWARE (= 논문 RWARE 열) — 5종 전부 FC

| Algo | hidden | lr | reward std | network | eval ε | ε anneal | target update | entropy | n-step |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IQL | 64 | 0.0005 | True | FC | 0.05 | 50,000 | 0.01 (soft) | - | - |
| VDN | 64 | 0.0005 | True | FC | 0.05 | 50,000 | 0.01 (soft) | - | - |
| QMIX | 64 | 0.0005 | True | FC | 0.05 | 50,000 | 0.01 (soft) | - | - |
| COMA | 64 | 0.0005 | True | FC | - | - | 0.01 (soft) | 0.01 | 5 |
| MAPPO | 128 | 0.0005 | False | FC | - | - | 0.01 (soft) | 0.001 | 10 |

## 3. 학습 예산 (SMAC/RWARE)

| Algo | policy | budget (양 환경) |
| --- | --- | --- |
| IQL / VDN / QMIX | off-policy | **4,000,000** |
| COMA / MAPPO | on-policy | **40,000,000** (10배) |

## 4. 공통 구현 (고정값 — EPyMARL 기본 + 본문)

| 항목 | 값 |
| --- | --- |
| Q 탐험 | ε-greedy |
| train ε 시작/끝 | 1.0 → 0.05 (선형) |
| eval ε | 위 표 (value 0.05) |
| replay buffer | **5K episodes 또는 1M samples 중 메모리 작은 쪽** |
| TD target | Double Q-learning |
| optimizer | Adam |
| gamma | 0.99 |
| grad_norm_clip | 10 |
| MAPPO PPO epochs / clip | 4 / 0.2 |
| 정책 실행(on-policy) | argmax 아닌 **policy sampling** |
| 평가 | 학습 중 41회, 각 100 에피소드, **Maximum returns**(peak, 5시드 평균±95%CI) |

---

## 5. 실행 명령 (바로 실행 — seed 1~5 루프)

공통 플래그: `use_cuda=True common_reward=True save_model=True save_best_model=True use_wandb=True wandb_mode=online wandb_project=marl-bench wandb_team=launcher1423-`
⚠️ **on-policy(COMA/MAPPO)는 실행 전 `$env:PYTHONUTF8="1"`** (Windows cp949 방지).

### SMAClite (MMM)
```powershell
$f="--env-config=smaclite with env_args.map_name=MMM"
$common="use_cuda=True common_reward=True save_model=True save_best_model=True use_wandb=True wandb_mode=online wandb_project=marl-bench wandb_team=launcher1423-"
foreach($s in 1..5){
  $env:WANDB_NAME="iql_smaclite_seed$s";   python src/main.py --config=iql   $f.Split() seed=$s t_max=4000000 hidden_dim=128 lr=0.0005 standardise_rewards=False use_rnn=True evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=200 $common.Split()
  $env:WANDB_NAME="vdn_smaclite_seed$s";   python src/main.py --config=vdn   $f.Split() seed=$s t_max=4000000 hidden_dim=128 lr=0.0005 standardise_rewards=True  use_rnn=True evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=200 $common.Split()
  $env:WANDB_NAME="qmix_smaclite_seed$s";  python src/main.py --config=qmix  $f.Split() seed=$s t_max=4000000 hidden_dim=128 lr=0.0005 standardise_rewards=True  use_rnn=True evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=200 $common.Split()
}
$env:PYTHONUTF8="1"
foreach($s in 1..5){
  $env:WANDB_NAME="coma_smaclite_seed$s";  python src/main.py --config=coma  $f.Split() seed=$s t_max=40000000 hidden_dim=128 lr=0.0005 standardise_rewards=True use_rnn=False entropy_coef=0.01 q_nstep=5 target_update_interval_or_tau=0.01 $common.Split()
  $env:WANDB_NAME="mappo_smaclite_seed$s"; python src/main.py --config=mappo $f.Split() seed=$s t_max=40000000 hidden_dim=64  lr=0.0005 standardise_rewards=False use_rnn=True entropy_coef=0.001 q_nstep=10 target_update_interval_or_tau=0.01 $common.Split()
}
```

### RWARE (tiny-2ag)
```powershell
$f="--env-config=gymma with env_args.time_limit=500 env_args.key=rware:rware-tiny-2ag-v2"
foreach($s in 1..5){
  $env:WANDB_NAME="iql_rware_seed$s";   python src/main.py --config=iql   $f.Split() seed=$s t_max=4000000 hidden_dim=64 lr=0.0005 standardise_rewards=True use_rnn=False evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=0.01 $common.Split()
  $env:WANDB_NAME="vdn_rware_seed$s";   python src/main.py --config=vdn   $f.Split() seed=$s t_max=4000000 hidden_dim=64 lr=0.0005 standardise_rewards=True use_rnn=False evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=0.01 $common.Split()
  $env:WANDB_NAME="qmix_rware_seed$s";  python src/main.py --config=qmix  $f.Split() seed=$s t_max=4000000 hidden_dim=64 lr=0.0005 standardise_rewards=True use_rnn=False evaluation_epsilon=0.05 epsilon_anneal_time=50000 target_update_interval_or_tau=0.01 $common.Split()
}
$env:PYTHONUTF8="1"
foreach($s in 1..5){
  $env:WANDB_NAME="coma_rware_seed$s";  python src/main.py --config=coma  $f.Split() seed=$s t_max=40000000 hidden_dim=64  lr=0.0005 standardise_rewards=True  use_rnn=False entropy_coef=0.01  q_nstep=5  target_update_interval_or_tau=0.01 $common.Split()
  $env:WANDB_NAME="mappo_rware_seed$s"; python src/main.py --config=mappo $f.Split() seed=$s t_max=40000000 hidden_dim=128 lr=0.0005 standardise_rewards=False use_rnn=False entropy_coef=0.001 q_nstep=10 target_update_interval_or_tau=0.01 $common.Split()
}
```
> 위 루프는 순차 실행 예시. 동시 실행은 PC 코어에 맞춰 조절(value 6~8개, on-policy 2개 권장).

---

## 6. 주의
- **QMIX SMAClite lr = 0.0005** (논문 표 0.005는 오타로 판단).
- **계산량**: 4M/40M은 큼 → 단일 PC 비현실. value는 동시 실행, on-policy는 분산/축소 고려.
- **맵 차이**: 논문 튜닝 태스크(3s5z, Tiny 4p) ≠ 우리(MMM, tiny-2ag) → 경향 비교만.
- 집계: `scripts/aggregate_seeds.py --reduce peak` (논문 Maximum returns와 동일 지표).
