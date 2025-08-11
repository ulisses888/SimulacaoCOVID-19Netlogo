globals [
  ; parametros do virus
  raio-transmissao
  taxa-transmissao
  duracao-infeccao
  taxa-mortalidade-base
  taxa-mortalidade-criancas
  taxa-mortalidade-adultos
  taxa-mortalidade-idosos
  eficacia-vacina-inicial
  eficacia-vacina-contra-doenca-grave
  chance-de-morrer
  dias-para-sintomas-graves
  chance-doenca-grave

  ; hospitalizado ou n, n ser hospitalizado aumenta muito a mortalidade
  fator-tratamento-hospitalar
  fator-penalidade-recusa

  ; duracao do dia
  ticks-por-dia;


  ;contadores

  mortos-vacinados
  mortos-semvacina
  leitos-publico
  leitos-privado
  leitos-publicos-vazios
  leitos-privados-vazios
  mortos-sem-plano
  mortos-plano
  pessoas-sem-atendimento
  ;crianca
  ;adultos
  ;idosos


  ; Controles
  ; numero-pessoas
  ; porcentagem-vacinados
  ; Variante
]

patches-own [
  distance-to-public
  distance-to-private
]

turtles-own [
  estado ; "suscetivel", "infectado", "recuperado"
  vacinado?
  imune?
  dias-doente ; contador
  plano-saude?
  mascara?
  comorbidade?
  vivo?
  hospitalizado?
  idade
  grupo-risco ; crianca, adultoe idoso
  minha-duracao-infeccao
  precisa-hospital?
  foi-recusado? ; isso aq e pro agente que n tinha vaga no hospital

]

to setup
  clear-turtles
  clear-drawing
  clear-all-plots
  import-pcolors "mapaNetLogo.png"
  setup-distance-maps
  ;clear-all cortado pro mapa
  set ticks-por-dia 24
  set fator-tratamento-hospitalar 0.5 ; Tratamento reduz a chance de morte em 50%
  set fator-penalidade-recusa 3     ; Ser recusado triplica a chance de morte
  apply-variant-parameters

  setup-turtles
  setup-plots
  set mortos-vacinados 0
  set mortos-semvacina 0
  set mortos-sem-plano 0
  set mortos-plano 0
  definir-vagas-hospitais
  reset-ticks
end

to definir-vagas-hospitais
  set leitos-publico int(numero-pessoas * 0.15)
  set leitos-privado int(numero-pessoas * 0.10)
  set leitos-publicos-vazios leitos-publico
  set leitos-privados-vazios leitos-privado
end

to set-default-parameters
  set raio-transmissao 1.5
  ;set num-infectados-iniciais 10 # Definido na interface agr
  ;set taxa-transmissao 0.5
  ;set duracao-infeccao 140 ; 14 dias em ticks (10 ticks/dia) - rever isso?
  ;set taxa-mortalidade 0.02
  ;set eficacia-vacina-inicial 0.70
  ;set eficacia-vacina-contra-doenca-grave 0.8
end

to apply-variant-parameters
  set-default-parameters

  ;; Agora definimos em DIAS e multiplicamos pela escala. (ex: 5 dias)
  set dias-para-sintomas-graves 5 * ticks-por-dia

  if Variante = "Alfa" [
    set taxa-transmissao 0.08
    set eficacia-vacina-inicial 0.85
    set eficacia-vacina-contra-doenca-grave 0.75
    set duracao-infeccao 14 * ticks-por-dia  ; Doença dura 14 dias
    set chance-doenca-grave 0.20
    set taxa-mortalidade-criancas 0.005
    set taxa-mortalidade-adultos 0.02
    set taxa-mortalidade-idosos 0.08
  ]

  if Variante = "Delta" [
    set taxa-transmissao 0.12
    set eficacia-vacina-inicial 0.70
    set eficacia-vacina-contra-doenca-grave 0.90
    set duracao-infeccao 12 * ticks-por-dia  ; Doença dura 12 dias
    set chance-doenca-grave 0.35
    set taxa-mortalidade-criancas 0.008
    set taxa-mortalidade-adultos 0.04
    set taxa-mortalidade-idosos 0.12
  ]

  if Variante = "Ômicron" [
    set taxa-transmissao 0.15
    set eficacia-vacina-inicial 0.30
    set eficacia-vacina-contra-doenca-grave 0.85
    set duracao-infeccao 10 * ticks-por-dia  ; Doença dura 10 dias
    set chance-doenca-grave 0.15
    set taxa-mortalidade-criancas 0.002
    set taxa-mortalidade-adultos 0.015
    set taxa-mortalidade-idosos 0.06
  ]
