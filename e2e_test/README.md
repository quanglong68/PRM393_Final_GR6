# e2e_test — ARTEMIS E2E harness (PRM393 Lab 3, Phase E)

Driver: [google/artemis](https://github.com/google/artemis) qua `artemis-client`
(SDK Python), thiết bị Android/AVD điều khiển bằng ADB. 16 ca test ánh xạ
`docs/test-plan.md` (TC-F1/F2/F3, TC-V1/V5, TC-S, exploratory).

## Setup một lần (E1 — cần bạn làm)

```powershell
# 1. Cài uv (guide tr.2 yêu cầu): 
powershell -c "irm https://astral.sh/uv/install.ps1|iex"

# 2.Clone + chạy ARTEMIS host (server device automation, model API đa phương thức):
git clone https://github.com/google/artemis.git
cd artemis
./start.sh            # tự cài ADB/scrcpy/ffmpeg + bật http://localhost:8000

# 3. Bản này:
cd ..\prm323-lab2-gr6\e2e_test
copy .env.example .env    # điền GEMINI_API_KEY, DEVICE_SERIAL, TEST_ACCOUNT_EMAIL
uv sync

# 4. Bật emulator (Pixel AVD, đã add account @fpt.edu.vn + phụ) và cài debug APK:
cd .. && flutter run -d emulator-5554   # hoặc flutter install APK debug đã build
```

> **ADB path:** harness mặc định `~/AppData/Local/Android/Sdk/platform-tools/adb.exe`;
> override bằng `ADB=...` trong `.env` nếu SDK ở chỗ khác. Thêm thư mục đó vào PATH
> để `adb devices` chạy được từ mọi shell.

## Chạy

```powershell
uv run pytest -m e2e -v                  # 1 lượt (≈25–40 phút, profile flash)
uv run pytest -m e2e -v --junitxml=results_run1.xml   # ghi pass-rate; chạy lặp 3 lần (E3)
uv run pytest -m e2e -k EXPLORATORY -v   # riêng phiên exploratory 15–30′ (guide tr.23)
```

Evidence tự đổ về `../evidence/artemis/`: `TC-*.png` (screencap qua adb),
`logs/*.log` (logcat flutter), `exploratory-summary.md`.

## Quy ước

- **Assertion trên giá trị quan sát được** (chữ trên màn, nội dung log), không chỉ
  `result.succeeded` — guide tr.23.
- Task/note do harness tạo prefix `E2E` — dọn bằng cách xóa thủ công sau batch
  (harness không xóa để tránh cuộc chiến race với rules).
- Ca fail < 3/3 runs → điều tra rồi ghi §3 `docs/test-plan.md`, đánh dấu `flaky`
  bằng `@pytest.mark.flaky` chỉ sau khi đã ghi chú.
- `.env` **không commit** (API key); `results_run*.xml` không commit.

## Trạng thái

Harness **chưa từng chạy** — mọi pass rate chờ E1. Nếu API `artemis_client` đổi
so với repo google/artemis tại thời điểm bạn cài, sửa theo README của repo đó
(chỗ gọi: `conftest.py` fixtures `artemis`/`pro_artemis`).
