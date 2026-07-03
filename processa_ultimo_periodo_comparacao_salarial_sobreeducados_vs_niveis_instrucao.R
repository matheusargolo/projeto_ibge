source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
ultimo <- obter_ultimo_periodo(base)

comparacao_todos <- calc_comparacao_salarial_sobreeducados_vs_niveis_instrucao(
  base = base,
  apenas_ultimo_periodo = TRUE
)

comparacao_todos <- comparacao_todos[order(suppressWarnings(as.integer(comparacao_todos$nivel_instrucao_codigo))), ]
rownames(comparacao_todos) <- NULL

escrever_saida_csv_json(
  tabela = comparacao_todos,
  arquivo_csv = file.path("saida", "ultimo_periodo_comparacao_salarial_sobreeducados_vs_niveis_instrucao.csv"),
  arquivo_json = file.path("saida", "ultimo_periodo_comparacao_salarial_sobreeducados_vs_niveis_instrucao.json"),
  nome_analise = "Ultimo periodo: comparacao salarial sobreeducados versus niveis de instrucao",
  descricao = paste(
    "Compara a remuneracao media ponderada dos sobreeducados com grupos de referencia por nivel de instrucao no ultimo periodo disponivel.",
    "Por ser analise relacionada a sobreeducacao, restringe o universo a ocupacoes classificadas como 0 ou 1, excluindo ocupacoes ambiguas (nivel_superior=2).",
    "Inclui diferencas absolutas (R$), razoes e diferencas percentuais para VD4019 e VD4020."
  ),
  extras_json = list(
    ultimo_periodo = list(
      ano = ultimo$ano,
      trimestre = ultimo$trimestre,
      periodo = paste0(ultimo$ano, "-T", ultimo$trimestre)
    )
  )
)

codigos_foco <- c("5", "6")
comparacao_foco <- calc_comparacao_salarial_sobreeducados_vs_niveis_instrucao(
  base = base,
  filtrar_codigos_nivel = codigos_foco,
  apenas_ultimo_periodo = TRUE
)

comparacao_foco <- comparacao_foco[order(suppressWarnings(as.integer(comparacao_foco$nivel_instrucao_codigo))), ]
rownames(comparacao_foco) <- NULL

escrever_saida_csv_json(
  tabela = comparacao_foco,
  arquivo_csv = file.path("saida", "ultimo_periodo_comparacao_salarial_sobreeducados_vs_medio_completo_e_superior_incompleto.csv"),
  arquivo_json = file.path("saida", "ultimo_periodo_comparacao_salarial_sobreeducados_vs_medio_completo_e_superior_incompleto.json"),
  nome_analise = "Ultimo periodo: comparacao salarial sobreeducados versus medio completo e superior incompleto",
  descricao = paste(
    "Recorte focal pedido para confronto dos sobreeducados com:",
    "(1) medio completo/equivalente (VD3004=5) e",
    "(2) superior incompleto/equivalente (VD3004=6).",
    "Por ser analise relacionada a sobreeducacao, restringe o universo a ocupacoes classificadas como 0 ou 1, excluindo ocupacoes ambiguas (nivel_superior=2)."
  ),
  extras_json = list(
    ultimo_periodo = list(
      ano = ultimo$ano,
      trimestre = ultimo$trimestre,
      periodo = paste0(ultimo$ano, "-T", ultimo$trimestre)
    ),
    codigos_nivel_referencia = codigos_foco
  )
)

cat("Concluido: ultimo periodo - comparacao salarial sobreeducados versus niveis de instrucao (todos e foco 5/6).\n")
