-- =====================================================
-- BLOCO F - CTE
-- Base: Olist Brazilian E-Commerce (banco growmarket)
-- Convencao: faturamento = soma de price dos itens (sem frete)
-- =====================================================


-- F1. Faturamento mensal por estado e variacao percentual mes a mes
-- Pergunta de negocio: como o faturamento de cada estado cresce ou cai de um mes para o outro?
-- A CTE agrupa por estado e mes; LAG traz o valor do mes anterior do mesmo estado.
WITH faturamento_mensal AS (
    SELECT
        c.customer_state                                                AS estado,
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp)::date AS mes,
        SUM(i.price)                                                    AS faturamento
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
      ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset i
      ON o.order_id = i.order_id
    GROUP BY 1, 2
)
SELECT
    estado,
    mes,
    faturamento,
    LAG(faturamento) OVER (PARTITION BY estado ORDER BY mes) AS faturamento_mes_anterior,
    ROUND(
        ((faturamento - LAG(faturamento) OVER (PARTITION BY estado ORDER BY mes))
         / NULLIF(LAG(faturamento) OVER (PARTITION BY estado ORDER BY mes), 0) * 100)::numeric,
        2
    ) AS variacao_pct
FROM faturamento_mensal
ORDER BY estado, mes;


-- F2. Categorias com pior reputacao
-- Pergunta de negocio: quais categorias tem as piores notas, considerando so as com volume relevante?
-- A CTE reune volume e nota media por categoria; so entram categorias com 100 ou mais avaliacoes.
-- DISTINCT evita contar a mesma avaliacao mais de uma vez quando o pedido tem varios itens da categoria.
WITH avaliacoes_categoria AS (
    SELECT DISTINCT
        r.order_id,
        r.review_id,
        r.review_score,
        t.product_category_name_english AS categoria
    FROM olist_order_reviews_dataset r
    JOIN olist_order_items_dataset i
      ON r.order_id = i.order_id
    JOIN olist_products_dataset p
      ON i.product_id = p.product_id
    JOIN product_category_name_translation t
      ON p.product_category_name = t.product_category_name
),
reputacao AS (
    SELECT
        categoria,
        COUNT(*)                                  AS volume_avaliacoes,
        ROUND(AVG(review_score)::numeric, 2)      AS nota_media
    FROM avaliacoes_categoria
    GROUP BY categoria
)
SELECT *
FROM reputacao
WHERE volume_avaliacoes >= 100
ORDER BY nota_media ASC
LIMIT 10;


-- F3. Frete medio por estado do cliente comparado com a media geral
-- Pergunta de negocio: quais estados pagam frete acima ou abaixo da media do pais?
-- Uma CTE calcula o frete medio de cada estado; outra, a media geral; o CROSS JOIN coloca as duas lado a lado.
WITH frete_estado AS (
    SELECT
        c.customer_state       AS estado,
        AVG(i.freight_value)   AS frete_medio
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o
      ON c.customer_id = o.customer_id
    JOIN olist_order_items_dataset i
      ON o.order_id = i.order_id
    GROUP BY c.customer_state
),
frete_geral AS (
    SELECT AVG(freight_value) AS frete_medio_geral
    FROM olist_order_items_dataset
)
SELECT
    fe.estado,
    ROUND(fe.frete_medio::numeric, 2)                          AS frete_medio_estado,
    ROUND(fg.frete_medio_geral::numeric, 2)                    AS frete_medio_geral,
    ROUND((fe.frete_medio - fg.frete_medio_geral)::numeric, 2) AS diferenca,
    CASE
        WHEN fe.frete_medio > fg.frete_medio_geral THEN 'acima da media'
        ELSE 'abaixo da media'
    END AS comparacao
FROM frete_estado fe
CROSS JOIN frete_geral fg
ORDER BY fe.frete_medio DESC;
