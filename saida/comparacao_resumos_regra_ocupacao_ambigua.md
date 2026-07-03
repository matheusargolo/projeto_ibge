# Comparacao entre resumo antigo e regra com ocupacao ambigua

O arquivo `saida/resumo.txt` foi restaurado com o resumo antigo. O arquivo `saida/resumo_atualizado.txt` contem o resumo recalculado com a nova regra.

| Indicador | Resumo antigo | Resumo atualizado | Mudanca |
|---|---:|---:|---:|
| Sobreeducados ponderados em 2012-T4 | 6.331.093 | 3.964.726 | -2.366.367 |
| Sobreeducados ponderados em 2025-T4 | 13.434.053 | 9.824.366 | -3.609.687 |
| Crescimento 2012-T4 a 2025-T4 | 112,20% | 147,79% | +35,59 p.p. |
| Taxa de sobreeducacao em 2012-T4 | 49,13% | 51,18% | +2,05 p.p. |
| Taxa de sobreeducacao em 2025-T4 | 51,77% | 57,66% | +5,89 p.p. |
| Homens, taxa 2025-T4 | 57,30% | 59,85% | +2,55 p.p. |
| Mulheres, taxa 2025-T4 | 47,23% | 55,86% | +8,63 p.p. |
| Top ocupacao 2025-T4 | Escriturarios gerais (10,52%) | Escriturarios gerais (14,39%) | +3,87 p.p. |
| Top 10 ocupacoes, participacao 2025-T4 | 33,20% | 40,91% | +7,71 p.p. |
| Rendimento habitual dos sobreeducados | R$ 6.046,62 | R$ 4.799,58 | -R$ 1.247,04 |
| Rendimento habitual dos nao sobreeducados superiores | R$ 8.083,49 | R$ 9.077,48 | +R$ 993,99 |
| Sobreeducados vs medio completo, diferenca habitual | R$ 3.404,98 | R$ 2.272,33 | -R$ 1.132,65 |
| Sobreeducados vs superior incompleto, diferenca habitual | R$ 2.847,72 | R$ 1.803,17 | -R$ 1.044,55 |

## Leitura

- A maior mudanca e conceitual: ocupacoes `nivel_superior = 2` deixam de compor o universo de sobreeducacao. Em 2025-T4, isso remove 16.984 registros de pessoas com superior completo e ocupacao informada.
- O numero ponderado de sobreeducados cai porque ocupacoes ambiguas que antes eram tratadas como nao exigentes deixam de gerar sobreeducados.
- A taxa de sobreeducacao sobe porque o denominador tambem fica mais restrito: agora entram apenas ocupacoes classificadas explicitamente como 0 ou 1.
- As analises de nivel de instrucao puro continuam iguais; as pequenas alteracoes em JSON dessas saidas sao apenas metadados de geracao.
