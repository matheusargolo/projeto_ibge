# Numero de sobreeducados no Brasil por ano e trimestre (com pesos PNADc)
#
# Definicao de sobreeducado usada neste script:
# pessoa com "Superior completo" (VD3004) em ocupacao classificada
# como nao sendo de nivel superior (nivel_superior == 0).
#
# Entradas:
# - Microdados brutos PNADc em dados_pnadc/PNADC_0TAAAA.txt
# - Classificacao de ocupacoes em saida/ocupacoes_cod2010_classificadas.csv
#
# Saidas:
# - saida/numero_sobreeducados_brasil_por_ano_trimestre.csv
# - saida/numero_sobreeducados_brasil_por_ano_trimestre.json

suppressPackageStartupMessages(library(PNADcIBGE))

dir_microdados <- "dados_pnadc"
arquivo_classificacao <- file.path("saida", "ocupacoes_cod2010_classificadas.csv")
arquivo_saida_csv <- file.path("saida", "numero_sobreeducados_brasil_por_ano_trimestre.csv")
arquivo_saida_json <- file.path("saida", "numero_sobreeducados_brasil_por_ano_trimestre.json")

if (!file.exists(arquivo_classificacao)) {
  stop("Arquivo de classificacao nao encontrado: ", normalizePath(arquivo_classificacao, winslash = "/", mustWork = FALSE))
}

