scripts <- c(
  "processa_nivel_instrucao_brasil.R",
  "processa_nivel_instrucao_por_raca_cor.R",
  "processa_nivel_instrucao_por_regiao.R",
  "processa_nivel_instrucao_por_sexo.R",
  "processa_nivel_instrucao_por_uf.R",
  "processa_participacao_superior_completo_por_raca_cor.R",
  "processa_participacao_superior_completo_por_regiao.R",
  "processa_participacao_superior_completo_por_sexo.R",
  "processa_participacao_superior_completo_por_uf.R",
  "processa_sobreeducacao_brasil_por_ano_trimestre.R",
  "processa_percentual_sobreeducados_por_ocupacao_ano_trimestre.R",
  "processa_percentual_sobreeducados_por_raca_cor.R",
  "processa_percentual_sobreeducados_por_regiao.R",
  "processa_percentual_sobreeducados_por_sexo.R",
  "processa_percentual_sobreeducados_por_uf.R",
  "processa_serie_comparacao_salarial_sobreeducados_vs_niveis_instrucao.R",
  "processa_ultimo_periodo_comparacao_salarial_sobreeducados_vs_niveis_instrucao.R",
  "processa_ultimo_periodo_percentual_sobreeducados_por_ocupacao_e_remuneracao.R",
  "processa_ultimo_periodo_remuneracao_media_por_nivel_instrucao.R",
  "processa_ultimo_periodo_remuneracao_media_por_raca_cor.R",
  "processa_ultimo_periodo_remuneracao_media_por_regiao.R",
  "processa_ultimo_periodo_remuneracao_media_por_sexo.R",
  "processa_ultimo_periodo_remuneracao_media_por_tipo_ocupacao_classificada.R",
  "processa_ultimo_periodo_remuneracao_media_por_uf.R",
  "processa_ultimo_periodo_remuneracao_media_sobreeducados_nao_sobreeducados_e_superior.R"
)

dir.create("saida", showWarnings = FALSE, recursive = TRUE)

status_path <- file.path("saida", "status_execucao_todas_analises_pnadc.csv")
log_path <- file.path("saida", "log_execucao_todas_analises_pnadc.csv")
cache_path <- file.path("saida", "base_pnadc_sobreeducacao.rds")

write_status <- function(df) {
  write.csv(df, status_path, row.names = FALSE, fileEncoding = "UTF-8")
  write.csv(df, log_path, row.names = FALSE, fileEncoding = "UTF-8")
}

cat("Iniciando execucao de todas as analises PNADc...\n")
cat("Scripts:", length(scripts), "\n")
cat("Status CSV:", normalizePath(status_path, winslash = "/", mustWork = FALSE), "\n")
cat("Log CSV:", normalizePath(log_path, winslash = "/", mustWork = FALSE), "\n")

if (file.exists(cache_path)) {
  unlink(cache_path)
  cat("Cache removido para reconstruir com todos os periodos e classificacao atual:", cache_path, "\n")
}

preservar <- c(
  "^ocupacoes_cod2010.*\\.csv$",
  "^resumo_download_pnadc_bruto_.*\\.csv$",
  "^log_execucao_analises_sobreeducacao_t4\\.csv$",
  "^status_execucao_todas_analises_pnadc\\.csv$",
  "^log_execucao_todas_analises_pnadc\\.csv$"
)

arquivos_saida <- list.files("saida", pattern = "\\.(csv|json)$", full.names = TRUE)
nomes_saida <- basename(arquivos_saida)
manter <- Reduce(`|`, lapply(preservar, grepl, x = nomes_saida))
remover <- arquivos_saida[!manter]
if (length(remover) > 0) {
  unlink(remover)
  cat("Saidas analiticas antigas removidas da raiz de saida/:", length(remover), "\n")
}

status <- data.frame(
  ordem = seq_along(scripts),
  script = scripts,
  inicio = NA_character_,
  fim = NA_character_,
  duracao_segundos = NA_real_,
  status = "PENDENTE",
  mensagem = "",
  stringsAsFactors = FALSE
)
write_status(status)

for (i in seq_along(scripts)) {
  s <- scripts[i]
  t0 <- Sys.time()
  status$inicio[i] <- format(t0, "%Y-%m-%d %H:%M:%S %z")
  status$status[i] <- "RODANDO"
  write_status(status)

  cat("\n---\nExecutando [", i, "/", length(scripts), "]: ", s, "\n", sep = "")

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
  status$fim[i] <- format(t1, "%Y-%m-%d %H:%M:%S %z")
  status$duracao_segundos[i] <- round(as.numeric(difftime(t1, t0, units = "secs")), 3)
  status$status[i] <- res$status
  status$mensagem[i] <- res$mensagem
  write_status(status)

  cat("Status:", res$status, "| Duracao(s):", status$duracao_segundos[i], "\n")
  if (nzchar(res$mensagem)) {
    cat("Mensagem:", res$mensagem, "\n")
  }
}

cat("\nExecucao finalizada.\n")
print(status, row.names = FALSE)
