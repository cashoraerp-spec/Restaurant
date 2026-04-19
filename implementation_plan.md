# Cashora Restaurant Management System — خطة التنفيذ

## نظرة عامة | Overview

نظام إدارة مطاعم متكامل يدعم ثلاثة أنواع من الخدمة (صالة، دليفري، تاك أواي)، مع واجهات متخصصة لكل دور في المطعم، ودعم كامل للغتين العربية والإنجليزية.

A full-featured restaurant management system supporting dine-in, delivery, and takeaway operations with role-based interfaces, multi-kitchen support, shift management, and bilingual (AR/EN) support.

---

## المتطلبات المؤكدة | Confirmed Requirements

| # | الميزة | الوصف |
|---|--------|-------|
| 1 | **أنواع الخدمة** | صالة (Dine-In) · دليفري (Delivery) · تاك أواي (Takeaway) |
| 2 | **إدارة الأصناف** | مكونات الأصناف (Modifiers/Variants) · مجموعات الإضافات |
| 3 | **المطابخ المتعددة** | توجيه الأوردر لأكثر من مطبخ تلقائياً |
| 4 | **واجهة الكاشير** | استقبال الطلبات، فتح طاولات، إصدار الفواتير |
| 5 | **واجهة المحاسب** | التقارير، إغلاق اليوم، متابعة الإيرادات |
| 6 | **واجهة الأدمن** | إدارة كاملة — الأصناف، المستخدمين، الإعدادات |
| 7 | **نظام الورديات** | فتح/إغلاق وردية، تقرير الشيفت، مطابقة كاش |
| 8 | **تتبع الدليفري** | تعيين طيار، تتبع حالة التوصيل، خريطة |
| 9 | **ثنائية اللغة** | عربي/إنجليزي مع دعم RTL كامل |
| 10 | **طباعة الريسيت** | طباعة فاتورة الزبون + تذكرة المطبخ (KOT) |

---

## اقتراحات إضافية | My Recommendations

> [!IMPORTANT]
> هذه الميزات ستكمل المنظومة وتجعل النظام احترافياً بالكامل — أرجو مراجعتها والموافقة على ما تريده.

### 🔐 الأمان والصلاحيات
- **نظام صلاحيات دقيق (RBAC)**: كل دور يرى فقط ما يخصه
- **PIN login** للكاشير بدلاً من كلمة مرور (أسرع في التشغيل)
- **سجل العمليات (Audit Log)**: من عمل إيه ومتى (مهم جداً للحماية من السرقة)

### 🍽️ إدارة الصالة
- **خريطة الطاولات (Table Map)**: تصميم مرئي للصالة، الطاولة المشغولة/الفاضية بلون مختلف
- **دمج/تقسيم الطاولات**: نقل أوردر من طاولة لأخرى
- **الحجوزات (Reservations)**: حجز طاولة بالاسم والتوقيت

### 💰 المدفوعات
- **طرق دفع متعددة**: كاش + بطاقة + فودا كاش/انستاباي + آجل (دين)
- **التقسيط على الطاولة (Split Bill)**: كل فرد يدفع نصيبه
- **الخصومات والكوبونات**: خصم نسبة أو مبلغ ثابت

### 📊 التقارير والتحليلات
- **لوحة تحكم لحظية (Live Dashboard)**: المبيعات اللحظية، أكثر الأصناف مبيعاً
- **تقارير يومية/أسبوعية/شهرية**
- **تقرير الكاشير**: مروح كام ودفع كام في كل وردية
- **تحليل الأداء**: أكثر الأوقات ازدحاماً، أبطأ صنف

### 🖨️ الطباعة
- **Kitchen Order Ticket (KOT)**: تذكرة للمطبخ بتتطبع عند استلام الأوردر
- **فاتورة رسمية (Tax Invoice)**: بالضريبة ورقم السجل التجاري
- **تقرير الشيفت المطبوع**

### 🚴 الدليفري المتقدم
- **مناطق التوصيل والأسعار**: كل منطقة بسعر توصيل مختلف
- **تقييم الطيار**: متوسط وقت التوصيل لكل طيار
- **ربط API خرائط** (Google Maps / OpenStreetMap)

### ⚙️ إعدادات المطعم
- **ضريبة القيمة المضافة (VAT/GST)**
- **رسوم الخدمة (Service Charge)**
- **أوقات العمل والإجازات**
- **إدارة الفروع** (لو في أكثر من فرع)

### 📱 اختياري مستقبلاً
- **تطبيق الموبايل للطيار** (PWA)
- **QR Code منيو للزبون**
- **تكامل مع Aggregators** (Talabat, Hunger Station, Uber Eats)

---

## Architecture & Tech Stack

```
┌─────────────────────────────────────────────────────┐
│                   Frontend (Next.js)                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │ Cashier  │  │Accountant│  │  Admin Dashboard │   │
│  │    UI    │  │    UI    │  │       UI         │   │
│  └──────────┘  └──────────┘  └──────────────────┘   │
│              ┌──────────────┐                        │
│              │ Kitchen KDS  │  (Kitchen Display)     │
│              └──────────────┘                        │
└──────────────────────┬──────────────────────────────┘
                       │ REST API + WebSockets
┌──────────────────────▼──────────────────────────────┐
│               Backend (Node.js + Express)            │
│  Auth · Orders · Menu · Shifts · Delivery · Reports  │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Database (PostgreSQL + Redis)            │
│    PostgreSQL: Core Data     Redis: Real-time cache  │
└─────────────────────────────────────────────────────┘
```

---

## الموديولات الرئيسية | Core Modules

