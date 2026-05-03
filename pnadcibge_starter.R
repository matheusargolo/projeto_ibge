# Download e recorte da PNADc: 2025, 4o trimestre

suppressPackageStartupMessages(library(PNADcIBGE))

message("PNADcIBGE versao: ", as.character(packageVersion("PNADcIBGE")))

dir.create("dados_pnadc", showWarnings = FALSE)
dir.create("saida", showWarnings = FALSE)

vars_desejadas <- c(
  "Ano", "Trimestre", "UF",
  "V1028", "V2007", "V2010", "VD3004", "VD4011", "VD4019"
)

dados_2025_t4 <- get_pnadc(
  year = 2025,
  quarter = 4,
  vars = vars_desejadas,
  labels = TRUE,
  deflator = FALSE,
  design = FALSE,
  reload = FALSE,
  savedir = "dados_pnadc"
)

derivar_regiao_uf <- function(uf) {
  uf_chr <- trimws(as.character(uf))
  uf_upper <- toupper(uf_chr)
  uf_norm <- tolower(iconv(uf_chr, from = "", to = "ASCII//TRANSLIT"))
  uf_num <- suppressWarnings(as.integer(uf_chr))

  regiao <- rep(NA_character_, length(uf_chr))

  regiao[uf_num %in% c(11, 12, 13, 14, 15, 16, 17)] <- "Norte"
  regiao[uf_num %in% c(21, 22, 23, 24, 25, 26, 27, 28, 29)] <- "Nordeste"
  regiao[uf_num %in% c(31, 32, 33, 35)] <- "Sudeste"
  regiao[uf_num %in% c(41, 42, 43)] <- "Sul"
  regiao[uf_num %in% c(50, 51, 52, 53)] <- "Centro-Oeste"

  regiao[uf_upper %in% c("RO", "AC", "AM", "RR", "PA", "AP", "TO")] <- "Norte"
  regiao[uf_upper %in% c("MA", "PI", "CE", "RN", "PB", "PE", "AL", "SE", "BA")] <- "Nordeste"
  regiao[uf_upper %in% c("MG", "ES", "RJ", "SP")] <- "Sudeste"
  regiao[uf_upper %in% c("PR", "SC", "RS")] <- "Sul"
  regiao[uf_upper %in% c("MS", "MT", "GO", "DF")] <- "Centro-Oeste"

  regiao[uf_norm %in% c("rondonia", "acre", "amazonas", "roraima", "para", "amapa", "tocantins")] <- "Norte"
  regiao[uf_norm %in% c("maranhao", "piaui", "ceara", "rio grande do norte", "paraiba", "pernambuco", "alagoas", "sergipe", "bahia")] <- "Nordeste"
  regiao[uf_norm %in% c("minas gerais", "espirito santo", "rio de janeiro", "sao paulo")] <- "Sudeste"
  regiao[uf_norm %in% c("parana", "santa catarina", "rio grande do sul")] <- "Sul"
  regiao[uf_norm %in% c("mato grosso do sul", "mato grosso", "goias", "distrito federal")] <- "Centro-Oeste"

  regiao
}

dados_2025_t4$Regiao_UF <- derivar_regiao_uf(dados_2025_t4$UF)

colunas_saida <- c(
  "Ano", "Trimestre", "UF", "Regiao_UF",
  "V1028", "V2007", "V2010", "VD3004", "VD4011", "VD4019"
)

faltantes <- setdiff(colunas_saida, names(dados_2025_t4))
if (length(faltantes) > 0) {
  warning("Colunas ausentes retornadas pelo download: ", paste(faltantes, collapse = ", "))
  for (col in faltantes) {
    dados_2025_t4[[col]] <- NA
  }
}

recorte <- dados_2025_t4[, colunas_saida]

arquivo_csv <- file.path("saida", "pnadc_2025_t4_recorte.csv")
arquivo_rds <- file.path("saida", "pnadc_2025_t4_recorte.rds")

write.csv(recorte, arquivo_csv, row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(recorte, arquivo_rds)

cat("\nDownload e recorte concluidos com sucesso.\n")
cat("Linhas:", nrow(recorte), " Colunas:", ncol(recorte), "\n")
cat("CSV:", normalizePath(arquivo_csv), "\n")
cat("RDS:", normalizePath(arquivo_rds), "\n\n")
print(utils::head(recorte, 10))
