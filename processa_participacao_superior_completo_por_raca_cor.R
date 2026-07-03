source("utils_nivel_participacao_base_completa.R")

processar_participacao_superior_base_completa(
  arquivo_csv = file.path("saida", "participacao_superior_completo_por_raca_cor_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "participacao_superior_completo_por_raca_cor_ano_trimestre.json"),
  dimensao_col = "cor_ou_raca",
  dimensao_nome = "raca_cor",
  descricao = "Participacao percentual ponderada de pessoas com superior completo por raca/cor, ano e trimestre."
)
