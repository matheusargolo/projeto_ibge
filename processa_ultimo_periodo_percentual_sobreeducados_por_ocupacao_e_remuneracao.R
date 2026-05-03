source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
ultimo <- obter_ultimo_periodo(base)
tabela <- calc_ultimo_periodo_percentual_sobreeducados_ocupacao_e_remuneracao(base)

escrever_saida_csv_json(
  tabela = tabela,
  arquivo_csv = file.path("saida", "ultimo_periodo_percentual_sobreeducados_por_ocupacao_e_remuneracao_media.csv"),
  arquivo_json = file.path("saida", "ultimo_periodo_percentual_sobreeducados_por_ocupacao_e_remuneracao_media.json"),
  nome_analise = "Ultimo periodo: percentual de sobreeducados por ocupacao + remuneracao media",
  descricao = "Para o ultimo ano/trimestre disponivel, calcula percentual de sobreeducados por ocupacao e junta remuneracao media ponderada (VD4019 e VD4020).",
  extras_json = list(
    ultimo_periodo = list(
      ano = ultimo$ano,
      trimestre = ultimo$trimestre,
      periodo = paste0(ultimo$ano, "-T", ultimo$trimestre)
    )
  )
)

cat("Concluido: ultimo periodo - sobreeducacao por ocupacao com remuneracao media.\n")
