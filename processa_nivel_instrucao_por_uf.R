source("utils_nivel_participacao_base_completa.R")

processar_distribuicao_nivel_base_completa(
  arquivo_csv = file.path("saida", "distribuicao_nivel_instrucao_por_unidade_da_federacao_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "distribuicao_nivel_instrucao_por_unidade_da_federacao_ano_trimestre.json"),
  dimensao_col = "uf_sigla",
  dimensao_nome = "unidade_da_federacao",
  descricao = "Distribuicao percentual ponderada de nivel de instrucao por UF, ano e trimestre."
)
