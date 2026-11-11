# Slide nộp bài

Thư mục này chứa **hai bộ slide riêng**, không gộp chung một file:

| Tệp | Dùng cho | Số slide |
|---|---|---|
| `Lab03_<MSSV>_slides.pdf` | Bảo vệ Lab 3 | 12–15 |
| `Final_<MSSV>_slides.pdf` | Bảo vệ Final | 12–15 |

Ví dụ với MSSV `SE123456`: `slides/Lab03_SE123456_slides.pdf` và `slides/Final_SE123456_slides.pdf`.

## Cách đưa slide lên GitHub

Cách 1 — GitHub web:

1. Mở repo, vào thư mục `slides/`.
2. **Add file → Upload files**, kéo hai file PDF vào, bấm **Commit changes**.

Cách 2 — bằng git:

```bash
git add slides/Lab03_<MSSV>_slides.pdf slides/Final_<MSSV>_slides.pdf
git commit -m "docs(slides): thêm slide Lab 3 và Final"
git push personal main
```

## Nội dung tham khảo

- Lab 3: [docs/lab3-slides-outline.md](../docs/lab3-slides-outline.md)
- Final: [docs/final-slide-content.md](../docs/final-slide-content.md) và kịch bản video [docs/lab3-video-script.md](../docs/lab3-video-script.md)
