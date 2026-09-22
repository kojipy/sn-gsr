# RTX 50-series (Blackwell, sm_120) 向けに CUDA 12.8 ビルドの PyTorch を使用する。
# torch/torchvision の cu128 index は pyproject.toml の [tool.uv.index] で指定済み。

.PHONY: venv install setup

venv:
	uv venv --python 3.11

install:
	uv pip install -e .

setup: venv install
