# Participacao percentual ponderada de pessoas com "Superior completo" por sexo
# Processa todos os recortes PNADc disponiveis em "saida/pnadc_*_t*_recorte.rds"

dir_entrada <- "saida"
arquivo_saida_distribuicao <- file.path(
  "saida",
  "participacao_superior_completo_por_sexo_ano_trimestre.csv"
)
arquivo_saida_json <- file.path(
  "saida",
  "participacao_superior_completo_por_sexo_ano_trimestre.json"
)

codigo_variavel_nivel_instrucao <- "VD3004"
valor_referencia_nivel_instrucao <- "Superior completo"
codigo_variavel_peso <- "V1028"
codigo_variavel_dimensao <- "V2007"
nome_campo_dimensao <- "sexo"

normalizar_texto <- function(x) {
  tolower(trimws(iconv(as.character(x), from = "", to = "ASCII//TRANSLIT")))
}

eh_superior_completo <- function(v) {
  norm <- normalizar_texto(v)
  ref <- normalizar_texto(valor_referencia_nivel_instrucao)
  !is.na(norm) & norm == ref
}

extrair_ano_trimestre_do_nome <- function(caminho) {
  nome <- basename(caminho)
  info <- sub("^pnadc_([0-9]{4})_t([1-4])_recorte\\.rds$", "\\1|\\2", nome)
  if (!grepl("^[0-9]{4}\\|[1-4]$", info)) {
    return(list(ano = NA_integer_, trimestre = NA_integer_))
  }
  partes <- strsplit(info, "\\|")[[1]]
  list(ano = as.integer(partes[1]), trimestre = as.integer(partes[2]))
}

arquivos_entrada <- sort(list.files(
  path = dir_entrada,
  pattern = "^pnadc_[0-9]{4}_t[1-4]_recorte\\.rds$",
  full.names = TRUE
))

if (length(arquivos_entrada) == 0) {
  stop(
    "Nenhum arquivo de entrada encontrado com o padrao ",
    normalizePath(file.path(dir_entrada, "pnadc_[AAAA]_t[T]_recorte.rds"), winslash = "/", mustWork = FALSE)
  )
}

cat("Arquivos de entrada encontrados:", length(arquivos_entrada), "\n")

lista_agregados_peso <- list()
lista_agregados_contagem <- list()
resumo_arquivos <- data.frame(
  arquivo = character(),
  ano_trimestre_nome = character(),
  registros_total = integer(),
  registros_superior_completo = integer(),
  registros_superior_completo_validos = integer(),
  registros_superior_completo_excluidos = integer(),
  perc_superior_completo_excluidos = numeric(),
  registros_superior_sem_dimensao = integer(),
  registros_superior_peso_invalido = integer(),
  stringsAsFactors = FALSE
)

