-- =====================================================
-- BLOCO E - CASE WHEN
-- Base: Olist Brazilian E-Commerce (banco growmarket)
-- Os limites de faixa (E2 e E3) sao decisoes minhas e podem ser ajustados.
-- =====================================================


-- E1. Classificar pedidos por prazo de entrega
-- Pergunta de negocio: quantos pedidos chegam antes, no dia ou depois do prometido?
-- Compara a data real de entrega com a estimada (so o dia, sem hora).
-- Apenas pedidos com data de entrega preenchida entram na analise.
SELECT
    o.order_id,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    CASE
        WHEN o.order_delivered_customer_date::date < o.order_estimated_delivery_date::date THEN 'adiantado'
        WHEN o.order_delivered_customer_date::date = o.order_estimated_delivery_date::date THEN 'no prazo'
        ELSE 'atrasado'
    END AS situacao_entrega
FROM olist_orders_dataset o
WHERE o.order_delivered_customer_date IS NOT NULL;


-- E2. Classificar clientes por faixa de gasto total
-- Pergunta de negocio: como segmentar clientes por valor gasto?
-- Faixas adotadas: bronze ate R$ 100, prata de R$ 100 a R$ 500, ouro acima de R$ 500.
SELECT
    c.customer_unique_id,
    SUM(i.price) AS gasto_total,
    CASE
        WHEN SUM(i.price) < 100  THEN 'bronze'
        WHEN SUM(i.price) <= 500 THEN 'prata'
        ELSE 'ouro'
    END AS faixa_cliente
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
  ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset i
  ON o.order_id = i.order_id
GROUP BY c.customer_unique_id
ORDER BY gasto_total DESC;


-- E3. Classificar produtos por faixa de peso
-- Pergunta de negocio: quais produtos sao leves, medios ou pesados para a logistica?
-- Faixas adotadas: leve ate 1 kg, medio ate 5 kg, pesado acima de 5 kg.
-- Produtos sem peso cadastrado ficam como 'sem peso'.
SELECT
    p.product_id,
    p.product_weight_g,
    CASE
        WHEN p.product_weight_g IS NULL  THEN 'sem peso'
        WHEN p.product_weight_g <= 1000  THEN 'leve'
        WHEN p.product_weight_g <= 5000  THEN 'medio'
        ELSE 'pesado'
    END AS faixa_peso
FROM olist_products_dataset p;


-- E4. Classificar pagamentos como a vista ou parcelado, sinalizando parcelamento longo
-- Pergunta de negocio: quanto do faturamento vem de pagamentos parcelados e quantos sao parcelamentos longos?
-- 1 parcela = a vista; 2 ou mais = parcelado; mais de 6 parcelas = parcelamento longo.
SELECT
    pg.order_id,
    pg.payment_type,
    pg.payment_installments,
    pg.payment_value,
    CASE
        WHEN pg.payment_installments <= 1 THEN 'a vista'
        ELSE 'parcelado'
    END AS tipo_pagamento,
    CASE
        WHEN pg.payment_installments > 6 THEN 'parcelamento longo'
        WHEN pg.payment_installments > 1 THEN 'parcelamento normal'
        ELSE NULL
    END AS sinalizacao_parcelamento
FROM olist_order_payments_dataset pg;
