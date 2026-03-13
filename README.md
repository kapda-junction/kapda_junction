# Kapda Junction – Men's Wear E‑commerce

Scalable full‑stack setup: Node.js backend (MVC), Angular Admin + Customer apps with NgRx state management.

## Structure

```
kapda_junction/
├── backend_kapda_junction/   # Node.js + Express MVC API
├── web_admin_kapda_junction/ # Angular Admin (port 4201)
├── web_kapda_junction/       # Angular Customer (port 4200)
└── package.json              # Root scripts
```

## Setup (ek baar)

### 1. MongoDB password

`backend_kapda_junction/.env` mein apna password daalo:

```
DB_PASSWORD=YOUR_MONGODB_PASSWORD
```

Connection string: `mongodb+srv://kapdajunction:<password>@cluster0.o2gaoxi.mongodb.net/`

### 2. Install & run

```bash
npm run install:all
npm run dev
```

- Backend API: http://localhost:3000  
- Admin: http://localhost:4201  
- Customer: http://localhost:4200  

## Backend (MVC)

- **Models**: User, Product, Category, Order  
- **Controllers**: auth, product, category, order  
- **Services**: business logic separate from controllers  
- **Routes**: `/api/auth`, `/api/products`, `/api/categories`, `/api/orders`  

## Angular Apps (NgRx)

- **Admin**: login, dashboard, products, categories, orders  
- **Customer**: product list, detail, cart (NgRx store)  
- **State**: NgRx Store + Effects  

## Seed data

```bash
cd backend_kapda_junction
npm run seed
```

(Seed script add karo agar data chahiye.)
