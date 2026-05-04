source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()

comparacao_serie <- calc_comparacao_salarial_sobreeducados_vs_niveis_instrucao(
  base = base,
  apenas_ultimo_periodo = FALSE
)

comparacao_serie <- comparacao_serie[order(
  comparacao_serie$ano,
  comparacao_serie$trimestre,
  suppressWarnings(as.integer(comparacao_serie$nivel_instrucao_codigo))
), ]
rownames(comparacao_serie) <- NULL

escrever_saida_csv_json(
  tabela = comparacao_serie,
  arquivo_csv = file.path("saida", "comparacao_salarial_sobreeducados_vs_niveis_instrucao_ano_trimestre.csv"),
  arquivo_json = file.path("saida", "comparacao_salarial_sobreeducados_vs_niveis_instrucao_ano_trimestre.json"),
  nome_analise = "Serie historica: comparacao salarial sobreeducados versus niveis de instrucao",
  descricao = paste(
    "Para cada ano/trimestre disponivel, compara remuneracao media ponderada dos sobreeducados",
    "com todos os niveis de instrucao existentes no periodo.",
    "Inclui diferencas absolutas, razoes e diferencas percentuais para VD4019 e VD4020."
  )
)

cat("Concluido: serie historica - comparacao salarial sobreeducados versus niveis de instrucao.\n")
