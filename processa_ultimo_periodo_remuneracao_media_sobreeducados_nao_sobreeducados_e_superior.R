source("utils_analises_sobreeducacao.R")

base <- carregar_base_sobreeducacao()
d <- filtrar_ultimo_periodo(base)
ultimo <- obter_ultimo_periodo(base)

calc_resumo_grupo <- function(df, condicao, grupo_label) {
  x <- df[condicao & df$peso_valido & df$ocupacao_informada, , drop = FALSE]

  if (nrow(x) == 0) {
    return(data.frame(
      grupo = grupo_label,
      registros_com_ocupacao_e_peso_valido = 0L,
      registros_com_rendimento_habitual = 0L,
      registros_com_rendimento_efetivo = 0L,
      rendimento_habitual_medio_ponderado = NA_real_,
      rendimento_efetivo_medio_ponderado = NA_real_,
      stringsAsFactors = FALSE
    ))
  }

  idx_h <- !is.na(x$rendimento_habitual_todos_trabalhos) &
    is.finite(x$rendimento_habitual_todos_trabalhos) &
    x$rendimento_habitual_todos_trabalhos > 0
  idx_e <- !is.na(x$rendimento_efetivo_todos_trabalhos) &
    is.finite(x$rendimento_efetivo_todos_trabalhos) &
    x$rendimento_efetivo_todos_trabalhos > 0

  media_h <- if (any(idx_h)) {
    sum(x$rendimento_habitual_todos_trabalhos[idx_h] * x$peso[idx_h]) / sum(x$peso[idx_h])
  } else {
    NA_real_
  }

  media_e <- if (any(idx_e)) {
    sum(x$rendimento_efetivo_todos_trabalhos[idx_e] * x$peso[idx_e]) / sum(x$peso[idx_e])
  } else {
    NA_real_
  }

  data.frame(
    grupo = grupo_label,
    registros_com_ocupacao_e_peso_valido = nrow(x),
    registros_com_rendimento_habitual = sum(idx_h),
    registros_com_rendimento_efetivo = sum(idx_e),
    rendimento_habitual_medio_ponderado = media_h,
    rendimento_efetivo_medio_ponderado = media_e,
    stringsAsFactors = FALSE
  )
}

tabela <- do.call(rbind, list(
  calc_resumo_grupo(
    d,
    condicao = d$sobreeducado,
    grupo_label = "sobreeducados"
  ),
  calc_resumo_grupo(
    d,
    condicao = d$nao_sobreeducado_superior,
    grupo_label = "nao_sobreeducados_superior_em_ocupacao_classificada"
  ),
  calc_resumo_grupo(
    d,
    condicao = d$superior_completo & d$ocupacao_classificada,
    grupo_label = "superior_completo_ocupacoes_classificadas_0_1"
  )
))

escrever_saida_csv_json(
  tabela = tabela,
  arquivo_csv = file.path("saida", "ultimo_periodo_remuneracao_media_sobreeducados_nao_sobreeducados_e_superior.csv"),
  arquivo_json = file.path("saida", "ultimo_periodo_remuneracao_media_sobreeducados_nao_sobreeducados_e_superior.json"),
  nome_analise = "Ultimo periodo: remuneracao media sobreeducados, nao sobreeducados e superior",
  descricao = paste(
    "Compara tres grupos no ultimo periodo:",
    "1) sobreeducados;",
    "2) nao sobreeducados (superior completo em ocupacao classificada como exigente de superior);",
    "3) superior completo em ocupacoes classificadas como 0 ou 1, excluindo ocupacoes ambiguas (nivel_superior=2)."
  ),
  extras_json = list(
    ultimo_periodo = list(
      ano = ultimo$ano,
      trimestre = ultimo$trimestre,
      periodo = paste0(ultimo$ano, "-T", ultimo$trimestre)
    )
  )
)

cat("Concluido: ultimo periodo - remuneracao media sobreeducados, nao sobreeducados e superior.\n")
