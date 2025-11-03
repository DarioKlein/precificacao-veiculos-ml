# ========================================
# Análise de Preços de Veículos - Tabela FIPE
# Modelo: SVM
# ========================================

cat("\n=== Iniciando Análise de Preços de Veículos ===\n\n")

library(e1071)

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

# Criar feature de marca AGRUPADA (se for usar o pacote randomForest padrao)
freq_marca <- table(dados$Marca)
top_marcas <- names(sort(freq_marca, decreasing = TRUE)[1:25])
dados$Marca_Agrupada <- ifelse(dados$Marca %in% top_marcas, dados$Marca, "Outras_Marcas") # nolint

# Converter variáveis categóricas em fatores
dados$Combustivel <- as.factor(dados$Combustivel)
dados$Cambio <- as.factor(dados$Cambio)
dados$Marca_Agrupada <- as.factor(dados$Marca_Agrupada)

# Criar feature de idade do veículo (idade em 2018)
dados$Idade <- 2018 - dados$Ano_Modelo

# Features avançadas
dados$Cilindradas_Quad <- dados$Cilindradas^2
dados$Idade_x_Cilindradas <- dados$Idade * dados$Cilindradas
dados$Deprec_Exp <- exp(-dados$Idade / 10)
dados$Cat_Idade <- cut(dados$Idade,
  breaks = c(-Inf, 3, 7, 12, 20, Inf),
  labels = c("Novo", "SemiNovo", "Usado", "Antigo", "Classico")
)
dados$Cat_Cilindradas <- cut(dados$Cilindradas,
  breaks = c(0, 1.2, 1.8, 2.5, 4.0, Inf),
  labels = c("Pequeno", "Medio", "Grande", "MuitoGrande", "Performance")
)
dados$Flag_Diesel <- ifelse(dados$Combustivel == "Diesel", 1, 0)
dados$Flag_Auto <- ifelse(dados$Cambio == "Aut", 1, 0)

# TRANSFORMAÇÃO LOGARÍTMICA DO PREÇO
dados$Log_Preco <- log(dados$Preco + 1)

cat(sprintf("   ✓ Preço médio: R$ %.2f\n", mean(dados$Preco)))
cat(sprintf("   ✓ Preço min: R$ %.2f | max: R$ %.2f\n", min(dados$Preco), max(dados$Preco))) # nolint

# Selecionar features para o modelo
features <- c(
  "Ano_Modelo", "Cilindradas", "Cilindradas_Quad", "Combustivel", "Cambio",
  "Idade", "Idade_x_Cilindradas", "Deprec_Exp", "Cat_Idade", "Cat_Cilindradas",
  "Flag_Diesel", "Flag_Auto", "Marca_Agrupada"
)
dados_modelo <- dados[, c(features, "Log_Preco", "Preco")]
dados_modelo <- na.omit(dados_modelo)

cat("\n   Features selecionadas:\n")
cat("   -", paste(features, collapse = "\n   - "), "\n")

# Dividir dados em treino e teste (70/30)
cat("\n4. Dividindo dados em treino (70%) e teste (30%)...\n")
set.seed(100)
n <- nrow(dados_modelo)
indices_treino <- sample(1:n, size = floor(0.70 * n))

treino <- dados_modelo[indices_treino, ]
teste <- dados_modelo[-indices_treino, ]

cat(sprintf("   ✓ Treino: %d registros\n", nrow(treino)))
cat(sprintf("   ✓ Teste: %d registros\n", nrow(teste)))

# NORMALIZAÇÃO DOS DADOS NUMÉRICOS
cat("\n5. Normalizando dados numéricos...\n")
colunas_numericas <- c(
  "Ano_Modelo", "Cilindradas", "Cilindradas_Quad",
  "Idade", "Idade_x_Cilindradas", "Deprec_Exp",
  "Flag_Diesel", "Flag_Auto"
)

medias <- sapply(treino[colunas_numericas], mean)
desvios <- sapply(treino[colunas_numericas], sd)

for (col in colunas_numericas) {
  treino[[col]] <- (treino[[col]] - medias[col]) / (desvios[col] + 1e-8)
  teste[[col]] <- (teste[[col]] - medias[col]) / (desvios[col] + 1e-8)
}
cat("   ✓ Normalização concluída!\n")

# Estrutura para armazenar resultados
resultados <- list()

# ========================================
# MODELO 3: SVM (Support Vector Machine)
# ========================================

cat("\n7. Treinando Modelo 3: SVM...\n")
inicio <- Sys.time()

set.seed(100)

cat(sprintf(
  "   (Usando parâmetros otimizados e transformação logarítmica)\n"
))

# Treinar com parâmetros ótimos
modelo_svm <- svm(
  Log_Preco ~ . - Preco,
  data = treino,
  type = "eps-regression",
  kernel = "radial",
  cost = 500,
  gamma = 0.05,
  epsilon = 0.1
)

tempo_svm <- as.numeric(difftime(Sys.time(), inicio, units = "secs"))
cat(sprintf("   ✓ Tempo de treinamento: %.2f segundos\n", tempo_svm))

# Predições (converter de log para preço real)
pred_log <- predict(modelo_svm, teste)
pred_svm <- exp(pred_log) - 1
pred_svm <- pmax(pred_svm, 0)

r_1 <- round(pred_svm / teste$Preco, 2)
r_1 <- r_1 - 1
r_1 <- abs(r_1)

r_final_1 <- mean(r_1[teste$Preco > 10000 & teste$Preco < 70000])

mae_svm <- mean(abs(teste$Preco - pred_svm))
rmse_svm <- sqrt(mean((teste$Preco - pred_svm)^2))
r2_svm <- cor(teste$Preco, pred_svm)^2
mape_svm <- mean(abs((teste$Preco - pred_svm) / teste$Preco)) * 100

cat(sprintf("   ✓ MAE: R$ %.2f\n", mae_svm))
cat(sprintf("   ✓ RMSE: R$ %.2f\n", rmse_svm))
cat(sprintf("   ✓ R²: %.4f\n", r2_svm))
cat(sprintf("   ✓ Erro Percentual Médio: %.2f%%\n", mape_svm))
cat(sprintf(
  "   ✓ Erro Percentual Médio entre os Veículos de 10000 a 70000: %.2f%%\n", r_final_1 * 100 # nolint
))

resultados$SVM <- list(
  MAE = mae_svm, RMSE = rmse_svm, R2 = r2_svm, MAPE = mape_svm, Tempo = tempo_svm # nolint
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

  # Análise adicional
  cat("\n   Distribuição dos erros:\n")
  erros_percentuais <- abs((teste$Preco - pred_svm) / teste$Preco) * 100
  cat(sprintf(
    "   - Predições com erro < 15%%: %.1f%%\n",
    sum(erros_percentuais < 15) / length(erros_percentuais) * 100
  ))
  cat(sprintf(
    "   - Predições com erro < 20%%: %.1f%%\n",
    sum(erros_percentuais < 20) / length(erros_percentuais) * 100
  ))
  cat(sprintf(
    "   - Predições com erro < 30%%: %.1f%%\n",
    sum(erros_percentuais < 30) / length(erros_percentuais) * 100
  ))
  cat(sprintf("   - Mediana do erro: %.1f%%\n", median(erros_percentuais)))

  cat("\n========================================\n")
  cat("Análise concluída com sucesso!\n")
  cat("========================================\n")
} else {
  cat("ERRO: Nenhum modelo foi treinado com sucesso.\n")
}
