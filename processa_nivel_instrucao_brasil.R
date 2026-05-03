# Distribuicao percentual ponderada do nivel de instrucao - Brasil
# Processa todos os recortes PNADc disponiveis em "saida/pnadc_*_t*_recorte.rds"

dir_entrada <- "saida"
arquivo_saida_distribuicao <- file.path("saida", "distribuicao_nivel_instrucao_brasil_por_ano_trimestre.csv")
arquivo_saida_json <- file.path("saida", "distribuicao_nivel_instrucao_brasil_por_ano_trimestre.json")

codigo_variavel_nivel_instrucao <- "VD3004"
rotulo_variavel_nivel_instrucao <- "Nivel de instrucao mais elevado alcancado (5 anos ou mais de idade)"
nome_campo_nivel_instrucao <- "nivel_instrucao_mais_elevado_alcancado_5_anos_ou_mais_de_idade"
codigo_variavel_peso <- "V1028"

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

extrair_ano_trimestre_do_nome <- function(caminho) {
  nome <- basename(caminho)
  info <- sub("^pnadc_([0-9]{4})_t([1-4])_recorte\\.rds$", "\\1|\\2", nome)
  if (!grepl("^[0-9]{4}\\|[1-4]$", info)) {
    return(list(ano = NA_integer_, trimestre = NA_integer_))
  }
  partes <- strsplit(info, "\\|")[[1]]
  list(
    ano = as.integer(partes[1]),
    trimestre = as.integer(partes[2])
  )
}

lista_agregados_nivel <- list()
lista_agregados_contagem <- list()
resumo_arquivos <- data.frame(
  arquivo = character(),
  ano_trimestre_nome = character(),
  registros_total = integer(),
  registros_validos = integer(),
  registros_excluidos = integer(),
  perc_excluidos = numeric(),
  registros_sem_periodo_valido = integer(),
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

  colunas_obrigatorias <- c(codigo_variavel_nivel_instrucao, codigo_variavel_peso)
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

  peso <- suppressWarnings(as.numeric(dados[[codigo_variavel_peso]]))
  nivel_instrucao <- trimws(as.character(dados[[codigo_variavel_nivel_instrucao]]))
  nivel_instrucao[nivel_instrucao %in% c("", "NA", "N/A", "NULL")] <- NA_character_

  periodo_invalido <- is.na(ano) | is.na(trimestre) | !(trimestre %in% 1:4)
  peso_invalido <- is.na(peso) | !is.finite(peso) | peso <= 0
  nivel_invalido <- is.na(nivel_instrucao)
  valido <- !(periodo_invalido | peso_invalido | nivel_invalido)

  n_total <- nrow(dados)
  n_validos <- sum(valido)
  n_excluidos <- n_total - n_validos
  n_sem_periodo_valido <- sum(periodo_invalido)

  resumo_arquivos <- rbind(
    resumo_arquivos,
    data.frame(
      arquivo = basename(arquivo),
      ano_trimestre_nome = paste0(info_nome$ano, "T", info_nome$trimestre),
      registros_total = n_total,
      registros_validos = n_validos,
      registros_excluidos = n_excluidos,
      perc_excluidos = if (n_total > 0) round(100 * n_excluidos / n_total, 4) else NA_real_,
      registros_sem_periodo_valido = n_sem_periodo_valido,
      stringsAsFactors = FALSE
    )
  )

  if (n_validos > 0) {
    dados_validos <- data.frame(
      Ano = ano[valido],
      Trimestre = trimestre[valido],
      nivel_instrucao_valor = nivel_instrucao[valido],
      peso = peso[valido],
      stringsAsFactors = FALSE
    )

    agg_nivel <- aggregate(
      peso ~ Ano + Trimestre + nivel_instrucao_valor,
      data = dados_validos,
      FUN = sum
    )
    lista_agregados_nivel[[length(lista_agregados_nivel) + 1]] <- agg_nivel
  }

  idx_periodo <- !periodo_invalido
  if (sum(idx_periodo) > 0) {
    dados_periodo <- data.frame(
      Ano = ano[idx_periodo],
      Trimestre = trimestre[idx_periodo],
      valido = as.integer(valido[idx_periodo]),
      one = 1L,
      stringsAsFactors = FALSE
    )

    total_periodo <- aggregate(one ~ Ano + Trimestre, data = dados_periodo, FUN = sum)
    validos_periodo <- aggregate(valido ~ Ano + Trimestre, data = dados_periodo, FUN = sum)
    contagem_periodo <- merge(total_periodo, validos_periodo, by = c("Ano", "Trimestre"), all = TRUE)
    names(contagem_periodo) <- c("Ano", "Trimestre", "registros_total", "registros_validos")

    lista_agregados_contagem[[length(lista_agregados_contagem) + 1]] <- contagem_periodo
  }

  rm(dados)
  invisible(gc())
}

if (length(lista_agregados_nivel) == 0) {
  stop("Nao ha registros validos para calcular distribuicao ponderada.")
}

agregado_nivel <- do.call(rbind, lista_agregados_nivel)
agregado_nivel <- aggregate(
  peso ~ Ano + Trimestre + nivel_instrucao_valor,
  data = agregado_nivel,
  FUN = sum
)

total_ponderado_periodo <- aggregate(
  peso ~ Ano + Trimestre,
  data = agregado_nivel,
  FUN = sum
)
names(total_ponderado_periodo)[3] <- "total_ponderado"

resultado <- merge(
  agregado_nivel,
  total_ponderado_periodo,
  by = c("Ano", "Trimestre"),
  all.x = TRUE
)
names(resultado)[names(resultado) == "nivel_instrucao_valor"] <- nome_campo_nivel_instrucao
resultado$percentual <- round((resultado$peso / resultado$total_ponderado) * 100, 4)
resultado <- resultado[order(resultado$Ano, resultado$Trimestre, -resultado$percentual, resultado[[nome_campo_nivel_instrucao]]), ]
rownames(resultado) <- NULL

