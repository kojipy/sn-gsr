# `uv run tracklab -cn soccernet` の実行フロー

## 1. エントリーポイント
`tracklab` コマンドは `pyproject.toml`（tracklabパッケージ側）の `console_scripts` により `tracklab.main:main` を実行します（`.venv/.../tracklab/main.py`）。この関数は `@hydra.main(config_path="pkg://tracklab.configs", config_name="config")` でデコレートされたHydraエントリーポイントです。`-cn soccernet` はこのデフォルトconfig名 `config` を `soccernet` に差し替える指定です。

## 2. `soccernet` configがどこから見つかるか
`soccernet.yaml` は `tracklab` 本体ではなく、このリポジトリの `sn_gamestate/configs/soccernet.yaml` にあります。これは以下の仕組みで探索パスに追加されています。

- `sn-gamestate` の `pyproject.toml` に
  ```
  [project.entry-points.tracklab_plugin]
  sn_gamestate = "sn_gamestate.config_finder:ConfigFinder"
  ```
  という entry point 登録があり、`ConfigFinder.config_package = "pkg://sn_gamestate.configs"`。
- `hydra_plugins/tracklab_searchpath_plugin` (`TracklabSearchPathPlugin`) がHydra起動時に `tracklab_plugin` グループのentry pointを全部読み込み、それぞれの `config_package` をHydraの検索パスに追加します。
- その結果、`sn_gamestate/configs/` がHydraの設定探索対象になり、`-cn soccernet` で `sn_gamestate/configs/soccernet.yaml` が採用されます。

## 3. `soccernet.yaml` の中身と実行内容
`defaults` リストにより以下のサブconfigが合成されます（一部は `sn_gamestate/configs/`、一部は `tracklab/configs/` 由来）:

- `dataset: soccernet_gs`（tracklab側） — SoccerNet Game Stateデータセットのロード
- `eval: gs_hota`（sn_gamestate側） — GS-HOTA指標での評価
- `engine: offline` → `tracklab.engine.OfflineTrackingEngine`
- `visualization: gamestate` — 結果を `.mp4` に書き出し
- 各モジュール実装:
  - `bbox_detector: yolo_ultralytics`
  - `reid: prtreid`
  - `track: bpbreid_strong_sort`
  - `pitch` / `calibration: nbjw_calib`
  - `jersey_number_detect: mmocr`
  - `tracklet_agg: voting_role_jn`
  - `team: kmeans_embeddings`
  - `team_side: mean_position`

`main()` はこの合成済み `cfg` を受け取り、

1. `instantiate(cfg.dataset)` でデータセット、`instantiate(cfg.eval, ...)` で評価器を生成
2. `cfg.pipeline`（`bbox_detector → reid → track → pitch → calibration → jersey_number_detect → tracklet_agg → team → team_side` の順）に従って各モジュールを `instantiate` し `Pipeline` を構築
3. `cfg.test_tracking=True` のため `TrackerState` と `OfflineTrackingEngine` を生成し `tracking_engine.track_dataset()` を実行（検出→ReID→トラッキング→ピッチ較正→背番号認識→トラックレット集約→チーム/サイド推定、を順にバッチ実行）
4. `cfg.eval_tracking=True` のため `evaluator.run(tracker_state)` でGS-HOTA評価
5. `state.save_file`（`states/sn-gamestate.pklz`）にトラッキング結果を保存
6. 出力は `outputs/sn-gamestate/<日付>/<時刻>/` 配下（Hydraの `run.dir` 設定、`hydra.job.chdir: True` でそこがカレントディレクトリになる）

## まとめ
このコマンドは、tracklab本体のHydraエントリーポイントを起点に、sn_gamestateプラグインが提供する `soccernet.yaml` 設定を合成し、SoccerNet Game Stateデータセットに対して検出・ReID・トラッキング・ピッチ較正・背番号認識・チーム推定のフルパイプラインをオフラインエンジンで実行し、GS-HOTAで評価して結果を保存する、という処理です。
