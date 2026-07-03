source("utils_nivel_participacao_base_completa.R")

processar_distribuicao_nivel_base_completa(
  arquivo_csv = file.path("saida", "distribuicao_nivel_instrucao_brasil_por_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "distribuicao_nivel_instrucao_brasil_por_ano_trimestre.json"),
  descricao = "Distribuicao percentual ponderada de nivel de instrucao no Brasil por ano e trimestre."
)
