# ========================================
# Análise de Preços de Veículos - Tabela FIPE
# Modelo: RPART
# ========================================

cat("\n=== Iniciando Análise de Preços de Veículos ===\n\n")

library(rpart)

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

# Converter variáveis categóricas em fatores
dados$Marca <- as.factor(dados$Marca)
dados$Combustivel <- as.factor(dados$Combustivel)
dados$Cambio <- as.factor(dados$Cambio)
dados$Nome <- as.factor(dados$Nome)

cat(sprintf("   ✓ Preço médio: R$ %.2f\n", mean(dados$Preco)))
cat(sprintf("   ✓ Preço min: R$ %.2f | max: R$ %.2f\n", min(dados$Preco), max(dados$Preco))) # nolint

# Selecionar features para o modelo
features <- c(
  "Ano_Modelo", "Nome", "Cilindradas", "Combustivel", "Cambio", "Idade"
)
dados_modelo <- dados[, c(features, "Preco")]

cat("\n   Features selecionadas:\n")
cat("   -", paste(features, collapse = "\n   - "), "\n")

# Dividir dados em treino e teste (70/30)
cat("\n4. Dividindo dados em treino (70%) e teste (30%)...\n")
set.seed(100)
n <- nrow(dados_modelo)
indices_treino <- sample(1:n, size = floor(0.7 * n))

treino <- dados_modelo[indices_treino, ]
teste <- dados_modelo[-indices_treino, ]

cat(sprintf("   ✓ Treino: %d registros\n", nrow(treino)))
cat(sprintf("   ✓ Teste: %d registros\n", nrow(teste)))

# Estrutura para armazenar resultados
resultados <- list()

# ========================================
# MODELO 1: RPART (Árvore de Decisão)
# ========================================
cat("\n5. Treinando Modelo 1: RPART (Árvore de Decisão)...\n")
inicio <- Sys.time()

modelo_rpart <- rpart(Preco ~ .,
  data = treino,
  control = rpart.control(cp = 0)
)

tempo_rpart <- as.numeric(difftime(Sys.time(), inicio, units = "secs"))
cat(sprintf("   ✓ Tempo de treinamento: %.2f segundos\n", tempo_rpart))

pred_rpart <- predict(modelo_rpart, teste)

r_1 <- round(pred_rpart / teste$Preco, 2)
r_1 <- r_1 - 1
r_1 <- abs(r_1)

r_final_1 <- mean(r_1[teste$Preco > 10000 & teste$Preco < 70000])

print(r_final_1)

mae_rpart <- mean(abs(teste$Preco - pred_rpart))
rmse_rpart <- sqrt(mean((teste$Preco - pred_rpart)^2))
r2_rpart <- cor(teste$Preco, pred_rpart)^2
mape_rpart <- mean(abs((teste$Preco - pred_rpart) / teste$Preco)) * 100


cat(sprintf("   ✓ MAE: R$ %.2f\n", mae_rpart))
cat(sprintf("   ✓ RMSE: R$ %.2f\n", rmse_rpart))
cat(sprintf("   ✓ R²: %.4f\n", r2_rpart))
cat(sprintf("   ✓ Erro Percentual Médio: %.2f%%\n", mape_rpart))
cat(sprintf(
  "   ✓ Erro Percentual Médio entre os Veículos de 10000 a 70000: %.2f%%\n", r_final_1 * 100 # nolint
))

resultados$RPART <- list(
  MAE = mae_rpart, RMSE = rmse_rpart, R2 = r2_rpart, MAPE = mape_rpart, Tempo = tempo_rpart # nolint
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
