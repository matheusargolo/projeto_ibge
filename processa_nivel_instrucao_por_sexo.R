source("utils_nivel_participacao_base_completa.R")

processar_distribuicao_nivel_base_completa(
  arquivo_csv = file.path("saida", "distribuicao_nivel_instrucao_por_sexo_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "distribuicao_nivel_instrucao_por_sexo_ano_trimestre.json"),
  dimensao_col = "sexo",
  dimensao_nome = "sexo",
  descricao = "Distribuicao percentual ponderada de nivel de instrucao por sexo, ano e trimestre."
)