for (i in seq_along(arquivos_entrada)) {
  arquivo <- arquivos_entrada[i]
  info_nome <- extrair_ano_trimestre_do_nome(arquivo)

  cat("\nProcessando [", i, "/", length(arquivos_entrada), "]: ", basename(arquivo), "\n", sep = "")

  dados <- readRDS(arquivo)
  if (!is.data.frame(dados)) {
    dados <- as.data.frame(dados, stringsAsFactors = FALSE)
  }

  colunas_obrigatorias <- c(codigo_variavel_nivel_instrucao, codigo_variavel_peso, codigo_variavel_dimensao)
  faltantes <- setdiff(colunas_obrigatorias, names(dados))
  if (length(faltantes) > 0) {
    stop("Colunas obrigatorias ausentes em ", basename(arquivo), ": ", paste(faltantes, collapse = ", "))
  }

  if ("Ano" %in% names(dados)) {
    ano <- suppressWarnings(as.integer(as.character(dados$Ano)))
  } else {
    ano <- rep(info_nome$ano, nrow(dados))
  }

  if ("Trimestre" %in% names(dados)) {
    trimestre <- suppressWarnings(as.integer(as.character(dados$Trimestre)))
  } else {
    trimestre <- rep(info_nome$trimestre, nrow(dados))
  }

  periodo_invalido <- is.na(ano) | is.na(trimestre) | !(trimestre %in% 1:4)

  peso <- suppressWarnings(as.numeric(dados[[codigo_variavel_peso]]))
  peso_invalido <- is.na(peso) | !is.finite(peso) | peso <= 0

  dimensao <- trimws(as.character(dados[[codigo_variavel_dimensao]]))
  dimensao[dimensao %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  dimensao_invalida <- is.na(dimensao)

  superior <- eh_superior_completo(dados[[codigo_variavel_nivel_instrucao]])
  universo <- superior & !periodo_invalido
  valido <- universo & !peso_invalido & !dimensao_invalida

  n_total <- nrow(dados)
  n_superior <- sum(universo)
  n_validos <- sum(valido)
  n_excluidos <- n_superior - n_validos
  n_sem_dimensao <- sum(universo & dimensao_invalida)
  n_peso_invalido <- sum(universo & peso_invalido)

  resumo_arquivos <- rbind(
    resumo_arquivos,
    data.frame(
      arquivo = basename(arquivo),
      ano_trimestre_nome = paste0(info_nome$ano, "T", info_nome$trimestre),
      registros_total = n_total,
      registros_superior_completo = n_superior,
      registros_superior_completo_validos = n_validos,
      registros_superior_completo_excluidos = n_excluidos,
      perc_superior_completo_excluidos = if (n_superior > 0) round(100 * n_excluidos / n_superior, 4) else NA_real_,
      registros_superior_sem_dimensao = n_sem_dimensao,
      registros_superior_peso_invalido = n_peso_invalido,
      stringsAsFactors = FALSE
    )
  )

  if (n_validos > 0) {
    dados_validos <- data.frame(
      Ano = ano[valido],
      Trimestre = trimestre[valido],
      dimensao_valor = dimensao[valido],
      peso = peso[valido],
      stringsAsFactors = FALSE
    )

    agg_peso <- aggregate(
      peso ~ Ano + Trimestre + dimensao_valor,
      data = dados_validos,
      FUN = sum
    )
    lista_agregados_peso[[length(lista_agregados_peso) + 1]] <- agg_peso
  }

  if (sum(universo & !dimensao_invalida) > 0) {
    dados_contagem <- data.frame(
      Ano = ano[universo & !dimensao_invalida],
      Trimestre = trimestre[universo & !dimensao_invalida],
      dimensao_valor = dimensao[universo & !dimensao_invalida],
      valido = as.integer(valido[universo & !dimensao_invalida]),
      one = 1L,
      stringsAsFactors = FALSE
    )

    total_dimensao <- aggregate(one ~ Ano + Trimestre + dimensao_valor, data = dados_contagem, FUN = sum)
    validos_dimensao <- aggregate(valido ~ Ano + Trimestre + dimensao_valor, data = dados_contagem, FUN = sum)
    contagem_dimensao <- merge(
      total_dimensao,
      validos_dimensao,
      by = c("Ano", "Trimestre", "dimensao_valor"),
      all = TRUE
    )
    names(contagem_dimensao) <- c(
      "Ano", "Trimestre", "dimensao_valor",
      "registros_superior_completo_total",
      "registros_superior_completo_validos"
    )

    lista_agregados_contagem[[length(lista_agregados_contagem) + 1]] <- contagem_dimensao
  }

  rm(dados)
  invisible(gc())
}

if (length(lista_agregados_peso) == 0) {
  stop("Nao ha registros validos para calcular participacao de superior completo por sexo.")
}

agregado_peso <- do.call(rbind, lista_agregados_peso)
agregado_peso <- aggregate(
  peso ~ Ano + Trimestre + dimensao_valor,
  data = agregado_peso,
  FUN = sum
)

total_superior_periodo <- aggregate(
  peso ~ Ano + Trimestre,
  data = agregado_peso,
  FUN = sum
)
names(total_superior_periodo)[3] <- "total_ponderado_superior_completo_periodo"

resultado <- merge(
  agregado_peso,
  total_superior_periodo,
  by = c("Ano", "Trimestre"),
  all.x = TRUE
)
names(resultado)[names(resultado) == "dimensao_valor"] <- nome_campo_dimensao
names(resultado)[names(resultado) == "peso"] <- "peso_ponderado_superior_completo"
resultado$percentual <- round(
  100 * resultado$peso_ponderado_superior_completo / resultado$total_ponderado_superior_completo_periodo,
  4
)
resultado <- resultado[order(
  resultado$Ano,
  resultado$Trimestre,
  -resultado$percentual,
  resultado[[nome_campo_dimensao]]
), ]
rownames(resultado) <- NULL

if (length(lista_agregados_contagem) > 0) {
  resumo_dimensao <- do.call(rbind, lista_agregados_contagem)
  resumo_dimensao <- aggregate(
    cbind(registros_superior_completo_total, registros_superior_completo_validos) ~ Ano + Trimestre + dimensao_valor,
    data = resumo_dimensao,
    FUN = sum
  )
} else {
  resumo_dimensao <- data.frame(
    Ano = integer(),
    Trimestre = integer(),
    dimensao_valor = character(),
    registros_superior_completo_total = integer(),
    registros_superior_completo_validos = integer(),
    stringsAsFactors = FALSE
  )
}
names(resumo_dimensao)[names(resumo_dimensao) == "dimensao_valor"] <- nome_campo_dimensao

resumo_dimensao <- merge(
  resumo_dimensao,
  total_superior_periodo,
  by = c("Ano", "Trimestre"),
  all = TRUE
)
resumo_dimensao$registros_superior_completo_excluidos <- resumo_dimensao$registros_superior_completo_total - resumo_dimensao$registros_superior_completo_validos
resumo_dimensao$perc_superior_completo_excluidos <- ifelse(
  resumo_dimensao$registros_superior_completo_total > 0,
  round(100 * resumo_dimensao$registros_superior_completo_excluidos / resumo_dimensao$registros_superior_completo_total, 4),
  NA_real_
)
resumo_dimensao <- resumo_dimensao[order(
  resumo_dimensao$Ano,
  resumo_dimensao$Trimestre,
  resumo_dimensao[[nome_campo_dimensao]]
), ]
rownames(resumo_dimensao) <- NULL

write.csv(resultado, arquivo_saida_distribuicao, row.names = FALSE, fileEncoding = "UTF-8")

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Pacote 'jsonlite' nao encontrado. Instale com install.packages('jsonlite').")
}

