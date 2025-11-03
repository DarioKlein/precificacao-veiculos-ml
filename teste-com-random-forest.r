# ========================================
# Análise de Preços de Veículos - Tabela FIPE
# Modelo: RandomForest
# ========================================

cat("\n=== Iniciando Análise de Preços de Veículos ===\n\n")

library(randomForest)

cat("\n")

# Carregar dados
cat("2. Carregando dados da Tabela FIPE...\n")
dados <- read.csv("./data/TabelaFipeTransformadaV2.csv",
  stringsAsFactors = FALSE
)

cat(sprintf("   ✓ Total de registros: %d\n", nrow(dados)))
cat(sprintf("   ✓ Total de colunas: %d\n", ncol(dados)))

# Pré-processamento dos dados
cat("\n3. Pré-processamento dos dados...\n")
cat("   (Tabela FIPE de 2018)\n")

# Criar feature de marca AGRUPADA
freq_marca <- table(dados$Marca)
top_marcas <- names(sort(freq_marca, decreasing = TRUE)[1:50])
dados$Marca_Agrupada <- ifelse(dados$Marca %in% top_marcas, dados$Marca, "Outras_Marcas") # nolint

# Criar feature de nome AGRUPADA
freq_nome <- table(dados$Nome)
top_nomes <- names(sort(freq_nome, decreasing = TRUE)[1:50])
dados$Nome_Agrupado <- ifelse(dados$Nome %in% top_nomes, dados$Nome, "Outros_Modelos") # nolint
dados$Nome_Agrupado <- as.factor(dados$Nome_Agrupado)

# Converter variáveis categóricas em fatores
dados$Marca <- as.factor(dados$Marca)
dados$Combustivel <- as.factor(dados$Combustivel)
dados$Cambio <- as.factor(dados$Cambio)
dados$Nome <- as.factor(dados$Nome)

cat(sprintf("   ✓ Preço médio: R$ %.2f\n", mean(dados$Preco)))
cat(sprintf("   ✓ Preço min: R$ %.2f | max: R$ %.2f\n", min(dados$Preco), max(dados$Preco))) # nolint

# Selecionar features para o modelo
features <- c(
  "Ano_Modelo", "Cilindradas", "Combustivel", "Cambio", "Idade", "Marca_Agrupada", "Nome_Agrupado" # nolint
)
dados_modelo <- dados[, c(features, "Preco")]

cat("\n   Features selecionadas:\n")
cat("   -", paste(features, collapse = "\n   - "), "\n")

# Dividir dados em treino e teste (80/20)
cat("\n4. Dividindo dados em treino (80%) e teste (20%)...\n")
set.seed(100)
n <- nrow(dados_modelo)
indices_treino <- sample(1:n, size = floor(0.8 * n))

treino <- dados_modelo[indices_treino, ]
teste <- dados_modelo[-indices_treino, ]

cat(sprintf("   ✓ Treino: %d registros\n", nrow(treino)))
cat(sprintf("   ✓ Teste: %d registros\n", nrow(teste)))

# Estrutura para armazenar resultados
resultados <- list()

# ========================================
# MODELO 2: Random Forest
# ========================================

cat("\n6. Treinando Modelo 2: Random Forest...\n")
inicio <- Sys.time()

modelo_rf <- randomForest(Preco ~ .,
  data = treino,
  ntree = 100,
  mtry = 5,
  nodesize = 1,
  importance = TRUE
)

tempo_rf <- as.numeric(difftime(Sys.time(), inicio, units = "secs"))
cat(sprintf("   ✓ Tempo de treinamento: %.2f segundos\n", tempo_rf))

pred_rf <- predict(modelo_rf, teste)

r_1 <- round(pred_rf / teste$Preco, 2)
r_1 <- r_1 - 1
r_1 <- abs(r_1)

r_final_1 <- mean(r_1[teste$Preco > 10000 & teste$Preco < 70000])

mae_rf <- mean(abs(teste$Preco - pred_rf))
rmse_rf <- sqrt(mean((teste$Preco - pred_rf)^2))
r2_rf <- cor(teste$Preco, pred_rf)^2
mape_rf <- mean(abs((teste$Preco - pred_rf) / teste$Preco)) * 100

cat(sprintf("   ✓ MAE: R$ %.2f\n", mae_rf))
cat(sprintf("   ✓ RMSE: R$ %.2f\n", rmse_rf))
cat(sprintf("   ✓ R²: %.4f\n", r2_rf))
cat(sprintf("   ✓ Erro Percentual Médio: %.2f%%\n", mape_rf))
cat(sprintf(
  "   ✓ Erro Percentual Médio entre os Veículos de 10000 a 70000: %.2f%%\n", r_final_1 * 100 # nolint
))

resultados$RandomForest <- list(
  MAE = mae_rf, RMSE = rmse_rf, R2 = r2_rf, MAPE = mape_rf, Tempo = tempo_rf
)

cat("\n========================================\n")
cat("RESULTADO FINAL DO MODELO\n")
cat("========================================\n\n")

# Criar dataframe de comparação
if (length(resultados) > 0) {
  comparacao <- data.frame(
    Modelo = names(resultados),
    MAE = sapply(resultados, function(x) x$MAE),
    RMSE = sapply(resultados, function(x) x$RMSE),
    R2 = sapply(resultados, function(x) x$R2),
    Erro_Perc = sapply(resultados, function(x) x$MAPE),
    Tempo_s = sapply(resultados, function(x) x$Tempo)
  )

  rownames(comparacao) <- NULL
  comparacao <- comparacao[order(-comparacao$R2), ]

  print(comparacao)

  cat("Análise dos Resultados:\n")

  cat(sprintf("\n%d. %s:\n", 1, comparacao$Modelo[1]))
  cat(sprintf(
    "   - Erro médio de previsão: R$ %.2f (%.1f%% do valor real)\n", comparacao$MAE[1], comparacao$Erro_Perc[1] # nolint
  ))
  cat(sprintf(
    "   - Explica %.1f%% da variação dos preços\n", comparacao$R2[1] * 100
  ))
  cat(sprintf(
    "   - Tempo de treinamento: %.2f segundos\n", comparacao$Tempo_s[1]
  ))
  cat("\n========================================\n")
  cat("Análise concluída com sucesso!\n")
  cat("========================================\n")
} else {
  cat("ERRO: Nenhum modelo foi treinado com sucesso.\n")
}
