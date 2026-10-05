"""
W&B(marl-bench)에서 시드별 run을 모아 알고리즘 x 환경 비교표를 만든다.

각 (algo, env) 그룹에 대해 시드들의 **peak**(또는 final) 성능을 모아
평균 ± 표준편차 / 95% CI를 계산하고, 비교표를 CSV로 저장.
옵션으로 학습곡선 집계(평균±분산, step별)도 CSV로 내보냄.

run 이름 규칙 가정: {algo}_{env}_seed{N}_{YYYY}_{MM}_{DD}
  예: vdn_smaclite_seed1_2026_06_22  ->  algo=vdn, env=smaclite, seed=1

사용 예:
  python scripts/aggregate_seeds.py --metric test_return_mean --reduce peak \
    --out comparison_table.csv
  python scripts/aggregate_seeds.py --metric test_battle_won_mean --curve curves.csv
"""
import argparse
import re
import sys
from collections import defaultdict

import numpy as np

try:
    import wandb
except Exception:
    print("wandb 필요: pip install wandb"); sys.exit(1)

NAME_RE = re.compile(r"^(?P<algo>[a-z0-9]+)_(?P<env>[a-z0-9]+)_seed(?P<seed>\d+)", re.I)


def ci95(vals):
    """표본 표준편차 기반 95% CI 반폭 (작은 표본은 근사). n<2면 0."""
    n = len(vals)
    if n < 2:
        return 0.0
    sd = np.std(vals, ddof=1)
    # t(0.975, df=n-1) 근사값 (n=2..6)
    tval = {2: 12.71, 3: 4.30, 4: 3.18, 5: 2.78, 6: 2.57}.get(n, 1.96)
    return tval * sd / np.sqrt(n)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--project", default="marl-bench")
    p.add_argument("--entity", default=None, help="기본: 로그인 계정")
    p.add_argument("--metric", default="test_return_mean")
    p.add_argument("--reduce", choices=["peak", "final"], default="peak",
                   help="시드별 대표값: peak=학습 중 최대, final=마지막")
    p.add_argument("--algos", nargs="*", default=None, help="필터 (예: iql vdn qmix)")
    p.add_argument("--envs", nargs="*", default=None, help="필터 (예: smaclite rware)")
    p.add_argument("--out", default="comparison_table.csv")
    p.add_argument("--curve", default=None, help="지정 시 step별 평균±std 곡선 CSV 저장")
    args = p.parse_args()

    api = wandb.Api()
    entity = args.entity or api.default_entity
    runs = list(api.runs(f"{entity}/{args.project}"))
    print(f"[info] {entity}/{args.project}: {len(runs)} runs")

    # (algo, env) -> {seed: run} (중복 시 _step 큰 것)
    groups = defaultdict(dict)
    for r in runs:
        m = NAME_RE.match(r.name)
        if not m:
            continue
        if r.state not in ("finished", "running"):
            continue
        algo, env, seed = m["algo"].lower(), m["env"].lower(), int(m["seed"])
        if args.algos and algo not in args.algos:
            continue
        if args.envs and env not in args.envs:
            continue
        cur = groups[(algo, env)].get(seed)
        step = r.summary.get("_step", 0) or 0
        if cur is None or step > (cur.summary.get("_step", 0) or 0):
            groups[(algo, env)][seed] = r

    # 시드별 대표값 수집
    rows = []
    curve_rows = []
    for (algo, env), seed_runs in sorted(groups.items()):
        vals = []
        for seed, r in sorted(seed_runs.items()):
            h = r.history(keys=[args.metric], samples=5000)
            if not len(h) or args.metric not in h or not h[args.metric].notna().any():
                continue
            series = h[args.metric].dropna()
            v = float(series.max()) if args.reduce == "peak" else float(series.iloc[-1])
            vals.append(v)
            if args.curve:
                for st, val in zip(h["_step"], h[args.metric]):
                    if val == val:  # not NaN
                        curve_rows.append((algo, env, seed, int(st), float(val)))
        if not vals:
            continue
        mean = np.mean(vals)
        sd = np.std(vals, ddof=1) if len(vals) > 1 else 0.0
        rows.append({
            "algo": algo, "env": env, "n_seeds": len(vals),
            "mean": round(mean, 3), "std": round(sd, 3),
            "ci95": round(ci95(vals), 3),
            "cell": f"{mean:.2f} ± {sd:.2f}",
            "seeds_used": ",".join(str(s) for s in sorted(seed_runs)),
        })

    # 출력
    if not rows:
        print("[warn] 매칭된 run 없음 (이름 규칙/필터 확인)"); return
    print(f"\n=== 비교표 ({args.metric}, {args.reduce}) ===")
    print(f"{'algo':6} {'env':10} {'n':>2} {'mean±std':>14} {'95%CI±':>8}")
    for r in rows:
        print(f"{r['algo']:6} {r['env']:10} {r['n_seeds']:>2} {r['cell']:>14} {r['ci95']:>8}")

    # CSV
    import csv
    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)
    print(f"\n[saved] {args.out}  ({len(rows)} 셀)")

    if args.curve and curve_rows:
        # step별 평균/std 집계 (같은 algo,env,step의 시드 평균)
        agg = defaultdict(list)
        for algo, env, seed, st, val in curve_rows:
            agg[(algo, env, st)].append(val)
        with open(args.curve, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["algo", "env", "step", "mean", "std", "n_seeds"])
            for (algo, env, st), vs in sorted(agg.items()):
                w.writerow([algo, env, st, round(np.mean(vs), 3),
                            round(np.std(vs, ddof=1) if len(vs) > 1 else 0.0, 3), len(vs)])
        print(f"[saved] {args.curve}  (곡선 집계)")


if __name__ == "__main__":
    main()
