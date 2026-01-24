# RedwoodSDK Hosting on Cloudflare

Deploy and host your RedwoodSDK applications on Cloudflare's Developer Platform.

## Overview

Cloudflare's Developer Platform provides comprehensive services:

- **Compute** (Workers) - Serverless functions at the edge
- **Database** (D1) - SQL database
- **Storage** (R2) - Object storage for files and assets
- **Queues** - Background job processing
- **KV** - Key-value store
- **Durable Objects** - Stateful coordination

Benefits:
- **World-class network**: Global edge locations
- **Best developer experience**: Local dev mirrors production
- **"It just works"**: Seamless local-to-production workflow

## Deploy to Production

Ship your webapp to Cloudflare with one command:

```bash
pnpm release
```

The CLI will ask: **Do you want to proceed with deployment? (y/N):**

Type `y` and press Enter.

### View Your Deployment

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Click **Workers & Pages** in left sidebar
3. Find your application in the list
4. Click the **Visit** link to see it live

## Deploy to Staging

Use environment-specific deployments with `CLOUDFLARE_ENV`:

```bash
CLOUDFLARE_ENV=staging pnpm release
```

This loads configuration from `wrangler.jsonc` under `env.staging`.

### Configure Staging Environment

```jsonc
// wrangler.jsonc
{
  "name": "my-app",
  "main": "./dist/worker.mjs",
  "compatibility_date": "2024-10-21",
  "env": {
    "staging": {
      "vars": {
        "APP_BASE_URL": "https://staging.example.com",
        "ENVIRONMENT": "staging"
      },
      "routes": [
        {
          "pattern": "staging.example.com/*",
          "custom_domain": true
        }
      ]
    }
  }
}
```

The terminal shows the staging Worker URL after deployment. View it in the Cloudflare dashboard under Workers & Pages.

## Custom Domain Names

### Prerequisites

You need a domain name either:
1. **Purchased through Cloudflare**, or
2. **Added to Cloudflare** (if purchased elsewhere)

