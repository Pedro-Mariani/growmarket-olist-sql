-- =====================================================
-- BLOCO G - VIEWS
-- Base: Olist Brazilian E-Commerce (banco growmarket)
-- =====================================================


-- G1. View vw_pedidos_completos
-- Pergunta de negocio: como ter numa unica tabela pedido, cliente, item, pagamento e vendedor para analises futuras?
-- Granularidade: uma linha por item x pagamento. Se o pedido tem varios itens e varios pagamentos,
-- ele aparece varias vezes; ao somar valores, use price OU payment_value com cuidado para nao duplicar.
CREATE OR REPLACE VIEW vw_pedidos_completos AS
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    i.price,
    i.freight_value,
    pg.payment_sequential,
    pg.payment_type,
    pg.payment_installments,
    pg.payment_value,
    s.seller_city,
    s.seller_state
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
  ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset i
  ON o.order_id = i.order_id
JOIN olist_order_payments_dataset pg
  ON o.order_id = pg.order_id
JOIN olist_sellers_dataset s
  ON i.seller_id = s.seller_id;

-- Teste da view (deve devolver linhas):
SELECT * FROM vw_pedidos_completos LIMIT 10;


-- G2. View vw_avaliacoes_categoria
-- Pergunta de negocio: qual a nota media e o volume de avaliacoes de cada categoria?
-- DISTINCT evita contar a mesma avaliacao varias vezes quando o pedido tem varios itens da categoria.
CREATE OR REPLACE VIEW vw_avaliacoes_categoria AS
SELECT
    categoria,
    COUNT(*)                             AS volume_avaliacoes,
    ROUND(AVG(review_score)::numeric, 2) AS nota_media
FROM (
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
) AS x
GROUP BY categoria;

-- Teste da view (categorias com pior nota primeiro):
SELECT * FROM vw_avaliacoes_categoria ORDER BY nota_media ASC;
