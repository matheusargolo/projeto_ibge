# Documentacao da execucao das analises de sobreeducacao (T4)

- Gerado em: 2026-05-03 17:51:44 -0300
- Escopo: periodos disponiveis localmente (atualmente T4 por ano).
- Peso amostral: V1028 (peso valido > 0).
- Definicao de sobreeducado: superior completo (VD3004=7) em ocupacao classificada como nao exigente de nivel superior.
- Classificacao de ocupacoes: saida/ocupacoes_cod2010_classificadas.csv.
- Remuneracao: foram calculadas duas metricas em paralelo:
  - VD4019: rendimento habitual em todos os trabalhos.
  - VD4020: rendimento efetivo em todos os trabalhos.
- Filtro de remuneracao para medias: apenas rendimentos positivos (>0), com ocupacao informada e peso valido.

## Log de execucao

- processa_percentual_sobreeducados_por_uf.R | status=OK | duracao_segundos=19.666
- processa_percentual_sobreeducados_por_regiao.R | status=OK | duracao_segundos=9.359
- processa_percentual_sobreeducados_por_raca_cor.R | status=OK | duracao_segundos=9.157
- processa_percentual_sobreeducados_por_sexo.R | status=OK | duracao_segundos=9.202
- processa_percentual_sobreeducados_por_ocupacao_ano_trimestre.R | status=OK | duracao_segundos=11.688
- processa_ultimo_periodo_percentual_sobreeducados_por_ocupacao_e_remuneracao.R | status=OK | duracao_segundos=10.75
- processa_ultimo_periodo_remuneracao_media_por_nivel_instrucao.R | status=OK | duracao_segundos=9.488
- processa_ultimo_periodo_remuneracao_media_por_uf.R | status=OK | duracao_segundos=9.121
- processa_ultimo_periodo_remuneracao_media_por_regiao.R | status=OK | duracao_segundos=9.045
- processa_ultimo_periodo_remuneracao_media_por_raca_cor.R | status=OK | duracao_segundos=9.184
- processa_ultimo_periodo_remuneracao_media_por_sexo.R | status=OK | duracao_segundos=9.115
- processa_ultimo_periodo_remuneracao_media_sobreeducados_nao_sobreeducados_e_superior.R | status=OK | duracao_segundos=8.855
- processa_ultimo_periodo_remuneracao_media_por_tipo_ocupacao_classificada.R | status=OK | duracao_segundos=8.957
