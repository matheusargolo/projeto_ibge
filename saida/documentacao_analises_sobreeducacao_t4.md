# Documentacao da execucao das analises de sobreeducacao (T4)

- Gerado em: 2026-07-02 21:30:28 -0300
- Escopo: periodos disponiveis localmente (atualmente T4 por ano).
- Peso amostral: V1028 (peso valido > 0).
- Definicao de sobreeducado: superior completo (VD3004=7) em ocupacao classificada como nao exigente de nivel superior (nivel_superior=0).
- Classificacao de ocupacoes: saida/ocupacoes_cod2010_classificadas.csv; ocupacoes ambiguas (nivel_superior=2) sao excluidas das analises de sobreeducacao.
- Remuneracao: foram calculadas duas metricas em paralelo:
  - VD4019: rendimento habitual em todos os trabalhos.
  - VD4020: rendimento efetivo em todos os trabalhos.
- Filtro de remuneracao para medias: apenas rendimentos positivos (>0), com ocupacao informada e peso valido.

## Log de execucao

- processa_percentual_sobreeducados_por_uf.R | status=OK | duracao_segundos=314.554
- processa_percentual_sobreeducados_por_regiao.R | status=OK | duracao_segundos=8.543
- processa_percentual_sobreeducados_por_raca_cor.R | status=OK | duracao_segundos=8.442
- processa_percentual_sobreeducados_por_sexo.R | status=OK | duracao_segundos=8.745
- processa_percentual_sobreeducados_por_ocupacao_ano_trimestre.R | status=OK | duracao_segundos=10.441
- processa_ultimo_periodo_percentual_sobreeducados_por_ocupacao_e_remuneracao.R | status=OK | duracao_segundos=8.69
- processa_ultimo_periodo_remuneracao_media_por_nivel_instrucao.R | status=OK | duracao_segundos=8.234
- processa_ultimo_periodo_remuneracao_media_por_uf.R | status=OK | duracao_segundos=8.322
- processa_ultimo_periodo_remuneracao_media_por_regiao.R | status=OK | duracao_segundos=8.285
- processa_ultimo_periodo_remuneracao_media_por_raca_cor.R | status=OK | duracao_segundos=8.136
- processa_ultimo_periodo_remuneracao_media_por_sexo.R | status=OK | duracao_segundos=8.097
- processa_ultimo_periodo_remuneracao_media_sobreeducados_nao_sobreeducados_e_superior.R | status=OK | duracao_segundos=8.057
- processa_ultimo_periodo_comparacao_salarial_sobreeducados_vs_niveis_instrucao.R | status=OK | duracao_segundos=9.702
- processa_serie_comparacao_salarial_sobreeducados_vs_niveis_instrucao.R | status=OK | duracao_segundos=22.689
- processa_ultimo_periodo_remuneracao_media_por_tipo_ocupacao_classificada.R | status=OK | duracao_segundos=12.853
