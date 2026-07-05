# API Restaurante — Reservaciones con JWT y Swagger

API REST profesional para la gestión de reservaciones de un restaurante. Permite que los
clientes se registren, inicien sesión y reserven mesas, mientras que los administradores
gestionan el catálogo de mesas y el estado de las reservaciones.

Construida con **Node.js + Express**, autenticación **JWT**, contraseñas encriptadas con
**bcryptjs**, control de acceso por **roles** (`cliente` / `admin`), base de datos
**PostgreSQL**, y documentación interactiva con **Swagger UI**.

---

## Tecnologías utilizadas

- **Node.js** + **Express** — servidor y enrutamiento
- **PostgreSQL** (`pg`) — base de datos relacional
- **jsonwebtoken** — autenticación basada en JWT
- **bcryptjs** — encriptación de contraseñas (implementación 100% JavaScript, sin
  dependencias nativas — evita problemas de compilación en cualquier entorno o proveedor de
  hosting)
- **swagger-jsdoc** + **swagger-ui-express** — documentación interactiva en `/api-docs`
- **cors**, **dotenv** — utilidades de configuración

---

## Estructura del proyecto

```
restaurante-api/
├── database/
│   ├── schema.sql          # DDL + datos de prueba (tal como se entregó)
│   └── seed.js              # Script que crea las tablas e inserta el seed
│                             # con las contraseñas ya encriptadas con bcrypt
├── src/
│   ├── config/
│   │   └── db.js            # Conexión a PostgreSQL (pool)
│   ├── middleware/
│   │   ├── auth.js          # Verifica el JWT (verificarToken)
│   │   └── roles.js         # Verifica el rol del usuario (verificarRol)
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── mesasController.js
│   │   └── reservacionesController.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── mesas.routes.js
│   │   └── reservaciones.routes.js
│   ├── swagger.js           # Configuración de swagger-jsdoc
│   └── app.js                # Configuración de Express (middlewares y rutas)
├── index.js                  # Punto de entrada — levanta el servidor
├── package.json
├── .env.example
├── .gitignore
└── README.md
```

---

## Instalación y uso local

### 1. Requisitos previos

- Node.js 18 o superior
- Una base de datos PostgreSQL (local o en la nube)

### 2. Clonar/descomprimir e instalar dependencias

```bash
cd restaurante-api
npm install
```

### 3. Configurar variables de entorno

Copia el archivo de ejemplo y edítalo con tus propios datos:

```bash
cp .env.example .env
```

Variables principales (ver `.env.example` para la lista completa):

| Variable         | Descripción                                                     |
|------------------|-------------------------------------------------------------------|
| `PORT`           | Puerto donde corre el servidor (default `3000`)                  |
| `API_BASE_URL`   | URL pública de la API (usada por Swagger)                        |
| `DATABASE_URL`   | Cadena de conexión completa a PostgreSQL                         |
| `DB_HOST/PORT/USER/PASSWORD/NAME` | Alternativa si no usas `DATABASE_URL`            |
| `DB_SSL`         | `true` si tu proveedor exige SSL (Railway, Render, etc.)          |
| `JWT_SECRET`     | Clave secreta para firmar los tokens — **cámbiala en producción** |
| `JWT_EXPIRES_IN` | Tiempo de vida del token (ej. `2h`, `7d`)                         |

### 4. Crear las tablas y cargar los datos de prueba (seed)

El script `database/seed.js` crea las tablas del `schema.sql` y luego inserta los usuarios,
mesas y reservaciones de prueba **con las contraseñas ya encriptadas con bcrypt** (el
`schema.sql` original las trae en texto plano solo como referencia, tal como fue entregado).

```bash
npm run seed
```

Esto crea 3 usuarios de prueba (contraseña `123456` para los tres):

| Correo               | Rol      |
|----------------------|----------|
| carlos@email.com     | admin    |
| ana@email.com        | cliente  |
| luis@email.com       | cliente  |

> Si prefieres usar el `database/schema.sql` directamente con `psql` (sin encriptar las
> contraseñas del seed), también puedes hacerlo: `psql -d restaurante -f database/schema.sql`.
> Pero para probar el login necesitas contraseñas encriptadas con bcrypt, así que se
> recomienda usar `npm run seed`.

### 5. Levantar el servidor

```bash
npm start        # producción
npm run dev       # desarrollo, con recarga automática (nodemon)
```

El servidor queda disponible en `http://localhost:3000` y la documentación interactiva en:

```
http://localhost:3000/api-docs
```

---

## Endpoints

### Autenticación — `/api/auth`

