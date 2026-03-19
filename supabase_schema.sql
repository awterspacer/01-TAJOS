-- ═══════════════════════════════════════════════════════════════
-- TAJOS · Schema Supabase
-- Pegar completo en: Supabase → SQL Editor → New query → Run
-- ═══════════════════════════════════════════════════════════════

-- ── EXTENSIONES ──────────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ── BARBEROS ─────────────────────────────────────────────────
create table if not exists barberos (
  id          bigserial primary key,
  nombre      text not null,
  apellido    text not null,
  fecha_ingreso date,
  local       int default 1,       -- 1=Central, 2=Superseis, 0=Ambas
  comision    int default 50,
  email       text,
  activo      boolean default true,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ── BARBERO_USERS (acceso al portal) ─────────────────────────
create table if not exists barbero_users (
  id          bigserial primary key,
  barbero_id  bigint references barberos(id) on delete cascade,
  login       text unique not null,
  pin         text not null,
  activo      boolean default true,
  ultimo_acceso text,
  created_at  timestamptz default now()
);

-- ── CLIENTES ─────────────────────────────────────────────────
create table if not exists clientes (
  id          bigserial primary key,
  nombre      text not null,
  apellido    text not null,
  documento   text,
  celular     text,
  email       text,
  notas       text,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ── CATEGORIAS_SERV / CATEGORIAS_PROD ────────────────────────
create table if not exists categorias_serv (
  id    bigserial primary key,
  nombre text not null,
  created_at timestamptz default now()
);

create table if not exists categorias_prod (
  id    bigserial primary key,
  nombre text not null,
  created_at timestamptz default now()
);

-- ── SERVICIOS ────────────────────────────────────────────────
create table if not exists servicios (
  id          bigserial primary key,
  nombre      text not null,
  precio      numeric default 0,
  duracion    int default 30,
  categoria   text,
  descripcion text,
  activo      boolean default true,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ── PRODUCTOS ────────────────────────────────────────────────
create table if not exists productos (
  id          bigserial primary key,
  nombre      text not null,
  precio      numeric default 0,
  stock       int default 0,
  categoria   text,
  descripcion text,
  activo      boolean default true,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ── TURNOS ───────────────────────────────────────────────────
create table if not exists turnos (
  id              bigserial primary key,
  cliente_id      bigint references clientes(id) on delete set null,
  cliente_nombre  text,
  barbero_id      bigint references barberos(id) on delete set null,
  fecha           date not null,
  hora            text not null,
  local           int default 1,
  servicios       jsonb default '[]',   -- array de strings con nombres de servicio
  notas           text,
  estado          text default 'pendiente', -- pendiente | completado | cancelado
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- ── COBROS ───────────────────────────────────────────────────
create table if not exists cobros (
  id          bigserial primary key,
  cliente_id  bigint references clientes(id) on delete set null,
  barbero_id  bigint references barberos(id) on delete set null,
  fecha       date not null,
  hora        text,
  local       int default 1,
  items       jsonb default '[]',   -- [{tipo, id, nombre, precio}]
  pagos       jsonb default '[]',   -- [{metodo, monto}]
  total       numeric default 0,
  factura     numeric default 0,
  giftcard_id bigint,
  registrado_por text,
  created_at  timestamptz default now()
);

-- ── USUARIOS (admin/cajero) ───────────────────────────────────
create table if not exists usuarios (
  id          bigserial primary key,
  login       text unique not null,
  password    text not null,
  nombre      text not null,
  apellido    text not null,
  email       text,
  rol         text default 'cajero',  -- admin | cajero
  estado      text default 'activo',  -- activo | inactivo
  acceso      jsonb default '{"central":true,"superseis":true}',
  ultimo_acceso text,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- ── HISTORIAL ────────────────────────────────────────────────
create table if not exists historial (
  id      bigserial primary key,
  usuario text,
  nombre  text,
  rol     text,
  accion  text,
  fecha   date,
  hora    text,
  ts      timestamptz default now()
);

-- ── ARQUEOS ──────────────────────────────────────────────────
create table if not exists arqueos (
  id          bigserial primary key,
  fecha       date not null,
  local       int default 1,
  turno       int default 1,
  cajero      text,
  detalle     jsonb default '{}',
  total       numeric default 0,
  nota        text,
  created_at  timestamptz default now()
);

-- ── ADELANTOS ────────────────────────────────────────────────
create table if not exists adelantos (
  id                bigserial primary key,
  barbero_id        bigint references barberos(id) on delete cascade,
  barbero_nombre    text,
  monto_solicitado  numeric default 0,
  monto_aprobado    numeric,
  estado            text default 'pendiente',  -- pendiente | aprobado | rechazado
  fecha_solicitud   date,
  nota_solicitud    text,
  nota_admin        text,
  fecha_aprobacion  date,
  ts                timestamptz default now()
);

-- ── EGRESOS (consumos de productos por barberos) ──────────────
create table if not exists egresos (
  id              bigserial primary key,
  barbero_id      bigint references barberos(id) on delete set null,
  barbero_nombre  text,
  producto_id     bigint references productos(id) on delete set null,
  producto        text,
  cantidad        int default 1,
  monto           numeric default 0,
  nota            text,
  registrado_por  text,
  fecha           date not null,
  created_at      timestamptz default now()
);

-- ── GIFTCARDS ────────────────────────────────────────────────
create table if not exists giftcards (
  id          bigserial primary key,
  codigo      text unique not null,
  cliente_id  bigint references clientes(id) on delete set null,
  valor       numeric not null,
  saldo       numeric not null,
  metodo_pago text,
  nota        text,
  estado      text default 'disponible',  -- disponible | vigente | canjeada
  fecha       date,
  ultimo_uso  date,
  created_at  timestamptz default now()
);

-- ═══════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- Habilitar RLS en todas las tablas.
-- Con anon key + RLS deshabilitado en client-side, cualquier
-- llamada desde el frontend puede leer/escribir. Si querés
-- restringir acceso más adelante, configurá policies aquí.
-- ═══════════════════════════════════════════════════════════════
alter table barberos          enable row level security;
alter table barbero_users     enable row level security;
alter table clientes          enable row level security;
alter table categorias_serv   enable row level security;
alter table categorias_prod   enable row level security;
alter table servicios         enable row level security;
alter table productos         enable row level security;
alter table turnos            enable row level security;
alter table cobros            enable row level security;
alter table usuarios          enable row level security;
alter table historial         enable row level security;
alter table arqueos           enable row level security;
alter table adelantos         enable row level security;
alter table egresos           enable row level security;
alter table giftcards         enable row level security;

-- POLICIES: acceso total desde anon key (para uso con login propio)
-- Podés hacer estas policies más restrictivas cuando tengas Auth.
do $$
declare
  t text;
  tables text[] := array[
    'barberos','barbero_users','clientes','categorias_serv','categorias_prod',
    'servicios','productos','turnos','cobros','usuarios','historial',
    'arqueos','adelantos','egresos','giftcards'
  ];
begin
  foreach t in array tables loop
    execute format('
      create policy if not exists "allow_all_%s"
      on %s for all
      to anon, authenticated
      using (true)
      with check (true);
    ', t, t);
  end loop;
end $$;

-- ═══════════════════════════════════════════════════════════════
-- ÍNDICES para mejorar performance en queries frecuentes
-- ═══════════════════════════════════════════════════════════════
create index if not exists idx_cobros_fecha        on cobros(fecha);
create index if not exists idx_cobros_barbero      on cobros(barbero_id);
create index if not exists idx_cobros_local        on cobros(local);
create index if not exists idx_turnos_fecha        on turnos(fecha);
create index if not exists idx_turnos_barbero      on turnos(barbero_id);
create index if not exists idx_adelantos_barbero   on adelantos(barbero_id);
create index if not exists idx_egresos_barbero     on egresos(barbero_id);
create index if not exists idx_historial_ts        on historial(ts desc);
create index if not exists idx_barbero_users_login on barbero_users(login);
create index if not exists idx_usuarios_login      on usuarios(login);

-- ═══════════════════════════════════════════════════════════════
-- USUARIO ADMIN POR DEFECTO
-- login: admin  |  password: 1234
-- Cambialo desde la app después de primer acceso.
-- ═══════════════════════════════════════════════════════════════
insert into usuarios (login, password, nombre, apellido, rol, estado, acceso)
values ('admin', '1234', 'Administrador', 'TAJOS', 'admin', 'activo', '{"central":true,"superseis":true}')
on conflict (login) do nothing;
