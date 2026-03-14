# Kapda Junction – Step-by-Step Deploy Guide

**Stack:** Backend (Vercel) + Frontend (Netlify) + MongoDB Atlas + Cloudinary

---

## Pehle ye karo (one-time setup)

### 1. MongoDB Atlas (Database)

1. Browser mein jao: **https://www.mongodb.com/atlas**
2. **Try Free** → Sign up (Google/Email)
3. **Create** → **M0 Free** cluster select karo → Region choose karo → **Create**
4. **Security Quickstart:**
   - Username + Password set karo (yaad rakhna)
   - **Create Database User**
5. **Where would you like to connect from?** → **My Local Environment** → **Add IP Address** → **Allow Access from Anywhere** (0.0.0.0/0) → **Finish**
6. **Connect** → **Drivers** → Connection string copy karo  
   Example: `mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/`
7. End mein database name add karo: `mongodb+srv://...mongodb.net/kapda_junction`

---

### 2. Cloudinary (Images)

1. **https://cloudinary.com** → Sign up (free)
2. **Dashboard** → **Account Details** se copy karo:
   - Cloud name
   - API Key
   - API Secret

---

## Backend deploy (Vercel)

### Step 1: Code GitHub pe push karo

```bash
cd /Users/paragjain/iesparag_github/kapda_junction
git init
git add .
git commit -m "Initial deploy"
git branch -M main
git remote add origin https://github.com/kapda-junction/kapda_junction.git
git push -u origin main
```

(Agar repo pehle se hai to sirf `git push` karo.)

---

### Step 2: Vercel pe backend deploy

1. **https://vercel.com** → **Sign Up** (GitHub se)
2. **Add New** → **Project**
3. **Import** → `kapda_junction` repo select karo
4. **Configure Project:**
   - **Root Directory:** `backend_kapda_junction` (Edit → type karo)
   - **Framework Preset:** Other
   - **Build Command:** (khali chhod do)
   - **Output Directory:** (khali chhod do)

5. **Environment Variables** → **Add:**
   | Name | Value |
   |------|-------|
   | `MONGODB_URI` | `mongodb+srv://user:pass@cluster.xxx.mongodb.net/kapda_junction` |
   | `JWT_SECRET` | koi bhi random 32+ char string (e.g. `kapda_junction_secret_key_2024`) |
   | `CLOUDINARY_CLOUD_NAME` | apna cloud name |
   | `CLOUDINARY_API_KEY` | apna API key |
   | `CLOUDINARY_API_SECRET` | apna API secret |
   | `CORS_ORIGIN` | `https://*.netlify.app` (pehle ye daal do, baad mein update) |
   | `NODE_ENV` | `production` |

6. **Deploy** click karo
7. Deploy hone ke baad URL copy karo, jaise: `https://kapda-junction-api-xxx.vercel.app`
8. **API URL:** `https://YOUR-PROJECT.vercel.app/api` (end mein `/api` add karo)

---

## Frontend update (API URL set karo)

Vercel backend URL milne ke baad ye files edit karo:

**File 1:** `web_kapda_junction/src/environments/environment.prod.ts`

```ts
export const environment = {
  production: true,
  apiUrl: 'https://YOUR-VERCEL-URL.vercel.app/api',
  shareBaseUrl: 'https://YOUR-CUSTOMER-SITE.netlify.app'
};
```

**File 2:** `web_admin_kapda_junction/src/environments/environment.prod.ts`

```ts
export const environment = {
  production: true,
  apiUrl: 'https://YOUR-VERCEL-URL.vercel.app/api'
};
```

`YOUR-VERCEL-URL` ko apne Vercel URL se replace karo (e.g. `kapda-junction-api-xxx`).  
`shareBaseUrl` ko pehle placeholder rakh sakte ho, Netlify deploy ke baad update karo.

---

## Frontend deploy (Netlify)

### Step 1: Customer site

1. **https://netlify.com** → **Sign up** (GitHub)
2. **Add new site** → **Import an existing project**
3. **GitHub** → `kapda_junction` repo select karo
4. **Configure build settings:**
   - **Base directory:** `web_kapda_junction`
   - **Build command:** `npm run build`
   - **Publish directory:** `dist/web-kapda-junction/browser`

5. **Deploy site** click karo
6. Deploy hone ke baad URL copy karo, jaise: `https://random-name-123.netlify.app`

---

### Step 2: Admin panel

1. **Add new site** → **Import an existing project** → same repo
2. **Configure:**
   - **Base directory:** `web_admin_kapda_junction`
   - **Build command:** `npm run build`
   - **Publish directory:** `dist/web-admin-kapda-junction/browser`

3. **Deploy site** click karo
4. Admin URL copy karo

---

## Step 3: CORS update

Netlify URLs milne ke baad ye karo:

1. **Vercel** → apna backend project → **Settings** → **Environment Variables**
2. `CORS_ORIGIN` edit karo:
   ```
   https://YOUR-CUSTOMER-SITE.netlify.app,https://YOUR-ADMIN-SITE.netlify.app
   ```
3. **Save** → **Redeploy** (Deployments → Redeploy)

---

## Step 4: shareBaseUrl update (optional)

