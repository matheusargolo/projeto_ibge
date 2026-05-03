source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
tabela <- calc_percentual_sobreeducados_por_dimensao(
  base = base,
  col_dimensao = "regiao",
  nome_dimensao_saida = "regiao"
)

escrever_saida_csv_json(
  tabela = tabela,
  arquivo_csv = file.path("saida", "percentual_sobreeducados_por_regiao_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "percentual_sobreeducados_por_regiao_ano_trimestre.json"),
  nome_analise = "Percentual de sobreeducados por regiao ao longo do tempo",
  descricao = "Percentual de sobreeducados por regiao e periodo. Inclui participacao da regiao no total de sobreeducados do periodo."
)

cat("Concluido: percentual de sobreeducados por regiao.\n")