end

to setup-turtles

  let candidatos patches with [pcolor = 125.4]

  if any? candidatos [
    repeat numero-pessoas [
      ask one-of candidatos [
        sprout 1 [
          set estado "suscetivel"
          set vacinado? false
          set imune? false
          set plano-saude? false
          set mascara? false
          set comorbidade? false
          set dias-doente 0
          set vivo? true
          set hospitalizado? false
          set precisa-hospital? false
          set foi-recusado? false
          set shape "person"
          ;set renda random 1000  ;; Atribui uma renda inicial - n usamos mais renda agr e plano de saude
          fd random-float 0.4

          ;calculo da idade
          let media-idade 20 + (distribuicao-etaria * 0.5)
          let desvio-padrao 18
          let idade-gerada random-normal media-idade desvio-padrao
          set idade max (list 0 min (list 100 idade-gerada))

          ifelse idade < 18 [
            set grupo-risco "crianca"
          ] [
            ifelse idade >= 65 [
              set grupo-risco "idoso"
            ] [
              set grupo-risco "adulto"
            ]
          ]
          ;fim calculo de idade

        ]
      ]
    ]
  ]


  let num-a-vacinar (porcentagem-vacinados / 100) * numero-pessoas
  ask n-of num-a-vacinar turtles [
    set vacinado? true
    if random-float 1.0 < eficacia-vacina-inicial [
      set imune? true
    ]
  ]
  let num-plano-saude ( porcentagem-plano-saude / 100) * numero-pessoas
  ask n-of num-plano-saude turtles [
    set plano-saude? true
  ]

  let num-comorbidade (porcentagem-pessoas-comorbidade / 100) * numero-pessoas
  ask n-of num-comorbidade turtles [
    set comorbidade? true
  ]

  let num-mascara (porcentagem-uso-mascara / 100) * numero-pessoas
  ask n-of num-mascara turtles [
    set mascara? true
  ]


if numero-pessoas > 0 and any? turtles with [imune? = false] [
    ask n-of min (list num-infectados-iniciais (count turtles with [imune? = false])) turtles with [imune? = false] [
      infectar self
    ]
  ]
  ask turtles [ update-agent-color ]
end

to go
  if not any? turtles with [estado = "infectado"] [
    stop
  ]

  ask turtles [ move ]
  ask turtles with [estado = "infectado"] [
    transmit
    progress-disease
  ]
  ask turtles [ update-agent-color ]
  update-plots
  tick
end

to move

  if hospitalizado? [ stop ]


  if foi-recusado? [
    walk-normally
    stop
  ]

  ;; Se nenhuma das condições acima for verdade, então:
  ;; Ele não está hospitalizado e não foi recusado.
  ;; Ele precisa de hospital?
  ifelse precisa-hospital? [
    find-hospital
  ][
    walk-normally
  ]
end

to find-hospital
  let ir-para-publico? (plano-saude? = false) or (leitos-privados-vazios <= 0)

  ifelse ir-para-publico? [
    ; --- Lógica do Hospital Público ---
    ifelse pcolor = 84.9 [ ; Chegou ao hospital público?
      ifelse leitos-publicos-vazios > 0 [
        set leitos-publicos-vazios leitos-publicos-vazios - 1
        set hospitalizado? true
      ][
        ;; HOSPITAL PÚBLICO LOTADO!
        set foi-recusado? true
      ]
    ][
      ; Ainda a caminho do hospital público
      let best-spot min-one-of neighbors [distance-to-public]
      move-to best-spot
    ]
  ] [
    ; --- Lógica do Hospital Privado ---
    ifelse pcolor = 104.9 [ ; Chegou ao hospital privado?
       ifelse leitos-privados-vazios > 0 [
        set leitos-privados-vazios leitos-privados-vazios - 1
        set hospitalizado? true
       ][
         ;; HOSPITAL PRIVADO LOTADO!
         set foi-recusado? true
       ]
    ][
      ; Ainda a caminho do hospital privado
      let best-spot min-one-of neighbors [distance-to-private]
      move-to best-spot
    ]
  ]
end

