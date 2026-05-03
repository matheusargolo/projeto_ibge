scripts <- c(
  "processa_percentual_sobreeducados_por_uf.R",
  "processa_percentual_sobreeducados_por_regiao.R",
  "processa_percentual_sobreeducados_por_raca_cor.R",
  "processa_percentual_sobreeducados_por_sexo.R",
  "processa_percentual_sobreeducados_por_ocupacao_ano_trimestre.R",
  "processa_ultimo_periodo_percentual_sobreeducados_por_ocupacao_e_remuneracao.R",
  "processa_ultimo_periodo_remuneracao_media_por_nivel_instrucao.R",
  "processa_ultimo_periodo_remuneracao_media_por_uf.R",
  "processa_ultimo_periodo_remuneracao_media_por_regiao.R",
  "processa_ultimo_periodo_remuneracao_media_por_raca_cor.R",
  "processa_ultimo_periodo_remuneracao_media_por_sexo.R",
  "processa_ultimo_periodo_remuneracao_media_sobreeducados_nao_sobreeducados_e_superior.R",
  "processa_ultimo_periodo_remuneracao_media_por_tipo_ocupacao_classificada.R"
)

dir.create("saida", showWarnings = FALSE, recursive = TRUE)

log_df <- data.frame(
  script = character(),
  inicio = character(),
  fim = character(),
  duracao_segundos = numeric(),
  status = character(),
  mensagem = character(),
  stringsAsFactors = FALSE
)

cat("Iniciando execucao em lote de analises de sobreeducacao...\n")

for (s in scripts) {
  t0 <- Sys.time()
  cat("\n---\nExecutando:", s, "\n")

  res <- tryCatch(
    {
      source(s, local = new.env(parent = globalenv()))
      list(status = "OK", mensagem = "")
    },
    error = function(e) {
      list(status = "ERRO", mensagem = conditionMessage(e))
    }
  )

  t1 <- Sys.time()
  dt <- as.numeric(difftime(t1, t0, units = "secs"))

  log_df <- rbind(
    log_df,
    data.frame(
      script = s,
      inicio = format(t0, "%Y-%m-%d %H:%M:%S %z"),
      fim = format(t1, "%Y-%m-%d %H:%M:%S %z"),
      duracao_segundos = round(dt, 3),
      status = res$status,
      mensagem = res$mensagem,
      stringsAsFactors = FALSE
    )
  )

  cat("Status:", res$status, "| Duracao(s):", round(dt, 2), "\n")
  if (nzchar(res$mensagem)) {
    cat("Mensagem:", res$mensagem, "\n")
  }
}

arquivo_log_csv <- file.path("saida", "log_execucao_analises_sobreeducacao_t4.csv")
write.csv(log_df, arquivo_log_csv, row.names = FALSE, fileEncoding = "UTF-8")

arquivo_doc_md <- file.path("saida", "documentacao_analises_sobreeducacao_t4.md")

linhas_md <- c(
  "# Documentacao da execucao das analises de sobreeducacao (T4)",
  "",
  paste0("- Gerado em: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  "- Escopo: periodos disponiveis localmente (atualmente T4 por ano).",
  "- Peso amostral: V1028 (peso valido > 0).",
  "- Definicao de sobreeducado: superior completo (VD3004=7) em ocupacao classificada como nao exigente de nivel superior.",
  "- Classificacao de ocupacoes: saida/ocupacoes_cod2010_classificadas.csv.",
  "- Remuneracao: foram calculadas duas metricas em paralelo:",
  "  - VD4019: rendimento habitual em todos os trabalhos.",
  "  - VD4020: rendimento efetivo em todos os trabalhos.",
  "- Filtro de remuneracao para medias: apenas rendimentos positivos (>0), com ocupacao informada e peso valido.",
  "",
  "## Log de execucao",
  ""
)

for (i in seq_len(nrow(log_df))) {
  linhas_md <- c(
    linhas_md,
    paste0(
      "- ", log_df$script[i],
      " | status=", log_df$status[i],
      " | duracao_segundos=", log_df$duracao_segundos[i],
      if (nzchar(log_df$mensagem[i])) paste0(" | mensagem=", log_df$mensagem[i]) else ""
    )
  )
}

writeLines(linhas_md, con = arquivo_doc_md, useBytes = TRUE)

cat("\nExecucao em lote finalizada.\n")
cat("Log CSV:", normalizePath(arquivo_log_csv), "\n")
cat("Documentacao MD:", normalizePath(arquivo_doc_md), "\n")
