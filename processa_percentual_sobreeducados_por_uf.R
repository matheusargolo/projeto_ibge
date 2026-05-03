source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
tabela <- calc_percentual_sobreeducados_por_dimensao(
  base = base,
  col_dimensao = "uf_sigla",
  nome_dimensao_saida = "unidade_da_federacao"
)

tabela <- merge(
  tabela,
  unique(base[, c("uf_sigla", "uf_nome")]),
  by.x = "unidade_da_federacao",
  by.y = "uf_sigla",
  all.x = TRUE
)

tabela <- tabela[order(tabela$Ano, tabela$Trimestre, tabela$unidade_da_federacao), ]
rownames(tabela) <- NULL

escrever_saida_csv_json(
  tabela = tabela,
  arquivo_csv = file.path("saida", "percentual_sobreeducados_por_unidade_da_federacao_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "percentual_sobreeducados_por_unidade_da_federacao_ano_trimestre.json"),
  nome_analise = "Percentual de sobreeducados por UF ao longo do tempo",
  descricao = "Percentual de sobreeducados por UF e periodo. Inclui participacao da UF no total de sobreeducados do periodo."
)

cat("Concluido: percentual de sobreeducados por UF.\n")