;; Procedimento para uma turtle saudável andar pelos caminhos
to walk-normally
  ;; Usa os valores decimais para filtrar as paredes
  let patches-caminhaveis patches in-cone 3 90 with [pcolor != 14.9 and pcolor != 65]

  ;; Separa os patches caminháveis usando os valores decimais
  let patches-amarelos patches-caminhaveis with [pcolor = 44.8]
  let patches-pretos patches-caminhaveis with [pcolor = 0]

  ifelse any? patches-amarelos [
    face one-of patches-amarelos
    fd 1
  ] [
    ifelse any? patches-pretos [
      face one-of patches-pretos
      fd 1
    ] [
      rt 180
    ]
  ]
end


to transmit
  let alvos-potenciais other turtles in-radius raio-transmissao with [estado = "suscetivel" and not imune?]

  ask alvos-potenciais [
    let chance-real-transmissao taxa-transmissao
    if [mascara?] of myself [ set chance-real-transmissao chance-real-transmissao * 0.5 ]
    if mascara? [ set chance-real-transmissao chance-real-transmissao * 0.5 ]

    if random-float 1.0 < chance-real-transmissao [
      infectar self ; <<--- ALTERADO: Usa o novo procedimento
    ]
  ]
end

to progress-disease
  set dias-doente dias-doente + 1

  ;; Lógica para desenvolver sintomas graves...
  if dias-doente = dias-para-sintomas-graves [
    if random-float 1.0 < chance-doenca-grave [
      set precisa-hospital? true
    ]
  ]

  ;; Lógica de recuperação ou morte...
  if dias-doente > minha-duracao-infeccao [

    ;; --- INÍCIO DA NOVA LÓGICA DE MORTALIDADE ---

    ;; 1. Calcula a chance de morrer base (idade + comorbidade)
    let chance-base 0
    if grupo-risco = "crianca" [ set chance-base taxa-mortalidade-criancas ]
    if grupo-risco = "adulto"  [ set chance-base taxa-mortalidade-adultos ]
    if grupo-risco = "idoso"   [ set chance-base taxa-mortalidade-idosos ]
    if comorbidade? [ set chance-base chance-base * 1.5 ]

    ;; 2. Aplica os fatores de hospitalização e vacina
    let chance-final chance-base

    ;; Benefício do tratamento hospitalar
    if hospitalizado? [
      set chance-final chance-final * fator-tratamento-hospitalar
    ]

    ;; Penalidade por ter sido recusado no hospital
    if foi-recusado? [
      set chance-final chance-final * fator-penalidade-recusa
    ]

    ;; Benefício da vacina contra doença grave
    if vacinado? [
      set chance-final chance-final * (1 - eficacia-vacina-contra-doenca-grave)
    ]

    ;; --- FIM DA NOVA LÓGICA DE MORTALIDADE ---

    ;; 5. Sorteio final com a chance calculada
    ifelse random-float 1.0 < chance-final [
      morrer
    ][
      set estado "recuperado"
      set imune? true
      set precisa-hospital? false ; Limpa a flag
      if hospitalizado? [ liberar-leito ]
    ]
  ]
end

to morrer
  ifelse vacinado? [
    set mortos-vacinados mortos-vacinados + 1
  ] [
    set mortos-semvacina mortos-semvacina + 1
  ]
  ; Libera o leito se estava hospitalizado ao morrer
  if hospitalizado? [ liberar-leito ]
  ifelse plano-saude? [
    set mortos-plano mortos-plano + 1 ]
  [
    set mortos-sem-plano mortos-sem-plano + 1
  ]

  ;ifelse plano

  die
end

to liberar-leito
  ; Verifica em qual tipo de hospital o agente estava para liberar a vaga correta
  if pcolor = 84.9 [ set leitos-publicos-vazios leitos-publicos-vazios + 1 ]
  if pcolor = 104.9 [ set leitos-privados-vazios leitos-privados-vazios + 1 ]
end

to update-agent-color
  if estado = "suscetivel" [
    set color green ; Susceptible agents are now green
  ]
  if estado = "infectado" [
    set color red   ; Infected agents remain red
  ]
  if estado = "recuperado" [
    set color sky   ; Recovered agents are now light blue (sky color)
  ]
end


