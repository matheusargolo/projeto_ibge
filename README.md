# Projeto IBGE - PNAD Contínua e sobreeducação

## Visão geral
Este repositório reúne scripts em R para:
- baixar microdados da PNAD Contínua;
- consolidar uma base local a partir dos microdados brutos trimestrais;
- calcular distribuição de nível de instrução;
- medir sobreeducação ao longo do tempo;
- comparar remuneração entre grupos, com foco em sobreeducados.

A definição de sobreeducação adotada é: pessoa com **superior completo** em ocupação classificada como **não exigente de nível superior** (`nivel_superior = 0`).

Na classificação de ocupações (`saida/ocupacoes_cod2010_classificadas.csv`), a coluna `nivel_superior` aceita três valores:
- `0`: ocupação classificada como não exigente de nível superior;
- `1`: ocupação classificada como exigente de nível superior;
- `2`: ocupação ambígua. Esses registros são excluídos das análises de sobreeducação, mas não afetam análises que contam nível de instrução sem usar ocupação.

## O que há no repositório

### Pastas principais
- `dados_pnadc/`: microdados brutos, dicionários e arquivos auxiliares da PNAD Contínua.
- `saida/`: resultados das análises (CSV/JSON), além de logs e documentação de execução.
- `.vscode/`: configurações do editor.

### Arquivos principais
- `utils_analises_sobreeducacao.R`: funções utilitárias compartilhadas (carregamento de base, cálculos e exportação).
- `executa_todas_analises_pnadc.R`: executor em lote das análises sobre todos os microdados trimestrais disponíveis localmente.
- `executa_lote_analises_sobreeducacao_t4.R`: executor legado das análises de sobreeducação.
- `README.md`: documentação do projeto.
- `.gitignore`: regras de versionamento.

## Pré-requisitos
- R instalado (o projeto foi executado com R 4.5.x).
- Pacote `PNADcIBGE`.
- Pacote `jsonlite`.

## O que cada script faz (resumo)

| Script | Função resumida |
|---|---|
| `baixar_pnadc_bruto_periodo.R` | Baixa microdados brutos da PNAD Contínua por intervalo de anos e trimestres (parametrizável). |
| `executa_todas_analises_pnadc.R` | Executa todas as análises usando os microdados locais `dados_pnadc/PNADC_0TAAAA.txt` e reescreve as saídas CSV/JSON. |
| `pnadcibge_starter.R` | Exemplo legado de uso do pacote `PNADcIBGE`; não é usado no pipeline atual. |
| `processa_sobreeducacao_brasil_por_ano_trimestre.R` | Calcula número ponderado de sobreeducados no Brasil por ano/trimestre e a taxa entre pessoas com superior completo. |
| `processa_nivel_instrucao_brasil.R` | Calcula a distribuição percentual ponderada do nível de instrução no Brasil por período. |
| `processa_nivel_instrucao_por_uf.R` | Calcula a distribuição percentual ponderada do nível de instrução por UF e período. |
| `processa_nivel_instrucao_por_regiao.R` | Calcula a distribuição percentual ponderada do nível de instrução por região e período. |
| `processa_nivel_instrucao_por_raca_cor.R` | Calcula a distribuição percentual ponderada do nível de instrução por cor/raça e período. |
| `processa_nivel_instrucao_por_sexo.R` | Calcula a distribuição percentual ponderada do nível de instrução por sexo e período. |
| `processa_participacao_superior_completo_por_uf.R` | Mede a participação de pessoas com superior completo por UF (com pesos), ao longo do tempo. |
| `processa_participacao_superior_completo_por_regiao.R` | Mede a participação de pessoas com superior completo por região (com pesos), ao longo do tempo. |
| `processa_participacao_superior_completo_por_raca_cor.R` | Mede a participação de pessoas com superior completo por cor/raça (com pesos), ao longo do tempo. |
| `processa_participacao_superior_completo_por_sexo.R` | Mede a participação de pessoas com superior completo por sexo (com pesos), ao longo do tempo. |
| `processa_percentual_sobreeducados_por_uf.R` | Calcula o percentual de sobreeducados por UF e período. |
| `processa_percentual_sobreeducados_por_regiao.R` | Calcula o percentual de sobreeducados por região e período. |
| `processa_percentual_sobreeducados_por_raca_cor.R` | Calcula o percentual de sobreeducados por cor/raça e período. |
| `processa_percentual_sobreeducados_por_sexo.R` | Calcula o percentual de sobreeducados por sexo e período. |
| `processa_percentual_sobreeducados_por_ocupacao_ano_trimestre.R` | Calcula o percentual de sobreeducados por ocupação ao longo do tempo. |
| `processa_ultimo_periodo_percentual_sobreeducados_por_ocupacao_e_remuneracao.R` | Para o último período disponível, junta percentual de sobreeducação por ocupação com remuneração média. |
| `processa_ultimo_periodo_remuneracao_media_por_nivel_instrucao.R` | Calcula remuneração média ponderada (habitual e efetiva) por nível de instrução no último período. |
| `processa_ultimo_periodo_remuneracao_media_por_uf.R` | Calcula remuneração média ponderada por UF no último período. |
| `processa_ultimo_periodo_remuneracao_media_por_regiao.R` | Calcula remuneração média ponderada por região no último período. |
| `processa_ultimo_periodo_remuneracao_media_por_raca_cor.R` | Calcula remuneração média ponderada por cor/raça no último período. |
| `processa_ultimo_periodo_remuneracao_media_por_sexo.R` | Calcula remuneração média ponderada por sexo no último período. |
| `processa_ultimo_periodo_remuneracao_media_sobreeducados_nao_sobreeducados_e_superior.R` | Compara remuneração média de sobreeducados, não sobreeducados (superior) e superior completo em ocupações classificadas como `0` ou `1` no último período. |
| `processa_ultimo_periodo_remuneracao_media_por_tipo_ocupacao_classificada.R` | Compara remuneração média entre ocupações classificadas como exigentes e não exigentes de nível superior. |
| `processa_ultimo_periodo_comparacao_salarial_sobreeducados_vs_niveis_instrucao.R` | Compara salários de sobreeducados com todos os níveis de instrução no último período, incluindo recorte focal (médio completo e superior incompleto). |
| `processa_serie_comparacao_salarial_sobreeducados_vs_niveis_instrucao.R` | Gera série histórica da comparação salarial entre sobreeducados e níveis de instrução por ano/trimestre. |
| `executa_lote_analises_sobreeducacao_t4.R` | Executa, em sequência, os principais scripts de sobreeducação e gera log/documentação da execução. |
| `teste_ibge.R` | Script mínimo de teste do ambiente R. |

Nas comparações salariais envolvendo sobreeducados, os grupos de referência por nível de instrução também ficam restritos a ocupações classificadas como `0` ou `1`.

## Saídas geradas
As saídas ficam na pasta `saida/`, em geral em dois formatos:
- CSV (tabelas para inspeção e uso em planilhas);
- JSON (tabelas + metadados metodológicos).

Também são gerados:
- `saida/log_execucao_todas_analises_pnadc.csv`;
- `saida/status_execucao_todas_analises_pnadc.csv`.

## Execução sugerida
1. Rodar o download bruto (quando necessário): `baixar_pnadc_bruto_periodo.R`.
2. Garantir a classificação de ocupações em `saida/ocupacoes_cod2010_classificadas.csv`.
3. Rodar os scripts analíticos individualmente ou em lote com `executa_todas_analises_pnadc.R`.

O pipeline atual não depende dos antigos arquivos `saida/pnadc_*_recorte.rds`; esses recortes foram removidos por serem um artefato legado restrito a T4.
