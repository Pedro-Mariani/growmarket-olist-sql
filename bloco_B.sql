-- =====================================================
-- BLOCO B - JOINS
-- Base: Olist Brazilian E-Commerce (banco growmarket)
-- =====================================================


-- B1. Categoria (traduzida), valor do item e cidade do vendedor
-- Pergunta de negocio: quanto vale cada item vendido, em qual categoria e de qual cidade saiu?
SELECT
    t.product_category_name_english AS categoria,
    i.price                         AS valor_item,
    s.seller_city                   AS cidade_vendedor
FROM olist_order_items_dataset i
JOIN olist_products_dataset p
  ON i.product_id = p.product_id
JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name
JOIN olist_sellers_dataset s
  ON i.seller_id = s.seller_id;


-- B2. Pedidos entregues com atraso
-- Pergunta de negocio: quais pedidos chegaram depois da data estimada e em qual cidade/estado do cliente?
-- Compara entrega real com estimada (so o dia); dias_atraso = diferenca em dias.
SELECT
    o.order_id,
    c.customer_city,
    c.customer_state,
    o.order_estimated_delivery_date,
    o.order_delivered_customer_date,
    (o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date) AS dias_atraso
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
  ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date
ORDER BY dias_atraso DESC;


-- B3. Pedidos e suas formas de pagamento (incluindo parcelas)
-- Pergunta de negocio: como cada pedido foi pago e em quantas parcelas?
-- Um pedido pode ter varios pagamentos, entao pode aparecer em mais de uma linha.
SELECT
    o.order_id,
    o.order_status,
    pg.payment_sequential,
    pg.payment_type,
    pg.payment_installments,
    pg.payment_value
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset pg
  ON o.order_id = pg.order_id
ORDER BY pg.payment_installments DESC, o.order_id;


-- B4. Produtos com categoria traduzida, incluindo os sem traducao
-- Pergunta de negocio: quais produtos ficam sem categoria em ingles?
-- LEFT JOIN mantem os produtos mesmo quando a categoria nao tem traducao (campo vem NULL).
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english
FROM olist_products_dataset p
LEFT JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name;

-- B4 (conferencia): total de produtos, com traducao e sem traducao.
-- Esperado: 32951 total, 32328 com traducao, 623 sem traducao.
SELECT
    COUNT(*)                                        AS total_produtos,
    COUNT(t.product_category_name_english)          AS com_traducao,
    COUNT(*) - COUNT(t.product_category_name_english) AS sem_traducao
FROM olist_products_dataset p
LEFT JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name;


-- B5. Pedidos em que cliente e vendedor sao do mesmo estado
-- Pergunta de negocio: quantas vendas acontecem dentro do mesmo estado?
-- Esperado: 40756 linhas (itens) e 35600 pedidos distintos.
SELECT
    COUNT(*)                   AS linhas,
    COUNT(DISTINCT o.order_id) AS pedidos_distintos
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
  ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset i
  ON o.order_id = i.order_id
JOIN olist_sellers_dataset s
  ON i.seller_id = s.seller_id
WHERE c.customer_state = s.seller_state;
