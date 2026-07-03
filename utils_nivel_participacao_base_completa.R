source("utils_analises_sobreeducacao.R")

escrever_json_simples <- function(tabela, arquivo_json, metadata) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Pacote 'jsonlite' nao encontrado. Instale com install.packages('jsonlite').")
  }

  jsonlite::write_json(
    x = list(metadata = metadata, tabela = tabela),
    path = arquivo_json,
    pretty = TRUE,
    auto_unbox = TRUE,
    digits = 8
  )
}

processar_distribuicao_nivel_base_completa <- function(
  arquivo_csv,
  arquivo_json,
  dimensao_col = NULL,
  dimensao_nome = NULL,
  descricao = ""
) {
  base <- carregar_base_sobreeducacao()

  cols <- c("ano", "trimestre", "periodo", "nivel_instrucao", "peso", "peso_valido")
  if (!is.null(dimensao_col)) cols <- c(cols, dimensao_col)
  assert_colunas(base, cols, contexto = "base completa PNADc")

  universo <- base$peso_valido & !is.na(base$nivel_instrucao)
  if (!is.null(dimensao_col)) {
    universo <- universo & !is.na(base[[dimensao_col]])
  }

  if (!any(universo)) {
    stop("Sem registros validos para distribuicao de nivel de instrucao.")
  }

  if (is.null(dimensao_col)) {
    df <- data.frame(
      Ano = base$ano[universo],
      Trimestre = base$trimestre[universo],
      periodo = base$periodo[universo],
      nivel_instrucao = base$nivel_instrucao[universo],
      peso = base$peso[universo],
      stringsAsFactors = FALSE
    )

    agg <- aggregate(peso ~ Ano + Trimestre + periodo + nivel_instrucao, data = df, FUN = sum)
    total <- aggregate(peso ~ Ano + Trimestre + periodo, data = agg, FUN = sum)
    names(total)[names(total) == "peso"] <- "total_ponderado"
    resultado <- merge(agg, total, by = c("Ano", "Trimestre", "periodo"), all.x = TRUE)
    resultado$percentual <- round(100 * resultado$peso / resultado$total_ponderado, 4)
    resultado <- resultado[order(resultado$Ano, resultado$Trimestre, -resultado$percentual, resultado$nivel_instrucao), ]
  } else {
    df <- data.frame(
      Ano = base$ano[universo],
      Trimestre = base$trimestre[universo],
      periodo = base$periodo[universo],
      dimensao = as.character(base[[dimensao_col]][universo]),
      nivel_instrucao = base$nivel_instrucao[universo],
      peso = base$peso[universo],
      stringsAsFactors = FALSE
    )

    agg <- aggregate(peso ~ Ano + Trimestre + periodo + dimensao + nivel_instrucao, data = df, FUN = sum)
    total <- aggregate(peso ~ Ano + Trimestre + periodo + dimensao, data = agg, FUN = sum)
    names(total)[names(total) == "peso"] <- "total_ponderado"
    resultado <- merge(agg, total, by = c("Ano", "Trimestre", "periodo", "dimensao"), all.x = TRUE)
    names(resultado)[names(resultado) == "dimensao"] <- dimensao_nome
    resultado$percentual <- round(100 * resultado$peso / resultado$total_ponderado, 4)
    resultado <- resultado[order(resultado$Ano, resultado$Trimestre, resultado[[dimensao_nome]], -resultado$percentual, resultado$nivel_instrucao), ]
  }

  rownames(resultado) <- NULL
  dir.create(dirname(arquivo_csv), showWarnings = FALSE, recursive = TRUE)
  write.csv(resultado, arquivo_csv, row.names = FALSE, fileEncoding = "UTF-8")

  escrever_json_simples(
    tabela = resultado,
    arquivo_json = arquivo_json,
    metadata = list(
      gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
      fuso_horario = Sys.timezone(),
      descricao = descricao,
      fonte_local = "dados_pnadc/PNADC_0TAAAA.txt",
      periodos = sort(unique(resultado$periodo)),
      quantidade_periodos = length(unique(resultado$periodo)),
      observacao = "Reprocessado sobre todos os microdados TXT disponiveis localmente."
    )
  )

  cat("Concluido:", arquivo_csv, "\n")
  invisible(resultado)
}

processar_participacao_superior_base_completa <- function(
  arquivo_csv,
  arquivo_json,
  dimensao_col,
  dimensao_nome,
  descricao = ""
) {
  base <- carregar_base_sobreeducacao()
  assert_colunas(base, c("ano", "trimestre", "periodo", dimensao_col, "superior_completo", "peso", "peso_valido"), contexto = "base completa PNADc")

  universo <- base$peso_valido & base$superior_completo & !is.na(base[[dimensao_col]])
  if (!any(universo)) {
    stop("Sem registros validos para participacao de superior completo.")
  }

  df <- data.frame(
    Ano = base$ano[universo],
    Trimestre = base$trimestre[universo],
    periodo = base$periodo[universo],
    dimensao = as.character(base[[dimensao_col]][universo]),
    peso = base$peso[universo],
    stringsAsFactors = FALSE
  )

  agg <- aggregate(peso ~ Ano + Trimestre + periodo + dimensao, data = df, FUN = sum)
  total <- aggregate(peso ~ Ano + Trimestre + periodo, data = agg, FUN = sum)
  names(total)[names(total) == "peso"] <- "total_ponderado_superior_completo_periodo"

  resultado <- merge(agg, total, by = c("Ano", "Trimestre", "periodo"), all.x = TRUE)
  names(resultado)[names(resultado) == "dimensao"] <- dimensao_nome
  names(resultado)[names(resultado) == "peso"] <- "peso_ponderado_superior_completo"
  resultado$percentual <- round(
    100 * resultado$peso_ponderado_superior_completo / resultado$total_ponderado_superior_completo_periodo,
    4
  )
  resultado <- resultado[order(resultado$Ano, resultado$Trimestre, -resultado$percentual, resultado[[dimensao_nome]]), ]
  rownames(resultado) <- NULL

  dir.create(dirname(arquivo_csv), showWarnings = FALSE, recursive = TRUE)
  write.csv(resultado, arquivo_csv, row.names = FALSE, fileEncoding = "UTF-8")

  escrever_json_simples(
    tabela = resultado,
    arquivo_json = arquivo_json,
    metadata = list(
      gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
      fuso_horario = Sys.timezone(),
      descricao = descricao,
      fonte_local = "dados_pnadc/PNADC_0TAAAA.txt",
      periodos = sort(unique(resultado$periodo)),
      quantidade_periodos = length(unique(resultado$periodo)),
      observacao = "Reprocessado sobre todos os microdados TXT disponiveis localmente."
    )
  )

  cat("Concluido:", arquivo_csv, "\n")
  invisible(resultado)
}
