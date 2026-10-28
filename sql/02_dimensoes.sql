-- 02_dimensoes.sql
-- Dimensões do modelo estrela (schema core).

-- Calendário: um registro por dia entre set/2016 e dez/2018
CREATE TABLE core.dim_date AS
SELECT d::date                            AS date_key,
       EXTRACT(YEAR    FROM d)::int       AS year,
       EXTRACT(QUARTER FROM d)::int       AS quarter,
       EXTRACT(MONTH   FROM d)::int       AS month,
       TO_CHAR(d, 'YYYY-MM')              AS year_month,
       EXTRACT(ISODOW  FROM d)::int       AS weekday_num,
       d::date IN ('2017-11-24', '2018-11-23') AS is_black_friday
FROM generate_series('2016-09-01'::date, '2018-12-31'::date, '1 day') d;
ALTER TABLE core.dim_date ADD PRIMARY KEY (date_key);

-- Clientes: um registro por pessoa (customer_unique_id), com a localização da compra mais recente
CREATE TABLE core.dim_customer AS
SELECT DISTINCT ON (c.customer_unique_id)
       c.customer_unique_id AS customer_key,
       c.customer_city,
       c.customer_state,
       'Brasil'             AS country
FROM staging.customers c
JOIN staging.orders o USING (customer_id)
ORDER BY c.customer_unique_id, o.order_purchase_timestamp DESC;
ALTER TABLE core.dim_customer ADD PRIMARY KEY (customer_key);

-- Produtos: categoria ausente vira 'unknown' para não perder a receita desses itens
CREATE TABLE core.dim_product AS
SELECT product_id,
       COALESCE(product_category_name, 'unknown') AS category_pt,
       product_category_name_english              AS category_en,
       product_weight_g
FROM staging.products;
ALTER TABLE core.dim_product ADD PRIMARY KEY (product_id);

-- Vendedores
CREATE TABLE core.dim_seller AS
SELECT seller_id, seller_city, seller_state, 'Brasil' AS country
FROM staging.sellers;
ALTER TABLE core.dim_seller ADD PRIMARY KEY (seller_id);
