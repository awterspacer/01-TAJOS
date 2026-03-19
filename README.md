# 01-TAJOS
Sistema de gestión de caja, portal para barberos y landing page para la barbería más potente de la región. 

# ✂ TAJOS · Sistema de Gestión para Barbería

Sistema web de gestión integral para barberías con múltiples sucursales. Corre 100% en el navegador, sin servidor propio, usando **Supabase** como backend en la nube y **GitHub Pages** como hosting estático.

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | HTML5 + CSS3 + JavaScript vanilla (sin frameworks) |
| Base de datos | [Supabase](https://supabase.com) (PostgreSQL gestionado) |
| Caché / Fallback offline | IndexedDB (nativo del navegador) |
| Hosting | GitHub Pages |
| Fuentes | Google Fonts (Bebas Neue, Barlow, Barlow Condensed) |

---

## Arquitectura de datos

El sistema usa una arquitectura **híbrida Supabase-first**:

1. Toda operación de lectura/escritura va primero a **Supabase** vía REST API.
2. Si la conexión falla o el dispositivo está offline, la operación se ejecuta en **IndexedDB** (base de datos local del navegador).
3. Las operaciones realizadas offline se encolan en `localStorage` y se sincronizan automáticamente con Supabase cuando se restaura la conexión.
4. Cada lectura exitosa desde Supabase actualiza la caché local en background.

```
Usuario
  │
  ▼
┌─────────────────────────────┐
│     Navegador (cliente)     │
│                             │
│  barberia_v01_2.html        │
│  barberos_portal.html       │
│                             │
│  ┌──────────┐  ┌─────────┐  │
│  │IndexedDB │  │ Pending │  │
│  │ (caché)  │  │  Queue  │  │
│  └────┬─────┘  └────┬────┘  │
└───────┼─────────────┼───────┘
        │             │ sync al reconectar
        ▼             ▼
┌───────────────────────────┐
│   Supabase (PostgreSQL)   │
│   REST API · RLS activo   │
└───────────────────────────┘
```

---

## Archivos del proyecto

```
tajos/
├── index.html              # Página de inicio con links a ambas apps
├── barberia_v01_2.html     # App principal: admin y cajeros
├── barberos_portal.html    # Portal exclusivo para barberos
├── supabase_schema.sql     # Schema completo para inicializar Supabase
└── README.md               # Este archivo
```

### `TAJOS-MNGMNT_v01_0.html` — App principal
Acceso para roles **Administrador** y **Cajero**. Incluye:
- Dashboard con métricas del día por sucursal
- Agenda de turnos (vista día / semana)
- Registro de cobros con múltiples métodos de pago
- Catálogo de servicios y productos con stock
- Gestión de clientes con historial
- Gestión de barberos y comisiones
- Giftcards (emisión, canje, seguimiento de saldo)
- Consumos de productos descontados en liquidación
- Reportes por período, sucursal y barbero
- Arqueo / cierre de caja
- Sistema de usuarios con roles y acceso por sucursal
- Backup y restauración en JSON / XML
- Historial de acciones por usuario

### `TAJOS-BRBRS_V01_0.html` — Portal barberos
Acceso exclusivo para barberos con login + PIN. Incluye:
- Agenda personal (día / semana)
- Resumen de servicios realizados y comisiones
- Reporte de liquidación por período
- Solicitud y seguimiento de adelantos

---

## Tablas en Supabase

| Tabla | Descripción |
|---|---|
| `barberos` | Datos de los barberos y porcentaje de comisión |
| `barbero_users` | Credenciales de acceso al portal de barberos |
| `clientes` | Clientes registrados |
| `servicios` | Catálogo de servicios con precio y duración |
| `productos` | Catálogo de productos con stock |
| `turnos` | Turnos agendados |
| `cobros` | Transacciones realizadas (items + métodos de pago en JSONB) |
| `usuarios` | Usuarios del sistema admin (admin / cajero) |
| `historial` | Log de acciones por usuario |
| `arqueos` | Cierres de caja |
| `adelantos` | Solicitudes y aprobaciones de adelantos a barberos |
| `egresos` | Consumos de productos descontados a barberos |
| `giftcards` | Tarjetas de regalo con seguimiento de saldo |
| `categorias_serv` | Categorías personalizadas de servicios |
| `categorias_prod` | Categorías personalizadas de productos |

---

## Setup inicial

### 1. Supabase

1. Crear proyecto en [supabase.com](https://supabase.com)
2. Ir a **SQL Editor → New query**
3. Pegar el contenido de `supabase_schema.sql` y ejecutar
4. Copiar desde **Settings → API**:
   - `Project URL`
   - `anon` / `public` key

### 2. Configurar credenciales

En `TAJOS-MNGMNT_v01_0.html` y `TAJOS-BRBRS_V01_0.html`, reemplazar al inicio del `<script>`:

```js
const SUPA_URL = 'https://TU_PROJECT_ID.supabase.co';
const SUPA_KEY = 'TU_ANON_KEY';
```

### 3. GitHub Pages

1. Crear repositorio en GitHub (recomendado: privado)
2. Subir todos los archivos a la rama `main`
3. Ir a **Settings → Pages → Deploy from branch → main / root**
4. El sitio queda disponible en `https://tu-usuario.github.io/nombre-repo/`

---

## Acceso por defecto

| App | Usuario | Contraseña / PIN |
|---|---|---|
| Admin (`barberia_v01_2.html`) | `admin` | `1234` |
| Portal (`barberos_portal.html`) | Definido al crear cada barbero | `1234` |

> ⚠ Cambiar las contraseñas por defecto tras el primer acceso.

---

## Seguridad

- **RLS (Row Level Security)** habilitado en todas las tablas de Supabase.
- La política actual permite acceso total a la `anon key` para simplificar el setup inicial con login propio. Se puede restringir por usuario o rol si se migra a Supabase Auth en el futuro.
- Las contraseñas de usuarios admin se almacenan en texto plano en la tabla `usuarios`. Para producción con datos sensibles se recomienda implementar hashing (bcrypt) o migrar a Supabase Auth.
- El portal de barberos usa un sistema de login + PIN independiente del sistema de usuarios admin.

---

## Comportamiento offline

El indicador en la esquina inferior derecha muestra el estado de conexión:

- 🟢 **Online** — todas las operaciones van a Supabase en tiempo real
- 🔴 **Offline** — las operaciones se guardan localmente y se encolan para sincronizar

Al recuperar la conexión, la cola se procesa automáticamente y el indicador vuelve a verde.

---

## Notas de desarrollo

- Los campos en la app usan `camelCase` (ej: `barberoId`, `fechaIngreso`). La conversión a `snake_case` para Supabase (ej: `barbero_id`, `fecha_ingreso`) se maneja automáticamente con los mapas `FIELD_TO_DB` / `FIELD_FROM_DB` definidos al inicio del script.
- Los campos `items` (cobros), `pagos` (cobros), `servicios` (turnos) y `acceso` (usuarios) se almacenan como `JSONB` en Supabase, sin necesidad de tablas relacionales adicionales.
- La función `seedData()` en el app principal crea datos de ejemplo (usuarios, servicios, productos, barberos) solo si las tablas están vacías.
