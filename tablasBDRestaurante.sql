-- ============================================
-- API RESTAURANTE - Script de Base de Datos
-- ============================================

-- ============================================
-- TABLA: usuarios
-- ============================================
CREATE TABLE usuarios (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    correo      VARCHAR(100) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    rol         VARCHAR(20) NOT NULL DEFAULT 'cliente' CHECK (rol IN ('cliente', 'admin')),
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- TABLA: mesas
-- ============================================
CREATE TABLE mesas (
    id          SERIAL PRIMARY KEY,
    numero      INT NOT NULL UNIQUE,
    capacidad   INT NOT NULL,
    disponible  BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- TABLA: reservaciones
-- ============================================
CREATE TABLE reservaciones (
    id          SERIAL PRIMARY KEY,
    fecha       DATE NOT NULL,
    hora        TIME NOT NULL,
    personas    INT NOT NULL,
    estado      VARCHAR(20) NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'confirmada', 'cancelada')),
    usuario_id  INT NOT NULL REFERENCES usuarios(id),
    mesa_id     INT NOT NULL REFERENCES mesas(id),
    created_at  TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- DATOS DE PRUEBA
-- ============================================

-- Usuarios (passwords son solo de prueba, en produccion van encriptadas con bcrypt)
INSERT INTO usuarios (nombre, correo, password, rol) VALUES
    ('Carlos Mendoza', 'carlos@email.com', '123456', 'admin'),
    ('Ana García',     'ana@email.com',    '123456', 'cliente'),
    ('Luis Pérez',     'luis@email.com',   '123456', 'cliente');

-- Mesas
INSERT INTO mesas (numero, capacidad, disponible) VALUES
    (1, 2, TRUE),
    (2, 4, TRUE),
    (3, 6, FALSE);

-- Reservaciones
INSERT INTO reservaciones (fecha, hora, personas, estado, usuario_id, mesa_id) VALUES
    ('2026-06-25', '12:00', 2, 'confirmada', 2, 1),
    ('2026-06-25', '14:00', 4, 'pendiente',  3, 2),
    ('2026-06-26', '19:00', 5, 'pendiente',  2, 3);

-- ============================================
-- VERIFICAR DATOS
-- ============================================
SELECT * FROM usuarios;
SELECT * FROM mesas;
SELECT * FROM reservaciones;
