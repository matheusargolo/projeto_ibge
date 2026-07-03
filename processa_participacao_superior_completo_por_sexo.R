source("utils_nivel_participacao_base_completa.R")

processar_participacao_superior_base_completa(
  arquivo_csv = file.path("saida", "participacao_superior_completo_por_sexo_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "participacao_superior_completo_por_sexo_ano_trimestre.json"),
  dimensao_col = "sexo",
  dimensao_nome = "sexo",
  descricao = "Participacao percentual ponderada de pessoas com superior completo por sexo, ano e trimestre."
)