to setup-distance-maps
  ;; ---- Mapa para Hospitais Públicos ----
  let public-hospitals patches with [pcolor = 84.9]
  ask patches [ set distance-to-public 99999 ]
  ask public-hospitals [ set distance-to-public 0 ]

  let queue-public (list)
  if any? public-hospitals [
    set queue-public sort public-hospitals
  ]

  while [not empty? queue-public] [
    let current first queue-public
    set queue-public but-first queue-public


    ;; Passo 1: Pega todos os 8 vizinhos.
    let all-neighbors [neighbors] of current
    ;; Passo 2: Filtra apenas os vizinhos válidos (não visitados e que não são paredes).
    let valid-neighbors all-neighbors with [distance-to-public = 99999 and pcolor != 14.9 and pcolor != 65]
    ;; Passo 3: Pede apenas para os vizinhos válidos executarem as ações.
    ask valid-neighbors [
      set distance-to-public ([distance-to-public] of current + 1)
      set queue-public lput self queue-public
    ]
  ]

  ;; ---- Mapa para Hospitais Privados ----
  let private-hospitals patches with [pcolor = 104.9]
  ask patches [ set distance-to-private 99999 ]
  ask private-hospitals [ set distance-to-private 0 ]

  let queue-private (list)
  if any? private-hospitals [
    set queue-private sort private-hospitals
  ]

  while [not empty? queue-private] [
    let current first queue-private
    set queue-private but-first queue-private


    let all-neighbors [neighbors] of current
    let valid-neighbors all-neighbors with [distance-to-private = 99999 and pcolor != 14.9 and pcolor != 65]
    ask valid-neighbors [
      set distance-to-private ([distance-to-private] of current + 1)
      set queue-private lput self queue-private
    ]
  ]
end

