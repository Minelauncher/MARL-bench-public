# 하이퍼파라미터 일치 검증표 (논문 vs 우리 config vs 실제 W&B 런)

> **목적**: 우리 매칭 config가 Papoudakis(2021) 벤치마크 논문 하이퍼파라미터와 일치함을 1:1 대조로 증빙. (보고서 재현성 산출물)
> **출처**: 논문 PDF `papers/Benchmarking.pdf` 부록 H·I, **Tables 11~29 (with parameter sharing)**.
> 우리는 **파라미터 공유(parameter sharing)** 사용 → 논문의 "with parameter sharing" 표(짝수 표: 12/20/24/26/28)와 대조.
> **범례**: ✅ 일치 / ⚠️ 의도적 보정(논문 오타) / 표값은 모두 "SMAC 열" 또는 "RWARE 열".

---

## 1. SMAClite (= 논문 SMAC 열, with parameter sharing)

| Algo | param | 논문 (표) | 우리 config | W&B 실제 | 일치 |
| --- | --- | --- | --- | --- | --- |
| **IQL** (T12) | hidden | 128 | 128 | 128 | ✅ |
| | lr | 0.0005 | 0.0005 | 0.0005 | ✅ |
| | reward std | **False** | False | False | ✅ |
| | network | GRU | GRU(use_rnn=T) | rnn=T | ✅ |
| | eval ε | 0.05 | 0.05 | 0.05 | ✅ |
| | ε anneal | 50,000 | 50,000 | 50,000 | ✅ |
| | target update | **200 (hard)** | 200 | 200 | ✅ |
| **VDN** (T26) | hidden | 128 | 128 | 128 | ✅ |
| | lr | 0.0005 | 0.0005 | 0.0005 | ✅ |
| | reward std | True | True | True | ✅ |
| | network | GRU | GRU | rnn=T | ✅ |
| | eval ε | 0.05 | 0.05 | 0.05 | ✅ |
| | ε anneal | 50,000 | 50,000 | 50,000 | ✅ |
| | target update | **200 (hard)** | 200 | 200 | ✅ |
| **QMIX** (T28) | hidden | 128 | 128 | 128 | ✅ |
| | lr | ~~0.005~~ → 0.0005¹ | 0.0005 | 0.0005 | ⚠️¹ |
| | reward std | True | True | True | ✅ |
| | network | GRU | GRU | rnn=T | ✅ |
| | eval ε | 0.05 | 0.05 | 0.05 | ✅ |
| | ε anneal | 50,000 | 50,000 | 50,000 | ✅ |
| | target update | **200 (hard)** | 200 | 200 | ✅ |
| **COMA** (T20) | hidden | 128 | 128 | (13700F) | ✅ |
| | lr | 0.0005 | 0.0005 | — | ✅ |
| | reward std | True | True | — | ✅ |
| | network | FC | FC(use_rnn=F) | — | ✅ |
| | entropy | 0.01 | 0.01 | — | ✅ |
| | n-step | 5 | 5 | — | ✅ |
| | target update | 0.01 (soft) | 0.01 | — | ✅ |
| **MAPPO** (T24) | hidden | 64 | 64 | (13700F) | ✅ |
| | lr | 0.0005 | 0.0005 | — | ✅ |
| | reward std | False | False | — | ✅ |
| | network | GRU | GRU(use_rnn=T) | — | ✅ |
| | entropy | 0.001 | 0.001 | — | ✅ |
| | n-step | 10 | 10 | — | ✅ |
| | target update | 0.01 (soft) | 0.01 | — | ✅ |

---

## 2. RWARE (= 논문 RWARE 열, with parameter sharing)

| Algo | param | 논문 (표) | 우리 config | W&B 실제 | 일치 |
| --- | --- | --- | --- | --- | --- |
| **IQL** (T12) | hidden | 64 | 64 | 64 | ✅ |
| | lr | 0.0005 | 0.0005 | 0.0005 | ✅ |
| | reward std | True | True | True | ✅ |
| | network | FC | FC(use_rnn=F) | rnn=F | ✅ |
| | eval ε | 0.05 | 0.05 | 0.05 | ✅ |
| | ε anneal | 50,000 | 50,000 | 50,000 | ✅ |
| | target update | 0.01 (soft) | 0.01 | 0.01 | ✅ |
| **VDN** (T26) | hidden | 64 | 64 | 64 | ✅ |
| | lr | 0.0005 | 0.0005 | 0.0005 | ✅ |
| | reward std | True | True | True | ✅ |
| | network | FC | FC | rnn=F | ✅ |
| | eval ε | 0.05 | 0.05 | 0.05 | ✅ |
| | ε anneal | 50,000 | 50,000 | 50,000 | ✅ |
| | target update | 0.01 (soft) | 0.01 | 0.01 | ✅ |
| **QMIX** (T28) | hidden | 64 | 64 | 64 | ✅ |
| | lr | 0.0005 | 0.0005 | 0.0005 | ✅ |
| | reward std | True | True | True | ✅ |
| | network | FC | FC | rnn=F | ✅ |
| | eval ε | 0.05 | 0.05 | 0.05 | ✅ |
| | ε anneal | 50,000 | 50,000 | 50,000 | ✅ |
| | target update | 0.01 (soft) | 0.01 | 0.01 | ✅ |
| **COMA** (T20) | hidden | 64 | 64 | (13700F) | ✅ |
| | lr | 0.0005 | 0.0005 | — | ✅ |
| | reward std | True | True | — | ✅ |
| | network | FC | FC | — | ✅ |
| | entropy | 0.01 | 0.01 | — | ✅ |
| | n-step | 5 | 5 | — | ✅ |
| | target update | 0.01 (soft) | 0.01 | — | ✅ |
| **MAPPO** (T24) | hidden | 128 | 128 | (13700F) | ✅ |
| | lr | 0.0005 | 0.0005 | — | ✅ |
| | reward std | False | False | — | ✅ |
| | network | FC | FC | — | ✅ |
| | entropy | 0.001 | 0.001 | — | ✅ |
| | n-step | 10 | 10 | — | ✅ |
| | target update | 0.01 (soft) | 0.01 | — | ✅ |

