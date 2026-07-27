# Altiora Estates — Base de Datos

> 📌 **Estado:** En desarrollo — Fase 1 del proyecto.
> Este README cubre únicamente la parte de base de datos. Próximamente se agregarán READMEs individuales para las APIs, infraestructura, ETL y frontend, junto con un README general del proyecto.

---

## 📖 Descripción

Modelo de datos para una plataforma de bienes raíces a nivel nacional (Costa Rica), donde agencias y constructoras publican propiedades, y compradores pueden explorar, solicitar compras y calificar a las agencias.

Este módulo contiene:
- El schema completo en PostgreSQL
- Un generador de datos de prueba (seed) con Faker y datos mapeados en un archivo JSON
- Contenedores para levantar PostgreSQL + pgAdmin (de manera local)
- Carga automática de datos de prueba al iniciar (de ser necesario ejecutar el script python antes de levantar los contenedores para tener los csv)

---

## 🧱 Stack

| Componente         | Tecnología           |
|--------------------|----------------------|
| Base de datos      | PostgreSQL 16        |
| Administración     | pgAdmin 4            |
| Contenedores       | Docker               |
| Generación de datos| Python 3 + Faker     |
| Formato intermedio | CSV                  |

---

## 🗂️ Estructura de Carpetas para la Base de Datos

```
altiora-db/
├── docker-compose.yaml
├── init_db/
│   ├── schema.sql              # DDL: tablas, tipos, índices, vistas
│   ├── load_data.sql           # carga los CSVs generados
│   ├── create_data.py          # generador de datos falsos
│   ├── map_data.json           # datos base (ubicaciones, nombres de plantillas, etc.)
│   ├── Dockerfile              # carga el schema y los datos en postgres al iniciar por primera vez
│   └── docker-entrypoint-wrapper.sh
└── init_data/                  # CSVs generados
```

---

## 🧩 Modelo de datos

### Tablas principales

| Tabla                | Descripción                                                   |
|-----------------------|----------------------------------------------------------------|
| `users`               | Cuenta base — compradores, agencias y admins (próximamente)    |
| `buyer_profiles`      | Perfil personalizable del comprador                            |
| `agency_profiles`     | Perfil personalizable de agencia/constructora                  |
| `properties`          | Propiedades subidas por las agencias/constructoras             |
| `property_images`     | Imágenes asociadas a cada propiedad                            |
| `purchase_requests`   | Solicitudes de compra (pending/accepted/rejected/cancelled)    |
| `agency_reviews`      | Reseñas de compradores sobre agencias (editables)              |
| `email_logs`          | Registro de correos enviados por el sistema                    |

### Reglas de negocio implementadas en el schema

- Un comprador solo puede tener una review por agencia (constraint UNIQUE), pero puede editarla.
- Una propiedad solo puede tener una solicitud de compra activa a la vez (constraint EXCLUDE), si se rechaza se vuelve a liberar la propiedad.
- Los timestamps updated_at se actualizan automáticamente vía triggers.
- Vistas (agency_rating_summary, property_detail) preparadas anticipando el consumo de estas directo desde la API.

---

## ⚙️ Configuración

### 1. Generar datos de prueba

Esto genera los CSVs en `init_data/`, uno por tabla, con datos realistas de Costa Rica (ubicaciones, precios, nombres de agencias, reviews, etc.) usando Faker. Se debe ejecutar desde la maquina local el script para generar los csv en caso de que se deseen volver a generar. De ser el caso confirmar que la carpeta esta vacía, así no se mantendrán los registros anteriores. Algunas de las libreria necesarias de instalar de pip son:
- faker=40.28.1
- bcrypt=5.0.0
- uuid=1.30
- datetime=6.0

### 2. Levantar los contenedores

```bash
docker-compose up -d
```

Esto:
1. Crea la base de datos
2. Ejecuta `schema.sql` (crea tablas, tipos, índices, vistas)
3. Ejecuta `load_data.sql` (carga los CSVs con `\copy`)
4. Levanta pgAdmin con la conexión pre-configurada automáticamente

### 3. Acceder a pgAdmin

```
http://localhost:5050
```

El servidor "Altiora" aparece ya conectado en el panel izquierdo, sin necesidad de configurarlo manualmente.

---

## 🔄 Reiniciar con datos frescos

Si regeneras el seed y quieres recargar todo desde cero:

```bash
docker-compose down -v      # borra los volúmenes de datos
docker-compose up -d --build
```

> Los scripts de inicialización solo corren cuando el volumen de PostgreSQL está vacío.

---

## ✅ Verificación rápida

```bash
docker exec -it altiora_postgres psql -U $POSTGRES_USER -d $POSTGRES_DB
```

```sql
\dt                          -- lista todas las tablas

SELECT 'users' AS tabla, COUNT(*) FROM users
UNION ALL SELECT 'properties', COUNT(*) FROM properties
UNION ALL SELECT 'purchase_requests', COUNT(*) FROM purchase_requests;
```

---

## 📌 Pendiente

- [ ] Índices adicionales de búsqueda (intentara hallar utilidad con `unaccent` + `pg_trgm` o se dejara como esta ahorita)
- [ ] Documentar relaciones con diagrama ER

---

## 📄 Licencia

Proyecto personal con fines educativos y de portafolio.

Hecho por, Roy Silva Castellón.