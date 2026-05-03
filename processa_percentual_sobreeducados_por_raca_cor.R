source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
tabela <- calc_percentual_sobreeducados_por_dimensao(
  base = base,
  col_dimensao = "cor_ou_raca",
  nome_dimensao_saida = "cor_ou_raca"
)

escrever_saida_csv_json(
  tabela = tabela,
  arquivo_csv = file.path("saida", "percentual_sobreeducados_por_raca_cor_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "percentual_sobreeducados_por_raca_cor_ano_trimestre.json"),
  nome_analise = "Percentual de sobreeducados por raca/cor ao longo do tempo",
  descricao = "Percentual de sobreeducados por raca/cor e periodo. Inclui participacao do grupo no total de sobreeducados do periodo."
)

cat("Concluido: percentual de sobreeducados por raca/cor.\n")
