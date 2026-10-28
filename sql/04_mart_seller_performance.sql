-- 04_mart_seller_performance.sql
-- Mart de desempenho por vendedor: volume, atraso e nota média.
-- Um pedido com vários itens do mesmo vendedor conta uma única vez (DISTINCT).

CREATE TABLE marts.seller_performance AS
WITH so AS (SELECT DISTINCT seller_id, order_id FROM core.fact_order_items)
SELECT so.seller_id,
       s.seller_state,
       COUNT(*)                                      AS orders,
       COUNT(*) FILTER (WHERE o.is_late)             AS late_orders,
       COUNT(*) FILTER (WHERE o.is_late IS NOT NULL) AS delivered_orders,
       ROUND(100.0 * COUNT(*) FILTER (WHERE o.is_late)
             / NULLIF(COUNT(*) FILTER (WHERE o.is_late IS NOT NULL), 0), 1) AS late_pct,
       ROUND(AVG(o.review_score), 2)                 AS avg_score
FROM so
JOIN core.fact_orders o ON o.order_id = so.order_id
JOIN core.dim_seller  s ON s.seller_id = so.seller_id
GROUP BY so.seller_id, s.seller_state;
ALTER TABLE marts.seller_performance ADD PRIMARY KEY (seller_id);
