source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
tabela <- calc_percentual_sobreeducados_por_ocupacao(base)

escrever_saida_csv_json(
  tabela = tabela,
  arquivo_csv = file.path("saida", "percentual_sobreeducados_por_ocupacao_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "percentual_sobreeducados_por_ocupacao_ano_trimestre.json"),
  nome_analise = "Percentual de sobreeducados por ocupacao ao longo do tempo",
  descricao = paste(
    "Para cada ocupacao e periodo, o script calcula:",
    "1) percentual de sobreeducados no total de ocupados da ocupacao;",
    "2) participacao da ocupacao no total de sobreeducados do periodo;",
    "3) percentual de sobreeducados entre superiores completos com ocupacao classificada."
  )
)

cat("Concluido: percentual de sobreeducados por ocupacao ao longo do tempo.\n")
