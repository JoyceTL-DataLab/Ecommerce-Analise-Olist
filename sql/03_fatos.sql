-- 03_fatos.sql
-- Tabelas fato (schema core).
-- Cancelados e indisponíveis ficam fora: não geram receita realizada.

-- Granularidade: 1 linha por pedido
CREATE TABLE core.fact_orders AS
WITH itm AS (
    SELECT order_id, SUM(price) AS items_value, SUM(freight_value) AS freight_value, COUNT(*) AS n_items
    FROM staging.items GROUP BY order_id
), pay AS (
    SELECT order_id, SUM(payment_value) AS total_paid
    FROM staging.payments GROUP BY order_id
)
SELECT o.order_id,
       c.customer_unique_id                      AS customer_key,
       o.order_purchase_timestamp::date          AS order_date,
       o.order_status,
       itm.items_value, itm.freight_value, itm.n_items,
       pay.total_paid,
       o.delivery_days,
       o.delay_days,
       CASE WHEN o.delay_days IS NULL THEN NULL ELSE o.delay_days > 0 END AS is_late,
       r.review_score
FROM staging.orders o
JOIN staging.customers c USING (customer_id)
JOIN itm ON itm.order_id = o.order_id
LEFT JOIN pay ON pay.order_id = o.order_id
LEFT JOIN staging.reviews r ON r.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable');

ALTER TABLE core.fact_orders ADD PRIMARY KEY (order_id);
ALTER TABLE core.fact_orders ADD FOREIGN KEY (customer_key) REFERENCES core.dim_customer;
ALTER TABLE core.fact_orders ADD FOREIGN KEY (order_date)   REFERENCES core.dim_date;
CREATE INDEX ON core.fact_orders (customer_key);
CREATE INDEX ON core.fact_orders (order_date);

-- Granularidade: 1 linha por item do pedido
CREATE TABLE core.fact_order_items AS
SELECT i.order_id, i.order_item_id, i.product_id, i.seller_id,
       o.customer_key, o.order_date,
       i.price, i.freight_value,
       i.price + i.freight_value AS gmv
FROM staging.items i
JOIN core.fact_orders o USING (order_id);

ALTER TABLE core.fact_order_items ADD PRIMARY KEY (order_id, order_item_id);
ALTER TABLE core.fact_order_items ADD FOREIGN KEY (product_id)   REFERENCES core.dim_product;
ALTER TABLE core.fact_order_items ADD FOREIGN KEY (seller_id)    REFERENCES core.dim_seller;
ALTER TABLE core.fact_order_items ADD FOREIGN KEY (customer_key) REFERENCES core.dim_customer;
ALTER TABLE core.fact_order_items ADD FOREIGN KEY (order_date)   REFERENCES core.dim_date;
CREATE INDEX ON core.fact_order_items (product_id);
CREATE INDEX ON core.fact_order_items (seller_id);
CREATE INDEX ON core.fact_order_items (order_date);
