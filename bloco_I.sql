-- =====================================================
-- BLOCO I - WINDOW FUNCTIONS
-- Base: Olist Brazilian E-Commerce (banco growmarket)
-- Convencao: faturamento = soma de price dos itens (sem frete)
-- Estado do vendedor = seller_state; mes = mes da compra do pedido.
-- =====================================================


-- I1. Ranking de vendedores por faturamento dentro de cada estado
-- Pergunta de negocio: quem sao os melhores vendedores de cada estado?
-- RANK() reinicia a contagem em cada estado (PARTITION BY) e ordena pelo maior faturamento.
WITH faturamento_vendedor AS (
    SELECT
        s.seller_state AS estado,
        i.seller_id,
        SUM(i.price)   AS faturamento
    FROM olist_order_items_dataset i
    JOIN olist_sellers_dataset s
      ON i.seller_id = s.seller_id
    GROUP BY s.seller_state, i.seller_id
)
SELECT
    estado,
    seller_id,
    faturamento,
    RANK() OVER (PARTITION BY estado ORDER BY faturamento DESC) AS ranking
FROM faturamento_vendedor
ORDER BY estado, ranking;


-- I2. Faturamento mensal acumulado por vendedor
-- Pergunta de negocio: como o faturamento de cada vendedor se acumula ao longo do tempo?
-- A CTE calcula o faturamento de cada vendedor por mes; SUM() OVER acumula mes a mes.
WITH faturamento_mensal AS (
    SELECT
        i.seller_id,
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp)::date AS mes,
        SUM(i.price) AS faturamento
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o
      ON i.order_id = o.order_id
    GROUP BY 1, 2
)
SELECT
    seller_id,
    mes,
    faturamento,
    SUM(faturamento) OVER (PARTITION BY seller_id ORDER BY mes) AS faturamento_acumulado
FROM faturamento_mensal
ORDER BY seller_id, mes;


-- I3. Participacao percentual de cada vendedor no faturamento do seu estado
-- Pergunta de negocio: quanto cada vendedor representa do faturamento total do proprio estado?
-- SUM() OVER (PARTITION BY estado) traz o total do estado em cada linha; a divisao da o percentual.
WITH faturamento_vendedor AS (
    SELECT
        s.seller_state AS estado,
        i.seller_id,
        SUM(i.price)   AS faturamento
    FROM olist_order_items_dataset i
    JOIN olist_sellers_dataset s
      ON i.seller_id = s.seller_id
    GROUP BY s.seller_state, i.seller_id
)
SELECT
    estado,
    seller_id,
    faturamento,
    SUM(faturamento) OVER (PARTITION BY estado) AS faturamento_estado,
    ROUND((faturamento / SUM(faturamento) OVER (PARTITION BY estado) * 100)::numeric, 2) AS participacao_pct
FROM faturamento_vendedor
ORDER BY estado, participacao_pct DESC;


-- I4. Variacao de faturamento de um mes para o outro por vendedor
-- Pergunta de negocio: o faturamento de cada vendedor esta crescendo ou caindo mes a mes?
-- LAG() traz o faturamento do mes anterior do mesmo vendedor; a primeira linha de cada vendedor fica sem comparacao (NULL).
WITH faturamento_mensal AS (
    SELECT
        i.seller_id,
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp)::date AS mes,
        SUM(i.price) AS faturamento
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o
      ON i.order_id = o.order_id
    GROUP BY 1, 2
)
SELECT
    seller_id,
    mes,
    faturamento,
    LAG(faturamento) OVER (PARTITION BY seller_id ORDER BY mes) AS faturamento_mes_anterior,
    ROUND((faturamento - LAG(faturamento) OVER (PARTITION BY seller_id ORDER BY mes))::numeric, 2) AS variacao_reais,
    ROUND(
        ((faturamento - LAG(faturamento) OVER (PARTITION BY seller_id ORDER BY mes))
         / NULLIF(LAG(faturamento) OVER (PARTITION BY seller_id ORDER BY mes), 0) * 100)::numeric,
        2
    ) AS variacao_pct
FROM faturamento_mensal
ORDER BY seller_id, mes;
