import torch.backends.mps

# torch==1.13.1's MPS backend is missing/broken for several ops used in this
# pipeline (torchvision::nms, HRNet convs in PRTReId, ...). Force
# tracklab.main.init_environment() to fall through to CPU by making MPS
# report as unavailable before tracklab is imported.
torch.backends.mps.is_available = lambda: False

from tracklab.main import main as _tracklab_main


def main():
    _tracklab_main()


if __name__ == "__main__":
    main()
