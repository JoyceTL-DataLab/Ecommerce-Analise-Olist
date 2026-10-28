-- 05_testes.sql
-- Testes de consistência do modelo.
-- Regra: cada teste deve retornar ZERO linhas; qualquer linha retornada indica falha.
-- Cada teste começa com a marcação "-- name: <descrição>".

-- name: receita reconcilia staging x core
SELECT 'diverge' FROM (
  SELECT (SELECT SUM(i.price) FROM staging.items i
          JOIN staging.orders o USING (order_id)
          WHERE o.order_status NOT IN ('canceled','unavailable')) AS stg,
         (SELECT SUM(price) FROM core.fact_order_items) AS core_v) x
WHERE ABS(stg - core_v) > 0.01;

-- name: fact_orders sem duplicidade
SELECT order_id FROM core.fact_orders GROUP BY order_id HAVING COUNT(*) > 1;

-- name: nota válida (1 a 5)
SELECT order_id FROM core.fact_orders
WHERE review_score IS NOT NULL AND review_score NOT BETWEEN 1 AND 5;

-- name: itens sem pedido
SELECT i.order_id FROM core.fact_order_items i
LEFT JOIN core.fact_orders o USING (order_id) WHERE o.order_id IS NULL;

-- name: atraso nulo só quando não entregue
SELECT o.order_id FROM core.fact_orders o
JOIN staging.orders s USING (order_id)
WHERE s.order_delivered_customer_date IS NOT NULL AND o.is_late IS NULL;