padronizar_codigo_ocupacao <- function(x) {
  y <- trimws(as.character(x))
  y[y %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  y <- gsub("[^0-9]", "", y)
  y[nchar(y) == 0] <- NA_character_
  idx_pad <- !is.na(y) & nchar(y) < 4
  y[idx_pad] <- paste0(strrep("0", 4 - nchar(y[idx_pad])), y[idx_pad])
  y
}

normalizar_texto <- function(x) {
  tolower(trimws(iconv(as.character(x), from = "", to = "ASCII//TRANSLIT")))
}

eh_superior_completo <- function(v) {
  x <- trimws(as.character(v))
  x[x %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  x_norm <- normalizar_texto(x)

  # Suporta tanto codigo (labels=FALSE) quanto rotulo (labels=TRUE)
  !is.na(x) & (x == "7" | x_norm == "superior completo")
}

extrair_periodos_disponiveis <- function(pasta) {
  arquivos_txt <- sort(list.files(
    path = pasta,
    pattern = "^PNADC_0[1-4][0-9]{4}\\.txt$",
    full.names = FALSE
  ))

  if (length(arquivos_txt) == 0) {
    return(data.frame(
      arquivo = character(),
      ano = integer(),
      trimestre = integer(),
      stringsAsFactors = FALSE
    ))
  }

  trimestre <- as.integer(substr(arquivos_txt, 8, 8))
  ano <- as.integer(substr(arquivos_txt, 9, 12))

  data.frame(
    arquivo = arquivos_txt,
    ano = ano,
    trimestre = trimestre,
    stringsAsFactors = FALSE
  )
}

classificacao <- read.csv2(
  arquivo_classificacao,
  stringsAsFactors = FALSE,
  fileEncoding = "UTF-8"
)

colunas_obrigatorias_classificacao <- c("codigo", "nivel_superior")
faltantes_classificacao <- setdiff(colunas_obrigatorias_classificacao, names(classificacao))
if (length(faltantes_classificacao) > 0) {
  stop(
    "Colunas obrigatorias ausentes na classificacao: ",
    paste(faltantes_classificacao, collapse = ", ")
  )
}

classificacao$codigo <- padronizar_codigo_ocupacao(classificacao$codigo)
classificacao$nivel_superior <- suppressWarnings(as.integer(as.character(classificacao$nivel_superior)))
valores_invalidos_classificacao <- sort(unique(classificacao$nivel_superior[
  !is.na(classificacao$nivel_superior) & !(classificacao$nivel_superior %in% c(0L, 1L, 2L))
]))
if (length(valores_invalidos_classificacao) > 0) {
  stop(
    "Valores invalidos em nivel_superior na classificacao: ",
    paste(valores_invalidos_classificacao, collapse = ", "),
    ". Use 0, 1 ou 2."
  )
}
classificacao <- classificacao[!is.na(classificacao$codigo) & !is.na(classificacao$nivel_superior), ]

if (nrow(classificacao) == 0) {
  stop("A classificacao de ocupacoes ficou vazia apos limpeza.")
}

if (anyDuplicated(classificacao$codigo) > 0) {
  codigos_duplicados <- unique(classificacao$codigo[duplicated(classificacao$codigo)])
  stop(
    "Classificacao com codigos duplicados: ",
    paste(codigos_duplicados, collapse = ", ")
  )
}

periodos <- extrair_periodos_disponiveis(dir_microdados)
if (nrow(periodos) == 0) {
  stop(
    "Nenhum microdado bruto encontrado em ",
    normalizePath(dir_microdados, winslash = "/", mustWork = FALSE),
    " com o padrao PNADC_0TAAAA.txt"
  )
}

periodos <- periodos[order(periodos$ano, periodos$trimestre), ]
rownames(periodos) <- NULL

cat("Periodos encontrados:", nrow(periodos), "\n")

carregar_pnadc_periodo <- function(ano, trimestre, pasta) {
  # get_pnadc costuma imprimir logs extensos; suprimimos stdout e mensagens aqui.
  tmp_out <- tempfile()
  tmp_msg <- tempfile()
  con_out <- file(tmp_out, open = "wt")
  con_msg <- file(tmp_msg, open = "wt")
  sink(con_out)
  sink(con_msg, type = "message")
  on.exit({
    sink(type = "message")
    sink()
    close(con_out)
    close(con_msg)
    unlink(c(tmp_out, tmp_msg))
  }, add = TRUE)

  dados <- get_pnadc(
    year = ano,
    quarter = trimestre,
    vars = c("Ano", "Trimestre", "VD3004", "V4010", "V1028"),
    labels = FALSE,
    deflator = FALSE,
    design = FALSE,
    reload = FALSE,
    savedir = pasta
  )
  dados
}

resultado <- data.frame(
  Ano = integer(),
  Trimestre = integer(),
  periodo = character(),
  numero_sobreeducados_ponderado = numeric(),
  total_superior_completo_ocupacao_classificada_ponderado = numeric(),
  percentual_sobreeducados_entre_superior_completo = numeric(),
  registros_superior_completo_total = integer(),
  registros_superior_completo_com_ocupacao_informada = integer(),
  registros_superior_completo_ocupacao_classificada = integer(),
  registros_superior_completo_sobreeducados = integer(),
  registros_superior_completo_excluidos_sem_ocupacao = integer(),
  registros_superior_completo_excluidos_ocupacao_ambigua = integer(),
  registros_superior_completo_excluidos_ocupacao_sem_classificacao = integer(),
  registros_superior_completo_excluidos_peso_invalido = integer(),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(periodos))) {
  ano_alvo <- periodos$ano[i]
  trimestre_alvo <- periodos$trimestre[i]

  cat("\nProcessando [", i, "/", nrow(periodos), "]: ", ano_alvo, " T", trimestre_alvo, "\n", sep = "")

  dados <- tryCatch(
    carregar_pnadc_periodo(ano_alvo, trimestre_alvo, dir_microdados),
    error = function(e) e
  )

  if (inherits(dados, "error")) {
    stop(
      "Falha ao carregar PNADc ",
      ano_alvo, " T", trimestre_alvo, ": ",
      conditionMessage(dados)
    )
  }

  ano <- if ("Ano" %in% names(dados)) suppressWarnings(as.integer(as.character(dados$Ano))) else rep(ano_alvo, nrow(dados))
  trimestre <- if ("Trimestre" %in% names(dados)) suppressWarnings(as.integer(as.character(dados$Trimestre))) else rep(trimestre_alvo, nrow(dados))
  periodo_invalido <- is.na(ano) | is.na(trimestre) | !(trimestre %in% 1:4)

  superior <- eh_superior_completo(dados$VD3004) & !periodo_invalido
  peso <- suppressWarnings(as.numeric(dados$V1028))
  peso_invalido <- is.na(peso) | !is.finite(peso) | peso <= 0

  ocupacao <- padronizar_codigo_ocupacao(dados$V4010)
  sem_ocupacao <- is.na(ocupacao)

  nivel_superior_ocupacao <- classificacao$nivel_superior[match(ocupacao, classificacao$codigo)]
  sem_classificacao <- is.na(nivel_superior_ocupacao)
  ocupacao_ambigua <- !sem_classificacao & nivel_superior_ocupacao == 2L
  ocupacao_classificada_sobreeducacao <- !sem_classificacao & nivel_superior_ocupacao %in% c(0L, 1L)

  universo <- superior & !sem_ocupacao & ocupacao_classificada_sobreeducacao & !peso_invalido
  sobreeducado <- universo & (nivel_superior_ocupacao == 0L)

  total_ponderado_universo <- sum(peso[universo])
  total_ponderado_sobreeducado <- sum(peso[sobreeducado])

  percentual_sobreeducados <- if (total_ponderado_universo > 0) {
    round(100 * total_ponderado_sobreeducado / total_ponderado_universo, 4)
  } else {
    NA_real_
  }

  resultado <- rbind(
    resultado,
    data.frame(
      Ano = ano_alvo,
      Trimestre = trimestre_alvo,
      periodo = paste0(ano_alvo, "-T", trimestre_alvo),
      numero_sobreeducados_ponderado = total_ponderado_sobreeducado,
      total_superior_completo_ocupacao_classificada_ponderado = total_ponderado_universo,
      percentual_sobreeducados_entre_superior_completo = percentual_sobreeducados,
      registros_superior_completo_total = sum(superior),
      registros_superior_completo_com_ocupacao_informada = sum(superior & !sem_ocupacao),
      registros_superior_completo_ocupacao_classificada = sum(superior & !sem_ocupacao & ocupacao_classificada_sobreeducacao),
      registros_superior_completo_sobreeducados = sum(sobreeducado),
      registros_superior_completo_excluidos_sem_ocupacao = sum(superior & sem_ocupacao),
      registros_superior_completo_excluidos_ocupacao_ambigua = sum(superior & !sem_ocupacao & ocupacao_ambigua),
      registros_superior_completo_excluidos_ocupacao_sem_classificacao = sum(superior & !sem_ocupacao & sem_classificacao),
      registros_superior_completo_excluidos_peso_invalido = sum(superior & !sem_ocupacao & ocupacao_classificada_sobreeducacao & peso_invalido),
      stringsAsFactors = FALSE
    )
  )

  rm(dados)
  invisible(gc())
}

resultado <- resultado[order(resultado$Ano, resultado$Trimestre), ]
rownames(resultado) <- NULL

write.csv(resultado, arquivo_saida_csv, row.names = FALSE, fileEncoding = "UTF-8")

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Pacote 'jsonlite' nao encontrado. Instale com install.packages('jsonlite').")
}

json_saida <- list(
  metadata = list(
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    fuso_horario = Sys.timezone(),
    arquivo_classificacao = arquivo_classificacao,
    periodos_processados = as.integer(nrow(resultado)),
    variavel_nivel_instrucao = "VD3004",
    variavel_ocupacao = "V4010",
    variavel_peso = "V1028",
    definicao_sobreeducado = "Superior completo em ocupacao classificada como nao nivel superior (nivel_superior=0); ocupacoes ambiguas (nivel_superior=2) sao excluidas do universo."
  ),
  tabela = resultado
)

jsonlite::write_json(
  x = json_saida,
  path = arquivo_saida_json,
  pretty = TRUE,
  auto_unbox = TRUE,
  digits = 8
)

cat("\nProcessamento concluido com sucesso.\n")
cat("Saida CSV: ", normalizePath(arquivo_saida_csv), "\n", sep = "")
cat("Saida JSON: ", normalizePath(arquivo_saida_json), "\n\n", sep = "")

print(resultado, row.names = FALSE)