resultado_json <- resultado
resultado_json$periodo <- paste0(resultado_json$Ano, "-T", resultado_json$Trimestre)
resultado_json <- resultado_json[
  ,
  c(
    "Ano",
    "Trimestre",
    "periodo",
    nome_campo_dimensao,
    "peso_ponderado_superior_completo",
    "total_ponderado_superior_completo_periodo",
    "percentual"
  )
]

resumo_dimensao_json <- resumo_dimensao
resumo_dimensao_json$periodo <- paste0(resumo_dimensao_json$Ano, "-T", resumo_dimensao_json$Trimestre)
resumo_dimensao_json <- resumo_dimensao_json[
  ,
  c(
    "Ano",
    "Trimestre",
    "periodo",
    nome_campo_dimensao,
    "registros_superior_completo_total",
    "registros_superior_completo_validos",
    "registros_superior_completo_excluidos",
    "perc_superior_completo_excluidos",
    "total_ponderado_superior_completo_periodo"
  )
]

cortes_json <- lapply(seq_len(nrow(resumo_dimensao_json)), function(i) {
  linha <- resumo_dimensao_json[i, ]
  list(
    ano = as.integer(linha$Ano),
    trimestre = as.integer(linha$Trimestre),
    periodo = as.character(linha$periodo),
    dimensao = as.character(linha[[nome_campo_dimensao]]),
    peso_ponderado_superior_completo = as.numeric(
      resultado_json$peso_ponderado_superior_completo[
        resultado_json$Ano == linha$Ano &
          resultado_json$Trimestre == linha$Trimestre &
          resultado_json[[nome_campo_dimensao]] == linha[[nome_campo_dimensao]]
      ][1]
    ),
    percentual = as.numeric(
      resultado_json$percentual[
        resultado_json$Ano == linha$Ano &
          resultado_json$Trimestre == linha$Trimestre &
          resultado_json[[nome_campo_dimensao]] == linha[[nome_campo_dimensao]]
      ][1]
    ),
    resumo = list(
      registros_superior_completo_total = as.integer(linha$registros_superior_completo_total),
      registros_superior_completo_validos = as.integer(linha$registros_superior_completo_validos),
      registros_superior_completo_excluidos = as.integer(linha$registros_superior_completo_excluidos),
      perc_superior_completo_excluidos = as.numeric(linha$perc_superior_completo_excluidos),
      total_ponderado_superior_completo_periodo = as.numeric(linha$total_ponderado_superior_completo_periodo)
    )
  )
})

