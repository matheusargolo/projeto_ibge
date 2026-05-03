cat("Ambiente R OK\n")
cat(R.version.string, "\n")

# Exemplo simples no estilo de analise de dados
municipios <- data.frame(
  nome = c("Sao Paulo", "Rio de Janeiro", "Belo Horizonte"),
  populacao = c(11451999, 6211223, 2315560)
)

municipios$pop_milhoes <- round(municipios$populacao / 1e6, 2)
print(municipios)
