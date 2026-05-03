source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
tabela <- calc_percentual_sobreeducados_por_dimensao(
  base = base,
  col_dimensao = "sexo",
  nome_dimensao_saida = "sexo"
)

escrever_saida_csv_json(
  tabela = tabela,
  arquivo_csv = file.path("saida", "percentual_sobreeducados_por_sexo_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "percentual_sobreeducados_por_sexo_ano_trimestre.json"),
  nome_analise = "Percentual de sobreeducados por sexo ao longo do tempo",
  descricao = "Percentual de sobreeducados por sexo e periodo. Inclui participacao do grupo no total de sobreeducados do periodo."
)

cat("Concluido: percentual de sobreeducados por sexo.\n")
