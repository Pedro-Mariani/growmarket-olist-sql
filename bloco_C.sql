-- =====================================================
-- BLOCO C - FUNCOES AGREGADAS, GROUP BY E HAVING
-- Base: Olist Brazilian E-Commerce (banco growmarket)
-- Convencao: faturamento = soma de price dos itens (sem frete)
-- =====================================================


-- C1. Faturamento total por estado do cliente
-- Pergunta de negocio: quais estados geram mais receita?
-- Esperado na 1a linha: SP, 5.202.955,05
SELECT
    c.customer_state AS estado,
    SUM(i.price)     AS faturamento
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
  ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset i
  ON o.order_id = i.order_id
GROUP BY c.customer_state
ORDER BY faturamento DESC;


-- C2. Top 10 vendedores por faturamento
-- Pergunta de negocio: quem sao os vendedores que mais faturam?
-- Esperado na 1a linha: vendedor 4869f7a5..., 229.472,63
SELECT
    i.seller_id,
    SUM(i.price) AS faturamento
FROM olist_order_items_dataset i
GROUP BY i.seller_id
ORDER BY faturamento DESC
LIMIT 10;


-- C3. Ticket medio por categoria de produto
-- Pergunta de negocio: quanto, em media, cada pedido gasta em uma categoria?
-- Primeiro soma o valor de cada categoria dentro de cada pedido; depois tira a media.
-- Esperado na 1a linha: computers, 1.231,84
SELECT
    categoria,
    ROUND(AVG(valor_pedido_categoria)::numeric, 2) AS ticket_medio
FROM (
    SELECT
        i.order_id,
        t.product_category_name_english AS categoria,
        SUM(i.price)                    AS valor_pedido_categoria
    FROM olist_order_items_dataset i
    JOIN olist_products_dataset p
      ON i.product_id = p.product_id
    JOIN product_category_name_translation t
      ON p.product_category_name = t.product_category_name
    GROUP BY i.order_id, t.product_category_name_english
) AS x
GROUP BY categoria
ORDER BY ticket_medio DESC;


-- C4. Vendedores com nota media de avaliacao abaixo de 3
-- Pergunta de negocio: quais vendedores tem reputacao ruim?
-- A avaliacao pertence ao pedido; o vinculo com o vendedor e feito pelos itens.
-- HAVING filtra depois de calcular a media. Esperado: 342 linhas.
SELECT
    i.seller_id,
    ROUND(AVG(r.review_score)::numeric, 2) AS nota_media
FROM olist_order_items_dataset i
JOIN olist_order_reviews_dataset r
  ON i.order_id = r.order_id
GROUP BY i.seller_id
HAVING AVG(r.review_score) < 3
ORDER BY nota_media;


-- C5. Quantidade de pedidos por forma de pagamento
-- Pergunta de negocio: quais formas de pagamento os clientes mais usam?
-- COUNT(DISTINCT) evita contar duas vezes pedidos com mais de um pagamento.
-- Esperado: credit_card 76.505, boleto 19.784, voucher 3.866, debit_card 1.528, not_defined 3
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS qtd_pedidos
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY qtd_pedidos DESC;


-- C6. Peso medio dos produtos por categoria
-- Pergunta de negocio: quais categorias tem os produtos mais pesados, em media?
-- Esperado na 1a linha: furniture_mattress_and_upholstery, 13.190 g
SELECT
    t.product_category_name_english AS categoria,
    ROUND(AVG(p.product_weight_g)::numeric, 0) AS peso_medio_g
FROM olist_products_dataset p
JOIN product_category_name_translation t
  ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY peso_medio_g DESC;


-- C7. Numero medio de parcelas por categoria de produto
-- Pergunta de negocio: em quais categorias o cliente mais parcela a compra?
-- DISTINCT evita contar o mesmo pagamento varias vezes quando o pedido tem varios itens da mesma categoria.
-- Esperado na 1a linha: computers, 5,98
SELECT
    categoria,
    ROUND(AVG(payment_installments)::numeric, 2) AS parcelas_media
FROM (
    SELECT DISTINCT
        i.order_id,
        t.product_category_name_english AS categoria,
        pg.payment_sequential,
        pg.payment_installments
    FROM olist_order_items_dataset i
    JOIN olist_products_dataset p
      ON i.product_id = p.product_id
    JOIN product_category_name_translation t
      ON p.product_category_name = t.product_category_name
    JOIN olist_order_payments_dataset pg
      ON i.order_id = pg.order_id
) AS x
GROUP BY categoria
ORDER BY parcelas_media DESC;
