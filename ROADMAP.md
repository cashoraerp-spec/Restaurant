# 🍽️ Cashora Restaurant Management System — ROADMAP

> **نظام إدارة مطاعم متكامل | Multi-Branch · Dynamic Settings · Full POS**
> Version: 1.0 | Status: In Progress
> Stack: Django 5 (Backend) · Django Channels (Real-time) · Next.js 14 (Frontend)
> Build Order: **Backend → API → Frontend**

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Core Architecture](#core-architecture)
3. [Dynamic Settings System](#dynamic-settings-system)
4. [Module Breakdown](#module-breakdown)
5. [Implementation Phases](#implementation-phases)
6. [Database Schema Overview](#database-schema-overview)
7. [API Structure](#api-structure)
8. [UI Interfaces](#ui-interfaces)

---

## Project Overview

**Cashora** is a comprehensive, fully dynamic multi-branch restaurant management system.

### Service Types
| Type | Arabic | Description |
|------|--------|-------------|
| Dine-In | صالة | Table-based ordering with table map |
| Delivery | دليفري | Delivery zone pricing, driver assignment & tracking |
| Takeaway | تاك أواي | Counter pickup orders |

### User Roles
| Role | Arabic | Access Level |
|------|--------|-------------|
| Super Admin | سوبر أدمن | Full system + multi-branch |
| Branch Admin | أدمن الفرع | Full access to one branch |
| Accountant | محاسب | Reports, shifts, payments |
| Cashier | كاشير | POS, orders, print |
| Kitchen Staff | موظف مطبخ | KDS view only |
| Delivery Driver | طيار | Assigned orders, status update |

---

## Core Architecture

```
cashora-restaurant/
│
├── backend/                          # ① Django Project (Build First)
│   ├── config/                       # Settings, URLs, ASGI
│   │   ├── settings/
│   │   │   ├── base.py
│   │   │   ├── development.py
│   │   │   └── production.py
│   │   ├── urls.py
│   │   └── asgi.py                   # Django Channels entry
│   │
│   ├── apps/                         # Django Apps (one per module)
│   │   ├── core/                     # Shared models, mixins, utils
│   │   ├── tenants/                  # Tenant/system management
│   │   ├── branches/                 # Multi-branch management
│   │   ├── settings_engine/          # Dynamic settings (all config)
│   │   ├── users/                    # Users, RBAC, PIN auth
│   │   ├── menu/                     # Categories, items, modifiers
│   │   ├── kitchens/                 # Multi-kitchen routing
│   │   ├── tables/                   # Tables & hall map
│   │   ├── orders/                   # Full order lifecycle
│   │   ├── payments/                 # Payments, discounts, refunds
│   │   ├── shifts/                   # Shift management
│   │   ├── delivery/                 # Zones, drivers, tracking
│   │   ├── reports/                  # All reporting
│   │   ├── printing/                 # Print templates & ESC/POS
│   │   └── audit/                    # Audit log
│   │
│   ├── channels_consumers/           # WebSocket consumers
│   │   ├── kitchen_consumer.py       # KDS real-time
│   │   ├── pos_consumer.py           # POS real-time
│   │   ├── delivery_consumer.py      # Delivery tracking
│   │   └── routing.py
│   │
│   ├── tasks/                        # Celery background tasks
│   │   ├── print_tasks.py
│   │   ├── report_tasks.py
│   │   └── shift_tasks.py
│   │
│   ├── manage.py
│   ├── requirements/
│   │   ├── base.txt
│   │   ├── development.txt
│   │   └── production.txt
│   └── .env.example
│
├── frontend/                         # ② Next.js App (Build After API)
│   ├── app/
│   │   ├── (auth)/                   # Login, PIN screen
│   │   ├── (cashier)/                # Cashier POS
│   │   ├── (admin)/                  # Admin panel
│   │   ├── (accountant)/             # Accountant dashboard
│   │   ├── (kitchen)/                # KDS display
│   │   └── (driver)/                 # Driver PWA
│   ├── components/
│   ├── lib/api/                      # Axios client → Django API
│   ├── lib/ws/                       # WebSocket → Django Channels
│   ├── stores/                       # Zustand state stores
│   └── messages/                     # i18n (ar.json, en.json)
│
├── nginx/                            # Reverse proxy config
├── docker-compose.yml
├── ROADMAP.md                        # This file
└── TECH_STACK.md                     # Technology documentation
```

---

## Dynamic Settings System

> **المبدأ**: كل قيمة قابلة للتغيير من الإعدادات — لا شيء hardcoded.

### Settings Scope (Hierarchy)
```
System Level (Super Admin)
  └── Branch Level (Branch Admin)
        └── Shift Level (auto-inherited)
```

### Settings Categories

#### 💰 Financial Settings (إعدادات مالية)
| Setting | Key | Type | Default | Example |
|---------|-----|------|---------|---------|
| VAT/Tax Rate | `tax_rate` | `percentage` | `0` | `14%` |
| Tax Display Name | `tax_label` | `string` | `"VAT"` | `"ضريبة القيمة المضافة"` |
| Tax Inclusive/Exclusive | `tax_type` | `enum` | `exclusive` | |
| Service Charge | `service_charge_rate` | `percentage` | `0` | `12%` |
| Service Charge Applies To | `service_charge_scope` | `enum` | `dine_in` | `all / dine_in / none` |
| Currency | `currency_code` | `string` | `"EGP"` | `"SAR"`, `"USD"` |
| Currency Symbol | `currency_symbol` | `string` | `"ج.م"` | `"ر.س"` |
| Rounding Method | `rounding` | `enum` | `round` | `floor / ceil / round` |

#### 🏪 Branch Settings (إعدادات الفرع)
| Setting | Key | Type |
|---------|-----|------|
| Branch Name (AR/EN) | `branch_name_ar / branch_name_en` | `string` |
| Branch Logo | `branch_logo` | `image_url` |
| Tax Registration Number | `tax_reg_number` | `string` |
| Commercial Register | `commercial_reg` | `string` |
| Address | `branch_address` | `string` |
| Phone | `branch_phone` | `string` |
| Working Hours | `working_hours` | `json` |
| Active Services | `enabled_services` | `array` | `[dine_in, delivery, takeaway]` |

#### 🖨️ Print Settings (إعدادات الطباعة)
| Setting | Key | Type |
|---------|-----|------|
| Printer Model | `printer_model` | `string` |
| Paper Width | `paper_width` | `enum` | `58mm / 80mm` |
| Receipt Header | `receipt_header` | `text` |
| Receipt Footer | `receipt_footer` | `text` |
| Auto-Print KOT | `auto_print_kot` | `boolean` |
| Auto-Print Receipt | `auto_print_receipt` | `boolean` |
| Print Copies | `receipt_copies` | `number` |
| Show Tax on Receipt | `show_tax_on_receipt` | `boolean` |

#### 🚴 Delivery Settings (إعدادات الدليفري)
| Setting | Key | Type |
|---------|-----|------|
| Delivery Zones | `delivery_zones` | `json[]` | `[{name, polygon, price}]` |
| Min Order for Delivery | `delivery_min_order` | `number` |
| Estimated Delivery Time | `delivery_eta_minutes` | `number` |
| Free Delivery Threshold | `free_delivery_above` | `number` |
| Enable Driver Tracking | `enable_driver_tracking` | `boolean` |

#### 🍽️ Table & Hall Settings
| Setting | Key | Type |
|---------|-----|------|
| Enable Table Map | `enable_table_map` | `boolean` |
| Table Map Layout | `table_map_layout` | `json` |
| Sections/Halls | `hall_sections` | `json[]` |
| Reservation Enabled | `reservations_enabled` | `boolean` |

#### ⏰ Shift Settings
| Setting | Key | Type |
|---------|-----|------|
| Require Opening Cash | `shift_require_cash` | `boolean` |
| Shift Auto-close | `shift_auto_close` | `boolean` |
| Shift Duration Hours | `shift_max_hours` | `number` |

#### 🌐 System Settings
| Setting | Key | Type |
|---------|-----|------|
| Default Language | `default_language` | `enum` | `ar / en` |
| Date Format | `date_format` | `string` |
| Time Format | `time_format` | `enum` | `12h / 24h` |
| Order Number Prefix | `order_prefix` | `string` | `"ORD-"` |
| Order Number Reset | `order_reset_daily` | `boolean` |

---

## Module Breakdown

### 1. 🏢 Multi-Branch Module
```
Branch Management
├── Create/Edit/Deactivate Branch
├── Branch-specific settings inheritance
├── Per-branch menu (or shared + override)
├── Per-branch staff assignment
├── Consolidated reports across branches
└── Super Admin cross-branch dashboard
```

### 2. 📋 Menu Module (Dynamic)
```
Menu Structure
├── Categories (AR/EN names, icon, sort order)
│   └── Items
│       ├── Name (AR/EN)
│       ├── Description (AR/EN)
│       ├── Base Price
│       ├── Image
│       ├── Available in: [Dine-In] [Delivery] [Takeaway]
│       ├── Kitchen Assignment (which kitchen to route to)
│       ├── Estimated Prep Time
│       ├── Availability Schedule (e.g., breakfast only)
│       ├── Is Active / Sold Out (toggle per branch)
│       └── Modifier Groups
│           └── Modifier Group
│               ├── Name (AR/EN) e.g., "Size", "Extras", "Remove"
│               ├── Type: single-select / multi-select
│               ├── Min/Max selections
│               ├── Required/Optional
│               └── Options
│                   ├── Name (AR/EN)
│                   ├── Price Adjustment (+/-)
│                   └── Is Default
```

### 3. 🖥️ POS / Cashier Module
```
Session Flow
├── Login (username+password OR PIN)
├── Open Shift → Enter opening cash
├── Select Order Type
│   ├── Dine-In → Select Table from map
│   ├── Takeaway → Enter customer name/phone
│   └── Delivery → Search/create customer + select zone
├── Build Order
│   ├── Browse menu by category
│   ├── Quick search
│   ├── Add item → Select modifiers → Confirm
│   ├── Edit quantity, add notes
│   └── Apply discount (if permitted)
├── Send to Kitchen (KOT auto-print)
├── Order holds open until payment
├── Payment
│   ├── Select method(s): Cash / Card / Wallet / Credit
│   ├── Split bill between guests
│   ├── Apply tax + service charge (from settings)
│   └── Print receipt
└── Close Shift → Cash count → Print shift report
```

### 4. 🍳 Kitchen Module (KDS)
```
Kitchen Display
├── Per-kitchen view (each kitchen sees only its items)
├── Order cards showing: table/type, items, time elapsed
├── Status actions: Accept → Preparing → Ready
├── Color coding: New (blue) → Late (yellow) → Critical (red)
├── Audio alerts for new orders
└── KOT printing (if no screen)
```

### 5. 🚴 Delivery Module
```
Delivery Management
├── Customer Management
│   ├── Create/Search customer
│   ├── Saved addresses
│   └── Order history
├── Zone Management (from settings)
│   └── Dynamic pricing per zone
├── Order Assignment
│   ├── Auto-assign or manual
│   └── Driver availability status
├── Driver Tracking
│   ├── Status updates: Assigned → Picked Up → On Way → Delivered
│   ├── GPS location (optional, driver app)
│   └── ETA display
└── Delivery Reports
    ├── Driver performance
    ├── Average delivery time
    └── Zone revenue breakdown
```

### 6. ⏰ Shift Module
```
Shift System
├── Shift opening
│   ├── Assigned cashier
│   ├── Opening cash amount
│   └── Timestamp
├── During shift
│   ├── All orders tagged with shift_id
│   ├── Running totals visible
│   └── Mid-shift cash drawer count
├── Shift closing
│   ├── Count cash in drawer
│   ├── System expected vs actual (variance)
│   ├── Summary: orders, revenue, per payment method
│   └── Print/export shift report
└── Shift history (searchable, filterable)
```

### 7. 💰 Payment Module
```
Payment Methods (all configurable)
├── Cash
├── Credit/Debit Card (manual entry or machine)
├── Digital Wallets (Vodafone Cash, Fawry, InstaPay...)
├── Credit/Tab (defer payment, track debt)
└── Mixed payments (e.g., part cash + part card)

Discount Engine
├── Percentage discount (%)
├── Fixed amount discount
├── Requires approval (role-based)
├── Discount reason log
└── Coupon/Promo codes
```

### 8. 📊 Reports Module
```
Report Types
├── Daily Sales Summary
├── Order Log (filterable by type/status/cashier)
├── Item Performance (top sellers, slow movers)
├── Shift Reports
├── Payment Method Breakdown
├── Driver Performance
├── Branch Comparison (multi-branch)
├── Tax Report
├── Discount & Void Report (audit)
└── Customer Report (delivery orders)

Export Options: PDF · Excel · Print
```

### 9. 🔐 Audit & Security Module
```
Audit Log (every action is logged)
├── User authentication events
├── Order creation/edit/void/delete
├── Payment operations
├── Refunds and discounts
├── Settings changes
├── Shift open/close
└── Menu changes

Security Features
├── Role-based access control (RBAC)
├── Per-role permission overrides
├── Session timeout
├── PIN login for cashiers
├── Void/refund requires supervisor approval
└── Access logs per branch
```

---

## Implementation Phases

> **ترتيب البناء: Backend (Django) أولاً ← API ← Frontend (Next.js)**

---

### 🏗️ Phase 1 — Django Project Setup & Core Models
**Duration: ~1 week**

- [ ] Django project scaffold (config, apps structure, Docker)
- [ ] PostgreSQL + Redis + Celery setup
- [ ] Django Channels ASGI config (Daphne)
- [ ] Custom User model (roles, PIN, branch assignment)
- [ ] Branch & Tenant models
- [ ] Dynamic Settings Engine models + management commands for seeding defaults
- [ ] RBAC permission system (custom permission classes)
- [ ] Audit log model + signal-based auto-logging
- [ ] Base model mixins (BranchScoped, Timestamped, SoftDelete)

**Deliverable**: Django project running with DB, Redis, Celery, all core models migrated.

---

### 🍽️ Phase 2 — Menu, Kitchen & Table Models
**Duration: ~1 week**

- [ ] Category model (AR/EN, sort order, icon)
- [ ] MenuItem model (AR/EN, price, image, service availability)
- [ ] ModifierGroup + ModifierOption models
- [ ] MenuItem ↔ Kitchen many-to-many
- [ ] Kitchen model (branch, name AR/EN, printer IP)
- [ ] Table model (branch, section, number, capacity, status)
- [ ] TableSession model
- [ ] All migrations + Django admin registration
- [ ] Seed data management command (sample menu)

**Deliverable**: Full menu, kitchen, table schema ready.

---

### 📦 Phase 3 — Orders, Payments & Shifts Models
**Duration: ~1 week**

- [ ] Order model (type, status, branch, shift)
- [ ] OrderItem + OrderItemModifier models
- [ ] KitchenOrder model (per-kitchen routing)
- [ ] Payment model (multi-method, amounts)
- [ ] Discount model (type, value, reason, approved_by)
- [ ] Shift model (cashier, opening/closing cash, status)
- [ ] Delivery models (Customer, CustomerAddress, Zone, Driver, Assignment)
- [ ] All signals wired (order saved → kitchen push, audit log)
- [ ] Business logic services (OrderService, PaymentService, ShiftService)

**Deliverable**: All operational models + service layer complete.

---

### 🔌 Phase 4 — REST API (Django REST Framework)
**Duration: ~2 weeks**

- [ ] Auth API (login, PIN login, refresh, logout)
- [ ] Branches API (CRUD)
- [ ] Settings API (get/update per branch, schema endpoint)
- [ ] Users & roles API
- [ ] Menu API (categories, items, modifiers — full CRUD)
- [ ] Kitchens API
- [ ] Tables API (CRUD + map endpoint)
- [ ] Orders API (CRUD + `send_to_kitchen`, `pay`, `void` actions)
- [ ] Payments API (process, refund)
- [ ] Shifts API (open, close, current, history)
- [ ] Delivery API (customers, zones, drivers, assignments)
- [ ] Reports API (daily, sales, items, shifts, drivers, tax)
- [ ] API documentation (drf-spectacular / Swagger)

**Deliverable**: Full REST API with Swagger docs — testable with Bruno/Postman.

---

### ⚡ Phase 5 — Real-time (Django Channels)
**Duration: ~1 week**

- [ ] KitchenConsumer (branch+kitchen scoped room)
- [ ] POSConsumer (order status updates → cashier)
- [ ] DeliveryConsumer (driver assignment updates)
- [ ] DriverConsumer (driver location & status)
- [ ] Signal → Channel group_send wiring
- [ ] JWT auth in WebSocket handshake
- [ ] WebSocket routing in asgi.py

**Deliverable**: All real-time events flowing through Django Channels.

---

### 🖨️ Phase 6 — Printing & Background Tasks (Celery)
**Duration: ~0.5 week**

- [ ] Celery app setup (workers, beat scheduler)
- [ ] `print_receipt` Celery task (ESC/POS via python-escpos)
- [ ] `print_kot` task (Kitchen Order Ticket)
- [ ] `print_shift_report` task
- [ ] `generate_pdf_report` task (WeasyPrint)
- [ ] `generate_excel_report` task (openpyxl)
- [ ] `auto_close_shift` scheduled task
- [ ] Celery Beat schedules in DB (django-celery-beat)

**Deliverable**: Async print & report system fully operational.

---

### 🖥️ Phase 7 — Next.js Frontend: Auth, Admin & Settings
**Duration: ~1.5 weeks**

- [ ] Next.js 14 project setup (App Router, TypeScript, Tailwind, RTL)
- [ ] i18n setup (next-intl, ar.json, en.json)
- [ ] Axios client → Django API (interceptors, token refresh)
- [ ] WebSocket client hooks → Django Channels
- [ ] Login page (username+password)
- [ ] PIN login screen (cashier)
- [ ] Auth middleware (role-based route protection)
- [ ] Admin panel layout (sidebar, navigation)
- [ ] Branch management UI
- [ ] Settings panel UI (all categories, tabbed)
- [ ] User & role management UI
- [ ] Menu builder UI (categories, items, modifiers, drag-to-reorder)
- [ ] Kitchen & table map designer

**Deliverable**: Admin panel fully operational connecting to Django API.

---

### 💳 Phase 8 — Cashier POS Interface
**Duration: ~2 weeks**

- [ ] POS layout (menu browser left, order right)
- [ ] Table map component (visual, status colors)
- [ ] Menu category browser + search
- [ ] Order builder (add item → modifier dialog → confirm)
- [ ] Dine-In, Takeaway, Delivery order type flows
- [ ] Discount application UI
- [ ] Payment screen (multi-method, split bill)
- [ ] Tax & service charge auto-calculation (from settings API)
- [ ] Receipt print (browser + thermal)
- [ ] KOT send to kitchen
- [ ] Shift open/close workflow
- [ ] Live order status updates via WebSocket

**Deliverable**: Full POS operational for all 3 order types.

---

### 🍳 Phase 9 — Kitchen KDS & Delivery
**Duration: ~1 week**

- [ ] KDS full-screen interface (dark mode, order cards)
- [ ] Per-kitchen filtering
- [ ] Real-time order push (Django Channels → WebSocket → KDS)
- [ ] Status update (Preparing → Ready)
- [ ] Color-coded urgency timer
- [ ] Audio notification
- [ ] Delivery dispatch UI (assign driver, zone pricing)
- [ ] Driver status tracking
- [ ] Driver PWA interface (mobile-optimized)

**Deliverable**: KDS + Delivery tracking live.

---

### 📊 Phase 10 — Accountant Dashboard & Reports
**Duration: ~1.5 weeks**

- [ ] Accountant dashboard layout
- [ ] KPI cards (live data from API)
- [ ] Revenue charts (Recharts)
- [ ] Order log with filters
- [ ] Shift reports listing
- [ ] Item performance analytics
- [ ] Payment breakdown table
- [ ] Tax report
- [ ] Export PDF/Excel (triggered → Celery → download)
- [ ] Branch comparison report (super admin)

**Deliverable**: Full accountant module.

---

### ✨ Phase 11 — Polish, Testing & Deployment
**Duration: ~1 week**

- [ ] Full AR/EN RTL polish pass
- [ ] Tablet-optimized POS responsive design
- [ ] Error handling & loading states
- [ ] Audit log UI
- [ ] Docker Compose production setup
- [ ] Nginx config (HTTPS, WebSocket proxy)
- [ ] Environment variables & secrets management
- [ ] Backend: pytest-django test suite
- [ ] E2E: Playwright critical paths
- [ ] Deployment documentation

**Deliverable**: Production-ready system.

---

### ⏱️ Total Timeline Summary

| Phase | Module | Duration |
|-------|--------|----------|
| 1 | Django Setup & Core Models | 1 week |
| 2 | Menu, Kitchen & Table Models | 1 week |
| 3 | Orders, Payments & Shifts Models | 1 week |
| 4 | REST API (DRF) | 2 weeks |
| 5 | Real-time (Django Channels) | 1 week |
| 6 | Printing & Celery Tasks | 0.5 week |
| 7 | Frontend: Auth, Admin & Settings | 1.5 weeks |
| 8 | Cashier POS Interface | 2 weeks |
| 9 | KDS & Delivery | 1 week |
| 10 | Accountant Dashboard & Reports | 1.5 weeks |
| 11 | Polish, Testing & Deployment | 1 week |
| **Total** | | **~13.5 weeks** |

---

## Database Schema Overview

> Defined as Django ORM models — auto-generates migrations via `python manage.py makemigrations`

```python
# ── Core ──────────────────────────────────────────────────────
Tenant            # System-level (multi-tenant support)
Branch            # branch_name_ar, branch_name_en, tenant, is_active
User              # email, role, branch, pin_hash (custom AbstractUser)
SettingDefinition # key, type, category, default_value, label_ar, label_en
BranchSetting     # branch FK, definition FK, value (JSONField)

# ── Menu ──────────────────────────────────────────────────────
Category          # name_ar, name_en, icon, sort_order, branch
MenuItem          # name_ar, name_en, description_ar/en, price, image
                  # available_in (ArrayField), kitchen M2M, is_active
ModifierGroup     # name_ar/en, type (single/multi), min, max, required
ModifierOption    # group FK, name_ar/en, price_adjustment, is_default

# ── Tables ────────────────────────────────────────────────────
Table             # branch, section, number, capacity, status, position_x/y
TableSession      # table, order (OneToOne), opened_at, closed_at

# ── Kitchens ──────────────────────────────────────────────────
Kitchen           # branch, name_ar/en, printer_ip, is_active
KitchenOrder      # order, kitchen, status, sent_at, ready_at

# ── Orders (Core) ─────────────────────────────────────────────
Order             # branch, shift, order_number, type, status, notes
OrderItem         # order, menu_item, quantity, unit_price, notes
OrderItemModifier # order_item, modifier_option, price_at_order
Payment           # order, method, amount, reference, processed_at
Discount          # order, type (pct/fixed), value, reason, approved_by

# ── Shifts ────────────────────────────────────────────────────
Shift             # branch, cashier, status, opening_cash, closing_cash
                  # opened_at, closed_at, expected_cash, variance

# ── Delivery ──────────────────────────────────────────────────
Customer          # name, phone, branch (or global)
CustomerAddress   # customer, address_text, zone, lat, lng, is_default
DeliveryZone      # branch, name_ar/en, delivery_price, min_order, polygon
DeliveryDriver    # user (OneToOne), status, current_lat, current_lng
DeliveryAssignment# order, driver, status, assigned_at, picked_at, delivered_at

# ── Audit ─────────────────────────────────────────────────────
AuditLog          # user, branch, action, entity, entity_id, snapshot (JSONField)
```

---

## API Structure

```
/api/v1/
├── auth/
│   ├── POST   /login
│   ├── POST   /login-pin
│   ├── POST   /refresh
│   └── POST   /logout
│
├── branches/
│   ├── GET    /                    - List branches
│   ├── POST   /                    - Create branch
│   ├── GET    /:id
│   ├── PUT    /:id
│   └── DELETE /:id
│
├── settings/
│   ├── GET    /                    - Get all settings (scoped by branch)
│   ├── PUT    /                    - Batch update settings
│   └── GET    /schema              - Settings schema with types & validation
│
├── menu/
│   ├── categories/                 (CRUD)
│   ├── items/                      (CRUD)
│   ├── modifier-groups/            (CRUD)
│   └── modifiers/                  (CRUD)
│
├── tables/
│   ├── GET    /map                 - Table map with status
│   ├── POST   /                    - Create table
│   └── PUT    /:id/status
│
├── orders/
│   ├── GET    /                    - List orders (filters)
│   ├── POST   /                    - Create order
│   ├── GET    /:id
│   ├── PUT    /:id
│   ├── POST   /:id/send-kitchen
│   ├── POST   /:id/pay
│   └── POST   /:id/void
│
├── kitchen/
│   ├── GET    /orders              - Active kitchen orders
│   └── PUT    /orders/:id/status
│
├── delivery/
│   ├── customers/                  (CRUD + search)
│   ├── zones/                      (CRUD)
│   ├── drivers/                    (CRUD + availability)
│   └── assignments/                (assign, track, update)
│
├── shifts/
│   ├── POST   /open
│   ├── POST   /close
│   ├── GET    /current
│   └── GET    /                    - Shift history
│
├── payments/
│   ├── POST   /process
│   └── POST   /refund
│
└── reports/
    ├── GET    /daily
    ├── GET    /sales
    ├── GET    /items
    ├── GET    /shifts
    ├── GET    /drivers
    └── GET    /tax
```

---

## UI Interfaces

### 🖥️ Cashier POS
- **Layout**: Left panel = menu browser | Right panel = current order
- **Table map**: Visual drag-and-drop layout (configured by admin)
- **Quick keys**: Most-ordered items on top
- **Hot key shortcuts**: keyboard shortcuts for speed
- **Language toggle**: Per-session AR/EN switch

### 📊 Accountant Dashboard
- KPI cards at top (today's revenue, orders, average)
- Date range filter
- Charts: revenue trend, payment method pie, hourly breakdown
- Tables: order log, shift summary
- One-click export

### ⚙️ Admin Panel
- Sidebar navigation (collapsible)
- Settings → tabbed by category (Financial, Branch, Print, Delivery, etc.)
- Menu builder with drag-to-reorder
- Table map designer (drag tables, set sections)
- Live dashboard widget

### 🍳 KDS (Kitchen Display)
- Full-screen dark mode
- Cards grid layout
- Timer on each order
- Touch-to-update status
- Separate display per kitchen

### 📱 Driver Interface (PWA)
- Mobile-optimized
- List of assigned orders
- Status update buttons (large tap targets)
- Customer address + map link
- Shift start/end

---

*Last updated: April 2026 | Cashora v1.0*
