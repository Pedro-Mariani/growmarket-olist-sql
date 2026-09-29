# GrowMarket: análise SQL da base Olist

Desafio de SQL (DQL) sobre o Olist Brazilian E-Commerce Public Dataset
(~100 mil pedidos, 2016 a 2018), feito com PostgreSQL local e DBeaver.

## Como reproduzir
1. Importar os CSVs do Kaggle no PostgreSQL (banco `growmarket`).
2. Rodar os scripts `bloco_A.sql` a `bloco_I.sql`, nessa ordem
   (o bloco G cria views usadas depois).

## Estrutura
| Arquivo | Conteúdo |
|---|---|
| bloco_A.sql | SELECT básico |
| bloco_B.sql | JOINs |
| bloco_C.sql | Agregações, GROUP BY e HAVING |
| bloco_D.sql | Subqueries |
| bloco_E.sql | CASE WHEN |
| bloco_F.sql | CTEs |
| bloco_G.sql | Views |
| bloco_H.sql | Functions de leitura |
| bloco_I.sql | Window functions |

## Decisões de análise
- Faturamento = soma de `price` dos itens, sem frete.
- Cliente = `customer_unique_id` (a mesma pessoa pode ter vários `customer_id`).
- Nas contagens por pedido usei `COUNT(DISTINCT order_id)` para não duplicar
  pedidos com vários itens ou vários pagamentos.
- Faixas de cliente (bronze/prata/ouro) e de peso (leve/médio/pesado)
  são limites definidos por mim e estão comentados nos scripts.
- "Volume relevante" de avaliações = pelo menos 100 por categoria.

## Principais insights
- **Estado líder:** SP concentra o maior faturamento, com R$ 5.202.955,05.
- **Qualidade dos dados:** dos 32.951 produtos, 623 não têm tradução de
  categoria (610 sem categoria e 13 de duas categorias fora da tabela de
  tradução). Um JOIN comum esconderia esses produtos; o LEFT JOIN os mantém.
- **Pagamento:** cartão de crédito domina, com 76.505 pedidos, contra 19.784
  de boleto, 3.866 de voucher e 1.528 de débito.
- **Parcelamento:** computers é a categoria com mais parcelas em média (5,98).
- **Logística:** 36,1% dos pedidos têm cliente e vendedor no mesmo estado;
  a maior parte das vendas cruza estados, o que pesa no frete.
- **Peso:** furniture_mattress_and_upholstery tem o maior peso médio (13.190 g).
- **Vendedores:** 342 vendedores têm nota média de avaliação abaixo de 3.
- **Entrega:** [PREENCHER: quantidade e % de pedidos entregues com atraso]
- **Reputação:** [PREENCHER: categoria com pior nota e valor]
- **Frete:** [PREENCHER: estado com frete médio mais alto e valor]

## Uso de IA
Usei IA como apoio para estruturar as consultas. Executei todas no DBeaver,
conferi os resultados e as decisões de análise acima são minhas.
