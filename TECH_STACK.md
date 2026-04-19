# ⚙️ Cashora — Technology Stack Documentation

> **توثيق التقنيات المستخدمة في النظام**
> Version: 1.0 | Backend: Django · Frontend: Next.js · Real-time: Django Channels

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Backend Stack — Django](#backend-stack--django)
4. [API Layer — Django REST Framework](#api-layer--django-rest-framework)
5. [Real-time Layer — Django Channels](#real-time-layer--django-channels)
6. [Database Layer](#database-layer)
7. [Task Queue — Celery](#task-queue--celery)
8. [Frontend Stack — Next.js](#frontend-stack--nextjs)
9. [Printing System](#printing-system)
10. [Internationalization](#internationalization)
11. [Authentication & Security](#authentication--security)
12. [DevOps & Deployment](#devops--deployment)
13. [Development Tooling](#development-tooling)
14. [Dependency Versions](#dependency-versions)
15. [Key Technical Decisions](#key-technical-decisions)

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                          CLIENT LAYER                            │
│                                                                  │
│   Browser (Next.js 14 App Router)            Driver PWA         │
│   ┌──────────┐  ┌─────────┐  ┌──────────┐  ┌────────────────┐  │
│   │ Cashier  │  │  Admin  │  │Accountant│  │ Kitchen (KDS)  │  │
│   │   POS    │  │  Panel  │  │Dashboard │  │  + Driver App  │  │
│   └──────────┘  └─────────┘  └──────────┘  └────────────────┘  │
└─────────────────────────┬────────────────────────────────────────┘
                          │  HTTPS + WSS (wss://)
┌─────────────────────────▼────────────────────────────────────────┐
│                    NGINX Reverse Proxy                           │
│         SSL Termination · Rate Limiting · Static Files          │
│   /api/*  →  Django (ASGI)    /  →  Next.js                    │
└──────────────┬─────────────────────────────────────────────────-─┘
               │
┌──────────────▼───────────────────────────────────────────────────┐
│               Django Application (ASGI via Daphne/Uvicorn)       │
│                                                                  │
│  ┌─────────────────────────┐   ┌──────────────────────────────┐ │
│  │   Django REST Framework  │   │      Django Channels         │ │
│  │   (HTTP REST API)        │   │      (WebSocket)             │ │
│  │                          │   │                              │ │
│  │  Auth · Menu · Orders    │   │  /ws/kitchen/{branch_id}/    │ │
│  │  Shifts · Delivery       │   │  /ws/pos/{branch_id}/        │ │
│  │  Payments · Reports      │   │  /ws/delivery/{branch_id}/   │ │
│  │  Settings · Branches     │   │  /ws/driver/{driver_id}/     │ │
│  └─────────────────────────┘   └──────────────────────────────┘ │
└──────────────┬───────────────────────────────────────────────────┘
               │
┌──────────────▼───────────────────────────────────────────────────┐
│                          DATA LAYER                              │
│                                                                  │
│  PostgreSQL 16           Redis 7              Celery Workers     │
│  (Primary DB)            (Cache + Channel     (Background Tasks) │
│  Django ORM              Layer + Sessions)    Print · Reports    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
cashora-restaurant/
│
├── backend/                          # Django Project Root
│   ├── config/                       # Django settings & config
│   │   ├── settings/
│   │   │   ├── base.py               # Common settings
│   │   │   ├── development.py
│   │   │   └── production.py
│   │   ├── urls.py                   # Root URL config
│   │   ├── asgi.py                   # ASGI entry (Channels)
│   │   └── wsgi.py
│   │
│   ├── apps/                         # Django Apps (each = one module)
│   │   ├── core/                     # Shared models, mixins, utils
│   │   ├── tenants/                  # Tenant (system-level) management
│   │   ├── branches/                 # Multi-branch management
│   │   ├── settings_engine/          # Dynamic settings system
│   │   ├── users/                    # Users, roles, RBAC, PIN auth
│   │   ├── menu/                     # Categories, items, modifiers
│   │   ├── kitchens/                 # Kitchen management
│   │   ├── tables/                   # Table & hall management
│   │   ├── orders/                   # Order lifecycle
│   │   ├── payments/                 # Payments, discounts, refunds
│   │   ├── shifts/                   # Shift management
│   │   ├── delivery/                 # Zones, drivers, assignments
│   │   ├── reports/                  # All reporting logic
│   │   ├── printing/                 # Print templates & queue
│   │   └── audit/                    # Audit log
│   │
│   ├── channels_consumers/           # Django Channels WebSocket consumers
│   │   ├── kitchen_consumer.py
│   │   ├── pos_consumer.py
│   │   ├── delivery_consumer.py
│   │   └── routing.py
│   │
│   ├── tasks/                        # Celery tasks
│   │   ├── print_tasks.py
│   │   ├── report_tasks.py
│   │   └── notification_tasks.py
│   │
│   ├── manage.py
│   ├── requirements/
│   │   ├── base.txt
│   │   ├── development.txt
│   │   └── production.txt
│   └── .env.example
│
├── frontend/                         # Next.js App
│   ├── app/
│   │   ├── (auth)/                   # Login, PIN screen
│   │   ├── (cashier)/                # Cashier POS
│   │   ├── (admin)/                  # Admin panel
│   │   ├── (accountant)/             # Accountant dashboard
│   │   ├── (kitchen)/                # KDS display
│   │   └── (driver)/                 # Driver PWA
│   ├── components/
│   ├── lib/
│   │   ├── api/                      # API client (axios)
│   │   └── ws/                       # WebSocket client
│   ├── stores/                       # Zustand stores
│   ├── messages/                     # i18n (ar.json, en.json)
│   └── package.json
│
├── nginx/                            # Nginx config
├── docker-compose.yml
├── docker-compose.dev.yml
├── ROADMAP.md
└── TECH_STACK.md                     # This file
```

---

## Backend Stack — Django

### Framework: **Django 5.x**

| Feature | Why Django? |
|---------|------------|
| Batteries included | ORM, admin, auth, migrations — all built-in |
| Django Admin | Instant admin UI we customize for managers |
| Signals | React to model events (order saved → push to kitchen) |
| Middleware | Branch isolation, auth, audit logging |
| Management Commands | Data seeding, maintenance tasks |
| Mature ecosystem | 15+ years, production-proven |

```python
# config/settings/base.py
INSTALLED_APPS = [
    # Django built-ins
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',

    # Third-party
    'rest_framework',
    'rest_framework_simplejwt',
    'corsheaders',
    'channels',
    'django_filters',
    'django_celery_beat',
    'django_celery_results',

    # Cashora apps
    'apps.core',
    'apps.tenants',
    'apps.branches',
    'apps.settings_engine',
    'apps.users',
    'apps.menu',
    'apps.kitchens',
    'apps.tables',
    'apps.orders',
    'apps.payments',
    'apps.shifts',
    'apps.delivery',
    'apps.reports',
    'apps.printing',
    'apps.audit',
]
```

---

### Django App Architecture Pattern

Each app follows this consistent structure:

```
apps/orders/
├── __init__.py
├── admin.py          # Django admin registration
├── apps.py
├── consumers.py      # WebSocket consumers (if needed)
├── filters.py        # django-filter FilterSets
├── migrations/       # Auto-generated DB migrations
├── models.py         # Django ORM models
├── permissions.py    # DRF permission classes
├── serializers.py    # DRF serializers (request/response)
├── services.py       # Business logic layer
├── signals.py        # Django signals (post_save, etc.)
├── tasks.py          # Celery tasks for this domain
├── tests/
│   ├── test_models.py
│   ├── test_api.py
│   └── test_services.py
├── urls.py           # App-specific URL patterns
└── views.py          # DRF ViewSets
```

> **Services Layer**: All business logic lives in `services.py`, NOT in views or models. Views only handle HTTP concerns.

---

### Dynamic Settings Engine (`apps/settings_engine`)

The most important architectural decision — zero hardcoded config.

```python
# apps/settings_engine/models.py
class SettingDefinition(models.Model):
    """Schema/definition of a setting — defined once in code"""
    key = models.CharField(max_length=100, unique=True)
    category = models.CharField(choices=SettingCategory.choices)
    data_type = models.CharField(choices=DataType.choices)
    # string | number | boolean | percentage | enum | json
    scope = models.CharField(choices=['system', 'branch'])
    default_value = models.JSONField()
    label_ar = models.CharField(max_length=200)
    label_en = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    options = models.JSONField(null=True)  # For enum type
    validation_rules = models.JSONField(null=True)
    is_sensitive = models.BooleanField(default=False)

class BranchSetting(models.Model):
    """Actual stored value per branch"""
    branch = models.ForeignKey('branches.Branch', on_delete=models.CASCADE)
    definition = models.ForeignKey(SettingDefinition, on_delete=models.CASCADE)
    value = models.JSONField()
    updated_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('branch', 'definition')
```

```python
# Resolution order: Branch setting → System default → Schema default
class SettingsService:
    @staticmethod
    def get(key: str, branch_id: int):
        try:
            setting = BranchSetting.objects.select_related('definition') \
                .get(branch_id=branch_id, definition__key=key)
            return setting.value
        except BranchSetting.DoesNotExist:
            definition = SettingDefinition.objects.get(key=key)
            return definition.default_value
```

---

## API Layer — Django REST Framework

### Key DRF Choices

| Feature | Approach |
|---------|----------|
| ViewSets | `ModelViewSet` + Custom actions (`@action`) |
| Serializers | Nested serializers for complex objects |
| Permissions | Custom permission classes per endpoint |
| Filtering | `django-filter` + `SearchFilter` + `OrderingFilter` |
| Pagination | `PageNumberPagination` (configurable per view) |
| Versioning | URL versioning `/api/v1/` |

```python
# Example: Orders ViewSet
class OrderViewSet(viewsets.ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated, BranchPermission]
    filter_backends = [DjangoFilterBackend, SearchFilter]
    filterset_class = OrderFilter

    def get_queryset(self):
        # Automatic branch scoping
        return Order.objects.filter(branch=self.request.user.branch)

    @action(detail=True, methods=['post'])
    def send_to_kitchen(self, request, pk=None):
        order = self.get_object()
        OrderService.send_to_kitchen(order)
        return Response({'status': 'sent'})

    @action(detail=True, methods=['post'])
    def pay(self, request, pk=None):
        order = self.get_object()
        payment = PaymentService.process(order, request.data)
        return Response(PaymentSerializer(payment).data)
```

---

### Multi-Branch Data Isolation

```python
# apps/core/mixins.py
class BranchScopedQuerysetMixin:
    """Auto-filter all queries to current user's branch"""
    def get_queryset(self):
        qs = super().get_queryset()
        if self.request.user.is_superadmin:
            branch_id = self.request.query_params.get('branch_id')
            if branch_id:
                return qs.filter(branch_id=branch_id)
            return qs
        return qs.filter(branch=self.request.user.branch)
```

---

### API URL Structure

```python
# config/urls.py
urlpatterns = [
    path('api/v1/auth/',      include('apps.users.urls.auth_urls')),
    path('api/v1/branches/',  include('apps.branches.urls')),
    path('api/v1/settings/',  include('apps.settings_engine.urls')),
    path('api/v1/menu/',      include('apps.menu.urls')),
    path('api/v1/kitchens/',  include('apps.kitchens.urls')),
    path('api/v1/tables/',    include('apps.tables.urls')),
    path('api/v1/orders/',    include('apps.orders.urls')),
    path('api/v1/payments/',  include('apps.payments.urls')),
    path('api/v1/shifts/',    include('apps.shifts.urls')),
    path('api/v1/delivery/',  include('apps.delivery.urls')),
    path('api/v1/reports/',   include('apps.reports.urls')),
    path('api/v1/users/',     include('apps.users.urls.user_urls')),
    path('api/v1/audit/',     include('apps.audit.urls')),
]
```

---

## Real-time Layer — Django Channels

### Why Django Channels?

| Advantage |
|-----------|
| Native Django integration (same models, auth, ORM) |
| No separate Node.js process needed |
| Uses Redis as channel layer (already in stack) |
| Supports WebSockets + HTTP long-polling fallback |
| Shares authentication with DRF (JWT) |

### WebSocket Consumers

```python
# channels_consumers/kitchen_consumer.py
from channels.generic.websocket import AsyncJsonWebsocketConsumer

class KitchenConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        self.branch_id = self.scope['url_route']['kwargs']['branch_id']
        self.kitchen_id = self.scope['url_route']['kwargs']['kitchen_id']
        self.room_group = f"kitchen_{self.branch_id}_{self.kitchen_id}"

        # JWT auth validation
        user = await self.get_authenticated_user()
        if not user or not user.has_kitchen_access(self.kitchen_id):
            await self.close(code=4003)
            return

        await self.channel_layer.group_add(self.room_group, self.channel_name)
        await self.accept()

    async def receive_json(self, content):
        action = content.get('action')
        if action == 'update_item_status':
            await self.handle_item_status_update(content)

    # Event handlers (called by group_send from Django signals)
    async def new_kitchen_order(self, event):
        await self.send_json({'type': 'new_order', 'data': event['data']})

    async def order_updated(self, event):
        await self.send_json({'type': 'order_updated', 'data': event['data']})
```

```python
# channels_consumers/routing.py
websocket_urlpatterns = [
    path('ws/kitchen/<int:branch_id>/<int:kitchen_id>/', KitchenConsumer.as_compat_view()),
    path('ws/pos/<int:branch_id>/',                      POSConsumer.as_compat_view()),
    path('ws/delivery/<int:branch_id>/',                 DeliveryConsumer.as_compat_view()),
    path('ws/driver/<int:driver_id>/',                   DriverConsumer.as_compat_view()),
]
```

### How Orders Reach Kitchen in Real-time

```python
# apps/orders/signals.py
from django.db.models.signals import post_save
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

@receiver(post_save, sender=KitchenOrder)
def push_order_to_kitchen(sender, instance, created, **kwargs):
    if created:
        channel_layer = get_channel_layer()
        group_name = f"kitchen_{instance.kitchen.branch_id}_{instance.kitchen_id}"
        async_to_sync(channel_layer.group_send)(group_name, {
            'type': 'new_kitchen_order',
            'data': KitchenOrderSerializer(instance).data,
        })
```

### Channel Layer Config (Redis)

```python
# config/settings/base.py
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer',
        'CONFIG': {
            'hosts': [('redis', 6379)],
            'capacity': 1500,
            'expiry': 10,
        },
    },
}
```

---

## Database Layer

### Primary Database: **PostgreSQL 16**

| Why PostgreSQL? |
|----------------|
| ACID compliance — critical for financial transactions |
| `JSONField` for settings, modifiers, table layouts |
| Full-text search (Arabic + English) |
| Row-level security for multi-branch isolation |
| Django ORM has excellent PostgreSQL support |
| `ArrayField`, `HStoreField` for structured data |

```python
# apps/orders/models.py
from django.db import models
from django.contrib.postgres.fields import ArrayField

class Order(models.Model):
    class OrderType(models.TextChoices):
        DINE_IN   = 'dine_in',   'صالة'
        DELIVERY  = 'delivery',  'دليفري'
        TAKEAWAY  = 'takeaway',  'تاك أواي'

    class OrderStatus(models.TextChoices):
        DRAFT     = 'draft',     'مسودة'
        CONFIRMED = 'confirmed', 'مؤكد'
        PREPARING = 'preparing', 'قيد التحضير'
        READY     = 'ready',     'جاهز'
        DELIVERED = 'delivered', 'تم التوصيل'
        CLOSED    = 'closed',    'مغلق'
        VOIDED    = 'voided',    'ملغي'

    branch      = models.ForeignKey('branches.Branch', on_delete=models.PROTECT)
    shift       = models.ForeignKey('shifts.Shift', on_delete=models.PROTECT)
    order_number= models.CharField(max_length=20)
    order_type  = models.CharField(max_length=20, choices=OrderType.choices)
    status      = models.CharField(max_length=20, choices=OrderStatus.choices)
    notes       = models.TextField(blank=True)
    created_by  = models.ForeignKey('users.User', on_delete=models.PROTECT)
    created_at  = models.DateTimeField(auto_now_add=True)
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['branch', 'created_at']),
            models.Index(fields=['shift']),
            models.Index(fields=['status']),
        ]
```

### Django ORM Benefits for This Project

```python
# Annotated queries for reports
from django.db.models import Sum, Count, Avg, F, Q

daily_summary = Order.objects.filter(
    branch=branch,
    created_at__date=today,
    status='closed'
).aggregate(
    total_revenue=Sum('total_amount'),
    total_orders=Count('id'),
    average_order=Avg('total_amount'),
    cash_total=Sum('payments__amount', filter=Q(payments__method='cash')),
    card_total=Sum('payments__amount', filter=Q(payments__method='card')),
)
```

---

### Cache Layer: **Redis 7**

| Use Case | Implementation |
|----------|----------------|
| JWT Refresh Tokens | `django-redis` cache backend |
| Settings Cache (per branch) | 10 min TTL, invalidated on update |
| Session store | Django session backend |
| Channel Layer | `channels_redis` |
| Celery Broker | Celery `redis://` broker |
| Rate limiting | `django-ratelimit` |

```python
# config/settings/base.py
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://redis:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        },
        'KEY_PREFIX': 'cashora',
    }
}
```

---

## Task Queue — Celery

### Why Celery?

| Use Case |
|----------|
| Print jobs (async — don't block API response) |
| PDF/Excel report generation |
| Shift auto-close at scheduled time |
| Email/SMS notifications to drivers |
| Database cleanup jobs |
| Aggregated analytics computation |

```python
# tasks/print_tasks.py
from celery import shared_task
from apps.printing.services import PrintService

@shared_task(bind=True, max_retries=3)
def print_receipt(self, order_id: int, printer_ip: str):
    try:
        PrintService.print_order_receipt(order_id, printer_ip)
    except Exception as exc:
        raise self.retry(exc=exc, countdown=5)

@shared_task
def generate_shift_report_pdf(shift_id: int, email_to: str = None):
    from apps.reports.services import ReportService
    pdf_path = ReportService.generate_shift_pdf(shift_id)
    if email_to:
        EmailService.send_report(email_to, pdf_path)
    return pdf_path
```

```python
# config/settings/base.py
CELERY_BROKER_URL = 'redis://redis:6379/0'
CELERY_RESULT_BACKEND = 'django-db'  # django-celery-results
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Scheduled tasks
CELERY_BEAT_SCHEDULE = {
    'auto-close-overdue-shifts': {
        'task': 'tasks.shift_tasks.auto_close_overdue_shifts',
        'schedule': crontab(minute='*/30'),
    },
}
```

---

## Frontend Stack — Next.js

### Core Framework: **Next.js 14** (App Router)

| Feature | Why Chosen |
|---------|-----------|
| App Router | Better route grouping per role (cashier/admin/etc.) |
| Server Components | Fast initial load for data-heavy pages |
| Middleware | JWT validation + role-based route protection |
| Image Optimization | Optimized menu item images |
| API Route handlers | Proxy to Django API (cookie-based auth) |

---

### UI: **shadcn/ui + Radix UI + Tailwind CSS**

```bash
# Core shadcn components
npx shadcn-ui@latest add button card dialog dropdown-menu
npx shadcn-ui@latest add table tabs select input form
npx shadcn-ui@latest add sheet badge toast calendar
npx shadcn-ui@latest add command popover scroll-area
```

**Tailwind Config for RTL + Arabic:**
```js
// tailwind.config.js
module.exports = {
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        arabic: ['Cairo', 'Tajawal', 'sans-serif'],
        latin:  ['Inter', 'sans-serif'],
      },
      colors: {
        brand:  { 50: '#f0fdf4', 500: '#22c55e', 900: '#14532d' },
        pos:    { bg: '#0f172a', card: '#1e293b', accent: '#f59e0b' },
      },
    }
  },
  plugins: [require('tailwindcss-rtl')],
}
```

---

### State Management: **Zustand**

```typescript
// stores/useCartStore.ts
interface CartState {
  items: CartItem[]
  orderType: 'dine_in' | 'delivery' | 'takeaway' | null
  tableId: number | null
  customerId: number | null
  addItem: (item: MenuItem, modifiers: ModifierOption[]) => void
  removeItem: (itemId: string) => void
  clear: () => void
  total: () => number
}

// stores/useSettingsStore.ts
interface SettingsState {
  settings: Record<string, unknown>  // Branch settings from API
  getSetting: (key: string) => unknown
  taxRate: () => number
  currency: () => string
}
```

### Data Fetching: **TanStack Query v5**

```typescript
// API client that talks to Django DRF
const useMenu = (branchId: number) =>
  useQuery({
    queryKey: ['menu', branchId],
    queryFn: () => api.get(`/menu/items/?branch=${branchId}`),
    staleTime: 5 * 60 * 1000,
  })

const useCreateOrder = () =>
  useMutation({
    mutationFn: (order: CreateOrderDTO) => api.post('/orders/', order),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['orders'] }),
  })
```

### WebSocket Client (Django Channels)

```typescript
// lib/ws/useKitchenSocket.ts
export function useKitchenSocket(branchId: number, kitchenId: number) {
  const ws = useRef<WebSocket>()

  useEffect(() => {
    ws.current = new WebSocket(
      `${process.env.NEXT_PUBLIC_WS_URL}/ws/kitchen/${branchId}/${kitchenId}/`
    )
    ws.current.onmessage = (event) => {
      const data = JSON.parse(event.data)
      if (data.type === 'new_order') {
        useOrdersStore.getState().addOrder(data.data)
        playNotificationSound()
      }
    }
    return () => ws.current?.close()
  }, [branchId, kitchenId])
}
```

---

## Printing System

### Hybrid Strategy: Browser Print + ESC/POS via Celery

#### 1. Browser-based (Default — works everywhere)
```
react-to-print → HTML receipt template → window.print()
CSS @page: { size: 80mm; margin: 0; }
```

#### 2. ESC/POS Direct via Celery Task (Thermal Printers)
```
Order saved → Celery Task → python-escpos → TCP/IP to Printer
```

```python
# apps/printing/services.py
from escpos.printer import Network

def print_kot(order_id: int, kitchen_printer_ip: str):
    """Print Kitchen Order Ticket to thermal printer"""
    order = Order.objects.prefetch_related('items__item').get(id=order_id)
    p = Network(kitchen_printer_ip)

    p.set(align='center', bold=True, custom_size=True, width=2, height=2)
    p.text(f"طلب #{order.order_number}\n")
    p.set(align='left', bold=False, normal_textsize=True)

    for item in order.items.all():
        p.text(f"{item.quantity}x {item.item.name_ar}\n")
        for modifier in item.modifiers.all():
            p.text(f"   + {modifier.name_ar}\n")
        if item.notes:
            p.text(f"   ملاحظة: {item.notes}\n")

    p.cut()
```

```
requirements: python-escpos==3.x
```

---

## Internationalization

### Backend: Django `gettext` + DRF response fields

```python
# All models have _ar and _en fields
class Category(models.Model):
    name_ar = models.CharField(max_length=100)
    name_en = models.CharField(max_length=100)

    def get_name(self, lang='ar'):
        return self.name_ar if lang == 'ar' else self.name_en
```

```python
# Serializer returns based on Accept-Language header
class CategorySerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()

    def get_name(self, obj):
        lang = self.context['request'].LANGUAGE_CODE
        return obj.name_ar if lang == 'ar' else obj.name_en
```

### Frontend: **next-intl**

```
frontend/messages/
├── ar.json     → Arabic UI strings
└── en.json     → English UI strings
```

```json
// ar.json
{
  "pos": {
    "new_order": "طلب جديد",
    "select_table": "اختر الطاولة",
    "send_to_kitchen": "إرسال للمطبخ",
    "payment": "الدفع"
  }
}
```

**RTL/LTR** — automatic via `html[lang]` + Tailwind RTL plugin.

**Arabic Fonts:**
| Font | Usage |
|------|-------|
| **Cairo** | Primary (clean, modern — great for POS) |
| **Tajawal** | Dense text tables & reports |
| **Inter** | English UI text |

---

## Authentication & Security

### JWT via `djangorestframework-simplejwt`

```python
# config/settings/base.py
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=15),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
    'AUTH_COOKIE': 'access_token',          # httpOnly cookie
    'AUTH_COOKIE_HTTP_ONLY': True,
    'AUTH_COOKIE_SECURE': True,             # HTTPS only
    'AUTH_COOKIE_SAMESITE': 'Lax',
}
```

### PIN Login for Cashiers

```python
# apps/users/views.py
class PINLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        pin = request.data.get('pin')
        branch_id = request.data.get('branch_id')
        user = User.objects.filter(
            branch_id=branch_id,
            pin_hash=make_password(pin),
            is_active=True,
            role__in=['cashier', 'kitchen']
        ).first()

        if not user:
            return Response({'error': 'PIN غير صحيح'}, status=401)

        refresh = RefreshToken.for_user(user)
        return Response({
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': UserSerializer(user).data,
        })
```

### RBAC — Django-level Permissions

```python
# apps/users/permissions.py
class IsInRole(BasePermission):
    def __init__(self, *allowed_roles):
        self.allowed_roles = allowed_roles

    def has_permission(self, request, view):
        return request.user.role in self.allowed_roles

# Usage in views
class ShiftViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated, IsInRole('cashier', 'branch_admin')]
```

### Audit Logging via Django Signals

```python
# apps/audit/signals.py
@receiver(post_save, sender=Order)
def log_order_change(sender, instance, created, **kwargs):
    AuditLog.objects.create(
        user=get_current_user(),
        branch=instance.branch,
        action='CREATE' if created else 'UPDATE',
        entity='Order',
        entity_id=instance.id,
        data=OrderSerializer(instance).data,
    )
```

---

## DevOps & Deployment

### Docker Compose

```yaml
# docker-compose.yml
services:
  backend:
    build: ./backend
    command: daphne -b 0.0.0.0 -p 8000 config.asgi:application
    environment:
      - DATABASE_URL=postgresql://cashora:password@postgres:5432/cashora
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY=${SECRET_KEY}
    depends_on: [postgres, redis]
    volumes:
      - media_files:/app/media

  celery_worker:
    build: ./backend
    command: celery -A config worker -l info -Q default,print,reports
    depends_on: [redis, postgres]

  celery_beat:
    build: ./backend
    command: celery -A config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
    depends_on: [redis, postgres]

  frontend:
    build: ./frontend
    environment:
      - NEXT_PUBLIC_API_URL=https://api.cashora.local
      - NEXT_PUBLIC_WS_URL=wss://api.cashora.local

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: cashora
      POSTGRES_USER: cashora
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - media_files:/media
    ports:
      - "80:80"
      - "443:443"
    depends_on: [backend, frontend]

volumes:
  postgres_data:
  media_files:
```

### Nginx Config

```nginx
upstream django_backend {
    server backend:8000;
}
upstream nextjs_frontend {
    server frontend:3000;
}

server {
    listen 443 ssl http2;
    server_name cashora.yourdomain.com;

    location /api/        { proxy_pass http://django_backend; }
    location /admin/      { proxy_pass http://django_backend; }
    location /static/     { alias /app/staticfiles/; }
    location /media/      { alias /media/; }
    location /ws/ {
        proxy_pass http://django_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    location /            { proxy_pass http://nextjs_frontend; }
}
```

### Environment Variables

```bash
# backend/.env.example
SECRET_KEY=your-django-secret-key-here
DEBUG=False
ALLOWED_HOSTS=cashora.yourdomain.com,localhost
DATABASE_URL=postgresql://cashora:password@postgres:5432/cashora
REDIS_URL=redis://redis:6379
CELERY_BROKER_URL=redis://redis:6379/0
MEDIA_URL=/media/
MEDIA_ROOT=/app/media/
CORS_ALLOWED_ORIGINS=https://cashora.yourdomain.com
```

```bash
# frontend/.env.local
NEXT_PUBLIC_API_URL=https://cashora.yourdomain.com
NEXT_PUBLIC_WS_URL=wss://cashora.yourdomain.com
```

---

## Development Tooling

### Backend (Python)
| Tool | Purpose |
|------|---------|
| **black** | Code formatter |
| **flake8** | Linting |
| **isort** | Import sorting |
| **mypy** | Type checking |
| **pytest-django** | Testing framework |
| **factory-boy** | Test data factories |
| **django-debug-toolbar** | Dev query inspector |
| **httpie / Bruno** | API testing |
| **pgAdmin** | Database GUI |

### Frontend (JavaScript/TypeScript)
| Tool | Purpose |
|------|---------|
| **TypeScript 5** | Type safety |
| **ESLint** | Linting |
| **Prettier** | Code formatting |
| **Husky** | Pre-commit hooks |
| **Playwright** | E2E testing |
| **Vitest** | Unit testing |

---

## Dependency Versions

### Backend (`requirements/base.txt`)
```
# Core
Django==5.0.x
djangorestframework==3.15.x
django-cors-headers==4.x

# Auth
djangorestframework-simplejwt==5.x

# Real-time
channels==4.x
channels-redis==4.x
daphne==4.x

# Database
psycopg2-binary==2.9.x
django-redis==5.x

# Task Queue
celery==5.x
django-celery-beat==2.x
django-celery-results==2.x
redis==5.x

# Filtering & Search
django-filter==24.x

# File Storage
django-storages==1.x
Pillow==10.x
boto3==1.x  # For S3

# Printing
python-escpos==3.x

# Reports
openpyxl==3.x      # Excel export
reportlab==4.x     # PDF generation
WeasyPrint==61.x   # HTML → PDF (receipt printing)

# Utils
python-decouple==3.x
django-extensions==3.x
```

### Frontend (`package.json`)
```json
{
  "dependencies": {
    "next": "14.2.x",
    "react": "18.3.x",
    "react-dom": "18.3.x",
    "next-intl": "3.x",
    "zustand": "4.x",
    "@tanstack/react-query": "5.x",
    "axios": "1.x",
    "react-hook-form": "7.x",
    "@hookform/resolvers": "3.x",
    "zod": "3.x",
    "recharts": "2.x",
    "react-to-print": "2.x",
    "react-dnd": "16.x",
    "react-dnd-html5-backend": "16.x",
    "leaflet": "1.x",
    "react-leaflet": "4.x",
    "date-fns": "3.x",
    "lucide-react": "0.x",
    "class-variance-authority": "0.7.x",
    "clsx": "2.x",
    "tailwind-merge": "2.x"
  },
  "devDependencies": {
    "typescript": "5.x",
    "tailwindcss": "3.x",
    "tailwindcss-rtl": "0.x",
    "autoprefixer": "10.x",
    "postcss": "8.x",
    "eslint": "8.x",
    "prettier": "3.x",
    "@playwright/test": "1.x"
  }
}
```

---

## Key Technical Decisions

| Decision | Chosen | Alternatives Considered | Reason |
|----------|--------|------------------------|--------|
| Backend framework | **Django 5** | FastAPI, Node.js/Express | Batteries included, ORM, admin, signals, mature |
| API layer | **DRF** | FastAPI, drf-spectacular | Native Django integration, flexible ViewSets |
| Real-time | **Django Channels** | Socket.io (Node.js) | Same codebase, no separate server, Redis-backed |
| Task queue | **Celery + Redis** | BullMQ, RQ | Django-native, production-proven |
| Frontend | **Next.js 14** | Vite+React, Remix | SSR, App Router, middleware auth |
| State mgmt | **Zustand** | Redux Toolkit, Jotai | Minimal boilerplate, perfect for POS |
| UI components | **shadcn/ui** | MUI, Ant Design | Full RTL control, copy-paste, no black box |
| Database | **PostgreSQL 16** | MySQL, SQLite | JSONField, full-text, ACID, Django ORM excellence |
| ORM | **Django ORM** | SQLAlchemy, Prisma | Built into Django, migrations, admin |
| Auth | **SimpleJWT + httpOnly** | Sessions, Auth0 | Stateless, mobile-ready, secure cookies |
| Print jobs | **Celery + python-escpos** | Browser-only | Async, doesn't block API, direct thermal printer |
| i18n backend | **Django gettext + AR/EN fields** | django-parler | Simple, fast, no extra joins |
| i18n frontend | **next-intl** | react-i18next | Native Next.js, server+client components |

---

*Last updated: April 2026 | Cashora v1.0 | Backend: Django · Frontend: Next.js*