if (length(lista_agregados_contagem) > 0) {
  contagem_periodo <- do.call(rbind, lista_agregados_contagem)
  contagem_periodo <- aggregate(
    cbind(registros_total, registros_validos) ~ Ano + Trimestre,
    data = contagem_periodo,
    FUN = sum
  )
} else {
  contagem_periodo <- data.frame(
    Ano = integer(),
    Trimestre = integer(),
    registros_total = integer(),
    registros_validos = integer(),
    stringsAsFactors = FALSE
  )
}

resumo_periodo <- merge(
  contagem_periodo,
  total_ponderado_periodo,
  by = c("Ano", "Trimestre"),
  all = TRUE
)
resumo_periodo$registros_excluidos <- resumo_periodo$registros_total - resumo_periodo$registros_validos
resumo_periodo$perc_excluidos <- ifelse(
  resumo_periodo$registros_total > 0,
  round(100 * resumo_periodo$registros_excluidos / resumo_periodo$registros_total, 4),
  NA_real_
)
resumo_periodo <- resumo_periodo[order(resumo_periodo$Ano, resumo_periodo$Trimestre), ]
rownames(resumo_periodo) <- NULL

write.csv(resultado, arquivo_saida_distribuicao, row.names = FALSE, fileEncoding = "UTF-8")

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Pacote 'jsonlite' nao encontrado. Instale com install.packages('jsonlite').")
}

resultado_json <- resultado
resultado_json$periodo <- paste0(resultado_json$Ano, "-T", resultado_json$Trimestre)
resultado_json <- resultado_json[, c("Ano", "Trimestre", "periodo", nome_campo_nivel_instrucao, "peso", "total_ponderado", "percentual")]

resumo_periodo_json <- resumo_periodo
resumo_periodo_json$periodo <- paste0(resumo_periodo_json$Ano, "-T", resumo_periodo_json$Trimestre)
resumo_periodo_json <- resumo_periodo_json[
  ,
  c(
    "Ano", "Trimestre", "periodo",
    "registros_total", "registros_validos", "registros_excluidos", "perc_excluidos",
    "total_ponderado"
  )
]

periodos_json <- lapply(seq_len(nrow(resumo_periodo_json)), function(i) {
  linha <- resumo_periodo_json[i, ]
  fatia <- resultado_json[resultado_json$Ano == linha$Ano & resultado_json$Trimestre == linha$Trimestre, ]
  fatia <- fatia[order(-fatia$percentual, fatia[[nome_campo_nivel_instrucao]]), ]

  list(
    ano = as.integer(linha$Ano),
    trimestre = as.integer(linha$Trimestre),
    periodo = as.character(linha$periodo),
    resumo = list(
      registros_total = as.integer(linha$registros_total),
      registros_validos = as.integer(linha$registros_validos),
      registros_excluidos = as.integer(linha$registros_excluidos),
      perc_excluidos = as.numeric(linha$perc_excluidos),
      total_ponderado = as.numeric(linha$total_ponderado)
    ),
    niveis = lapply(seq_len(nrow(fatia)), function(j) {
      setNames(
        list(
          as.character(fatia[[nome_campo_nivel_instrucao]][j]),
          as.numeric(fatia$peso[j]),
          as.numeric(fatia$percentual[j])
        ),
        c(nome_campo_nivel_instrucao, "peso", "percentual")
      )
    })
  )
})

split_nivel <- split(resultado_json, resultado_json[[nome_campo_nivel_instrucao]])
series_por_nivel <- lapply(names(split_nivel), function(nivel) {
  df <- split_nivel[[nivel]]
  df <- df[order(df$Ano, df$Trimestre), ]
  bloco <- list(
    pontos = lapply(seq_len(nrow(df)), function(i) {
      list(
        ano = as.integer(df$Ano[i]),
        trimestre = as.integer(df$Trimestre[i]),
        periodo = as.character(df$periodo[i]),
        percentual = as.numeric(df$percentual[i]),
        peso = as.numeric(df$peso[i]),
        total_ponderado = as.numeric(df$total_ponderado[i])
      )
    })
  )
  bloco[[nome_campo_nivel_instrucao]] <- as.character(nivel)
  bloco
})

json_saida <- list(
  metadata = list(
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    fuso_horario = Sys.timezone(),
    arquivos_entrada = basename(arquivos_entrada),
    quantidade_arquivos = as.integer(length(arquivos_entrada)),
    quantidade_periodos = as.integer(nrow(resumo_periodo_json)),
    variavel_principal = codigo_variavel_nivel_instrucao,
    rotulo_variavel_principal = rotulo_variavel_nivel_instrucao,
    variavel_peso = codigo_variavel_peso,
    descricao = "Distribuicao percentual ponderada de nivel de instrucao no Brasil por ano e trimestre."
  ),
  periodos = periodos_json,
  series_por_nivel = series_por_nivel,
  tabela_distribuicao = resultado_json,
  tabela_resumo_periodo = resumo_periodo_json,
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
cat("Periodos processados:", nrow(resumo_periodo), "\n")
cat("Arquivos processados:", nrow(resumo_arquivos), "\n")
cat("Saida distribuicao:", normalizePath(arquivo_saida_distribuicao), "\n")
cat("Saida JSON:", normalizePath(arquivo_saida_json), "\n\n")

resumo_print <- resultado
resumo_print$percentual <- sprintf("%.2f%%", resumo_print$percentual)
print(utils::head(resumo_print, 30), row.names = FALSE)
