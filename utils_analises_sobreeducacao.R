# Utilitarios para analises de sobreeducacao com PNADc
# - Carrega/cacheia base harmonizada a partir dos microdados brutos
# - Aplica classificacao de ocupacoes (nivel_superior)
# - Fornece funcoes de agregacao e exportacao CSV/JSON

`%||%` <- function(a, b) {
  if (!is.null(a)) a else b
}

assert_colunas <- function(df, cols, contexto = "") {
  faltantes <- setdiff(cols, names(df))
  if (length(faltantes) > 0) {
    stop(
      "Colunas ausentes ",
      if (nzchar(contexto)) paste0("em ", contexto, ": ") else ": ",
      paste(faltantes, collapse = ", ")
    )
  }
}

padronizar_codigo_ocupacao <- function(x) {
  y <- trimws(as.character(x))
  y[y %in% c("", "NA", "N/A", "NULL")] <- NA_character_
  y <- gsub("[^0-9]", "", y)
  y[nchar(y) == 0] <- NA_character_
  idx <- !is.na(y) & nchar(y) < 4
  y[idx] <- paste0(strrep("0", 4 - nchar(y[idx])), y[idx])
  y
}

mapa_ufs <- function() {
  data.frame(
    uf_codigo = c(11, 12, 13, 14, 15, 16, 17, 21, 22, 23, 24, 25, 26, 27, 28, 29, 31, 32, 33, 35, 41, 42, 43, 50, 51, 52, 53),
    uf_sigla = c("RO", "AC", "AM", "RR", "PA", "AP", "TO", "MA", "PI", "CE", "RN", "PB", "PE", "AL", "SE", "BA", "MG", "ES", "RJ", "SP", "PR", "SC", "RS", "MS", "MT", "GO", "DF"),
    uf_nome = c(
      "Rondonia", "Acre", "Amazonas", "Roraima", "Para", "Amapa", "Tocantins",
      "Maranhao", "Piaui", "Ceara", "Rio Grande do Norte", "Paraiba", "Pernambuco", "Alagoas", "Sergipe", "Bahia",
      "Minas Gerais", "Espirito Santo", "Rio de Janeiro", "Sao Paulo",
      "Parana", "Santa Catarina", "Rio Grande do Sul",
      "Mato Grosso do Sul", "Mato Grosso", "Goias", "Distrito Federal"
    ),
    regiao = c(
      "Norte", "Norte", "Norte", "Norte", "Norte", "Norte", "Norte",
      "Nordeste", "Nordeste", "Nordeste", "Nordeste", "Nordeste", "Nordeste", "Nordeste", "Nordeste", "Nordeste",
      "Sudeste", "Sudeste", "Sudeste", "Sudeste",
      "Sul", "Sul", "Sul",
      "Centro-Oeste", "Centro-Oeste", "Centro-Oeste", "Centro-Oeste"
    ),
    stringsAsFactors = FALSE
  )
}

mapa_sexo <- function() {
  c(
    "1" = "Homem",
    "2" = "Mulher"
  )
}

mapa_raca_cor <- function() {
  c(
    "1" = "Branca",
    "2" = "Preta",
    "3" = "Amarela",
    "4" = "Parda",
    "5" = "Indigena",
    "9" = "Ignorado"
  )
}

mapa_nivel_instrucao <- function() {
  c(
    "1" = "Sem instrucao e menos de 1 ano de estudo",
    "2" = "Fundamental incompleto ou equivalente",
    "3" = "Fundamental completo ou equivalente",
    "4" = "Medio incompleto ou equivalente",
    "5" = "Medio completo ou equivalente",
    "6" = "Superior incompleto ou equivalente",
    "7" = "Superior completo"
  )
}

extrair_periodos_disponiveis <- function(dir_microdados = "dados_pnadc") {
  arquivos <- sort(list.files(
    path = dir_microdados,
    pattern = "^PNADC_0[1-4][0-9]{4}\\.txt$",
    full.names = FALSE
  ))

  if (length(arquivos) == 0) {
    stop(
      "Nenhum arquivo PNADc bruto encontrado em ",
      normalizePath(dir_microdados, winslash = "/", mustWork = FALSE),
      " com padrao PNADC_0TAAAA.txt"
    )
  }

  data.frame(
    arquivo = arquivos,
    trimestre = as.integer(substr(arquivos, 8, 8)),
    ano = as.integer(substr(arquivos, 9, 12)),
    stringsAsFactors = FALSE
  )
}

