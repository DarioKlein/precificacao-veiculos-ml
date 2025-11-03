df <- read.csv("./data/TabelaFipeTransformada.csv", header = TRUE, encoding = "UTF-8") #nolint

library(stringr)

# Criando uma nova coluna de cilindradas
df$Cilindradas <- str_extract(df$Veiculo, "[0-9]\\.[0-9]")
str(df$Cilindradas)
df$Cilindradas <- as.factor(df$Cilindradas)

library(dplyr)

filtered <- df %>%
  filter(is.na(df$Cilindradas)) %>%
  select(Veiculo) %>%
  distinct(Veiculo)

# Criando uma nova coluna de Cambio
aut <- subset(df, str_detect(df$Veiculo, " Aut\\."), "Veiculo")
aut <- unique(aut)
aut$Cambio <- "Aut"

df <- left_join(df, aut)
df$Cambio[is.na(df$Cambio)] <- "Mec"

library(tidyr)

# Separando as informações adjacentes do nome do veículo
df <- separate(df, "Veiculo", into = "Nome", sep = " ", remove = FALSE)
df$Nome <- as.factor(df$Nome)

# Omitindo os dados faltantes
df <- na.omit(df)

# Converter Ano_Modelo para numérico (tratar "Zero KM" como 2018)
df$Ano_Modelo <- ifelse(
  df$Ano_Modelo == "Zero KM", 2018, as.numeric(df$Ano_Modelo)
)

# Criar feature de idade do veículo (idade em 2018)
df$Idade <- 2018 - df$Ano_Modelo

write.table(
  df,
  file = "TabelaFipeTransformadaV2.csv", row.names = FALSE, sep = ",", fileEncoding = "UTF-8" # nolint
)
