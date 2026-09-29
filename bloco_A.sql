-- =====================================================
-- BLOCO A - SELECT BASICO
-- Base: Olist Brazilian E-Commerce (banco growmarket)
-- =====================================================


-- A1. 20 pedidos entregues mais recentes
-- Pergunta de negocio: quais foram as ultimas entregas concluidas?
-- Filtra status 'delivered' e ordena pela data de entrega, da mais recente para a mais antiga.
SELECT
    order_id,
    customer_id,
    order_status,
    order_delivered_customer_date
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
ORDER BY order_delivered_customer_date DESC
LIMIT 20;


-- A2. Produtos de uma categoria especifica (filtrando pelo nome em portugues)
-- Pergunta de negocio: quais produtos existem em uma determinada categoria?
-- A tabela de traducao guarda o nome em portugues; o filtro usa esse nome ('informatica_acessorios').
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    p.product_weight_g
FROM olist_products_dataset p
JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name
WHERE t.product_category_name = 'informatica_acessorios';


-- A3. Metodos de pagamento distintos
-- Pergunta de negocio: quais formas de pagamento a plataforma aceita/registra?
SELECT DISTINCT payment_type
FROM olist_order_payments_dataset
ORDER BY payment_type;


-- A4. Produtos com peso acima de 10 kg
-- Pergunta de negocio: quais sao os produtos mais pesados (relevantes para logistica)?
-- 10 kg = 10.000 g; ordena do mais pesado para o mais leve.
SELECT
    product_id,
    product_category_name,
    product_weight_g
FROM olist_products_dataset
WHERE product_weight_g > 10000
ORDER BY product_weight_g DESC;