Skip to [Hooking Up Your Domain](#hooking-up-your-domain-name-to-your-project) if you already have an active domain on Cloudflare.

### Purchase a New Domain

1. Go to [Cloudflare's Domain Registrar](https://domains.cloudflare.com/)
2. Search for your desired domain name
3. If available, purchase it
4. Domain automatically added to your Cloudflare account

### Add an Existing Domain

**Don't worry about breaking things**: Cloudflare automatically imports existing DNS records, so email and other services continue working.

#### Steps:

1. Go to Cloudflare Dashboard
2. Click **+ Add a domain**
3. Enter your domain name
4. Keep "Quick scan for DNS records" checked
5. Click **Continue**
6. Select a plan (Free plan is perfect for most use cases)
7. Click **Select plan**
8. Review imported DNS records
9. Click **Continue to activation**

#### Update Nameservers

Cloudflare provides nameservers you must set at your registrar:

Common registrar instructions:
- [Porkbun](https://kb.porkbun.com/article/22-how-to-change-your-nameservers)
- [Namecheap](https://www.namecheap.com/support/knowledgebase/article.aspx/767/10/how-to-change-dns-for-a-domain/)
- [GoDaddy](https://www.godaddy.com/help/edit-my-domain-nameservers-664)
- [More registrars](https://developers.cloudflare.com/dns/nameservers/update-nameservers/#your-domain-uses-a-different-registrar)

After updating nameservers:
1. Go back to Cloudflare
2. Click **Continue**
3. (Optional) Click **Check nameservers now** to verify immediately
4. Wait for email confirmation

### Hooking Up Your Domain Name to Your Project

1. Go to **Workers & Pages**
2. Click your project name
3. Go to **Settings** tab
4. Find **Domains & Routes** section
5. Click **+ Add** button
6. Click **Custom Domain** option
7. Enter your domain name
8. Click **Add domain**

Your project is now live at your custom domain!

## Deployment Workflow

### Pre-Deployment Checklist

Before deploying:

- [ ] Database migrations applied locally: `pnpm migrate:dev`
- [ ] Types generated: `pnpm generate`
- [ ] Type check passes: `pnpm types`
- [ ] Build succeeds: `pnpm build`
- [ ] Tests pass (if applicable)
- [ ] Environment variables/secrets set

### First-Time Production Setup

```bash
# 1. Apply migrations to production D1
pnpm migrate:prd

# 2. Seed database (if needed)
pnpm seed:prd

# 3. Set production secrets
wrangler secret put SECRET_KEY
wrangler secret put WEBAUTHN_RP_ID

# 4. Deploy
pnpm release
```

### Subsequent Deployments

```bash
# 1. Apply new migrations (if any)
pnpm migrate:prd

# 2. Deploy
pnpm release
```

## Environment-Specific Deployments

### Development (Local)

```bash
pnpm dev
```

Uses `.env` file for environment variables.

### Staging

```bash
# Set staging secrets
wrangler secret put DATABASE_URL --env staging
wrangler secret put API_KEY --env staging

# Deploy to staging
CLOUDFLARE_ENV=staging pnpm release
```

### Production

```bash
# Set production secrets
wrangler secret put DATABASE_URL --env production
wrangler secret put API_KEY --env production

# Deploy to production
pnpm release
# or explicitly:
CLOUDFLARE_ENV=production pnpm release
```

## Managing Workers

### View Worker Details

1. Dashboard → **Workers & Pages**
2. Click worker name
3. View:
   - **Deployment history**
   - **Metrics** (requests, errors, CPU time)
   - **Settings** (environment variables, triggers)
   - **Logs** (real-time logs)

### View Logs

```bash
# Tail logs in real-time
wrangler tail

# Tail specific environment
wrangler tail --env staging
```

Or in dashboard:
1. Workers & Pages → Your worker
2. **Logs** tab
3. View real-time logs

### Rollback Deployment

1. Dashboard → Workers & Pages → Your worker
2. **Deployments** tab
3. Find previous deployment
4. Click **···** menu
5. Click **Rollback to this deployment**

## Deleting a Project

1. Go to **Workers & Pages**
2. Click your project name
3. Go to **Settings** tab
4. Scroll to bottom
5. Click **Delete** button
6. Type project name to confirm
7. Click **Delete**

## Multiple Environments Pattern

Organize deployments with clear naming:

```jsonc
// wrangler.jsonc
{
  "name": "my-app-production",
  "env": {
    "staging": {
      "name": "my-app-staging",
      "vars": {
        "ENVIRONMENT": "staging"
      }
    },
    "preview": {
      "name": "my-app-preview",
      "vars": {
        "ENVIRONMENT": "preview"
      }
    }
  }
}
```

Deploy:
```bash
# Production
pnpm release

# Staging
CLOUDFLARE_ENV=staging pnpm release

# Preview
CLOUDFLARE_ENV=preview pnpm release
```

## Monitoring and Analytics

### View Metrics

Dashboard → Workers & Pages → Your worker → **Metrics**

See:
- Requests per second
- Error rate
- CPU time
- Duration (p50, p99)
- Bandwidth usage

### Set Up Alerts

1. Dashboard → **Notifications**
2. Click **Add**
3. Choose **Workers** alert type
4. Configure thresholds
5. Set notification destinations (email, webhook, PagerDuty, etc.)

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/deploy.yml
name: Deploy to Cloudflare

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Build
        run: npm run build

      - name: Deploy to Cloudflare
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          command: deploy
```

### Staging + Production Pipeline

```yaml
name: Deploy

on:
  push:
    branches:
      - main        # Deploy to production
      - staging     # Deploy to staging

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - run: npm install
      - run: npm run build

      - name: Deploy to Staging
        if: github.ref == 'refs/heads/staging'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          command: deploy
        env:
          CLOUDFLARE_ENV: staging

      - name: Deploy to Production
        if: github.ref == 'refs/heads/main'
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          command: deploy
```

## Best Practices

1. **Test locally first**: Always test with `pnpm dev` before deploying
2. **Use staging**: Test in staging before production
3. **Database migrations**: Apply migrations before deploying code changes
4. **Environment-specific secrets**: Use different secrets for staging/production
5. **Monitor deployments**: Watch logs after deploying for errors
6. **Gradual rollouts**: Use staging to validate changes
7. **Version control**: Tag releases in git
8. **Document deployments**: Keep changelog or deployment notes
9. **Set up alerts**: Get notified of errors or high usage
10. **Regular backups**: Export D1 database regularly

## Troubleshooting

### "Module not found" Errors

Ensure build output is correct in `wrangler.jsonc`:

```jsonc
{
  "main": "./dist/worker.mjs"
}
```

Run `pnpm build` before deploying.

### Environment Variables Not Working

1. Check secrets are set:
   ```bash
   wrangler secret list
   ```

2. Verify `wrangler.jsonc` vars config

3. Run `pnpm generate` after changes

### Database Errors in Production

1. Apply migrations:
   ```bash
   pnpm migrate:prd
   ```

2. Check D1 binding in `wrangler.jsonc`

3. Verify database exists in Cloudflare dashboard

### Custom Domain Not Working

1. Verify domain added to Cloudflare
2. Check DNS records are proxied (orange cloud)
3. Wait for DNS propagation (up to 24h, usually minutes)
4. Check domain in **Domains & Routes** settings

## Further Reading

- [Cloudflare Workers](https://developers.cloudflare.com/workers/)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)
- [Custom Domains](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/)
- [Environments](https://developers.cloudflare.com/workers/wrangler/environments/)
- [CI/CD](https://developers.cloudflare.com/workers/ci-cd/)