split_dimensao <- split(resultado_json, resultado_json[[nome_campo_dimensao]])
series_por_dimensao <- lapply(names(split_dimensao), function(valor_dimensao) {
  df <- split_dimensao[[valor_dimensao]]
  df <- df[order(df$Ano, df$Trimestre), ]
  list(
    dimensao = as.character(valor_dimensao),
    pontos = lapply(seq_len(nrow(df)), function(i) {
      list(
        ano = as.integer(df$Ano[i]),
        trimestre = as.integer(df$Trimestre[i]),
        periodo = as.character(df$periodo[i]),
        percentual = as.numeric(df$percentual[i]),
        peso_ponderado_superior_completo = as.numeric(df$peso_ponderado_superior_completo[i]),
        total_ponderado_superior_completo_periodo = as.numeric(df$total_ponderado_superior_completo_periodo[i])
      )
    })
  )
})

json_saida <- list(
  metadata = list(
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    fuso_horario = Sys.timezone(),
    arquivos_entrada = basename(arquivos_entrada),
    quantidade_arquivos = as.integer(length(arquivos_entrada)),
    quantidade_cortes = as.integer(nrow(resultado_json)),
    variavel_nivel_instrucao = codigo_variavel_nivel_instrucao,
    valor_referencia_nivel_instrucao = valor_referencia_nivel_instrucao,
    variavel_peso = codigo_variavel_peso,
    variavel_dimensao = codigo_variavel_dimensao,
    nome_campo_dimensao = nome_campo_dimensao,
    descricao = "Participacao percentual, por periodo, de pessoas com superior completo distribuidas por sexo (com pesos)."
  ),
  cortes = cortes_json,
  series_por_dimensao = series_por_dimensao,
  tabela_participacao = resultado_json,
  tabela_resumo_dimensao = resumo_dimensao_json,
  tabela_resumo_arquivo = resumo_arquivos
)

jsonlite::write_json(
  x = json_saida,
  path = arquivo_saida_json,
  pretty = TRUE,
  auto_unbox = TRUE,
  digits = 8
)

cat("\nProcessamento concluido com sucesso.\n")
cat("Cortes processados:", nrow(resultado_json), "\n")
cat("Arquivos processados:", nrow(resumo_arquivos), "\n")
cat("Saida distribuicao:", normalizePath(arquivo_saida_distribuicao), "\n")
cat("Saida JSON:", normalizePath(arquivo_saida_json), "\n\n")

resumo_print <- resultado
resumo_print$percentual <- sprintf("%.2f%%", resumo_print$percentual)
print(utils::head(resumo_print, 30), row.names = FALSE)