ler_classificacao_ocupacoes <- function(
  arquivo_classificacao = file.path("saida", "ocupacoes_cod2010_classificadas.csv")
) {
  if (!file.exists(arquivo_classificacao)) {
    stop("Arquivo de classificacao nao encontrado: ", normalizePath(arquivo_classificacao, winslash = "/", mustWork = FALSE))
  }

  # Tenta UTF-8 e, se necessario, Latin1.
  cls <- tryCatch(
    read.csv2(arquivo_classificacao, stringsAsFactors = FALSE, fileEncoding = "UTF-8"),
    error = function(e) NULL
  )
  if (is.null(cls)) {
    cls <- read.csv2(arquivo_classificacao, stringsAsFactors = FALSE, fileEncoding = "Latin1")
  }

  assert_colunas(cls, c("codigo", "nivel_superior"), contexto = "classificacao de ocupacoes")

  cls$codigo <- padronizar_codigo_ocupacao(cls$codigo)
  cls$nivel_superior <- suppressWarnings(as.integer(as.character(cls$nivel_superior)))
  valores_invalidos <- sort(unique(cls$nivel_superior[!is.na(cls$nivel_superior) & !(cls$nivel_superior %in% c(0L, 1L, 2L))]))
  if (length(valores_invalidos) > 0) {
    stop(
      "Valores invalidos em nivel_superior na classificacao de ocupacoes: ",
      paste(valores_invalidos, collapse = ", "),
      ". Use 0, 1 ou 2."
    )
  }
  if (!("nome" %in% names(cls))) {
    cls$nome <- NA_character_
  }
  cls$nome <- trimws(as.character(cls$nome))
  cls$nome[cls$nome %in% c("", "NA", "N/A", "NULL")] <- NA_character_

  cls <- cls[!is.na(cls$codigo) & !is.na(cls$nivel_superior), c("codigo", "nome", "nivel_superior")]
  cls <- cls[!duplicated(cls$codigo), ]

  if (nrow(cls) == 0) {
    stop("Classificacao de ocupacoes ficou vazia apos limpeza.")
  }

  cls
}