### 1. نظام المستخدمين والصلاحيات
```
Admin → Full Access
Accountant → Reports, Shifts, Payments
Cashier → Orders, Tables, Print
Kitchen Staff → View/Update Orders (KDS)
Delivery Driver → View Assigned Orders, Update Status
```

### 2. إدارة المنيو
```
Categories (فئات)
  └── Menu Items (أصناف)
        ├── Base Price
        ├── Modifiers Groups (مجموعات إضافات)
        │     └── Options (Extra Cheese, Size, Spice Level...)
        ├── Kitchen Assignment (أي مطبخ ينفذه)
        └── Availability (متاح/غير متاح)
```

### 3. دورة الأوردر
```
New Order
  ├── Select Type: Dine-In / Delivery / Takeaway
  ├── Add Items + Modifiers
  ├── Send to Kitchen (KOT Printed)
  ├── Kitchen Updates Status: Preparing → Ready
  ├── [Delivery] Assign Driver → Out for Delivery → Delivered
  └── Payment → Receipt Printed → Order Closed
```

### 4. نظام الورديات
```
Open Shift → Enter Opening Cash
  │
  ▼ (During Shift)
  Orders, Payments, Refunds
  │
  ▼
Close Shift → Count Cash → Print Shift Report
  Shift Summary: Sales, Cash, Card, Tips, Refunds
```

---

## الواجهات التفصيلية | Interface Details

### 🖥️ واجهة الكاشير (Cashier POS)
- خريطة الطاولات + حالة كل طاولة
- بحث سريع في الأصناف
- إضافة/تعديل/حذف أصناف من الأوردر
- اختيار المكونات والإضافات (Modifiers)
- تطبيق الخصومات
- اختيار طريقة الدفع وإصدار الفاتورة
- طباعة ريسيت + KOT للمطبخ

### 📊 واجهة المحاسب (Accountant)
- ملخص يومي/أسبوعي/شهري
- مراجعة جميع الأوردرات
- تقارير الورديات
- متابعة الديون والآجل
- تقرير الضريبة
- تصدير Excel/PDF

### ⚙️ واجهة الأدمن (Admin)
- إدارة المنيو الكاملة (Add/Edit/Delete)
- إدارة المستخدمين والصلاحيات
- إعدادات المطعم (الضريبة، رسوم الخدمة، أوقات العمل)
- إدارة الطيارين ومناطق التوصيل
- إدارة المطابخ
- إعدادات الطباعة
- تقارير متقدمة وتحليلات

### 🍳 شاشة المطبخ (KDS - Kitchen Display System)
- أوردرات لحظية مرتبة بالوقت
- تمييز الأوردر المتأخر باللون الأحمر
- تحديث الحالة: New → Preparing → Ready

---

## ترتيب التنفيذ | Implementation Phases

### Phase 1 — الأساس (Foundation) 🏗️
- [ ] إعداد المشروع (Next.js + Node.js + PostgreSQL)
- [ ] نظام المصادقة والصلاحيات
- [ ] إدارة المنيو (الفئات والأصناف والمكونات)
- [ ] إدارة الطاولات

### Phase 2 — الكاشير وأوردر (Core POS) 💳
- [ ] واجهة الكاشير الكاملة
- [ ] دورة الأوردر (صالة، تاك أواي)
- [ ] نظام الدفع ومتعدد طرق الدفع
- [ ] طباعة الريسيت وKOT
- [ ] شاشة المطبخ (KDS)

### Phase 3 — الدليفري والورديات 🚴
- [ ] واجهة وإدارة الدليفري
- [ ] تتبع الطيار ومراحل التوصيل
- [ ] نظام الورديات (فتح/إغلاق/تقرير)

### Phase 4 — المحاسبة والتقارير 📊
- [ ] واجهة المحاسب
- [ ] التقارير والتحليلات
- [ ] تصدير Excel/PDF

### Phase 5 — الأدمن والبولش ⚙️
- [ ] واجهة الأدمن الكاملة
- [ ] ثنائية اللغة AR/EN + RTL
- [ ] تحسينات UI/UX وUX polish

---

## أسئلة مفتوحة | Open Questions

> [!IMPORTANT]
> **هل النظام لفرع واحد ولا متعدد الفروع؟**
> لو متعدد الفروع هيغير في الـ architecture بشكل كبير.

> [!IMPORTANT]
> **هل في backend جاهز ولا نبني من الصفر؟**
> هل ح نبني كل حاجة بـ Next.js + Prisma + PostgreSQL أو في backend محدد؟

> [!NOTE]
> **الدليفري — هل في تطبيق موبايل للطيار ولا بس واجهة ويب؟**
> لو موبايل هنعمل PWA أو React Native منفصل؟

> [!NOTE]
> **هل في ضريبة؟** VAT/GST نسبتها كام؟

> [!NOTE]
> **هل في integration مع أجهزة POS أو طابعات حرارية معينة؟**
> نوع الطابعة مهم لتنسيق الريسيت.

---

## التقنيات المقترحة | Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Frontend | **Next.js 14** (App Router) | SSR، سريع، مناسب POS |
| UI Components | **shadcn/ui + Radix** | احترافي، قابل للتخصيص |
| Styling | **Tailwind CSS** | سريع في التطوير |
| State Management | **Zustand** | خفيف ومناسب |
| Real-time | **Socket.io** | لحظي بين الكاشير والمطبخ |
| Backend | **Node.js + Express** | |
| ORM | **Prisma** | سهل وآمن |
| Database | **PostgreSQL** | بيانات علائقية |
| Cache/Real-time | **Redis** | |
| Auth | **NextAuth / JWT** | |
| i18n | **next-intl** | عربي/إنجليزي |
| Print | **react-to-print** + Thermal Printer ESC/POS | |

