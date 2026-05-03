source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
d <- filtrar_ultimo_periodo(base)
ultimo <- obter_ultimo_periodo(base)

tabela <- calc_medias_remuneracao_por_grupo(
  df = d,
  group_cols = c("cor_ou_raca")
)

tabela <- tabela[order(tabela$cor_ou_raca), ]
rownames(tabela) <- NULL

escrever_saida_csv_json(
  tabela = tabela,
  arquivo_csv = file.path("saida", "ultimo_periodo_remuneracao_media_por_raca_cor.csv"),
  arquivo_json = file.path("saida", "ultimo_periodo_remuneracao_media_por_raca_cor.json"),
  nome_analise = "Ultimo periodo: remuneracao media por raca/cor",
  descricao = "Para o ultimo ano/trimestre disponivel, calcula remuneracao media ponderada por raca/cor (VD4019 e VD4020).",
  extras_json = list(
    ultimo_periodo = list(
      ano = ultimo$ano,
      trimestre = ultimo$trimestre,
      periodo = paste0(ultimo$ano, "-T", ultimo$trimestre)
    )
  )
)

cat("Concluido: ultimo periodo - remuneracao media por raca/cor.\n")
