source("utils_nivel_participacao_base_completa.R")

processar_distribuicao_nivel_base_completa(
  arquivo_csv = file.path("saida", "distribuicao_nivel_instrucao_por_raca_cor_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "distribuicao_nivel_instrucao_por_raca_cor_ano_trimestre.json"),
  dimensao_col = "cor_ou_raca",
  dimensao_nome = "raca_cor",
  descricao = "Distribuicao percentual ponderada de nivel de instrucao por raca/cor, ano e trimestre."
)
