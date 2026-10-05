# 협력형 MARL 비교 실험

EPyMARL을 활용해 IQL·VDN·QMIX·MAPPO·COMA를 SMAClite와 RWARE에서 실행하고 비교한 학습 프로젝트입니다. 새 알고리즘의 제안이 아니라, 기존 구현을 실행하고 실험 조건과 결과를 검토한 기록입니다.

## 실험 범위

| 항목 | 당시 기록 |
| --- | --- |
| 환경 | SMAClite MMM, RWARE tiny-2ag |
| 알고리즘 | IQL, VDN, QMIX, MAPPO, COMA |
| 시드 | 그룹당 1–5, 총 10개 그룹·50런으로 보고됨 |
| 학습 예산 | IQL·VDN·QMIX 4M, MAPPO·COMA 40M 환경 스텝 |
| 공통 보상 | common_reward=True |

50런 완료는 당시 보고서의 기록이며, 이번 공개 정리에서 W&B 전체 원시 로그를 다시 집계한 결과는 아닙니다. 서로 다른 학습 예산으로 얻은 결과이므로 동일 표본 수에서의 알고리즘 우열이나 표본효율 비교로 해석하지 않습니다.

## 개인 기여와 코드 출처

김용현은 과제에서 value 계열인 VDN·QMIX를 담당했고, IQL 공통 실습 및 이후 통합 비교에 참여했습니다. 당시 보고서는 다른 참여자의 MAPPO·COMA 담당 및 인수인계도 명시합니다. 전체 결과를 혼자 알고리즘부터 구현한 성과로 주장하지 않습니다.

실험 실행과 결과 검토 등 코딩 외 작업에 관여했으며, 프로젝트의 추가 코드 작성에는 생성형 AI를 사용했습니다. 알고리즘 본체는 [EPyMARL](https://github.com/uoe-agents/epymarl)의 기존 구현입니다. 포함된 원본 라이선스와 NOTICE를 유지했습니다. 공개용 설명 정리에도 AI의 도움을 받았습니다.

## 결과와 해석 범위

[기존 비교표](historical/docs/comparison_table.csv)와 [설정 기록](historical/docs/benchmark_match_config.md)을 보관합니다. 기존 표에서는 RWARE의 MAPPO 반환값이 다른 알고리즘보다 높고, SMAClite에서는 COMA의 결과 분산이 큰 양상이 나타납니다. 이것은 제한된 두 환경과 당시 설정에 대한 관찰입니다.

**집계 정의에 확인할 차이가 있습니다.** 노션 보고서는 “5시드 평균 평가곡선의 최고 시점”을 설명하지만, 보관된 `aggregate_seeds.py`는 “각 시드별 최고값을 구한 뒤 평균”을 계산합니다. 기존 CSV를 생성한 정확한 절차는 이번 검토로 확정하지 못했습니다. 따라서 수치는 과거 보고값으로 보존하며 독립적으로 재검증된 최종 성능으로 제시하지 않습니다.

과거 곡선은 [SMAClite](historical/figures/curves_smaclite.png), [RWARE](historical/figures/curves_rware.png)에 있습니다. 곡선 생성 코드가 W&B `_step`을 사용했던 점 때문에 환경 스텝 및 예산 진행률 축도 원시 로그와 재대조가 필요합니다.

## 코드와 실행

`epymarl/`에 당시 추적되던 소스를 보관했습니다. 원본 기준 커밋은 당시 문서에 `cbc38c09588064eab978501d0f12c2cf58fa7fc2`로 기록되어 있습니다. [패치](historical/docs/epymarl_changes.patch)는 수정 내역 참고용이며, 포함된 소스에 다시 적용하지 않습니다.

Python 3.10 환경을 기준으로 한 설치 예시입니다. 이번 정리에서 전체 학습을 다시 실행하지 않았습니다.

```bash
cd epymarl
pip install -r requirements.txt
pip install "git+https://github.com/uoe-agents/smaclite.git"
pip install rware wandb
python src/main.py --config=vdn --env-config=smaclite with env_args.map_name=MMM seed=1 t_max=2000 use_cuda=False use_wandb=False common_reward=True
```

위 명령은 짧은 동작 확인용이고 최종 결과 재현 명령이 아닙니다. 본 실험은 설정 기록의 환경별 하이퍼파라미터와 4M/40M 예산을 적용해야 합니다. `historical/scripts`는 당시 실행 기록으로, 개인 경로·실행 환경을 조정해야 할 수 있습니다. 기존 모델 체크포인트와 원시 로그는 포함하지 않았으므로 학습된 정책의 즉시 재생은 제공하지 않습니다.

## 공개 정리 범위

노션 보고서와 로컬 문서·코드를 대조해 정리했습니다. 인턴 기관명, 업무지시서 원문, 팀 발표 자료, 논문 PDF, 인증 정보 및 학습 로그는 이 공개 묶음에 포함하지 않았습니다. 기존 보고서에는 초기 2M/20M 설정과 최종 4M/40M 설정이 섞여 있어 이 문서에서는 최종 보고 설정을 명시했습니다.