---

## 3. 주석 / 알려진 차이

**¹ QMIX SMAC learning rate (의도적 보정):**
- Table 28(QMIX, 공유)은 SMAC lr = **0.005**로 표기.
- 그러나 **Table 11(탐색 범위)**: "SMAC learning rate = **0.0005** (단일값 → SMAC 전 알고리즘 공통)"으로 명시 → Table 28의 `0.005`는 **Table 11과 모순되는 오타**로 판단.
- QMIX의 다른 환경 lr도 0.0003~0.0005 수준이라 0.005(10배)는 비정상.
- → **우리는 0.0005 사용** = 논문 의도(Table 11)와 일치. **나머지 4종 SMAC lr도 전부 0.0005로 일관.**

**target update가 SMAC에서 N/A인 이유 (Table 11):**
- SMAC는 target update를 탐색하지 않고(N/A) **원 논문 관례값 사용** → value 계열은 **200(hard)**.
- 따라서 IQL/VDN/QMIX SMAC = 200(hard)은 논문이 SMAC 표준 관례를 그대로 채택한 것.

**EPyMARL 필드 매핑:**
- network GRU→`use_rnn=True` / FC→`use_rnn=False`
- target 200(hard)→`target_update_interval_or_tau=200` / 0.01(soft)→`=0.01`
- reward std→`standardise_rewards`, eval ε→`evaluation_epsilon`, ε anneal→`epsilon_anneal_time`, entropy→`entropy_coef`, n-step→`q_nstep`

**학습 예산(t_max)** — 위 표(튜닝 하이퍼파라미터)와 별개:
- off-policy(value) = 4M, on-policy(MAPPO/COMA) = 40M (함정② 10배 규칙). 논문과 1:1 절대값 비교가 아닌 **경향 비교**용.

**태스크 차이:**
- 논문 튜닝 태스크(SMAC=3s5z 등, RWARE=tiny-4ag) ≠ 우리(SMAClite=MMM, RWARE=tiny-2ag).
- 같은 환경군 내에서 best 하이퍼파라미터는 동일하게 적용(논문 방식) → **config는 일치, 수치는 경향 비교.**

---

## 4. 파라미터 선택 근거 — 논문은 어디까지 말하나

> **핵심: 논문은 "왜 이 값인가"를 파라미터별로 설명하지 않음. 전부 경험적 그리드서치.**
> (본문 전체 검색 결과, reward std·network type 등의 *언급*은 "EPyMARL이 튜닝 지원" 수준이지, 특정 값 선택의 *이유* 서술은 없음.)

### 논문이 명시하는 것 (사실, 인용 가능)
- **선택 방법 (부록 H, p28)**: Table 11 범위를 그리드서치 → 각 조합 **3시드 평가** → **평균 평가 최대 조합 채택**. 환경별 한 태스크에서 튜닝 후 같은 환경 내 나머지 태스크에 동일 적용.
- **SMAC 예외**: "계산비용 절감 위해 SMAC 탐색을 축소했고, 여러 알고리즘은 이미 SMAC best가 원논문에 공개돼 그것을 활용." → SMAC target update가 N/A(원논문 관례 **200 hard**)인 이유.
- **reward std는 SMAC에서도 탐색됨** (Table 11 SMAC 열 = `True/False`) → **IQL-SMAC=False는 관례가 아니라 진짜 탐색 결과** (target update와 다른 점).
- **환경별 주 난이도 (p4, Table 1)**:

  | 환경 | 희소성 | 주 난이도(논문) |
  | --- | --- | --- |
  | MatrixGames | dense | 준최적 평형 |
  | MPE | dense | 비정상성 |
  | **SMAC** | dense | **큰 행동공간** |
  | LBF | sparse | 협응(coordination) |
  | **RWARE** | **sparse** | **희소보상** |

  → 논문은 **환경 난이도 수준만** 규정. "이 난이도라서 이 하이퍼파라미터"라는 연결은 **서술하지 않음.**

### 논문이 말하지 않는 것 (= 우리 해석 영역, 인용 불가)
- "왜 IQL-SMAC만 reward std off가 최적인가" 같은 **메커니즘적 이유는 논문에 없음.**
- 앞서 논한 설명(mixer 없는 IQL + 조밀보상 SMAC에서 *움직이는 정규화 통계*가 불안정을 가중 등)은 **합리적 추론이지 논문 인용이 아님.**
- → **보고서 작성 원칙**: "논문은 경험적 탐색(Table 11)으로 선택. 메커니즘 해석은 우리 분석"으로 **반드시 구분**해 표기.

---

## 5. 결론

> **우리 매칭 config는 Papoudakis(2021) Tables 12·20·24·26·28(parameter sharing)과 완전 일치.**
> 유일한 차이는 **QMIX SMAC lr** — 논문 표기 0.005가 Table 11과 모순되는 오타라 0.0005로 보정(논문 의도 일치).
> W&B 실제 런 config도 value 3종(SMAClite·RWARE)에서 표값과 일치 확인. on-policy(13700F)는 진행 중 — 등록되는 대로 채움.
