-- 06_consultas_analiticas.sql
-- Consultas analíticas sobre o modelo core/marts.
-- Cada consulta começa com "-- name: <id>" para poder ser executada individualmente.

-- name: crescimento_mensal
-- Receita mensal e variação mês a mês (MoM).
-- Restrito a jan/2017–ago/2018: os meses das pontas têm volume muito baixo
-- e distorcem a variação (ver EDA, seção 0.7).
WITH monthly AS (
    SELECT d.year_month, SUM(f.price)::numeric AS revenue
    FROM core.fact_order_items f
    JOIN core.dim_date d ON d.date_key = f.order_date
    WHERE d.year_month BETWEEN '2017-01' AND '2018-08'
    GROUP BY d.year_month)
SELECT year_month,
       ROUND(revenue, 0) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year_month))
             / NULLIF(LAG(revenue) OVER (ORDER BY year_month), 0), 1) AS mom_pct
FROM monthly
ORDER BY year_month;

-- name: top3_categorias_por_estado
-- As 3 categorias de maior receita em cada estado do cliente.
WITH ranked AS (
    SELECT c.customer_state, p.category_en, SUM(f.price) AS revenue,
           RANK() OVER (PARTITION BY c.customer_state ORDER BY SUM(f.price) DESC) AS rk
    FROM core.fact_order_items f
    JOIN core.dim_customer c ON c.customer_key = f.customer_key
    JOIN core.dim_product  p ON p.product_id  = f.product_id
    GROUP BY 1, 2)
SELECT * FROM ranked WHERE rk <= 3 ORDER BY customer_state, rk;

-- name: receita_por_estado
-- Top 10 estados por receita e participação no total.
SELECT c.customer_state,
       ROUND(SUM(f.price)::numeric, 0) AS revenue,
       ROUND(100.0 * SUM(f.price)::numeric / SUM(SUM(f.price)::numeric) OVER (), 1) AS pct
FROM core.fact_order_items f JOIN core.dim_customer c USING (customer_key)
GROUP BY 1 ORDER BY 2 DESC LIMIT 10;

-- name: atraso_x_nota
-- Nota média de pedidos entregues no prazo vs. atrasados.
SELECT is_late, COUNT(*) AS pedidos, ROUND(AVG(review_score), 2) AS nota_media
FROM core.fact_orders
WHERE is_late IS NOT NULL AND review_score IS NOT NULL
GROUP BY is_late;

-- name: piores_vendedores_atraso
-- Vendedores com maior taxa de atraso (mínimo de 30 pedidos entregues).
SELECT seller_id, seller_state, delivered_orders, late_pct, avg_score
FROM marts.seller_performance
WHERE delivered_orders >= 30
ORDER BY late_pct DESC
LIMIT 20;
