# Download bruto da PNADc com periodo e trimestre parametrizaveis.
#
# Uso padrao: edite os parametros abaixo e rode o script.
# Uso opcional por linha de comando:
# Rscript baixar_pnadc_bruto_periodo.R --ano_inicio=2012 --ano_fim=2024 --trimestres=1,4

suppressPackageStartupMessages(library(PNADcIBGE))

# -------------------------
# Parametros do usuario
# -------------------------
ano_inicio <- 2012
ano_fim <- 2024
trimestres <- c(4)
savedir <- "dados_pnadc"
forcar_redownload <- FALSE
# -------------------------

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  for (arg in args) {
    if (!grepl("^--", arg) || !grepl("=", arg)) {
      next
    }
    chave <- sub("^--", "", sub("=.*$", "", arg))
    chave <- gsub("-", "_", chave)
    valor <- sub("^[^=]*=", "", arg)

    if (chave == "ano_inicio") {
      ano_inicio <- suppressWarnings(as.integer(valor))
    } else if (chave == "ano_fim") {
      ano_fim <- suppressWarnings(as.integer(valor))
    } else if (chave == "trimestres") {
      trimestres <- suppressWarnings(as.integer(strsplit(valor, ",")[[1]]))
    } else if (chave == "savedir") {
      savedir <- valor
    } else if (chave == "forcar_redownload") {
      valor_lower <- tolower(trimws(valor))
      forcar_redownload <- valor_lower %in% c("1", "true", "t", "sim", "s", "yes", "y")
    }
  }
}

if (is.na(ano_inicio) || is.na(ano_fim)) {
  stop("ano_inicio e ano_fim devem ser inteiros validos.")
}
if (ano_inicio > ano_fim) {
  stop("ano_inicio nao pode ser maior que ano_fim.")
}

trimestres <- sort(unique(trimestres))
if (length(trimestres) == 0 || any(is.na(trimestres)) || any(!trimestres %in% 1:4)) {
  stop("trimestres deve conter valores entre 1 e 4. Exemplo: c(1, 4)")
}

anos_alvo <- ano_inicio:ano_fim

dir.create(savedir, showWarnings = FALSE, recursive = TRUE)
dir.create("saida", showWarnings = FALSE)

message("PNADcIBGE versao: ", as.character(packageVersion("PNADcIBGE")))
cat("Parametros efetivos:\n")
cat("- ano_inicio:", ano_inicio, "\n")
cat("- ano_fim:", ano_fim, "\n")
cat("- trimestres:", paste(trimestres, collapse = ","), "\n")
cat("- savedir:", normalizePath(savedir, winslash = "/", mustWork = FALSE), "\n")
cat("- forcar_redownload:", forcar_redownload, "\n")

descobrir_zip <- function(ano, trimestre, pasta) {
  padrao <- file.path(pasta, sprintf("PNADC_0%d%d*.zip", trimestre, ano))
  zips <- sort(Sys.glob(padrao))
  if (length(zips) == 0) {
    return(NA_character_)
  }
  zips[1]
}

garantir_zip_canonico <- function(ano, trimestre, pasta) {
  zip_canonico <- file.path(pasta, sprintf("PNADC_0%d%d.zip", trimestre, ano))
  if (file.exists(zip_canonico)) {
    return(zip_canonico)
  }

  zips <- sort(Sys.glob(file.path(pasta, sprintf("PNADC_0%d%d_*.zip", trimestre, ano))))
  if (length(zips) != 1) {
    return(NA_character_)
  }

  ok_link <- suppressWarnings(file.link(zips[1], zip_canonico))
  if (!isTRUE(ok_link)) {
    ok_copy <- suppressWarnings(file.copy(zips[1], zip_canonico))
    if (!isTRUE(ok_copy)) {
      return(NA_character_)
    }
  }

  zip_canonico
}

resumo <- data.frame(
  ano = integer(),
  trimestre = integer(),
  status = character(),
  zip = character(),
  txt = character(),
  mensagem = character(),
  stringsAsFactors = FALSE
)

for (ano in anos_alvo) {
  for (trimestre in trimestres) {
    cat("\n==========\nAno", ano, "- T", trimestre, "\n==========\n")

    txt_path <- file.path(savedir, sprintf("PNADC_0%d%d.txt", trimestre, ano))
    zip_antes <- !is.na(descobrir_zip(ano, trimestre, savedir))
    txt_antes <- file.exists(txt_path)

    cat("Antes da execucao: zip=", zip_antes, " txt=", txt_antes, "\n", sep = "")

    if (zip_antes && txt_antes && !forcar_redownload) {
      garantir_zip_canonico(ano, trimestre, savedir)
      cat("Ja existente. Pulando download.\n")

      resumo <- rbind(
        resumo,
        data.frame(
          ano = ano,
          trimestre = trimestre,
          status = "SKIP",
          zip = "sim",
          txt = "sim",
          mensagem = "arquivos ja existiam",
          stringsAsFactors = FALSE
        )
      )
      next
    }

    dados <- tryCatch(
      get_pnadc(
        year = ano,
        quarter = trimestre,
        vars = c("Ano"),
        labels = FALSE,
        deflator = FALSE,
        design = FALSE,
        reload = forcar_redownload,
        savedir = savedir
      ),
      error = function(e) e
    )

    if (inherits(dados, "error")) {
      mensagem_erro <- conditionMessage(dados)
      cat("ERRO:", mensagem_erro, "\n")

      resumo <- rbind(
        resumo,
        data.frame(
          ano = ano,
          trimestre = trimestre,
          status = "ERRO",
          zip = ifelse(!is.na(descobrir_zip(ano, trimestre, savedir)), "sim", "nao"),
          txt = ifelse(file.exists(txt_path), "sim", "nao"),
          mensagem = mensagem_erro,
          stringsAsFactors = FALSE
        )
      )
      next
    }

    rm(dados)
    invisible(gc())

    garantir_zip_canonico(ano, trimestre, savedir)
    zip_ok <- !is.na(descobrir_zip(ano, trimestre, savedir))
    txt_ok <- file.exists(txt_path)
    status <- if (zip_ok && txt_ok) "OK" else "PARCIAL"

    cat("Concluido: zip=", zip_ok, " txt=", txt_ok, "\n", sep = "")

    resumo <- rbind(
      resumo,
      data.frame(
        ano = ano,
        trimestre = trimestre,
        status = status,
        zip = ifelse(zip_ok, "sim", "nao"),
        txt = ifelse(txt_ok, "sim", "nao"),
        mensagem = "",
        stringsAsFactors = FALSE
      )
    )
  }
}

arquivo_resumo <- file.path(
  "saida",
  sprintf(
    "resumo_download_pnadc_bruto_%d_%d_t%s.csv",
    ano_inicio,
    ano_fim,
    paste(trimestres, collapse = "-")
  )
)
write.csv(resumo, arquivo_resumo, row.names = FALSE, fileEncoding = "UTF-8")

cat("\nResumo salvo em:", normalizePath(arquivo_resumo), "\n\n")
print(resumo, row.names = FALSE)
