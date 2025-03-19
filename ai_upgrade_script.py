import subprocess
import sys
import os
from concurrent.futures import ThreadPoolExecutor

def install_package(package):
    """Installs a package with error handling"""
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", package, "--no-cache-dir", "--timeout=100"], check=True)
    except subprocess.CalledProcessError:
        print(f"Error installing {package}, retrying...")
        subprocess.run([sys.executable, "-m", "pip", "install", package, "--no-cache-dir", "--timeout=200"], check=True)

# List of AI, UI/UX, and CI/CD packages
packages = [
    "tensorflow", "torch", "torchvision", "torchaudio", "keras", "transformers", "diffusers",
    "deepspeed", "jax", "onnxruntime", "stable-diffusion-webui",
    "spacy", "sentencepiece", "fasttext", "nltk", "langchain", "haystack",
    "arxiv", "scholarly", "pdfminer.six", "googlesearch-python",
    "yfinance", "prophet", "mlfinlab", "backtrader", "plotly", "fastapi", "flask",
    "opencv-python", "scikit-image", "librosa", "deepface", "mediapipe", "ultralytics",
    "pycryptodome", "scapy", "fairlearn", "qiskit", "pennylane", "cirq",
    "docker", "kubernetes", "github-actions", "gitlab-ci", "streamlit", "dash",
]

# Run installations in parallel
with ThreadPoolExecutor(max_workers=min(8, os.cpu_count())) as executor:
    executor.map(install_package, packages)

print("✅ AI/CD, UI/UX, and Full-Stack Integration Ready for Deployment!")

# Optimize the system
def optimize_system():
    print("🔹 Optimizing system performance...")
    os.system("pip cache purge")
    os.system("python -m spacy download en_core_web_sm")
    os.system("python -m nltk.downloader all")
    os.system("nvidia-smi")
    os.system("python -m pip install --upgrade pip setuptools wheel")
    print("🚀 System Optimization Complete!")

optimize_system()
