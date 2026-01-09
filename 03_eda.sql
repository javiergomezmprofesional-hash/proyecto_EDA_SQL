-- Consultas de prueba y analisis de datos

USE tienda_deportesdb;

-- 1. COMPROBAR QUE HAY DATOS
select * from dim_categoria;
select * from dim_producto;
select * from dim_tienda;
select * from dim_cliente;
select * from dim_tiempo;
select * from fact_ventas limit 20; -- solo veo las 20 primeras

-- 2. CONSULTAS DE AGREGACIÓN BÁSICA

-- Cuanto se ha vendido en total
SELECT 
    COUNT(venta_id) AS total_ventas,
    SUM(cantidad) AS articulos,
    SUM(total_venta) AS dinero_total,
    AVG(total_venta) AS media_ticket
FROM FACT_VENTAS;

-- Clientes nuevos por año
SELECT 
    YEAR(fecha_registro) AS anio,
    COUNT(cliente_id) AS num_clientes
FROM DIM_CLIENTE
GROUP BY YEAR(fecha_registro);

-- Valor del inventario que tenemos
SELECT 
    c.nombre_categoria,
    SUM(p.stock_actual * p.precio_actual) AS valor_stock
FROM DIM_PRODUCTO p
JOIN DIM_CATEGORIA c ON p.categoria_id = c.categoria_id
GROUP BY c.nombre_categoria;


-- 3. RANKINGS Y ANÁLISIS CON JOINS

-- Top 5 categorias con mas ingresos
SELECT 
    c.nombre_categoria,
    SUM(v.cantidad) AS vendidos,
    SUM(v.total_venta) AS total_euros
FROM FACT_VENTAS v
JOIN DIM_PRODUCTO p ON v.producto_id = p.producto_id
JOIN DIM_CATEGORIA c ON p.categoria_id = c.categoria_id
GROUP BY c.nombre_categoria
ORDER BY total_euros DESC
LIMIT 5;

-- Top 10 Clientes que mas gastan
SELECT 
    cli.nombre,
    cli.apellido,
    COUNT(v.venta_id) AS compras_hechas,
    SUM(v.total_venta) AS gastado
FROM FACT_VENTAS v
JOIN DIM_CLIENTE cli ON v.cliente_id = cli.cliente_id
GROUP BY cli.cliente_id, cli.nombre, cli.apellido
ORDER BY gastado DESC
LIMIT 10;

-- Ventas por tipo de tienda (Fisica vs Online)
SELECT 
    t.tipo_tienda,
    COUNT(v.venta_id) AS num_ventas,
    SUM(v.total_venta) AS total_ingresos
FROM FACT_VENTAS v
JOIN DIM_TIENDA t ON v.tienda_id = t.tienda_id
GROUP BY t.tipo_tienda
ORDER BY total_ingresos DESC;

-- Productos que no se han vendido nunca (Left Join)
SELECT 
    p.nombre,
    c.nombre_categoria,
    p.stock_actual
FROM DIM_PRODUCTO p
JOIN DIM_CATEGORIA c ON p.categoria_id = c.categoria_id
LEFT JOIN FACT_VENTAS v ON p.producto_id = v.producto_id
WHERE v.venta_id IS NULL;


-- 4. ANÁLISIS DE TIEMPO

-- Ventas por año y mes
SELECT 
    ti.anio,
    ti.mes,
    SUM(v.total_venta) AS ingresos
FROM FACT_VENTAS v
JOIN DIM_TIEMPO ti ON v.fecha = ti.fecha
GROUP BY ti.anio, ti.mes
ORDER BY ti.anio DESC, ti.mes DESC;

-- Ventas Fin de semana vs Laborable
SELECT 
    CASE WHEN ti.es_fin_de_semana = 1 THEN 'Fin de Semana' ELSE 'Laborable' END AS dia,
    AVG(v.total_venta) AS media_venta,
    SUM(v.total_venta) AS total
FROM FACT_VENTAS v
JOIN DIM_TIEMPO ti ON v.fecha = ti.fecha
GROUP BY ti.es_fin_de_semana;


-- 5. ACTUALIZACIONES Y BORRADOS (DML)

-- Subir precio un 5% a la categoria 1 (Futbol)
UPDATE DIM_PRODUCTO 
SET precio_actual = precio_actual * 1.05 
WHERE categoria_id = 1;

-- Borrar la venta id 1
DELETE FROM FACT_VENTAS 
WHERE venta_id = 1;


-- 6. USO DE FUNCIONES Y TRANSACCIONES

-- Pruebo la funcion de clasificacion creada en el script 01_schema
SELECT 
    venta_id, 
    total_venta, 
    f_clasificar_venta(total_venta) as tipo_compra
FROM FACT_VENTAS
LIMIT 5;

SET SQL_SAFE_UPDATES = 0; -- Desactivo el modo seguro temporalmente para poder borrar por fecha
-- Prueba de Transaccion con Rollback (deshacer cambios)
START TRANSACTION;
    -- Borro clientes antiguos
    DELETE FROM DIM_CLIENTE WHERE fecha_registro < '2023-02-01';
    
    -- Veo cuantos quedan
    SELECT COUNT(*) FROM DIM_CLIENTE;

    -- Deshago
ROLLBACK;
SET SQL_SAFE_UPDATES = 1; -- Vuelvo a activar el modo seguro


-- 7. CONSULTA AVANZADA (CTE y Window Function)
-- Ranking de tiendas por año
WITH MetricasTiendas AS (
    SELECT 
        t.ciudad,
        ti.anio,
        SUM(v.total_venta) as facturacion
    FROM FACT_VENTAS v
    JOIN DIM_TIENDA t ON v.tienda_id = t.tienda_id
    JOIN DIM_TIEMPO ti ON v.fecha = ti.fecha
    GROUP BY t.ciudad, ti.anio
),
Ranking AS (
    SELECT 
        ciudad,
        CONCAT('Año: ', CAST(anio AS CHAR)) as periodo,
        facturacion,
        RANK() OVER (PARTITION BY anio ORDER BY facturacion DESC) as puesto
    FROM MetricasTiendas
)
SELECT * FROM Ranking
WHERE puesto <= 3
ORDER BY periodo, puesto;