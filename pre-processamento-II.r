df <- read.csv("./data/fipe.csv", header = TRUE, encoding = "UTF-8")

# Excluindo colunas inúteis
df$X <- NULL
df$price_reference <- NULL

# Alterando o nome das colunas
names(df) <- c("Marca", "Veiculo", "Ano_Modelo", "Combustivel", "Preco")

print(summary(df$Ano_Modelo))

print(summary(df$Ano_Modelo))

# Ajustando a coluna de preço para valores numéricos
df$Preco <- gsub("R\\$ |\\.", "", df$Preco)
df$Preco <- as.numeric(sub(",", ".", df$Preco))

# Reescrevendo o arquivo CSV com as novas alterações
write.table(
  df,
  file = "TabelaFipeTransformada.csv", row.names = FALSE, sep = ",", fileEncoding = "UTF-8" # nolint
)