to infectar [ a-tartaruga ]
  ask a-tartaruga [
    set estado "infectado"
    set dias-doente 0
    set precisa-hospital? false ; Garante que a flag seja reiniciada

    ;; Define uma duração de doença individual e variável
    let variacao-em-dias (random 5) - 2 ; Variação de +/- 2 dias
    set minha-duracao-infeccao duracao-infeccao + (variacao-em-dias * ticks-por-dia)
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1063
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-32
32
-16
16
0
0
1
ticks
30.0

SLIDER
1061
254
1313
287
porcentagem-vacinados
porcentagem-vacinados
0
100
48.0
1
1
%
HORIZONTAL

BUTTON
24
154
87
187
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
92
154
155
187
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
6
10
144
55
Variante
Variante
"Alfa" "Delta" "Ômicron"
1

PLOT
1063
10
1414
136
Evolução Epidemiologica
NIL
Pessoas
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Contaminados" 1.0 0 -2674135 true "" "plot count turtles with [estado = \"infectado\"]"
"Suscetiveis" 1.0 0 -13840069 true "" "plot count turtles with [estado = \"suscetivel\"]"
"Recuperados" 1.0 0 -13791810 true "" "plot count turtles with [estado = \"recuperado\"]"
"Mortos" 1.0 0 -7500403 true "" "plot mortos-vacinados + mortos-semvacina\n"

PLOT
1062
135
1414
255
Contaminados Vacinados/Nao Vacinados
NIL
Pessoas
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Vacinados" 1.0 0 -11085214 true "" "plot count turtles with [estado = \"infectado\" and vacinado? = true]"
"Não Vacinados" 1.0 0 -6759204 true "" "plot count turtles with [estado = \"infectado\" and vacinado? = false]"

SLIDER
0
438
182
471
numero-pessoas
numero-pessoas
0
1000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
0
469
181
502
num-infectados-iniciais
num-infectados-iniciais
0
numero-pessoas
100.0
1
1
NIL
HORIZONTAL

SLIDER
1071
418
1323
451
porcentagem-uso-mascara
porcentagem-uso-mascara
0
100
71.0
1
1
%
HORIZONTAL

MONITOR
6
56
201
101
Taxa de transmissão da variante
taxa-transmissao
17
1
11

MONITOR
6
102
200
147
Taxa de mortalidade por grupo
(word \"C: \" (100 * taxa-mortalidade-criancas) \"% | A: \" (100 * taxa-mortalidade-adultos) \"% | I: \" (100 * taxa-mortalidade-idosos) \"%\")
17
1
11

SLIDER
1071
386
1323
419
porcentagem-pessoas-comorbidade
porcentagem-pessoas-comorbidade
0
100
12.0
1
1
%
HORIZONTAL

SLIDER
1072
454
1274
487
porcentagem-plano-saude
porcentagem-plano-saude
0
100
5.0
1
1
%
HORIZONTAL

MONITOR
2
191
87
236
NIL
leitos-publico
17
1
11

MONITOR
87
191
175
236
NIL
leitos-privado
17
1
11

MONITOR
744
452
860
497
NIL
leitos-publicos-vazios
17
1
11

MONITOR
743
496
861
541
NIL
leitos-privados-vazios
17
1
11

MONITOR
0
252
101
297
NIL
mortos-vacinados
17
1
11

MONITOR
100
252
204
297
NIL
mortos-semvacina
17
1
11

MONITOR
1065
293
1182
338
Pessoas vacinadas
count turtles with [vacinado? = true]
17
1
11

MONITOR
1183
292
1307
337
Pessoas sem vacina
count turtles with [vacinado? = false]
17
1
11

MONITOR
1064
337
1189
382
Pessoas c/plano saude
count turtles with [plano-saude? = true]
17
1
11

MONITOR
1192
335
1331
380
Pessoas s/plano saude
count turtles with [plano-saude? = false]
17
1
11

MONITOR
0
299
132
344
Mortos c/plano saude
mortos-plano
17
1
11

MONITOR
0
344
132
389
Mortos s/plano saude
mortos-sem-plano
17
1
11

TEXTBOX
213
453
432
479
NUMERO DE PESSOAS POR GRUPO DE RISCO:
10
0.0
1

MONITOR
206
561
267
606
Crianças
count turtles with [grupo-risco = \"crianca\"]
17
1
11

MONITOR
207
515
271
560
Adultos
count turtles with [grupo-risco = \"adulto\"]
17
1
11

MONITOR
208
469
259
514
Idosos
count turtles with [grupo-risco = \"idoso\"]
17
1
11

MONITOR
268
561
413
606
Desses tem comorbidade:
count turtles with [comorbidade? = true and grupo-risco = \"crianca\"]
17
1
11

MONITOR
271
515
413
560
Desses tem comorbidade:
count turtles with [comorbidade? = true and grupo-risco = \"adulto\"]
17
1
11

MONITOR
259
469
398
514
Desses tem comorbidade:
count turtles with [comorbidade? = true and grupo-risco = \"idoso\"]
17
1
11

SLIDER
0
401
212
434
distribuicao-etaria
distribuicao-etaria
0
100
70.0
1
1
Jovem < - > Adulto
HORIZONTAL

PLOT
451
451
743
571
Colapso do sistema de saude
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"S/Atendimento" 1.0 0 -2674135 true "" "plot count turtles with [foi-recusado? = true]"

@#$#@#$#@
## O que é?

Este modelo NetLogo foi desenvolvido para simular a propagação de uma infecção viral da covid-19 em uma população, aprofundando-se em como diversos fatores influenciam a progressão da doença, a demanda por serviços hospitalares e as taxas de mortalidade. Ele não apenas considera características individuais dos agentes, como idade, status de vacinação, presença de comorbidades e o uso de máscaras, mas também integra aspectos cruciais do sistema de saúde, como a disponibilidade de leitos em hospitais públicos e privados. Uma funcionalidade chave do modelo é a capacidade de investigar o impacto de diferentes variantes do vírus, cada uma com suas próprias particularidades em termos de transmissibilidade, severidade da doença e eficácia das vacinas.

## Como funciona

A operação do modelo se baseia na interação entre uma grade de "patches", que representam o ambiente físico, e "turtles", que são os agentes individuais simulando pessoas.

Inicialização
A simulação começa com o procedimento setup. Primeiramente, o modelo importa uma imagem de mapa (mapaNetLogo.png), que é utilizada para definir áreas caminháveis no ambiente, bem como a localização de hospitais públicos e privados. Para otimizar a navegação dos agentes, mapas de distância até esses hospitais são pré-calculados.

Em seguida, os parâmetros globais são configurados. Estes incluem características do vírus, como o raio de transmissão, a duração da infecção, as taxas de mortalidade diferenciadas por faixa etária e a eficácia da vacina, além de fatores relacionados à capacidade hospitalar. É crucial notar que muitos desses parâmetros são dinamicamente ajustados conforme a Variante do vírus selecionada pelo usuário – seja "Alfa", "Delta" ou "Ômicron" –, refletindo suas distintas propriedades epidemiológicas.

A população é então gerada: um número especificado de numero-pessoas é criado em patches caminháveis. Cada agente é dotado de várias propriedades: seu estado inicial ("suscetivel", "infectado" ou "recuperado"); uma idade gerada aleatoriamente com base na distribuicao-etaria, que os classifica em grupo-risco (criança, adulto ou idoso); seu status de vacinado? (uma porcentagem inicial é vacinada, com a possibilidade de se tornarem imune? dependendo da eficacia-vacina-inicial); a posse de plano-saude? (um percentual da população); o uso de mascara? (também um percentual); e a presença de comorbidade?. Um num-infectados-iniciais é definido para iniciar a propagação. A capacidade hospitalar também é estabelecida, com o número de leitos-publico e leitos-privado sendo determinado proporcionalmente ao numero-pessoas total.

O movimento dos agentes é gerenciado pelo procedimento move. Agentes que estão hospitalizados permanecem imóveis. Aqueles que foram recusados em um hospital devido à lotação continuam a se mover normalmente. Indivíduos que precisam de hospital tentam encontrar um leito através do procedimento find-hospital, priorizando hospitais privados se possuírem plano-saude? e houver vagas, ou buscando leitos públicos caso contrário. Se todos os leitos estiverem ocupados, eles são marcados como recusados. Os demais agentes simplesmente andam aleatoriamente pelos caminhos predefinidos no mapa.

A transmissão do vírus é gerenciada por uma função onde indivíduos infectados podem transmitir o vírus a agentes suscetíveis dentro do seu raio de transmissao. A probabilidade de transmissão, influenciada pela taxa-transmissao, é reduzida se o indivíduo infectado ou o suscetível estiverem usando mascara.

A progressão da doença é simulada no procedimento progress-disease. Indivíduos infectados incrementam seu contador de dias-doente. Após atingir dias-para-sintomas-graves, alguns podem desenvolver doença grave, tornando-se necessario a hospitalização, com base na chance-doenca-grave. Ao final da minha-duracao-infeccao individual de cada agente, o modelo determina se ele irá morrer ou se recuperar.

A chance de morrer é calculada dinamicamente: começa com uma taxa baseada no grupo-risco (taxa-mortalidade-criancas, taxa-mortalidade-adultos, taxa-mortalidade-idosos), aumenta em 1.5x se o agente tiver comorbidade, diminui em fator-tratamento-hospitalar se estiver hospitalizado, aumenta em fator-penalidade-recusa se foi recusado em um hospital, e diminui com base na eficacia-vacina-contra-doenca-grave se vacinado. Se o agente morrer, é removido da simulação, e os contadores de mortos-vacinados, mortos-semvacina, mortos-plano e mortos-sem-plano são atualizados. Se o agente se recupera, seu estado muda para "recuperado", ele se torna imune, e o leito hospitalar é liberado, se aplicável.

Por fim, as cores dos agentes são atualizadas para refletir seu estado atual (verde para suscetível, vermelho para infectado, azul-claro para recuperado), e os gráficos na interface são atualizados para visualizar o progresso da simulação.

## Como usar

A interface do modelo oferece uma série de controles para manipular as variáveis e observar os resultados.

Nos controles deslizantes (sliders), você pode ajustar o numero-pessoas total na simulação, a porcentagem-vacinados inicial da população, o num-infectados-iniciais, a porcentagem-plano-saude e a porcentagem-pessoas-comorbidade. Você também pode definir a porcentagem-uso-mascara e influenciar a distribuicao-etaria da população, com valores mais altos resultando em uma média de idade mais avançada.

Um seletor (chooser) permite que você escolha a Variante do vírus a ser simulada, com opções como "Alfa", "Delta" ou "Ômicron", cada uma com seus próprios parâmetros predefinidos para transmissibilidade, severidade e eficácia da vacina.

Os botões setup e go são essenciais: setup inicializa o modelo com os parâmetros definidos, enquanto go inicia a simulação, que continua até que não haja mais indivíduos infectados.

Diversos monitores fornecem feedback em tempo real, exibindo o mortos-vacinados e mortos-semvacina, a disponibilidade de leitos-publicos-vazios e leitos-privados-vazios, e o mortos-sem-plano e mortos-plano. Embora declarado, o monitor pessoas-sem-atendimento não é explicitamente incrementado no código fornecido.

É provável que a interface também inclua gráficos (plots) que visualizam a evolução do número de indivíduos suscetíveis, infectados e recuperados ao longo do tempo, e possivelmente curvas de mortalidade ou a ocupação dos leitos hospitalares.

## Coisas a se observar

Ao executar o modelo, preste atenção em algumas dinâmicas chave. Observe o padrão de propagação da infecção no mapa: ela segue as vias de movimentação dos agentes ou se espalha de forma mais difusa? A sobrecarga hospitalar é um ponto crítico; monitore a rapidez com que os leitos públicos e privados se esgotam e como isso correlaciona com as taxas de mortalidade.

Compare as execuções com diferentes porcentagem-vacinados para entender o impacto da vacinação na taxa de pico de infecções e no número total de óbitos. Da mesma forma, experimente as diversas configurações de Variante para ver como a duração da doença, a transmissibilidade e os padrões de mortalidade se alteram entre as variantes Alfa, Delta e Ômicron.

O efeito do uso de máscaras também é visível; observe como a porcentagem-uso-mascara influencia a taxa de transmissão. Fique atento a como indivíduos com comorbidade? ou aqueles no grupo-risco "idoso" se comportam em relação à doença grave e à mortalidade. Por fim, analise o impacto do plano-saude? na mortalidade, comparando mortos-sem-plano e mortos-plano, especialmente em cenários de sobrecarga hospitalar.

## Coisas para tentar

Para explorar o modelo mais a fundo, algumas experiências sugeridas incluem:

Testar a capacidade dos hospitais: Configure um num-infectados-iniciais alto e um numero-pessoas relativamente baixo para simular uma sobrecarga rápida do sistema de saúde. Inversamente, reduza a população total mantendo o número inicial de infectados constante para observar o impacto em uma comunidade menor, porém mais densamente infectada.

Avaliar a efetividade de campanhas de vacinação: Compare os resultados de uma simulação com 0% de porcentagem-vacinados com outra com 80%, analisando o impacto nas taxas de infecção e mortalidade. Você também pode experimentar com a eficacia-vacina-inicial ao mudar a Variante para ver como isso afeta a imunidade inicial.

Analisar a carga nos sistemas de saúde público e privado: Ajuste a porcentagem-plano-saude para observar a redistribuição da demanda por leitos. Considere cenários extremos, como escassez de leitos públicos e abundância de privados, ou vice-versa.

Investigar o impacto do uso de máscara: Simule com 0% e depois com 100% de porcentagem-uso-mascara para notar a diferença na taxa e extensão da propagação da infecção.

Explorar os efeitos da distribuição etária: Modifique a distribuicao-etaria para criar populações mais jovens ou mais velhas e observe como isso afeta a mortalidade geral, dado que as taxas de mortalidade são dependentes da idade.

## Extendendo o modelo

Se você tiver familiaridade com o código, pode criar suas próprias variantes hipotéticas: modifique o procedimento apply-variant-parameters para definir características personalizadas de transmissibilidade, severidade e eficácia da vacina.

Tambem existe a possibilidade de criar o proprio mapa des-de que respeitado as cores dos patches ou alterando-as no codigo para que os procedimentos funcionem corretamente

## Modelos relacionados

Este modelo se conecta a uma série de outros modelos na biblioteca NetLogo e em outros contextos:

Disease Spread (Propagação de Doenças): Um modelo fundamental na biblioteca NetLogo que demonstra a dinâmica básica do modelo SIR (Suscetível-Infectado-Recuperado).
Virus (Vírus): Outro modelo clássico que ilustra a transmissão e recuperação de vírus, frequentemente incorporando conceitos de imunidade.
Flu (Gripe): Um modelo que explora a propagação da gripe, muitas vezes integrando padrões de movimento e redes sociais para uma simulação mais rica.
Pandemic (Pandemia - de Uri Wilensky): Semelhante a este modelo, ele simula a propagação de uma pandemia, frequentemente com interações sociais mais complexas e a possibilidade de implementação de intervenções.

## Creditos e Referencias

Modelo criado para o artigo: [Sistema Multiagente para Simulacao de Propagacao Viral
no contexto da COVID-19 usando NetLogo]

Pelo grupo: [ Bruno C. Alves, Leticia B. Caldas, Ulisses G. F. Junior, Agatha C. S. Santos e Rodolfo B. Grossmann ]

Data: 26 de junho de 2025
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