Customer site deploy hone ke baad:

1. `web_kapda_junction/src/environments/environment.prod.ts` mein `shareBaseUrl` ko apne Netlify customer URL se replace karo
2. Commit + push karo

---

## Final URLs

| Part | URL |
|------|-----|
| Customer | `https://xxx.netlify.app` |
| Admin | `https://yyy.netlify.app` |
| API | `https://zzz.vercel.app/api` |

---

## Admin user create karo

Pehli baar admin login ke liye:

1. MongoDB Atlas → **Browse Collections** → `kapda_junction` → `users`
2. **Add Document** → manually insert karo (ya seed script run karo locally, phir DB se copy)

Ya seed script run karo (backend pe deploy nahi hai, seed sirf local MongoDB pe chalega):

```bash
cd backend_kapda_junction
# .env mein MONGODB_URI set karo (production URL)
npm run seed
```

---

### API 5+ second pe load ho rahi hai?

Vercel serverless **cold start** ki wajah se pehla request slow hota hai (3–6 sec). Backend 1–2 min idle rehne ke baad so jata hai, phir next request pe dubara boot hota hai.

**Tez karne ke tarike:**

1. **Keep-alive cron (recommended):** [cron-job.org](https://cron-job.org) (free) par job banao jo har 5 min pe `GET https://YOUR-VERCEL-URL.vercel.app/api/health` hit kare. Backend warm rahega, cold start kam hoga.

2. **Backend Render pe shift karo:** Always-on server = cold start nahi. Neeche "Backend Render pe" section dekho.

3. **MongoDB region:** Atlas cluster ko Vercel ke region ke kareeb rakhna (e.g. dono US East) – connection faster hoga.

---

## Troubleshooting

| Problem | Solution |
|--------|----------|
| **CORS error** | Vercel pe CORS_ORIGIN mein Netlify URLs add karo |
| **API 404** | Frontend mein `apiUrl` sahi hai? `/api` end mein hai? |
| **Build fail** | Netlify pe Base directory + Publish directory check karo |
| **DB connection failed** | MONGODB_URI sahi hai? Atlas mein IP 0.0.0.0/0 allow hai? |
| **Vercel 500 / FUNCTION_INVOCATION_FAILED** | Neeche dekho ↓ |
| **API 5+ sec load (landing / products)** | Neeche "API slow" dekho ↓ |

---

### API 5 second slow – Cold Start (Vercel)

Agar landing page ya products API pe **5–6 second** lag raha ho:

**Reason:** Vercel serverless = **cold start**. Koi request na aaye 1–2 min to function so jata hai. First request pe:
- Node.js boot
- MongoDB connect (2–3 sec)
- Query run

**Solution (choose one):**

1. **Keep warm with cron (recommended):**  
   - [cron-job.org](https://cron-job.org) (free) pe signup
   - New cron: `GET https://YOUR-API.vercel.app/api/health` every **5 minutes**
   - Result: Function sleep nahi karega, first load fast rahega

2. **Backend Render pe move karo:**  
   - Render **always-on** hai (free tier bhi)
   - Cold start nahi, API ~500ms–1s mein aayegi  
   - Steps upar "Backend Render pe" section mein hai

3. **MongoDB region:**  
   - Atlas cluster ka region Vercel region ke kareeb rakho (e.g. Mumbai → Singapore)

---

### Vercel 500 crash fix

Agar backend pe **500: INTERNAL_SERVER_ERROR** ya **FUNCTION_INVOCATION_FAILED** aa raha ho:

1. **Vercel Logs check karo:**  
   Project → Deployments → Latest → **Functions** → Logs (exact error dekhne ke liye)

2. **Env vars:** `MONGODB_URI`, `JWT_SECRET`, `CLOUDINARY_*` sab set hai?

3. **Agar ab bhi fail ho:** Backend **Render** pe shift karo (serverless limitations ke liye better hai)

---

### API 5+ second load (landing / products slow)

**Cause:** Vercel serverless = **cold start**. Jab koi request nahi aati (30–60 sec), function so jata hai. Next request pe:
- Node.js runtime boot
- MongoDB connection (2–4 sec)
- Query run

**Fix 1 – Keep warm (free):** Cron se har 5 min `/api/health` hit karo:
- **cron-job.org** (free) → Create → URL: `https://YOUR-VERCEL-URL.vercel.app/api/health` → Interval: 5 min
- Ya **UptimeRobot** use karo (free monitoring + ping)

**Fix 2 – Always-on backend:** Backend ko **Render** pe shift karo (free tier bhi always-on). Cold start nahi hoga, landing API ~200–500ms mein load hogi.

---

### Backend Render pe (Vercel fail hone par)

1. **https://render.com** → Sign up (GitHub)
2. **New** → **Web Service**
3. Repo select karo
4. Settings:
   - **Root Directory:** `backend_kapda_junction`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Instance:** Free
5. **Environment Variables** same daalo: MONGODB_URI, JWT_SECRET, CLOUDINARY_*, CORS_ORIGIN
6. Deploy → URL milega: `https://kapda-junction-api.onrender.com`
7. Frontend `environment.prod.ts` mein API URL update karo:  
   `https://kapda-junction-api.onrender.com/api`
