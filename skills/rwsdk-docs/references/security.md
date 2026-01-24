# RedwoodSDK Security Headers

Configure security headers and Content Security Policy (CSP) for your application.

## Overview

Security headers protect your application from common attacks like cross-site scripting (XSS), clickjacking, and data injection. RedwoodSDK makes it easy to add these headers using middleware.

## Basic Security Headers

Create a middleware file to set common security headers:

```typescript
// src/app/headers.ts
import type { RouteMiddleware } from "rwsdk/worker";

export const setCommonHeaders =
  (): RouteMiddleware =>
  ({ response, rw: { nonce } }) => {
    const headers = response.headers;

    headers.set("X-Frame-Options", "DENY");
    headers.set("X-Content-Type-Options", "nosniff");
    headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
    headers.set(
      "Content-Security-Policy",
      `default-src 'self'; script-src 'self' 'nonce-${nonce}'; style-src 'self' 'unsafe-inline'; object-src 'none';`
    );
    headers.set(
      "Permissions-Policy",
      "geolocation=(), microphone=(), camera=()"
    );
  };
```

Apply in your worker:

```typescript
// src/worker.tsx
import { defineApp } from "rwsdk/worker";
import { setCommonHeaders } from "./app/headers";

export default defineApp([
  setCommonHeaders(),
  // Your routes...
]);
```

## Security Headers Explained

### X-Frame-Options

Prevents clickjacking by controlling iframe embedding:

```typescript
headers.set("X-Frame-Options", "DENY");          // No iframes allowed
headers.set("X-Frame-Options", "SAMEORIGIN");    // Only same-origin iframes
```

### X-Content-Type-Options

Prevents MIME-type sniffing:

```typescript
headers.set("X-Content-Type-Options", "nosniff");
```

### Referrer-Policy

Controls referrer information sent with requests:

```typescript
headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
```

Options:
- `no-referrer` - Never send referrer
- `strict-origin-when-cross-origin` - Send origin for cross-origin, full URL for same-origin
- `same-origin` - Only send for same-origin requests

### Permissions-Policy

Controls browser feature access:

```typescript
headers.set(
  "Permissions-Policy",
  "geolocation=(), microphone=(), camera=()"
);
```

## Content Security Policy (CSP)

CSP controls what resources can be loaded and executed.

### Default Configuration

```typescript
headers.set(
  "Content-Security-Policy",
  `default-src 'self'; script-src 'self' 'nonce-${nonce}'; style-src 'self' 'unsafe-inline'; object-src 'none';`
);
```

Breakdown:
- `default-src 'self'` - Only load resources from same origin
- `script-src 'self' 'nonce-${nonce}'` - Scripts from same origin or with nonce
- `style-src 'self' 'unsafe-inline'` - Styles from same origin or inline
- `object-src 'none'` - No plugins (Flash, etc.)

### Adding Trusted Domains

Allow resources from specific external domains:

```typescript
headers.set(
  "Content-Security-Policy",
  `default-src 'self'; ` +
  `script-src 'self' 'nonce-${nonce}' https://trusted-scripts.example.com; ` +
  `style-src 'self' 'unsafe-inline'; ` +
  `img-src 'self' https://images.example.com; ` +
  `object-src 'none';`
);
```

### Allowing Images from Multiple Sources

```typescript
headers.set(
  "Content-Security-Policy",
  `default-src 'self'; ` +
  `script-src 'self' 'nonce-${nonce}'; ` +
  `style-src 'self' 'unsafe-inline'; ` +
  `img-src 'self' https://trusted-images.com https://cdn.example.com data:; ` +
  `object-src 'none';`
);
```

The `data:` directive allows base64-encoded data URIs.

**Warning**: Be cautious with `data:` URIs as they can significantly increase HTML size.

### Common CSP Directives

- `default-src` - Fallback for other directives
- `script-src` - JavaScript sources
- `style-src` - CSS sources
- `img-src` - Image sources
- `font-src` - Font sources
- `connect-src` - AJAX, WebSocket, fetch sources
- `media-src` - Audio/video sources
- `frame-src` - iframe sources
- `object-src` - Plugin sources
- `base-uri` - Base tag URLs
- `form-action` - Form submission targets

## Using Nonces for Inline Scripts

RedwoodSDK automatically generates a cryptographically secure nonce for each request. Access it via `rw.nonce` in Document or page components:

```tsx
export const Document = ({ rw, children }) => (
  <html lang="en">
    <head>
      <title>My App</title>
    </head>
    <body>
      <div id="root">{children}</div>

      {/* Inline script with nonce */}
      <script nonce={rw.nonce}>
        {`
          console.log('Inline script with nonce');
          window.APP_CONFIG = { apiUrl: '/api' };
        `}
      </script>
    </body>
  </html>
);
```

**Warning**: Only use nonces for trusted inline scripts you control. Never add nonces to third-party or user-generated scripts.

## Permissions Policy

Control device and browser feature access.

### Default (Restrictive)

```typescript
headers.set(
  "Permissions-Policy",
  "geolocation=(), microphone=(), camera=()"
);
```

This blocks all device access.

### Allow for Same Origin

```typescript
headers.set(
  "Permissions-Policy",
  "geolocation=self, microphone=self, camera=self"
);
```

### Allow for Specific Domains

```typescript
headers.set(
  "Permissions-Policy",
  "camera=(self 'https://trusted-video-app.com'), " +
  "microphone=(self 'https://trusted-video-app.com'), " +
  "geolocation=self"
);
```

### Common Features

- `geolocation` - GPS location
- `microphone` - Audio input
- `camera` - Video input
- `payment` - Payment Request API
- `usb` - USB devices
- `accelerometer` - Device motion
- `gyroscope` - Device orientation
- `magnetometer` - Device compass
- `fullscreen` - Fullscreen mode

## Complete Example

Full security headers middleware with comments:

```typescript
// src/app/headers.ts
import type { RouteMiddleware } from "rwsdk/worker";

