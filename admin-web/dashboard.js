const form = document.querySelector('#filters');
const status = document.querySelector('#status');
const results = document.querySelector('#results');
const rows = document.querySelector('#issues');
const refresh = document.querySelector('#refresh');
const dates = new Intl.DateTimeFormat('vi-VN', {
  dateStyle: 'short', timeStyle: 'short', timeZone: 'Asia/Ho_Chi_Minh',
});

async function loadReport() {
  refresh.disabled = true;
  status.textContent = 'Đang tải báo cáo…';
  rows.replaceChildren();
  results.hidden = true;
  try {
    const days = document.querySelector('#days').value;
    const response = await fetch(`/api/crashes?days=${encodeURIComponent(days)}`);
    const report = await response.json();
    if (!response.ok) throw new Error(report.error);
    for (const issue of report.issues) {
      const row = rows.insertRow();
      for (const value of [issue.title, issue.type, issue.events, issue.users]) {
        row.insertCell().textContent = value ?? '—';
      }
      if (issue.type === 'FATAL') row.cells[1].className = 'fatal';
    }
    results.hidden = report.issues.length === 0;
    const interval = `${dates.format(new Date(report.start))} – ${dates.format(new Date(report.end))}`;
    status.textContent = report.issues.length
      ? `${report.issues.length} nhóm sự cố${report.moreAvailable ? ' đầu tiên' : ''} · ${interval}`
      : `Firebase chưa trả sự cố trong khoảng ${interval}.`;
  } catch (error) {
    status.textContent = error.message || 'Không tải được báo cáo.';
  } finally {
    refresh.disabled = false;
  }
}

form.addEventListener('submit', (event) => {
  event.preventDefault();
  loadReport();
});
loadReport();
