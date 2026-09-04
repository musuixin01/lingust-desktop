/**
 * 通用网络请求客户端封装
 */

export class ApiError extends Error {
  constructor(public status: number, message: string, public data?: any) {
    super(message);
    this.name = 'ApiError';
  }
}

export async function request<T>(url: string, options: RequestInit = {}): Promise<T> {
  const headers = new Headers(options.headers || {});
  if (!headers.has('Content-Type') && !(options.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  // If running via file:// protocol in packaged Electron, route relative /api requests to local Express server
  let targetUrl = url;
  if (typeof window !== 'undefined' && window.location?.protocol === 'file:' && url.startsWith('/api/')) {
    targetUrl = `http://127.0.0.1:3000${url}`;
  }

  const response = await fetch(targetUrl, {
    ...options,
    headers,
  });

  const contentType = response.headers.get('content-type');
  const isJson = contentType && contentType.includes('application/json');
  const data = isJson ? await response.json() : await response.text();

  if (!response.ok) {
    const errorMessage =
      (typeof data === 'object' && data !== null && (data.error || data.message)) ||
      response.statusText ||
      '网络请求失败';
    throw new ApiError(response.status, errorMessage, data);
  }

  return data as T;
}