export const setCommonHeaders =
  (): RouteMiddleware =>
  ({ response, rw: { nonce } }) => {
    const headers = response.headers;

    // Prevent clickjacking
    headers.set("X-Frame-Options", "DENY");

    // Prevent MIME-type sniffing
    headers.set("X-Content-Type-Options", "nosniff");

    // Control referrer information
    headers.set("Referrer-Policy", "strict-origin-when-cross-origin");

    // Content Security Policy
    headers.set(
      "Content-Security-Policy",
      [
        "default-src 'self'",
        `script-src 'self' 'nonce-${nonce}' https://trusted-cdn.com`,
        "style-src 'self' 'unsafe-inline'",
        "img-src 'self' https://images.example.com data:",
        "font-src 'self' https://fonts.googleapis.com",
        "connect-src 'self' https://api.example.com",
        "frame-ancestors 'none'",
        "base-uri 'self'",
        "form-action 'self'",
        "object-src 'none'",
      ].join("; ")
    );

    // Restrict device permissions
    headers.set(
      "Permissions-Policy",
      [
        "geolocation=()",
        "microphone=()",
        "camera=()",
        "payment=()",
        "usb=()",
      ].join(", ")
    );

    // Strict Transport Security (HTTPS only, production)
    if (process.env.NODE_ENV === "production") {
      headers.set(
        "Strict-Transport-Security",
        "max-age=63072000; includeSubDomains; preload"
      );
    }
  };
```

## Environment-Specific Headers

Different headers for development vs production:

```typescript
export const setCommonHeaders =
  (): RouteMiddleware =>
  ({ response, rw: { nonce }, request }) => {
    const headers = response.headers;
    const isDev = new URL(request.url).hostname === "localhost";

    // Relaxed CSP for development
    const csp = isDev
      ? `default-src 'self' 'unsafe-inline' 'unsafe-eval'; script-src 'self' 'unsafe-inline' 'unsafe-eval';`
      : `default-src 'self'; script-src 'self' 'nonce-${nonce}'; style-src 'self' 'unsafe-inline'; object-src 'none';`;

    headers.set("Content-Security-Policy", csp);

    // Other headers...
  };
```

## Best Practices

1. **Start strict, relax as needed**: Begin with restrictive policies and open up only when necessary
2. **Use nonces for inline scripts**: Avoid `'unsafe-inline'` for scripts when possible
3. **Test thoroughly**: Verify all features work after adding CSP
4. **Monitor CSP violations**: Use `report-uri` directive to track violations
5. **Different policies per environment**: Use stricter policies in production
6. **Document exceptions**: Comment why specific domains are whitelisted
7. **Regular audits**: Review and update security headers periodically
8. **Understand tradeoffs**: Balance security with functionality needs

## Common Issues

### Images Not Loading

Add `img-src` directive:

```typescript
"img-src 'self' https://your-cdn.com data:"
```

### Third-party Scripts Blocked

Add domain to `script-src`:

```typescript
`script-src 'self' 'nonce-${nonce}' https://analytics.example.com`
```

### Styles Not Applying

Ensure `'unsafe-inline'` in `style-src` or use nonces for inline styles:

```typescript
"style-src 'self' 'unsafe-inline'"
```

### API Requests Blocked

Add API domain to `connect-src`:

```typescript
"connect-src 'self' https://api.example.com"
```

## Further Reading

- [MDN Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)
- [MDN Permissions Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Permissions-Policy)
- [CSP Evaluator](https://csp-evaluator.withgoogle.com/)
- [Security Headers Checker](https://securityheaders.com/)
