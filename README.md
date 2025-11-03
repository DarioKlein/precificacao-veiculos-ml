# Projeto: Previsão de Preços de Veículos - Tabela FIPE

## Objetivo

Criar um algoritmo de machine learning capaz de prever preços de veículos **com base na tabela FIPE**.

## Status Atual

🟡 **Progresso Parcial** - Conseguimos bons resultados, porém ainda longe do ideal que seria em torno de 95% de acurácia.

## Dados

- **Fonte**: https://www.kaggle.com/datasets/sandey/brazilian-vehicle-prices-june-2018-fipe
- **Registros**: 21.797 veículos
- **Features originais**: Marca, Veículo, Ano_Modelo, Preço de Referência, Preço do Veículo.

## Resultados Obtidos

### Modelo Original - Início - Sem Pré-processamento

- Erro médio - Rpart: **18-24%**
- Erro médio - RandomForest: **32-41%**
- Erro médio - SVM: **39-44%**

### Modelo Melhorado - Avanço Parcial - Com Pré-processamento

- Erro médio - Rpart: **11.26-12.92%** ✅ Melhoria de ~12%!
- Tempo de execução: 0.31 Segundos

- Erro médio - RandomForest: **12.38-14.66%** ✅ Melhoria de ~27%!
- Tempo de execução:

- Erro médio - SVM: **12.29-14.05%** ✅ Melhoria de ~12%!
- Tempo de execução: 268.78 Segundos

## Features Engineering Implementadas

1. **Idade do veículo** (Calculada a partir do ano)
2. **Categorias de idade** (O ano de 2018 - O ano do veículo)
3. **Encoding de marcas** (Top 30-40 marcas, resto agrupado)
4. **Encoding de Nomes/Modelos** (Top 30-40 Nomes/Modelos, resto agrupado)
5. **Preço por cilindrada** (Eficiência do motor)
6. **Ano numérico** (Em vez de categórico)
7. **Câmbio** (Manual ou Automático)

### 🔸 Features Específicas para o SVM

8. **Cilindradas² (`Cilindradas_Quad`)** — Captura efeitos não lineares da cilindrada.
9. **Interação Idade × Cilindrada (`Idade_x_Cilindradas`)** — Permite modelar a relação entre potência e depreciação.
10. **Depreciação exponencial (`Deprec_Exp`)** — simula a desvalorização acelerada com o tempo.
11. **Categorias de cilindrada (`Cat_Cilindradas`)** — divide motores em faixas (_Pequeno_, _Médio_, _Grande_, etc.).
12. **Flag Diesel (`Flag_Diesel`)** — identifica veículos com combustível _Diesel_.
13. **Flag Automático (`Flag_Auto`)** — identifica veículos com câmbio _Automático_.

## Arquivos do Projeto

- `pre-processamento-I.r` - Primeira parte do pré-processamento realizado
- `pre-processamento-II.r` - Segunda parte do pré-processamento realizado
- `teste-com-random-forest.r` - Implementação da predição com o Modelo RandomForest
- `teste-com-rpart.r` - Implementação da predição com o Modelo Rpart (Árvores de Decisão)
- `teste-com-svm.r` - Implementação da predição com o Modelo Support Vector Machine (SVM)
- `fipe.csv` - Base de dados FIPE - Original
- `TabelaFipeTransformada.csv` - Base de dados FIPE parcialmente pré-processada
- `TabelaFipeTransformadaV2.csv` - Base de dados FIPE - Finalizada

## Limitações Identificadas

### Por que não alcançamos um resultado melhor, ou ao menos inferior a 10% em TODAS as previsões?

1. **Dados limitados**:

   - Faltam features importantes: **quilometragem**, **estado de conservação**, **região/cidade**
   - Veículos raros e outliers têm pouco dados para treinamento

2. **Modelos usados**:

   - Os modelos utilizados são bons, mas as versões utilizadas são limitadas.
   - Algoritmos mais sofisticados (Ranger, XGBoost, LightGBM, CatBoost) provavelmente teriam melhor desempenho

3. **Problema de conversão**:

   - Imputação de valores faltantes usa média global (não ideal)

4. **Sem otimização sistemática**:
   - Hiperparâmetros escolhidos manualmente
   - Grid Search ou validação cruzada provavelmente melhoraria os resultados

## Próximos Passos para Alcançar ≤5% de Erro

### Curto Prazo (podem ser feitos agora)

2. ✅ Implementar XGBoost ou LightGBM
3. ✅ Otimização de hiperparâmetros com grid search
4. ✅ Modelos específicos por segmento (popular, médio, luxo)

### Médio Prazo (requer mais dados)

5. 🔴 Adicionar quilometragem (não disponível na FIPE)
6. 🔴 Adicionar estado de conservação (não disponível na FIPE)
7. 🔴 Adicionar localização/região (não disponível na FIPE)
8. 🔴 Adicionar dados de mercado real (anúncios, vendas)

## 🏆 Melhor Algoritmo

Após os testes e comparações entre diferentes modelos de Machine Learning citados neste trabalho, o modelo que apresentou **melhor desempenho geral** foi o:

### 🎯 **RPART (Recursive PARTitioning and Regression Trees)**

#### 🔹 Motivos da Escolha:

- **Melhor performance em termos de erro médio (MAE/RMSE)** nas previsões
- **Modelo simples e objetivo** utilizou a menor quantidade de variáveis e conseguiu ter o melhor desempenho
- **Generalização superior** em relação a outros modelos, evitando overfitting
- **O modelo mais rápido que foi testado** em relação a outros modelos, que são bem mais lentos

## Conclusão

**Alcançamos melhorias substanciais** (de ~32% para ~12.5% de erro médio), mas para chegar a **erro ≤ 5% em TODAS as previsões** precisaríamos:

- **Mais features** (dados que a tabela FIPE não fornece)
- **Algoritmos mais sofisticados** (XGBoost, Deep Learning)
- **Modelos especializados** por segmento de mercado

A tabela FIPE, por si só, tem limitações porque fornece apenas preços tabelados médios, sem considerar fatores como estado do veículo, quilometragem, e variações regionais.

## Recomendação

Para uso prático:

- ✅ O modelo atual é **muito bom para estimativas rápidas**
- ✅ **~85% das previsões têm erro ≤ 10%** (aceitável para muitos casos)
- ⚠️ Para decisões críticas, considerar margem de erro de ~10-15%
- 🎯 Para alcançar ≤5% consistentemente, seria necessário dados adicionais além da FIPE

---

_Última atualização: 02/11/2025_
