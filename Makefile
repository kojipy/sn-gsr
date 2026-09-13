# macOS(Apple Silicon)でのビルド時、CLTのデフォルトSDK(MacOSX27.0.sdk)が
# 壊れているためリンクに失敗する。安定版SDKを明示的に指定する。
SDKROOT := /Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk

# 古いPyTorch(1.13.1)のヘッダーが新しいclangでは無効な標準ライブラリの
# 特殊化として検出されビルドが失敗するため、当該診断を抑制する。
CFLAGS := -Wno-invalid-specialization
CXXFLAGS := -Wno-invalid-specialization

BUILD_ENV := SDKROOT=$(SDKROOT) CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)"

.PHONY: venv install mmcv setup

venv:
	uv venv --python 3.9

install:
	$(BUILD_ENV) uv pip install -e .

mmcv:
	$(BUILD_ENV) uv run mim install mmcv==2.0.1

setup: venv install mmcv
