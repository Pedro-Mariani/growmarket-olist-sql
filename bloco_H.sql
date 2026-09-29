-- =====================================================
-- BLOCO H - PROCEDURES / FUNCTIONS DE LEITURA (PARAMETRIZADAS)
-- Base: Olist Brazilian E-Commerce (banco growmarket)
-- No PostgreSQL, quem retorna dados e uma FUNCTION (PROCEDURE nao retorna tabela).
-- As duas functions so leem dados (SELECT); nada e alterado.
-- Periodo filtrado pela data de compra do pedido (order_purchase_timestamp).
-- =====================================================


-- H1. sp_relatorio_vendedor(id_vendedor, data_inicio, data_fim)
-- Pergunta de negocio: qual o faturamento, o ticket medio e a nota media de um vendedor em um periodo?
-- Faturamento = soma de price; ticket medio = faturamento / pedidos distintos;
-- nota media = media das avaliacoes dos pedidos do vendedor no periodo.
CREATE OR REPLACE FUNCTION sp_relatorio_vendedor(
    id_vendedor TEXT,
    data_inicio DATE,
    data_fim    DATE
)
RETURNS TABLE (
    faturamento  NUMERIC,
    ticket_medio NUMERIC,
    nota_media   NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        ROUND(SUM(i.price)::numeric, 2),
        ROUND((SUM(i.price) / NULLIF(COUNT(DISTINCT i.order_id), 0))::numeric, 2),
        (
            SELECT ROUND(AVG(r.review_score)::numeric, 2)
            FROM olist_order_reviews_dataset r
            WHERE r.order_id IN (
                SELECT i2.order_id
                FROM olist_order_items_dataset i2
                JOIN olist_orders_dataset o2
                  ON i2.order_id = o2.order_id
                WHERE i2.seller_id = id_vendedor
                  AND o2.order_purchase_timestamp::date BETWEEN data_inicio AND data_fim
            )
        )
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o
      ON i.order_id = o.order_id
    WHERE i.seller_id = id_vendedor
      AND o.order_purchase_timestamp::date BETWEEN data_inicio AND data_fim;
$$;

-- Teste: relatorio do vendedor que mais faturou, de 2017 a 2018.
SELECT *
FROM sp_relatorio_vendedor(
    (SELECT seller_id
       FROM olist_order_items_dataset
      GROUP BY seller_id
      ORDER BY SUM(price) DESC
      LIMIT 1),
    DATE '2017-01-01',
    DATE '2018-12-31'
);


-- H2. sp_relatorio_categoria(categoria, data_inicio, data_fim)
-- Pergunta de negocio: qual o faturamento total e o ticket medio de uma categoria em um periodo?
-- A categoria e informada em ingles (como na tabela de traducao), por exemplo 'computers'.
-- Ticket medio = faturamento / pedidos distintos da categoria.
CREATE OR REPLACE FUNCTION sp_relatorio_categoria(
    categoria   TEXT,
    data_inicio DATE,
    data_fim    DATE
)
RETURNS TABLE (
    faturamento_total NUMERIC,
    ticket_medio      NUMERIC
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        ROUND(SUM(i.price)::numeric, 2),
        ROUND((SUM(i.price) / NULLIF(COUNT(DISTINCT i.order_id), 0))::numeric, 2)
    FROM olist_order_items_dataset i
    JOIN olist_orders_dataset o
      ON i.order_id = o.order_id
    JOIN olist_products_dataset p
      ON i.product_id = p.product_id
    JOIN product_category_name_translation t
      ON p.product_category_name = t.product_category_name
    WHERE t.product_category_name_english = categoria
      AND o.order_purchase_timestamp::date BETWEEN data_inicio AND data_fim;
$$;

-- Teste: categoria 'computers', de 2017 a 2018.
SELECT * FROM sp_relatorio_categoria('computers', DATE '2017-01-01', DATE '2018-12-31');
