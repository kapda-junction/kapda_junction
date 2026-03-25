# Kapda Junction - Vercel Deploy Guide

## Customer App (web_kapda_junction)

1. **Vercel Dashboard** → New Project → Import Git repo
2. **Root Directory:** `web_kapda_junction`
3. **Framework Preset:** Other (या Angular - Vercel auto-detect करेगा)
4. **Build Command:** `npm run build` (auto from vercel.json)
5. **Output Directory:** `dist/web-kapda-junction/browser` (auto from vercel.json)
6. **Environment Variables:** (optional, env files already have prod API URL)
   - Production API: already in `environment.prod.ts` → `https://kapda-junction-api.onrender.com/api`
7. Deploy

**URL:** `kapda-junction-customer.vercel.app` (या आपका custom domain)

---

## Admin App (web_admin_kapda_junction)

1. **Vercel Dashboard** → New Project → Same repo (या duplicate)
2. **Root Directory:** `web_admin_kapda_junction`
3. **Build Command:** `npm run build`
4. **Output Directory:** `dist/web-admin-kapda-junction/browser`
5. Deploy

**URL:** `kapda-junction-admin.vercel.app`

---

## Quick Summary

| App | Root Directory | Output |
|-----|----------------|--------|
| Customer | `web_kapda_junction` | `dist/web-kapda-junction/browser` |
| Admin | `web_admin_kapda_junction` | `dist/web-admin-kapda-junction/browser` |

दोनों SPAs – `vercel.json` में rewrites सब routes को `index.html` पर भेजता है।

---

## Backend (Optional – Render pe hai)

Backend पहले से Render पर deploy है: `https://kapda-junction-api.onrender.com`

CORS में दोनों Vercel URLs add करो (Backend `.env` / Render env vars):
```
CORS_ORIGIN=https://your-customer.vercel.app,https://your-admin.vercel.app
```
