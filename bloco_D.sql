-- =====================================================
-- BLOCO D - SUBQUERIES
-- Base: Olist Brazilian E-Commerce (banco growmarket)
-- Convencao: "cliente" = customer_unique_id (mesma pessoa pode ter varios customer_id)
-- Convencao: "gasto/valor" = soma de price dos itens (sem frete)
-- =====================================================


-- D1. Clientes cujo gasto total esta acima da media geral de gasto por cliente
-- Pergunta de negocio: quem sao os clientes que gastam mais que o cliente medio?
-- A subquery interna calcula o gasto de cada cliente; a do meio tira a media desses gastos.
SELECT
    c.customer_unique_id,
    SUM(i.price) AS gasto_total
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
  ON c.customer_id = o.customer_id
JOIN olist_order_items_dataset i
  ON o.order_id = i.order_id
GROUP BY c.customer_unique_id
HAVING SUM(i.price) > (
    SELECT AVG(gasto_cliente)
    FROM (
        SELECT SUM(i2.price) AS gasto_cliente
        FROM olist_customers_dataset c2
        JOIN olist_orders_dataset o2
          ON c2.customer_id = o2.customer_id
        JOIN olist_order_items_dataset i2
          ON o2.order_id = i2.order_id
        GROUP BY c2.customer_unique_id
    ) AS gastos
)
ORDER BY gasto_total DESC;


-- D2. Produtos que nunca receberam avaliacao
-- Pergunta de negocio: quais produtos nao tem nenhum feedback de cliente?
-- A avaliacao pertence ao pedido, entao o caminho e produto -> itens -> avaliacoes.
-- NOT EXISTS deixa o produto passar so se nao existir nenhuma avaliacao ligada a ele.
SELECT
    p.product_id,
    p.product_category_name
FROM olist_products_dataset p
WHERE NOT EXISTS (
    SELECT 1
    FROM olist_order_items_dataset i
    JOIN olist_order_reviews_dataset r
      ON r.order_id = i.order_id
    WHERE i.product_id = p.product_id
);


-- D3. Vendedores que venderam produtos de mais de 5 categorias diferentes
-- Pergunta de negocio: quais vendedores tem um mix de produtos mais diversificado?
-- A subquery correlacionada conta as categorias distintas de cada vendedor;
-- a consulta externa filtra quem passa de 5.
SELECT *
FROM (
    SELECT
        s.seller_id,
        s.seller_city,
        s.seller_state,
        (
            SELECT COUNT(DISTINCT p.product_category_name)
            FROM olist_order_items_dataset i
            JOIN olist_products_dataset p
              ON i.product_id = p.product_id
            WHERE i.seller_id = s.seller_id
        ) AS qtd_categorias
    FROM olist_sellers_dataset s
) AS vendedores
WHERE qtd_categorias > 5
ORDER BY qtd_categorias DESC;


-- D4. Pedidos cujo frete total e maior que o valor total dos itens
-- Pergunta de negocio: em quais pedidos o cliente pagou mais de frete do que de produto?
-- Duas subqueries correlacionadas somam frete e itens do proprio pedido (o.order_id).
SELECT
    o.order_id,
    (SELECT SUM(i.freight_value)
       FROM olist_order_items_dataset i
      WHERE i.order_id = o.order_id) AS frete_total,
    (SELECT SUM(i.price)
       FROM olist_order_items_dataset i
      WHERE i.order_id = o.order_id) AS valor_itens
FROM olist_orders_dataset o
WHERE (SELECT SUM(i.freight_value)
         FROM olist_order_items_dataset i
        WHERE i.order_id = o.order_id)
    > (SELECT SUM(i.price)
         FROM olist_order_items_dataset i
        WHERE i.order_id = o.order_id)
ORDER BY frete_total DESC;
