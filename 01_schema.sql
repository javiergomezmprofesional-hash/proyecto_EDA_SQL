-- Trabajo final SQL
-- Base de datos para la tienda de deportes

DROP DATABASE IF EXISTS tienda_deportesdb;
CREATE DATABASE tienda_deportesdb;
USE tienda_deportesdb;

-- Primero creo las tablas de dimensiones

create table DIM_CATEGORIA (
    categoria_id INT PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL,
    descripcion TEXT
);

create table DIM_PRODUCTO (
    producto_id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio_actual DECIMAL(10, 2),
    categoria_id INT,
    stock_actual INT DEFAULT 0,
    FOREIGN KEY (categoria_id) REFERENCES DIM_CATEGORIA(categoria_id)
);

create table DIM_TIENDA (
    tienda_id INT PRIMARY KEY,
    ciudad VARCHAR(50),
    provincia VARCHAR(50),
    pais VARCHAR(50) DEFAULT 'España',
    tipo_tienda VARCHAR(20) -- Fisica, Online u Outlet
);

create table DIM_CLIENTE (
    cliente_id INT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    fecha_registro DATE
);

create table DIM_TIEMPO (
    fecha DATE PRIMARY KEY,
    dia INT,
    mes INT,
    anio INT,
    trimestre INT,
    es_fin_de_semana BOOLEAN
);

-- Tabla de hechos (ventas)
create table FACT_VENTAS (
    venta_id INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE,
    cliente_id INT,
    tienda_id INT,
    producto_id INT,
    cantidad INT,
    precio_unitario DECIMAL(10, 2),
    total_venta DECIMAL(10, 2), -- Se calcula cantidad * precio
    
    -- Claves foraneas
    FOREIGN KEY (fecha) REFERENCES DIM_TIEMPO(fecha),
    FOREIGN KEY (cliente_id) REFERENCES DIM_CLIENTE(cliente_id),
    FOREIGN KEY (tienda_id) REFERENCES DIM_TIENDA(tienda_id),
    FOREIGN KEY (producto_id) REFERENCES DIM_PRODUCTO(producto_id)
);

-- Indices para que la busqueda en la bbdd de clientes y productos sea más sencilla
CREATE INDEX idx_email ON DIM_CLIENTE(email);
CREATE INDEX idx_producto ON DIM_PRODUCTO(nombre);

-- Funcion para ver el tipo de venta
DELIMITER //
CREATE FUNCTION f_clasificar_venta(importe DECIMAL(10,2)) 
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE tipo VARCHAR(20);
    IF importe >= 200 THEN
        SET tipo = 'Venta Premium';
    ELSEIF importe >= 50 THEN
        SET tipo = 'Venta Estándar';
    ELSE
        SET tipo = 'Venta Menor';
    END IF;
    RETURN tipo;
END //
DELIMITER ;

-- Vista resumen
CREATE VIEW v_resumen_categorias AS
SELECT 
    c.nombre_categoria,
    COUNT(v.venta_id) as total_transacciones,
    SUM(v.total_venta) as ingresos_totales
FROM FACT_VENTAS v
JOIN DIM_PRODUCTO p ON v.producto_id = p.producto_id
JOIN DIM_CATEGORIA c ON p.categoria_id = c.categoria_id
GROUP BY c.nombre_categoria;
