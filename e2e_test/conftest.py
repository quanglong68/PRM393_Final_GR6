"""ARTEMIS E2E fixtures — PRM393 Lab 3 (FPTU Second Brain).

Chạy qua ARTEMIS host (google/artemis) bằng `artemis_client`.
Mỗi test = 1 task giao cho agent Flash/Pro trên device; assertion dựa trên
GIÁ TRỊ QUAN SÁT ĐƯỢC (screen text, logcat, Firestore doc qua Console ảnh) —
không chỉ trạng thái SUCCESS (guide tr.23).
"""

import os
import shutil
import subprocess
import time
from pathlib import Path

import pytest

try:
    from dotenv import load_dotenv

    load_dotenv(Path(__file__).parent / ".env")
except ImportError:  # .env chỉ bắt buộc khi chạy thật
    pass

try:
    from artemis_client import ArtemisClient
except ImportError:  # chưa `uv sync` (E1) — fixture sẽ skip kèm lý do
    ArtemisClient = None

ARTEMIS_HOST = os.getenv("ARTEMIS_HOST", "http://127.0.0.1:8000")
DEVICE_SERIAL = os.getenv("DEVICE_SERIAL", "emulator-5554")
APP_PACKAGE = os.getenv("APP_PACKAGE", "com.example.prm323_lab3")
ADB = os.getenv(
    "ADB",
    str(Path.home() / "AppData/Local/Android/Sdk/platform-tools/adb.exe"),
)
EVIDENCE_DIR = Path(
    os.getenv("EVIDENCE_DIR")
    or Path(__file__).parent.parent / "evidence" / "artemis"
)


def pytest_configure(config):
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    (EVIDENCE_DIR / "logs").mkdir(exist_ok=True)


@pytest.fixture(scope="session")
def artemis() -> "ArtemisClient":
    if ArtemisClient is None:
        pytest.skip("chưa cài artemis-client — chạy `uv sync` trong e2e_test/ (E1)")
    client = ArtemisClient(ARTEMIS_HOST, device_serial=DEVICE_SERIAL, default_profile="flash")
    return client


@pytest.fixture(scope="session")
def pro_artemis() -> "ArtemisClient":
    """Profile Pro cho flow nhiều nhánh/cần checker (guide: crash, error branch)."""
    if ArtemisClient is None:
        pytest.skip("chưa cài artemis-client — chạy `uv sync` trong e2e_test/ (E1)")
    return ArtemisClient(ARTEMIS_HOST, device_serial=DEVICE_SERIAL, default_profile="pro")


def adb(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run([ADB, "-s", DEVICE_SERIAL, *args], capture_output=True, text=True, timeout=30)


@pytest.fixture()
def device_state():
    """ADB helpers cho tương tác Android gốc + quan sát log (guide tr.23)."""
    return adb


@pytest.fixture()
def logcat():
    """Trả về callable start/stop capture `logcat -s flutter` cho 1 test."""
    handle: dict = {}

    class Cap:
        def start(self, name: str) -> None:
            path = EVIDENCE_DIR / "logs" / f"{name}_{int(time.time())}.log"
            handle["proc"] = subprocess.Popen(
                [ADB, "-s", DEVICE_SERIAL, "logcat", "-v", "time", "-s", "flutter", "*:S"],
                stdout=open(path, "w", encoding="utf-8", errors="replace"),
                stderr=subprocess.DEVNULL,
            )
            handle["path"] = path
            adb("logcat", "-c")

        def stop_and_text(self) -> str:
            proc = handle.get("proc")
            if proc:
                proc.terminate()
                proc.wait(timeout=10)
            text = handle["path"].read_text(encoding="utf-8", errors="replace") if "path" in handle else ""
            return text

    return Cap()


@pytest.fixture()
def evidence_shot():
    """adb exec-out screencap → file PNG đặt tên TC-*, trả về callable save(name)."""

    def save(name: str) -> Path:
        out = EVIDENCE_DIR / f"{name}.png"
        with open(out, "wb") as fh:
            subprocess.run(
                [ADB, "-s", DEVICE_SERIAL, "exec-out", "screencap", "-p"],
                stdout=fh, stderr=subprocess.DEVNULL, timeout=30, check=True,
            )
        return out

    return save


skip_without_adb = pytest.mark.skipif(
    shutil.which(ADB) is None and not Path(ADB).exists(),
    reason="ADB không tồn tại — cần E1 setup (user)",
)


# Alias, not a wrapper: `skip_without_adb` is a pytest MarkDecorator, so
# `skip_without_adb(func)` raised. Modules import `require_artemis` by name.
require_artemis = skip_without_adb
