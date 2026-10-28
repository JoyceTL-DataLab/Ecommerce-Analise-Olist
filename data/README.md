# Olist Analytics: atrasos, satisfação e comportamento de clientes

Projeto de análise de dados ponta a ponta sobre o e-commerce brasileiro **Olist** (2016–2018): da qualidade dos dados ao dashboard executivo em Power BI, passando por ETL em Python, modelagem dimensional em PostgreSQL, estatística inferencial e mapas interativos.

> **Pergunta central:** o que está por trás das notas baixas dos clientes e onde a operação precisa melhorar?
> **Resposta curta:** o atraso na entrega. Pedidos atrasados têm nota média de 2,27 contra 4,29 dos pedidos no prazo, e a chance de nota baixa (1–2) é ~16x maior, mesmo controlando pela região.

![Dashboard](docs/dashboard_visao_executiva.png)

---

## Principais resultados

| Tema | Resultado |
|---|---|
| **Escala** | R$ 13,49 mi em receita (itens, sem frete), 98.199 pedidos, ticket médio R$ 137,42, nota média 4,12 |
| **Atraso x satisfação** | Nota média 4,29 (no prazo) vs 2,27 (atrasado): diferença de 2,02 pontos (IC 95%: 1,98 a 2,06), Mann-Whitney p < 0,001, rank-biserial = 0,64 (efeito grande) |
| **Efeito do atraso na nota baixa** | Regressão logística controlada por região: odds ratio = 16,1 (IC 95%: 15,2 a 17,0). 62,4% dos atrasados recebem nota 1–2, contra 9,3% dos pontuais |
| **Taxa de atraso** | 6,77% dos pedidos entregues. Nordeste 12,7%, Norte 8,6%, Centro-Oeste 6,5%, Sudeste 6,1%, Sul 5,9% |
| **Estados críticos** | AL (21,4%), MA (17,4%), SE (15,2%), PI (13,9%), CE (13,7%). RJ (12,1%) tem o maior volume absoluto de atrasos |
| **Região x prazo** | Região explica bastante o *tempo* de entrega (ε² = 0,153; mediana de 8 dias no Sudeste e 20 no Norte), mas pouco o *atraso* (V de Cramér = 0,077): o prazo prometido já embute a distância |
| **Origem x destino** | Entregas na mesma região: 6,30% de atraso e mediana de 8 dias. Entre regiões: 7,75% e 13 dias. O destino Nordeste é o pior (9,3% a 13,1%) qualquer que seja a origem do vendedor, o que aponta para a operação logística local |
| **Clientes (RFM)** | Só 3,0% dos clientes recompram (2.887 de 94.983). Os dois segmentos de alto valor (47,5% da base) geram ~75% da receita. "Em risco de alto valor" soma 22.384 clientes e R$ 5,3 mi (39% da receita): prioridade de reativação |
| **Vendedores** | 3.053 vendedores ativos; os 10 maiores somam apenas 13,2% da receita (mercado pulverizado). Taxa de atraso média de 6,69% e nota 4,10 |
| **Sazonalidade** | Pico em nov/2017 (Black Friday): R$ 1,0 mi em receita e 7.544 pedidos |

> Os resultados são **associações**, não causalidade: o modelo não controla vendedor, categoria, preço ou tipo de problema.

---

## Arquitetura

```
CSVs Olist (Kaggle)
      │  Extract / Transform / Validate / Load  (Python + pandas)
      ▼
PostgreSQL ── schema staging   (tabelas tratadas)
      │  SQL
      ▼
        ── schema core         (modelo dimensional)
        │    dim_date · dim_customer · dim_product · dim_seller
        │    fact_orders · fact_order_items
        ▼
        ── schema marts        (tabelas analíticas)
             seller_performance · rfm
      │
      ├─► Análise estatística e mapas (Python: scipy, statsmodels, plotly)
      └─► Export CSV ─► Power BI (dashboard de 4 páginas)
```

**Decisões de modelagem**
- Duas tabelas fato (pedidos e itens) para analisar vendas em níveis diferentes de granularidade.
- Clientes identificados por `customer_unique_id` (o `customer_id` muda a cada pedido: 99.441 ids para 96.096 pessoas).
- Pedidos `canceled` e `unavailable` excluídos do modelo (sem receita realizada).
- Atraso (`delay_days`) fica nulo para pedidos não entregues, para não classificá-los como "no prazo".
- Uma avaliação por pedido (a mais recente); 551 duplicadas descartadas.

## SQL

Todo o SQL está versionado em [`sql/`](sql/) (PostgreSQL): criação das dimensões e fatos, mart de vendedores, testes de consistência e consultas de negócio com CTEs e window functions (`LAG`, `RANK() OVER (PARTITION BY ...)`, `SUM() OVER ()`). O notebook `02_modelagem_sql.ipynb` apenas executa os scripts.

## Qualidade de dados

A análise exploratória (`00_eda_qualidade_dados.ipynb`) mede nulos, duplicatas, inconsistências de datas, outliers e normalidade, e termina com uma tabela de decisões (problema, quantidade, decisão, justificativa). Destaques:

- Valores extremos (IQR sinalizou de 5% a 14% das linhas) foram **mantidos**, por serem plausíveis; como as distribuições são assimétricas, a análise usa mediana e testes não paramétricos.
- Crescimento mensal restrito a **jan/2017–ago/2018** (20 meses completos); os meses das pontas têm volume muito baixo.
- 7 validações no ETL (5 críticas que interrompem a carga, 2 de aviso) e 5 testes em SQL (`sql/05_testes.sql`), incluindo a reconciliação da receita entre `staging` e `core`.

## Metodologia estatística

| Pergunta | Técnica |
|---|---|
| Atraso muda a nota? | Mann-Whitney + tamanho de efeito (rank-biserial) + bootstrap do IC da diferença |
| Região associa-se ao atraso? | Qui-quadrado + V de Cramér |
| Região afeta o tempo de entrega? | Kruskal-Wallis + ε² |
| Relação dias de atraso x nota | Correlação de Spearman (ρ = -0,176; fraca porque a penalidade surge ao cruzar o prazo, não é linear) |
| Efeito do atraso isolado da região | Regressão logística (odds ratio) |
| Segmentação de clientes | RFM por quartis, com segmentos por recorrência |

Com ~96 mil pedidos qualquer diferença vira "significativa", então a interpretação se apoia nos **tamanhos de efeito**, não só nos p-valores.

## Dashboard (Power BI)

Quatro páginas, em `docs/olist-projeto-BI.pdf`:

1. **Visão Executiva:** KPIs, receita mensal, top 10 categorias e estados, com filtros de ano, região e estado.
2. **Atrasos derrubam a nota:** nota por faixa de atraso, distribuição das notas, estados e regiões com mais atraso.
3. **Recompra e RFM:** clientes e receita por segmento, com recomendações de ação.
4. **Vendedores:** concentração de receita, volume x nota e ranking de vendedores com maior atraso.

Mapas interativos (abrir no navegador): [`docs/mapa_regioes.html`](docs/mapa_regioes.html) e [`docs/mapa_estados.html`](docs/mapa_estados.html).

## Estrutura do repositório

```
olist-analytics/
├── data/                              # CSVs brutos do Kaggle (não versionados)
│   └── export/                        # CSVs gerados para o Power BI (não versionados)
├── notebooks/
│   ├── 00_eda_qualidade_dados.ipynb   # EDA e decisões de tratamento
│   ├── 01_setup_download_e_etl.ipynb  # banco, ETL e carga no schema staging
│   ├── 02_modelagem_sql.ipynb         # executa os scripts SQL e mostra os resultados
│   ├── 03_analise.ipynb               # estatística, RFM e mapas
│   └── 04_export_para_powerbi.ipynb   # exporta tabelas para o Power BI
├── sql/                               # modelo dimensional e consultas
│   ├── 01_schemas.sql
│   ├── 02_dimensoes.sql
│   ├── 03_fatos.sql
│   ├── 04_mart_seller_performance.sql
│   ├── 05_testes.sql                  # testes de consistência (0 linhas = passou)
│   └── 06_consultas_analiticas.sql    # crescimento mensal, top categorias, vendedores...
├── docs/                              # dashboard (PDF/prints) e mapas HTML
├── requirements.txt
└── README.md
```

## Como reproduzir

**Pré-requisitos:** Python 3.10+, PostgreSQL 17 (desenvolvido na 17.11) e Power BI Desktop (só para abrir o dashboard).

1. Clone o repositório e instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```
2. Baixe o dataset [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) e coloque os 9 CSVs em `data/`.
3. Execute os notebooks **em ordem numérica** (00 a 04).
   - No notebook `01`, informe a senha do superusuário do seu Postgres na variável `SENHA_POSTGRES` (não commite a senha). A célula cria o usuário e o banco `olist`.
   - O notebook `04` gera os CSVs em `data/export/`, que alimentam o Power BI.

## Limitações

- Os dados cobrem 2016–2018: os segmentos RFM refletem o comportamento naquele período (recência medida até o último pedido da base, não até hoje).
- A receita considera apenas o preço dos itens (sem frete) e inclui pedidos ainda em andamento (enviados, faturados etc.); apenas cancelados e indisponíveis foram excluídos.
- Estados com poucos pedidos (ex.: AL com 397, SE com 336) têm percentuais mais instáveis; estados com menos de 100 pedidos ficam sem cor nos mapas.
- A análise de atraso é observacional: associação, não causalidade.

## Próximos passos

- Controlar vendedor e categoria na regressão para isolar melhor o efeito do atraso.
- Investigar o ticket das recompras (recorrentes gastam em média R$ 255–264, parecido com os "novos de alto valor", o que sugere recompras de menor valor por pedido).
- Modelo preditivo de risco de atraso por pedido.

## Stack

Python (pandas, SQLAlchemy, SciPy, statsmodels, seaborn, matplotlib, Plotly) · PostgreSQL · SQL (CTEs, window functions) · Power BI · Jupyter

## Dados e licença

Dataset público da Olist no Kaggle, licença CC BY-NC-SA 4.0 (uso não comercial, com atribuição). Os dados são anonimizados pela própria Olist.

## Autor

**Joyce Tavares**: [LinkedIn](https://www.linkedin.com/in/joyce-tavares-1a89a0252/) · [E-mail](mailto:salesjunior1995@gmail.com)