carregar_pnadc_periodo <- function(ano, trimestre, dir_microdados = "dados_pnadc") {
  arquivo <- file.path(dir_microdados, sprintf("PNADC_0%d%d.txt", trimestre, ano))
  if (!file.exists(arquivo)) {
    stop("Microdado local nao encontrado: ", normalizePath(arquivo, winslash = "/", mustWork = FALSE))
  }

  ler_num <- function(x) {
    x <- trimws(x)
    x[x == ""] <- NA_character_
    suppressWarnings(as.numeric(x))
  }

  ler_int <- function(x) {
    x <- trimws(x)
    x[x == ""] <- NA_character_
    suppressWarnings(as.integer(x))
  }

  con <- file(arquivo, open = "rt")
  on.exit(close(con), add = TRUE)

  partes <- list()
  i <- 0L
  repeat {
    linhas <- readLines(con, n = 100000L, warn = FALSE)
    if (length(linhas) == 0) break

    i <- i + 1L
    partes[[i]] <- data.frame(
      Ano = substr(linhas, 1L, 4L),
      Trimestre = substr(linhas, 5L, 5L),
      UF = substr(linhas, 6L, 7L),
      V1028 = ler_num(substr(linhas, 50L, 64L)),
      V2007 = substr(linhas, 95L, 95L),
      V2010 = substr(linhas, 107L, 107L),
      V4010 = substr(linhas, 152L, 155L),
      VD3004 = substr(linhas, 405L, 405L),
      VD4019 = ler_num(substr(linhas, 444L, 451L)),
      VD4020 = ler_num(substr(linhas, 452L, 459L)),
      stringsAsFactors = FALSE
    )
  }

  if (length(partes) == 0) {
    return(data.frame(
      Ano = character(),
      Trimestre = character(),
      UF = character(),
      V1028 = numeric(),
      V2007 = character(),
      V2010 = character(),
      V4010 = character(),
      VD3004 = character(),
      VD4019 = numeric(),
      VD4020 = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  do.call(rbind, partes)
}

montar_base_sobreeducacao <- function(
  dir_microdados = "dados_pnadc",
  arquivo_classificacao = file.path("saida", "ocupacoes_cod2010_classificadas.csv"),
  verbose = TRUE
) {
  periodos <- extrair_periodos_disponiveis(dir_microdados)
  periodos <- periodos[order(periodos$ano, periodos$trimestre), ]
  rownames(periodos) <- NULL

  if (verbose) {
    cat("Periodos encontrados:", nrow(periodos), "\n")
  }

  classificacao <- ler_classificacao_ocupacoes(arquivo_classificacao)
  mapa_nivel_ocupacao <- setNames(classificacao$nivel_superior, classificacao$codigo)
  mapa_nome_ocupacao <- setNames(classificacao$nome, classificacao$codigo)

  uf_tab <- mapa_ufs()
  mapa_uf_sigla <- setNames(uf_tab$uf_sigla, uf_tab$uf_codigo)
  mapa_uf_nome <- setNames(uf_tab$uf_nome, uf_tab$uf_codigo)
  mapa_regiao <- setNames(uf_tab$regiao, uf_tab$uf_codigo)

  mapa_sexo_cod <- mapa_sexo()
  mapa_raca_cod <- mapa_raca_cor()
  mapa_instr_cod <- mapa_nivel_instrucao()

  blocos <- vector("list", length = nrow(periodos))

  for (i in seq_len(nrow(periodos))) {
    ano_alvo <- periodos$ano[i]
    trimestre_alvo <- periodos$trimestre[i]

    if (verbose) {
      cat("\nCarregando [", i, "/", nrow(periodos), "]: ", ano_alvo, " T", trimestre_alvo, "\n", sep = "")
    }

    dados <- carregar_pnadc_periodo(ano_alvo, trimestre_alvo, dir_microdados = dir_microdados)
    if (!is.data.frame(dados)) {
      dados <- as.data.frame(dados, stringsAsFactors = FALSE)
    }

    n <- nrow(dados)

    ano <- if ("Ano" %in% names(dados)) suppressWarnings(as.integer(as.character(dados$Ano))) else rep(ano_alvo, n)
    trimestre <- if ("Trimestre" %in% names(dados)) suppressWarnings(as.integer(as.character(dados$Trimestre))) else rep(trimestre_alvo, n)

    uf_codigo <- if ("UF" %in% names(dados)) suppressWarnings(as.integer(as.character(dados$UF))) else rep(NA_integer_, n)
    uf_sigla <- unname(mapa_uf_sigla[as.character(uf_codigo)])
    uf_nome <- unname(mapa_uf_nome[as.character(uf_codigo)])
    regiao <- unname(mapa_regiao[as.character(uf_codigo)])

    sexo_cod <- if ("V2007" %in% names(dados)) trimws(as.character(dados$V2007)) else rep(NA_character_, n)
    sexo <- unname(mapa_sexo_cod[sexo_cod])

    raca_cod <- if ("V2010" %in% names(dados)) trimws(as.character(dados$V2010)) else rep(NA_character_, n)
    cor_ou_raca <- unname(mapa_raca_cod[raca_cod])

    nivel_instrucao_cod <- if ("VD3004" %in% names(dados)) trimws(as.character(dados$VD3004)) else rep(NA_character_, n)
    nivel_instrucao <- unname(mapa_instr_cod[nivel_instrucao_cod])
    superior_completo <- !is.na(nivel_instrucao_cod) & nivel_instrucao_cod == "7"

    ocupacao_codigo <- if ("V4010" %in% names(dados)) padronizar_codigo_ocupacao(dados$V4010) else rep(NA_character_, n)
    ocupacao_nome <- unname(mapa_nome_ocupacao[ocupacao_codigo])
    ocupacao_nivel_superior <- suppressWarnings(as.integer(unname(mapa_nivel_ocupacao[ocupacao_codigo])))
    ocupacao_informada <- !is.na(ocupacao_codigo)
    ocupacao_ambigua_nivel_superior <- !is.na(ocupacao_nivel_superior) & ocupacao_nivel_superior == 2L
    ocupacao_classificada <- !is.na(ocupacao_nivel_superior) & ocupacao_nivel_superior %in% c(0L, 1L)

    peso <- if ("V1028" %in% names(dados)) suppressWarnings(as.numeric(dados$V1028)) else rep(NA_real_, n)
    peso_valido <- !is.na(peso) & is.finite(peso) & peso > 0

    rendimento_habitual_todos_trabalhos <- if ("VD4019" %in% names(dados)) suppressWarnings(as.numeric(dados$VD4019)) else rep(NA_real_, n)
    rendimento_efetivo_todos_trabalhos <- if ("VD4020" %in% names(dados)) suppressWarnings(as.numeric(dados$VD4020)) else rep(NA_real_, n)

    sobreeducado <- superior_completo & ocupacao_classificada & (ocupacao_nivel_superior == 0L)
    nao_sobreeducado_superior <- superior_completo & ocupacao_classificada & (ocupacao_nivel_superior == 1L)

    bloco <- data.frame(
      ano = ano,
      trimestre = trimestre,
      periodo = paste0(ano, "-T", trimestre),
      uf_codigo = uf_codigo,
      uf_sigla = uf_sigla,
      uf_nome = uf_nome,
      regiao = regiao,
      sexo = sexo,
      cor_ou_raca = cor_ou_raca,
      nivel_instrucao_codigo = nivel_instrucao_cod,
      nivel_instrucao = nivel_instrucao,
      ocupacao_codigo = ocupacao_codigo,
      ocupacao_nome = ocupacao_nome,
      ocupacao_nivel_superior = ocupacao_nivel_superior,
      ocupacao_informada = ocupacao_informada,
      ocupacao_ambigua_nivel_superior = ocupacao_ambigua_nivel_superior,
      ocupacao_classificada = ocupacao_classificada,
      superior_completo = superior_completo,
      sobreeducado = sobreeducado,
      nao_sobreeducado_superior = nao_sobreeducado_superior,
      peso = peso,
      peso_valido = peso_valido,
      rendimento_habitual_todos_trabalhos = rendimento_habitual_todos_trabalhos,
      rendimento_efetivo_todos_trabalhos = rendimento_efetivo_todos_trabalhos,
      stringsAsFactors = FALSE
    )

    periodo_valido <- !is.na(bloco$ano) & !is.na(bloco$trimestre) & bloco$trimestre %in% 1:4
    bloco <- bloco[periodo_valido, ]

    blocos[[i]] <- bloco
    rm(dados, bloco)
    invisible(gc())
  }

  base <- do.call(rbind, blocos)
  base <- base[order(base$ano, base$trimestre), ]
  rownames(base) <- NULL
  base
}

carregar_base_sobreeducacao <- function(
  cache_path = file.path("saida", "base_pnadc_sobreeducacao.rds"),
  force_rebuild = FALSE,
  dir_microdados = "dados_pnadc",
  arquivo_classificacao = file.path("saida", "ocupacoes_cod2010_classificadas.csv"),
  verbose = TRUE
) {
  if (!force_rebuild && file.exists(cache_path)) {
    if (verbose) cat("Lendo base de cache:", normalizePath(cache_path), "\n")
    base <- readRDS(cache_path)
    return(base)
  }

  if (verbose) cat("Construindo base harmonizada de sobreeducacao...\n")
  base <- montar_base_sobreeducacao(
    dir_microdados = dir_microdados,
    arquivo_classificacao = arquivo_classificacao,
    verbose = verbose
  )

  dir.create(dirname(cache_path), showWarnings = FALSE, recursive = TRUE)
  saveRDS(base, cache_path)

  if (verbose) {
    cat("Base salva em:", normalizePath(cache_path), "\n")
    cat("Registros:", nrow(base), "\n")
  }

  base
}

obter_ultimo_periodo <- function(base) {
  assert_colunas(base, c("ano", "trimestre"), contexto = "base")
  max_ano <- max(base$ano, na.rm = TRUE)
  max_tri <- max(base$trimestre[base$ano == max_ano], na.rm = TRUE)
  list(ano = as.integer(max_ano), trimestre = as.integer(max_tri))
}

filtrar_ultimo_periodo <- function(base) {
  p <- obter_ultimo_periodo(base)
  base[base$ano == p$ano & base$trimestre == p$trimestre, ]
}

metadados_decisoes_metodologicas <- function() {
  list(
    periodo_analisado = "Todos os periodos trimestrais disponiveis localmente em dados_pnadc/PNADC_0TAAAA.txt.",
    definicao_sobreeducado = "Pessoa com nivel de instrucao 'Superior completo' (VD3004=7) trabalhando em ocupacao classificada como nao exigente de nivel superior (nivel_superior=0).",
    classificacao_ocupacoes = "Arquivo saida/ocupacoes_cod2010_classificadas.csv, definido previamente pelo usuario. Ocupacoes com nivel_superior=2 sao ambiguas e ficam fora do universo das analises de sobreeducacao.",
    pesos = "Todas as estimativas ponderadas usam V1028 e ignoram pesos invalidos (NA, nao finito, <=0).",
    percentual_sobreeducacao_dimensoes = "Percentual dentro de cada grupo: peso_sobreeducados / peso_superior_completo_com_ocupacao_classificada_para_sobreeducacao (nivel_superior 0 ou 1).",
    remuneracao_escolha = "Foram calculadas duas metricas: VD4019 (rendimento habitual em todos os trabalhos) e VD4020 (rendimento efetivo em todos os trabalhos).",
    filtro_remuneracao = "Medias de remuneracao usam apenas rendimentos positivos (>0), com peso valido e ocupacao informada."
  )
}

escrever_saida_csv_json <- function(
  tabela,
  arquivo_csv,
  arquivo_json,
  nome_analise,
  descricao,
  extras_json = list()
) {
  dir.create(dirname(arquivo_csv), showWarnings = FALSE, recursive = TRUE)
  dir.create(dirname(arquivo_json), showWarnings = FALSE, recursive = TRUE)

  write.csv(tabela, arquivo_csv, row.names = FALSE, fileEncoding = "UTF-8")

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Pacote 'jsonlite' nao encontrado. Instale com install.packages('jsonlite').")
  }

  base_json <- list(
    metadata = c(
      list(
        nome_analise = nome_analise,
        descricao = descricao,
        gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
        fuso_horario = Sys.timezone()
      ),
      metadados_decisoes_metodologicas()
    ),
    tabela = tabela
  )

  for (k in names(extras_json)) {
    base_json[[k]] <- extras_json[[k]]
  }

  jsonlite::write_json(
    x = base_json,
    path = arquivo_json,
    pretty = TRUE,
    auto_unbox = TRUE,
    digits = 8
  )
}

calc_percentual_sobreeducados_por_dimensao <- function(base, col_dimensao, nome_dimensao_saida) {
  assert_colunas(base, c("ano", "trimestre", "periodo", col_dimensao, "peso", "peso_valido", "superior_completo", "ocupacao_classificada", "sobreeducado"))

  universo <- base$peso_valido & base$superior_completo & base$ocupacao_classificada & !is.na(base[[col_dimensao]])
  if (!any(universo)) {
    stop("Sem registros validos para calcular sobreeducacao por ", col_dimensao)
  }

  df_uni <- data.frame(
    Ano = base$ano[universo],
    Trimestre = base$trimestre[universo],
    periodo = base$periodo[universo],
    dimensao = as.character(base[[col_dimensao]][universo]),
    peso = base$peso[universo],
    sobreeducado = as.integer(base$sobreeducado[universo]),
    stringsAsFactors = FALSE
  )

  agg_den <- aggregate(
    cbind(peso_universo = peso, registros_universo = sobreeducado * 0 + 1L) ~ Ano + Trimestre + periodo + dimensao,
    data = df_uni,
    FUN = sum
  )

  df_num <- df_uni[df_uni$sobreeducado == 1L, ]
  if (nrow(df_num) > 0) {
    agg_num <- aggregate(
      cbind(peso_sobreeducados = peso, registros_sobreeducados = sobreeducado * 0 + 1L) ~ Ano + Trimestre + periodo + dimensao,
      data = df_num,
      FUN = sum
    )
  } else {
    agg_num <- data.frame(
      Ano = integer(),
      Trimestre = integer(),
      periodo = character(),
      dimensao = character(),
      peso_sobreeducados = numeric(),
      registros_sobreeducados = integer(),
      stringsAsFactors = FALSE
    )
  }

  res <- merge(agg_den, agg_num, by = c("Ano", "Trimestre", "periodo", "dimensao"), all.x = TRUE)
  res$peso_sobreeducados[is.na(res$peso_sobreeducados)] <- 0
  res$registros_sobreeducados[is.na(res$registros_sobreeducados)] <- 0L
  res$percentual_sobreeducados_no_grupo <- round(100 * res$peso_sobreeducados / res$peso_universo, 4)

  total_periodo <- aggregate(
    peso_sobreeducados ~ Ano + Trimestre + periodo,
    data = res,
    FUN = sum
  )
  names(total_periodo)[4] <- "peso_sobreeducados_total_periodo"
  res <- merge(res, total_periodo, by = c("Ano", "Trimestre", "periodo"), all.x = TRUE)
  res$participacao_do_grupo_no_total_sobreeducados_periodo <- ifelse(
    res$peso_sobreeducados_total_periodo > 0,
    round(100 * res$peso_sobreeducados / res$peso_sobreeducados_total_periodo, 4),
    NA_real_
  )

  names(res)[names(res) == "dimensao"] <- nome_dimensao_saida
  res <- res[order(res$Ano, res$Trimestre, res[[nome_dimensao_saida]]), ]
  rownames(res) <- NULL
  res
}

calc_percentual_sobreeducados_por_ocupacao <- function(base) {
  assert_colunas(base, c(
    "ano", "trimestre", "periodo", "ocupacao_codigo", "ocupacao_nome", "ocupacao_nivel_superior",
    "peso", "peso_valido", "ocupacao_informada", "ocupacao_classificada", "superior_completo", "sobreeducado"
  ))

  idx_ocup <- base$peso_valido & base$ocupacao_informada & base$ocupacao_classificada
  idx_uni_sup <- idx_ocup & base$superior_completo & base$ocupacao_classificada
  idx_sob <- idx_uni_sup & base$sobreeducado

  if (!any(idx_ocup)) {
    stop("Sem registros validos com ocupacao para calcular percentual por ocupacao.")
  }

  df_ocup <- data.frame(
    Ano = base$ano[idx_ocup],
    Trimestre = base$trimestre[idx_ocup],
    periodo = base$periodo[idx_ocup],
    ocupacao_codigo = base$ocupacao_codigo[idx_ocup],
    ocupacao_nome = base$ocupacao_nome[idx_ocup],
    ocupacao_nivel_superior = base$ocupacao_nivel_superior[idx_ocup],
    peso = base$peso[idx_ocup],
    stringsAsFactors = FALSE
  )

  agg_tot_ocup <- aggregate(
    cbind(peso_total_ocupados_ocupacao = peso, registros_total_ocupados_ocupacao = peso * 0 + 1L) ~
      Ano + Trimestre + periodo + ocupacao_codigo + ocupacao_nome + ocupacao_nivel_superior,
    data = df_ocup,
    FUN = sum
  )

  if (any(idx_uni_sup)) {
    df_uni <- data.frame(
      Ano = base$ano[idx_uni_sup],
      Trimestre = base$trimestre[idx_uni_sup],
      periodo = base$periodo[idx_uni_sup],
      ocupacao_codigo = base$ocupacao_codigo[idx_uni_sup],
      ocupacao_nome = base$ocupacao_nome[idx_uni_sup],
      ocupacao_nivel_superior = base$ocupacao_nivel_superior[idx_uni_sup],
      peso = base$peso[idx_uni_sup],
      stringsAsFactors = FALSE
    )
    agg_uni <- aggregate(
      cbind(
        peso_universo_superior_completo_classificado_ocupacao = peso,
        registros_universo_superior_completo_classificado_ocupacao = peso * 0 + 1L
      ) ~ Ano + Trimestre + periodo + ocupacao_codigo + ocupacao_nome + ocupacao_nivel_superior,
      data = df_uni,
      FUN = sum
    )
  } else {
    agg_uni <- data.frame(
      Ano = integer(),
      Trimestre = integer(),
      periodo = character(),
      ocupacao_codigo = character(),
      ocupacao_nome = character(),
      ocupacao_nivel_superior = integer(),
      peso_universo_superior_completo_classificado_ocupacao = numeric(),
      registros_universo_superior_completo_classificado_ocupacao = integer(),
      stringsAsFactors = FALSE
    )
  }

  if (any(idx_sob)) {
    df_sob <- data.frame(
      Ano = base$ano[idx_sob],
      Trimestre = base$trimestre[idx_sob],
      periodo = base$periodo[idx_sob],
      ocupacao_codigo = base$ocupacao_codigo[idx_sob],
      ocupacao_nome = base$ocupacao_nome[idx_sob],
      ocupacao_nivel_superior = base$ocupacao_nivel_superior[idx_sob],
      peso = base$peso[idx_sob],
      stringsAsFactors = FALSE
    )
    agg_sob <- aggregate(
      cbind(peso_sobreeducados = peso, registros_sobreeducados = peso * 0 + 1L) ~
        Ano + Trimestre + periodo + ocupacao_codigo + ocupacao_nome + ocupacao_nivel_superior,
      data = df_sob,
      FUN = sum
    )
  } else {
    agg_sob <- data.frame(
      Ano = integer(),
      Trimestre = integer(),
      periodo = character(),
      ocupacao_codigo = character(),
      ocupacao_nome = character(),
      ocupacao_nivel_superior = integer(),
      peso_sobreeducados = numeric(),
      registros_sobreeducados = integer(),
      stringsAsFactors = FALSE
    )
  }

  res <- merge(
    agg_tot_ocup,
    agg_uni,
    by = c("Ano", "Trimestre", "periodo", "ocupacao_codigo", "ocupacao_nome", "ocupacao_nivel_superior"),
    all.x = TRUE
  )
  res <- merge(
    res,
    agg_sob,
    by = c("Ano", "Trimestre", "periodo", "ocupacao_codigo", "ocupacao_nome", "ocupacao_nivel_superior"),
    all.x = TRUE
  )

  num_cols_zero <- c(
    "peso_universo_superior_completo_classificado_ocupacao",
    "registros_universo_superior_completo_classificado_ocupacao",
    "peso_sobreeducados",
    "registros_sobreeducados"
  )
  for (cc in num_cols_zero) {
    res[[cc]][is.na(res[[cc]])] <- 0
  }

  res$percentual_sobreeducados_no_total_ocupados_ocupacao <- round(
    100 * res$peso_sobreeducados / res$peso_total_ocupados_ocupacao,
    4
  )

  res$percentual_sobreeducados_entre_superior_completo_classificado_ocupacao <- ifelse(
    res$peso_universo_superior_completo_classificado_ocupacao > 0,
    round(
      100 * res$peso_sobreeducados / res$peso_universo_superior_completo_classificado_ocupacao,
      4
    ),
    NA_real_
  )

  total_sob_periodo <- aggregate(
    peso_sobreeducados ~ Ano + Trimestre + periodo,
    data = res,
    FUN = sum
  )
  names(total_sob_periodo)[4] <- "peso_sobreeducados_total_periodo"
  res <- merge(res, total_sob_periodo, by = c("Ano", "Trimestre", "periodo"), all.x = TRUE)
  res$participacao_da_ocupacao_no_total_sobreeducados_periodo <- ifelse(
    res$peso_sobreeducados_total_periodo > 0,
    round(100 * res$peso_sobreeducados / res$peso_sobreeducados_total_periodo, 4),
    NA_real_
  )

  res <- res[order(res$Ano, res$Trimestre, -res$peso_sobreeducados, res$ocupacao_codigo), ]
  rownames(res) <- NULL
  res
}

calc_medias_remuneracao_por_grupo <- function(df, group_cols) {
  assert_colunas(df, c("peso", "peso_valido", "ocupacao_informada", "rendimento_habitual_todos_trabalhos", "rendimento_efetivo_todos_trabalhos"))

  idx_base <- df$peso_valido & df$ocupacao_informada
  if (!any(idx_base)) {
    stop("Sem registros validos para medias de remuneracao.")
  }

  d0 <- df[idx_base, c(group_cols, "peso", "rendimento_habitual_todos_trabalhos", "rendimento_efetivo_todos_trabalhos"), drop = FALSE]
  d0$one <- 1L

  agg_base <- aggregate(one ~ ., data = d0[, c(group_cols, "one"), drop = FALSE], FUN = sum)
  names(agg_base)[names(agg_base) == "one"] <- "registros_com_ocupacao_e_peso_valido"

  # Habitual
  dh <- d0[!is.na(d0$rendimento_habitual_todos_trabalhos) & is.finite(d0$rendimento_habitual_todos_trabalhos) & d0$rendimento_habitual_todos_trabalhos > 0, , drop = FALSE]
  if (nrow(dh) > 0) {
    dh$soma_pond_h <- dh$rendimento_habitual_todos_trabalhos * dh$peso
    ah <- aggregate(
      cbind(soma_pond_h, peso_h = peso, registros_com_rendimento_habitual = one) ~ .,
      data = dh[, c(group_cols, "soma_pond_h", "peso", "one"), drop = FALSE],
      FUN = sum
    )
    names(ah)[names(ah) == "peso"] <- "peso_h"
    ah$rendimento_habitual_medio_ponderado <- ah$soma_pond_h / ah$peso_h
  } else {
    ah <- agg_base[, group_cols, drop = FALSE]
    ah$soma_pond_h <- NA_real_
    ah$peso_h <- NA_real_
    ah$registros_com_rendimento_habitual <- 0L
    ah$rendimento_habitual_medio_ponderado <- NA_real_
  }

  # Efetivo
  de <- d0[!is.na(d0$rendimento_efetivo_todos_trabalhos) & is.finite(d0$rendimento_efetivo_todos_trabalhos) & d0$rendimento_efetivo_todos_trabalhos > 0, , drop = FALSE]
  if (nrow(de) > 0) {
    de$soma_pond_e <- de$rendimento_efetivo_todos_trabalhos * de$peso
    ae <- aggregate(
      cbind(soma_pond_e, peso_e = peso, registros_com_rendimento_efetivo = one) ~ .,
      data = de[, c(group_cols, "soma_pond_e", "peso", "one"), drop = FALSE],
      FUN = sum
    )
    names(ae)[names(ae) == "peso"] <- "peso_e"
    ae$rendimento_efetivo_medio_ponderado <- ae$soma_pond_e / ae$peso_e
  } else {
    ae <- agg_base[, group_cols, drop = FALSE]
    ae$soma_pond_e <- NA_real_
    ae$peso_e <- NA_real_
    ae$registros_com_rendimento_efetivo <- 0L
    ae$rendimento_efetivo_medio_ponderado <- NA_real_
  }

  res <- merge(agg_base, ah, by = group_cols, all.x = TRUE)
  res <- merge(res, ae, by = group_cols, all.x = TRUE)

  drop_cols <- intersect(c("soma_pond_h", "peso_h", "soma_pond_e", "peso_e"), names(res))
  if (length(drop_cols) > 0) {
    res <- res[, setdiff(names(res), drop_cols), drop = FALSE]
  }

  res
}

calc_ultimo_periodo_percentual_sobreeducados_ocupacao_e_remuneracao <- function(base) {
  d <- filtrar_ultimo_periodo(base)
  tab_pct <- calc_percentual_sobreeducados_por_ocupacao(d)

  medias <- calc_medias_remuneracao_por_grupo(
    d,
    group_cols = c("ocupacao_codigo", "ocupacao_nome", "ocupacao_nivel_superior")
  )

  res <- merge(
    tab_pct,
    medias,
    by = c("ocupacao_codigo", "ocupacao_nome", "ocupacao_nivel_superior"),
    all.x = TRUE
  )
  res <- res[order(-res$peso_sobreeducados, -res$percentual_sobreeducados_no_total_ocupados_ocupacao, res$ocupacao_codigo), ]
  rownames(res) <- NULL
  res
}

calc_comparacao_salarial_sobreeducados_vs_niveis_instrucao <- function(
  base,
  filtrar_codigos_nivel = NULL,
  apenas_ultimo_periodo = FALSE
) {
  assert_colunas(base, c(
    "ano", "trimestre", "periodo", "sobreeducado",
    "nivel_instrucao_codigo", "nivel_instrucao"
  ))

  d <- base
  if (apenas_ultimo_periodo) {
    d <- filtrar_ultimo_periodo(d)
  }
  if ("ocupacao_classificada" %in% names(d)) {
    d <- d[d$ocupacao_classificada %in% TRUE, , drop = FALSE]
  }

  d_sobre <- d[d$sobreeducado %in% TRUE, , drop = FALSE]
  if (nrow(d_sobre) == 0) {
    stop("Nao ha sobreeducados no recorte selecionado para comparacao salarial.")
  }

  tab_sobre <- calc_medias_remuneracao_por_grupo(
    df = d_sobre,
    group_cols = c("ano", "trimestre", "periodo")
  )

  names_sobre_prefixo <- setdiff(
    names(tab_sobre),
    c("ano", "trimestre", "periodo")
  )
  names(tab_sobre)[match(names_sobre_prefixo, names(tab_sobre))] <- paste0("sobreeducados_", names_sobre_prefixo)

  d_ref <- d[
    !is.na(d$nivel_instrucao_codigo) &
      !is.na(d$nivel_instrucao),
    ,
    drop = FALSE
  ]
  if (!is.null(filtrar_codigos_nivel)) {
    codigos <- trimws(as.character(filtrar_codigos_nivel))
    d_ref <- d_ref[trimws(as.character(d_ref$nivel_instrucao_codigo)) %in% codigos, , drop = FALSE]
  }
  if (nrow(d_ref) == 0) {
    stop("Nao ha grupo(s) de referencia por nivel de instrucao no recorte selecionado.")
  }

  tab_ref <- calc_medias_remuneracao_por_grupo(
    df = d_ref,
    group_cols = c("ano", "trimestre", "periodo", "nivel_instrucao_codigo", "nivel_instrucao")
  )

  names_ref_prefixo <- setdiff(
    names(tab_ref),
    c("ano", "trimestre", "periodo", "nivel_instrucao_codigo", "nivel_instrucao")
  )
  names(tab_ref)[match(names_ref_prefixo, names(tab_ref))] <- paste0("referencia_", names_ref_prefixo)

  res <- merge(
    tab_ref,
    tab_sobre,
    by = c("ano", "trimestre", "periodo"),
    all.x = TRUE
  )

  res$diferenca_absoluta_rendimento_habitual <- res$sobreeducados_rendimento_habitual_medio_ponderado - res$referencia_rendimento_habitual_medio_ponderado
  res$diferenca_absoluta_rendimento_efetivo <- res$sobreeducados_rendimento_efetivo_medio_ponderado - res$referencia_rendimento_efetivo_medio_ponderado

  res$razao_rendimento_habitual_sobreeducados_sobre_referencia <- ifelse(
    !is.na(res$referencia_rendimento_habitual_medio_ponderado) &
      res$referencia_rendimento_habitual_medio_ponderado > 0,
    res$sobreeducados_rendimento_habitual_medio_ponderado / res$referencia_rendimento_habitual_medio_ponderado,
    NA_real_
  )
  res$razao_rendimento_efetivo_sobreeducados_sobre_referencia <- ifelse(
    !is.na(res$referencia_rendimento_efetivo_medio_ponderado) &
      res$referencia_rendimento_efetivo_medio_ponderado > 0,
    res$sobreeducados_rendimento_efetivo_medio_ponderado / res$referencia_rendimento_efetivo_medio_ponderado,
    NA_real_
  )

  res$diferenca_percentual_rendimento_habitual <- ifelse(
    !is.na(res$razao_rendimento_habitual_sobreeducados_sobre_referencia),
    (res$razao_rendimento_habitual_sobreeducados_sobre_referencia - 1) * 100,
    NA_real_
  )
  res$diferenca_percentual_rendimento_efetivo <- ifelse(
    !is.na(res$razao_rendimento_efetivo_sobreeducados_sobre_referencia),
    (res$razao_rendimento_efetivo_sobreeducados_sobre_referencia - 1) * 100,
    NA_real_
  )

  res <- res[order(
    res$ano,
    res$trimestre,
    suppressWarnings(as.integer(res$nivel_instrucao_codigo))
  ), ]
  rownames(res) <- NULL
  res
}
