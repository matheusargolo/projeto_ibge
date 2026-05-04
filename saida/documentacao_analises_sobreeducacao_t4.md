# Documentacao da execucao das analises de sobreeducacao (T4)

- Gerado em: 2026-05-03 21:54:17 -0300
- Escopo: periodos disponiveis localmente (atualmente T4 por ano).
- Peso amostral: V1028 (peso valido > 0).
- Definicao de sobreeducado: superior completo (VD3004=7) em ocupacao classificada como nao exigente de nivel superior.
- Classificacao de ocupacoes: saida/ocupacoes_cod2010_classificadas.csv.
- Remuneracao: foram calculadas duas metricas em paralelo:
  - VD4019: rendimento habitual em todos os trabalhos.
  - VD4020: rendimento efetivo em todos os trabalhos.
- Filtro de remuneracao para medias: apenas rendimentos positivos (>0), com ocupacao informada e peso valido.

## Log de execucao

- processa_percentual_sobreeducados_por_uf.R | status=OK | duracao_segundos=14.831
- processa_percentual_sobreeducados_por_regiao.R | status=OK | duracao_segundos=8.613
- processa_percentual_sobreeducados_por_raca_cor.R | status=OK | duracao_segundos=8.249
- processa_percentual_sobreeducados_por_sexo.R | status=OK | duracao_segundos=8.291
- processa_percentual_sobreeducados_por_ocupacao_ano_trimestre.R | status=OK | duracao_segundos=10.612
- processa_ultimo_periodo_percentual_sobreeducados_por_ocupacao_e_remuneracao.R | status=OK | duracao_segundos=8.442
- processa_ultimo_periodo_remuneracao_media_por_nivel_instrucao.R | status=OK | duracao_segundos=8.209
- processa_ultimo_periodo_remuneracao_media_por_uf.R | status=OK | duracao_segundos=8.209
- processa_ultimo_periodo_remuneracao_media_por_regiao.R | status=OK | duracao_segundos=8.017
- processa_ultimo_periodo_remuneracao_media_por_raca_cor.R | status=OK | duracao_segundos=8.106
- processa_ultimo_periodo_remuneracao_media_por_sexo.R | status=OK | duracao_segundos=8.142
- processa_ultimo_periodo_remuneracao_media_sobreeducados_nao_sobreeducados_e_superior.R | status=OK | duracao_segundos=7.976
- processa_ultimo_periodo_comparacao_salarial_sobreeducados_vs_niveis_instrucao.R | status=OK | duracao_segundos=8.876
- processa_serie_comparacao_salarial_sobreeducados_vs_niveis_instrucao.R | status=OK | duracao_segundos=15.181
- processa_ultimo_periodo_remuneracao_media_por_tipo_ocupacao_classificada.R | status=OK | duracao_segundos=8.127
