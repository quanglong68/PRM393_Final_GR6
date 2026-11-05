import { GoogleAuth } from 'google-auth-library';

const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/cloud-platform'],
});

export class FirebaseApiError extends Error {
  constructor(status, code) {
    super(`Firebase API: HTTP ${status} (${code})`);
    this.status = status;
  }
}

export async function firebaseRequest(url, { method = 'GET', body } = {}) {
  const token = process.env.FIREBASE_ACCESS_TOKEN || await auth.getAccessToken();
  if (!token) throw new Error('Firebase OAuth credentials unavailable.');
  const response = await fetch(url, {
    method,
    headers: {
      authorization: `Bearer ${token}`,
      ...(body && { 'content-type': 'application/json' }),
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(15000),
    redirect: 'error',
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const code = data.error?.status;
    throw new FirebaseApiError(
      response.status,
      typeof code === 'string' && /^[A-Z_]+$/.test(code) ? code : 'API_ERROR',
    );
  }
  return data;
}

export function projectId() {
  const project = process.env.FIREBASE_PROJECT_ID ?? '';
  if (!/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(project)) {
    throw new Error('Set FIREBASE_PROJECT_ID.');
  }
  return project;
}

export async function getCrashReport(days, request = firebaseRequest) {
  const appId = process.env.FIREBASE_ANDROID_APP_ID ?? '';
  const app = /^1:(\d+):android:[a-f0-9]+$/.exec(appId);
  if (!app) throw new Error('Set FIREBASE_ANDROID_APP_ID.');
  const url = new URL(`https://firebasecrashlytics.googleapis.com/v1alpha/projects/${app[1]}/apps/${appId}/reports/topIssues`);
  const end = new Date();
  const start = new Date(end.getTime() - days * 86400000);
  url.searchParams.set('filter.interval.startTime', start.toISOString());
  url.searchParams.set('filter.interval.endTime', end.toISOString());
  url.searchParams.set('pageSize', '50');
  const report = await request(url);
  const issues = (report.groups ?? []).map(({ issue, metrics }) => ({
    id: issue?.name?.split('/').at(-1) ?? '',
    title: issue?.title ?? 'Lỗi chưa có tiêu đề',
    type: issue?.errorType ?? 'UNKNOWN',
    events: metrics?.[0]?.eventsCount ?? null,
    users: metrics?.[0]?.impactedUsersCount ?? null,
  }));
  return {
    source: 'Firebase Crashlytics',
    start: start.toISOString(),
    end: end.toISOString(),
    issues,
    moreAvailable: Boolean(report.nextPageToken),
  };
}
