# 협력형 MARL 비교 실험

EPyMARL로 여러 강화학습 알고리즘을 돌려보고 비교한 기록입니다.

인턴 업무로 SMAClite와 RWARE에서 IQL, VDN, QMIX, MAPPO, COMA를 실행했습니다. 당시 정리한 노션과 컴퓨터에 남아 있던 코드, 설정, 결과표를 바탕으로 필요한 자료를 모아두었습니다.

## 실험 설정

| 항목 | 설정 |
| --- | --- |
| 환경 | SMAClite MMM, RWARE tiny-2ag |
| 알고리즘 | IQL, VDN, QMIX, MAPPO, COMA |
| 시드 | 알고리즘·환경별 1–5, 보고서 기준 총 50회 |
| 학습 예산 | IQL·VDN·QMIX 4M, MAPPO·COMA 40M 환경 스텝 |
| 공통 보상 | common_reward=True |

당시 보고서에는 50회 실행을 완료한 것으로 정리해두었습니다. 이번에 올리면서 W&B 로그 전체를 다시 집계하지는 않았습니다. 알고리즘 계열에 따라 학습 스텝 수가 달라서, 같은 양을 학습했을 때의 성능 비교로 보기는 어렵습니다.

## 직접 한 작업

처음에는 IQL을 공통으로 실습하고, 저는 VDN과 QMIX를 맡았습니다. MAPPO와 COMA는 다른 참여자가 맡았고, 이후 인수인계를 받아 전체 결과를 비교했습니다.

알고리즘 코드는 [EPyMARL](https://github.com/uoe-agents/epymarl)의 구현을 사용했습니다. 추가로 필요한 코드는 AI의 도움을 받아 작성했고, 실험을 돌리거나 결과를 확인하는 작업은 직접 했습니다. 이 README를 정리할 때도 AI를 사용했습니다. 원본 코드의 라이선스와 NOTICE는 그대로 넣어두었습니다.

## 결과

[비교표](historical/docs/comparison_table.csv)와 [설정 기록](historical/docs/benchmark_match_config.md)을 올려두었습니다. 당시 결과에서는 RWARE에서 MAPPO의 보상이 높았고, SMAClite에서는 COMA가 시드에 따라 결과 차이가 컸습니다. 여기서 사용한 환경과 설정에서 나온 결과입니다.

정리하면서 집계 방식이 다르게 적힌 부분을 발견했습니다. 노션에는 5개 시드의 평균 곡선에서 최고점을 고른다고 적혀 있는데, `aggregate_seeds.py`는 각 시드의 최고값을 먼저 고른 뒤 평균을 냅니다. 기존 CSV를 어느 방식으로 만들었는지는 더 확인해야 해서 수치는 당시 자료 그대로 두었습니다.

학습 그래프도 [SMAClite](historical/figures/curves_smaclite.png)와 [RWARE](historical/figures/curves_rware.png)로 나눠두었습니다. 그래프를 만들 때 W&B의 `_step`을 사용해서, 가로축이 실제 환경 스텝이나 학습 진행률과 맞는지도 로그를 다시 확인할 필요가 있습니다.

## 코드와 실행

`epymarl/`에 당시 사용하던 소스를 넣었습니다. 문서에 적어둔 원본 기준 커밋은 `cbc38c09588064eab978501d0f12c2cf58fa7fc2`입니다. [패치 파일](historical/docs/epymarl_changes.patch)은 수정한 부분을 보기 위해 남겨둔 것이고, 여기 있는 코드에는 다시 적용할 필요가 없습니다.

Python 3.10을 기준으로 설치했던 방법입니다. 이번에 자료를 정리하면서 학습을 다시 돌리지는 않았습니다.

```bash
cd epymarl
pip install -r requirements.txt
pip install "git+https://github.com/uoe-agents/smaclite.git"
pip install rware wandb
python src/main.py --config=vdn --env-config=smaclite with env_args.map_name=MMM seed=1 t_max=2000 use_cuda=False use_wandb=False common_reward=True
```

위 명령은 짧게 실행이 되는지 확인하는 용도입니다. 당시 실험처럼 돌리려면 설정 기록에 있는 환경별 값과 4M/40M 스텝을 적용해야 합니다. `historical/scripts`에는 당시 실행 스크립트를 넣었는데, 사용하던 컴퓨터 경로 등이 들어 있어서 실행 전에 수정이 필요할 수 있습니다. 학습된 모델과 원시 로그는 올리지 않았습니다.

## 참고

업무지시서와 팀 발표자료, 논문 PDF, 개인 설정은 제외하고 코드와 실험 자료 위주로 올렸습니다. 예전 문서에는 처음 사용한 2M/20M 설정도 남아 있어서, 여기에는 최종 보고서의 4M/40M을 기준으로 적었습니다.