| Método | Endpoint             | Descripción                          | Acceso   |
|--------|-----------------------|---------------------------------------|----------|
| POST   | `/api/auth/register`  | Registro de nuevo usuario (cliente)  | Público  |
| POST   | `/api/auth/login`     | Login — devuelve JWT firmado         | Público  |
| GET    | `/api/auth/perfil`    | Datos del usuario autenticado        | Cliente/Admin |

### Mesas — `/api/mesas`

| Método | Endpoint           | Descripción                        | Acceso  |
|--------|----------------------|--------------------------------------|---------|
| GET    | `/api/mesas`         | Listar mesas (filtro `?disponible=`) | Público |
| GET    | `/api/mesas/:id`     | Detalle de una mesa                  | Público |
| POST   | `/api/mesas`         | Crear nueva mesa                     | Admin   |
| PUT    | `/api/mesas/:id`     | Actualizar datos de mesa             | Admin   |
| DELETE | `/api/mesas/:id`     | Desactivar mesa (soft delete)        | Admin   |

### Reservaciones — `/api/reservaciones`

| Método | Endpoint                          | Descripción                            | Acceso  |
|--------|------------------------------------|-------------------------------------------|---------|
| POST   | `/api/reservaciones`               | Crear reservación (valida disponibilidad) | Cliente |
| GET    | `/api/reservaciones/mis`           | Mis reservaciones (usuario actual)       | Cliente |
| GET    | `/api/reservaciones`               | Todas las reservaciones, con filtros     | Admin   |
| PUT    | `/api/reservaciones/:id/estado`    | Cambiar estado de una reservación        | Admin   |
| DELETE | `/api/reservaciones/:id`           | Cancelar la propia reservación           | Cliente |

Todos los endpoints protegidos requieren el header:

```
Authorization: Bearer <token>
```

El token se obtiene en `/api/auth/login`.

---

## Reglas de negocio implementadas

- Todo nuevo registro (`/api/auth/register`) siempre se crea con rol `cliente`. No existe un
  endpoint público para crear administradores.
- Antes de confirmar una reservación, el sistema valida que:
  - La mesa exista y esté marcada como `disponible`.
  - El número de `personas` no exceda la `capacidad` de la mesa.
  - No exista ya otra reservación **pendiente o confirmada** para esa misma mesa, fecha y
    hora (se permite volver a reservar el mismo bloque si la reservación anterior fue
    `cancelada`).
- `DELETE /api/mesas/:id` es un **soft delete**: no borra el registro, solo pone
  `disponible = false`.
- `DELETE /api/reservaciones/:id` solo cancela (cambia `estado` a `cancelada`) y únicamente
  si la reservación pertenece al usuario autenticado.
- Las contraseñas nunca se guardan ni se devuelven en texto plano; se encriptan con bcrypt
  (10 salt rounds) antes de guardarse.

---

## Pruebas realizadas

El proyecto fue probado de extremo a extremo (registro, login, roles, creación de mesas,
creación/consulta/cancelación de reservaciones, y validación de conflictos de horario) contra
una base de datos PostgreSQL real antes de la entrega. Todos los flujos de la tabla de
endpoints funcionan correctamente.

---

## Despliegue en producción (Railway / Render / Fly.io)

Pasos generales (ejemplo con **Railway**, aplican de forma equivalente a Render o Fly.io):

1. Sube el proyecto a un repositorio de GitHub.
2. Crea un nuevo proyecto en [Railway](https://railway.app) y conéctalo a tu repositorio.
3. Agrega un servicio de **PostgreSQL** desde el marketplace de Railway; Railway generará
   automáticamente una variable `DATABASE_URL`.
4. En las variables de entorno del servicio de la API, configura:
   - `DATABASE_URL` → la que generó Railway (o copia la de tu servicio de Postgres)
   - `DB_SSL=true`
   - `JWT_SECRET` → una clave larga y aleatoria
   - `JWT_EXPIRES_IN=2h`
   - `API_BASE_URL` → la URL pública que te asigna Railway, para que Swagger la muestre bien
5. En el comando de arranque usa `npm start`.
6. Una vez desplegado, ejecuta el seed una sola vez contra la base de datos de producción
   (por ejemplo desde la consola/shell de Railway): `npm run seed`.
7. Verifica que la API responda en `https://<tu-app>.up.railway.app/` y que la documentación
   esté disponible en `https://<tu-app>.up.railway.app/api-docs`.

> Recuerda actualizar la URL base de la API desplegada en la sección de entregables de tu
> actividad una vez tengas el enlace definitivo.

---

## Notas

- El archivo `database/schema.sql` se conserva exactamente como fue proporcionado, como
  documentación oficial del esquema.
- `database/seed.js` es el script recomendado para poblar la base de datos, ya que aplica
  bcrypt a las contraseñas de prueba antes de insertarlas (el `schema.sql` las trae en texto
  plano únicamente como referencia del diseño original).
