source("utils_nivel_participacao_base_completa.R")

processar_participacao_superior_base_completa(
  arquivo_csv = file.path("saida", "participacao_superior_completo_por_unidade_da_federacao_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "participacao_superior_completo_por_unidade_da_federacao_ano_trimestre.json"),
  dimensao_col = "uf_sigla",
  dimensao_nome = "unidade_da_federacao",
  descricao = "Participacao percentual ponderada de pessoas com superior completo por UF, ano e trimestre."
)
