source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
d <- filtrar_ultimo_periodo(base)
ultimo <- obter_ultimo_periodo(base)

tabela <- calc_medias_remuneracao_por_grupo(
  df = d,
  group_cols = c("sexo")
)

tabela <- tabela[order(tabela$sexo), ]
rownames(tabela) <- NULL

escrever_saida_csv_json(
  tabela = tabela,
  arquivo_csv = file.path("saida", "ultimo_periodo_remuneracao_media_por_sexo.csv"),
  arquivo_json = file.path("saida", "ultimo_periodo_remuneracao_media_por_sexo.json"),
  nome_analise = "Ultimo periodo: remuneracao media por sexo",
  descricao = "Para o ultimo ano/trimestre disponivel, calcula remuneracao media ponderada por sexo (VD4019 e VD4020).",
  extras_json = list(
    ultimo_periodo = list(
      ano = ultimo$ano,
      trimestre = ultimo$trimestre,
      periodo = paste0(ultimo$ano, "-T", ultimo$trimestre)
    )
  )
)

cat("Concluido: ultimo periodo - remuneracao media por sexo.\n")
