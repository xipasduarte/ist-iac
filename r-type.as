; Stack Pointer inicial
SP_INIC         EQU     FDFFh
NavePosInicial  EQU     0503h

; Mascaras de interaccoes
INIT_MASK_ADDR  EQU     FFFAh
INIT_MASK       EQU     6000h
INT_GAME_MASK   EQU     E01Fh
INT_GAME2_MASK  EQU     E003h

; Controlo de tempo (temporizador)
TimeControl     EQU     FFF7h
TimeInterval    EQU     FFF6h

; Portos da Janela
LeituraJanela   EQU     FFFFh
EscritaJanela   EQU     FFFEh
EstadoJanela    EQU     FFFDh
ControloJanela  EQU     FFFCh

; Portos do LCD
ControloLCD     EQU     FFF4h
EscritaLCD      EQU     FFF5h

; Portos dos LEDs
EscritaLED      EQU     FFF8h

; Display
EntradaDisplay  EQU     FFF0h ; Porto de escrita
NUM_NIBBLES     EQU     4

; Limites da janela
MAX_I           EQU     0017h
MAX_J           EQU     004Eh

; Caracteres
Limite          EQU     '#'
Asteroide       EQU     '*'
Buraco          EQU     'o'
Tiro            EQU     '-'
AsaEsquerda     EQU     '\'
AsaDireita      EQU     '/'
Canhao          EQU     '>'
Corpo           EQU     '|'
KeyUp           EQU     'w'
KeyDown         EQU     's'
KeyLeft         EQU     'a'
KeyRight        EQU     'd'
KeySpace        EQU     ' '
KeyCross        EQU     'X'
StopStr         EQU     '@'

                ORIG    FE00h
INT0            WORD    IntBaixo
INT1            WORD    IntCima
INT2            WORD    IntEsquerda
INT3            WORD    IntDireita
INT4            WORD    IntTiro

                ORIG    FE0Eh
INTE            WORD    StartGame
INTF            WORD    LoopTime

                ORIG    8000h
                ; Mensagens dos diversos displais e ecrãs
MsgInicial      STR     'Press INTE to start a new game...@'
MsgGameOver     STR     'GAME OVER@'
MsgGameOver2    STR     'Score -@'
MsgGameOver3    STR     'HighScore -@'
MsgLCDLinha     STR     ' linha:@'
MsgLCDColuna    STR     'coluna:@'

                ; Variaveis de jogo
IsGameOver      WORD    0000h ; Indicador da existencia de um jogo anterior perdido
PosicaoNave     WORD    0000h ; Inicializado a 0503h para novos jogos
Cima            WORD    0000h ; Movimentos a realizar para cima
Baixo           WORD    0000h ; Movimentos a realizar para baixo
Esquerda        WORD    0000h ; Movimentos a realizar para a esquerda
Direita         WORD    0000h ; Movimentos a realizar para a direita
Tempo           WORD    0000h ; Iteracoes de tempo a realizar
TimeInt         WORD    0000h ; Intervalo de tempo
Disparo         WORD    0000h ; Indicador para a realizacao de um disparo
ContaCiclos     WORD    0000h ; Contador de ciclos de relogio
NumAle          WORD    0000h ; Base de numeros aleatorios
NumAleNorm      WORD    0000h ; Numero aleatorio normalizado
MoveAstros      WORD    0000h ; Identifica o ciclo de tempo que move os astros
ContaEspaco     WORD    0000h ; Conta a distancia entre objectos
ContaAsteroide  WORD    0000h ; Conta os asteroides inseridos
ContaPontos     WORD    0000h ; Asteroides destruidos
HighScore       WORD    0000h ; Score mais alto da sessao
                ; Pilha de objectos
ObjSP           WORD    0000h ; Object stack pointer, indica a entrada vazia seguinte
ObjectStack     TAB     94    ; 14 '*' (Asteroide) || 'o' (Buraco) e 80 '-' (Tiros)

                ORIG    0000h
                JMP     Inicio

;------------------------------------------------------------------------------;
; INTERRUPCOES                                                                 ;
;------------------------------------------------------------------------------;

;
; Iniciar jogo com interrupcoes
;   Interrupcao que inicia o jogo em mode de execucao com interrupcoes.
;
StartGame:      PUSH    R1

                ; Inicializa memoria
                CALL    ResetInitMem

                ; Inicializa nova mascara de interrupcoes
                MOV     R1, INT_GAME_MASK
                MOV     M[INIT_MASK_ADDR], R1
                ; Inicializa temporizador
                MOV     R1, M[TimeInt]
                MOV     M[TimeInterval], R1
                MOV     R1, 0001h
                MOV     M[TimeControl], R1

                ; Pinta terreno de jogo
                CALL    PintaEcra

                POP R1
                RTI

;
; Interrupcao "cima"
;   Incrementa o número de vezes a mover a nave para cima.
;
;   Saidas:
;       Enderecamento M[Cima] - indicador de execucao da rotina de movimento
;                               para cima da nave.
;
IntCima:        INC     M[Cima]
                RTI

;
; Interrupcao "baixo"
;   Incrementa o número de vezes a mover a nave para baixo.
;
;   Saidas:
;       Enderecamento M[Baixo] - indicador de execucao da rotina de movimento
;                                para baixo da nave.
;
IntBaixo:       INC     M[Baixo]
                RTI

;
; Interrupcao "esquerda"
;   Incrementa o número de vezes a mover a nave para esquerda.
;
;   Saidas:
;       Enderecamento M[Esquerda] - indicador de execucao da rotina de movimento
;                                   à esquerda da nave.
;
IntEsquerda:    INC     M[Esquerda]
                RTI

;
; Interrupcao "direita"
;   Incrementa o número de vezes a mover a nave para direita.
;
;   Saidas:
;       Enderecamento M[Direita] - indicador de execucao da rotina de movimento
;                                  à direita da nave.
;
IntDireita:     INC     M[Direita]
                RTI

;
; Interrupcao "disparo"
;   Activa a accao de disparo num dado ciclo de tempo de jogo.
;   Os disparos estão limitados a um por ciclo de jogo de modo a impedir que
;   ocorram disparos de tiros a serem sobrepostos sobre si mesmos.
;
;   Saidas:
;       Enderecamento M[Disparo] - indicador de execucao da rotina de disparo.
;
IntTiro:        PUSH    R1
                MOV     R1, 0001h
                OR      M[Disparo], R1
                POP     R1
                RTI

;
; Interrupcao do tempo
;   Incrementa o número de ciclos de tempo a executar.
;
LoopTime:       PUSH    R1
                PUSH    R2
                PUSH    R3

                ; Determina o número de loops de tempo com base no nivel
                MOV     R1, 0001h
                MOV     R2, M[ContaPontos]
                MOV     R3, 0014h   ; Sobe velocidade a cada 20 pontos
                DIV     R2, R3
                ADD     R1, R2
                MOV     M[Tempo], R1

                ; Reactiva ciclo do temporizador
                MOV     R1, 0001h
                MOV     R1, M[TimeInt]
                MOV     M[TimeInterval], R1
                MOV     R1, 0001h
                MOV     M[TimeControl], R1

                POP     R3
                POP     R2
                POP     R1
                RTI


;------------------------------------------------------------------------------;
; ROTINAS AUXILIARES                                                           ;
;------------------------------------------------------------------------------;

;
; Reset Memoria Inicial
;   Reset da memoria para carregar o jogo.
;
ResetInitMem:   PUSH    R7

                ; Inicializa "variaveis"
                MOV     M[IsGameOver], R0
                MOV     M[Cima], R0
                MOV     M[Baixo], R0
                MOV     M[Esquerda], R0
                MOV     M[Direita], R0
                MOV     M[Tempo], R0
                MOV     M[Disparo], R0
                MOV     M[ContaCiclos], R0
                MOV     M[MoveAstros], R0
                MOV     M[ContaAsteroide], R0
                MOV     M[ContaPontos], R0
                ; Inicializa valor do intervalo de tempo
                MOV     R7, 0001h
                MOV     M[TimeInt], R7
                ; Inicializa espaco para criar logo um astro
                MOV     R7, 0006h
                MOV     M[ContaEspaco], R7
                ; Inicializa a posicao da nave
                MOV     R7, NavePosInicial
                MOV     M[PosicaoNave], R7
                ; Inicializa o SP da stack de objectos
                MOV     R7, ObjectStack
                MOV     M[ObjSP], R7

                ; Limpa display
                CALL    DisplayZero

                POP     R7
                RET

;
; Numero aleatorio
;   Rotina que gera numeros para dar ideia de aleatoriedade na criacao de
;   astros.
;
;   Entrada:
;       Enderecamento M[ContaCiclos] - Numero de ciclos de GameLoop
;       Enderecamento M[NumAle] - Numero aleatorio anterior
;       INT_GAME_MASK - Mascara de jogo
;       MAX_I - Maximo de linhas da janela
;
GeradorNum:     PUSH    R1 ; Ciclos de GameLoop
                PUSH    R2 ; Numero aleatorio anterior
                PUSH    R3

                ; Determinar tipo de geracao
                MOV     R1, M[ContaCiclos]
                MOV     R2, M[NumAle]
                AND     R1, 0001h
                CMP     R1, R0
                BR.Z    GeradorSimples
                XOR     R2, INT_GAME_MASK
                ROR     R2, 1
                BR      NormalizarNum
GeradorSimples: ROR     R2, 1

                ; Guarda e Normaliza numero aleatorio
                ; TODO: Fazer apenas uma vez quando se insere.
NormalizarNum:  MOV     M[NumAle], R2
                MOV     R3, MAX_I
                DEC     R3
                DIV     R2, R3
                INC     R3
                MOV     M[NumAleNorm], R3

                INC     M[ContaCiclos] ; Incrementar ciclos GameLoop
                POP     R3
                POP     R2
                POP     R1
                RET


;------------------------------------------------------------------------------;
; ESCRITAS NA JANELA                                                           ;
;------------------------------------------------------------------------------;

;
; Escreve String na Janela
;   Rotina que escreve um qualquer string passado por pilha, com simbolo de
;   paragem igual a '@'.
;
;   Entrada:
;       Stack P3 R1 - Indice do primeiro caractere
;       Stack P3 R3 - Posicao de origem da escrita
;
EscreveString:  PUSH    R1  ; Indice do primeiro caracter a escrever
                PUSH    R2
                PUSH    R3  ; Posicao de origem da escrita

                MOV     R1, M[SP+6]
                MOV     R3, M[SP+5]
                MOV     R2, M[R1]
CicloEscStr:    MOV     M[ControloJanela], R3
                MOV     M[EscritaJanela], R2
                INC     R3
                INC     R1
                MOV     R2, M[R1]
                CMP     R2, StopStr
                BR.NZ   CicloEscStr
                POP     R3
                POP     R2
                POP     R1
                RETN    2

;
; Limpar Janela
;   Rotina que limpa a janela de texto inserindo espacos em todas as posicoes.
;
;   Entrada:
;       MAX_J - Maximo de colunas da janela.
;
LimpaJanela:    PUSH    R1
                PUSH    R2
                PUSH    R3

                ; Reset do cursor (simulador)
                MOV     R1, FFFFh
                MOV     M[ControloJanela], R1

                ; Percorrer linhas
                MOV     R1, R0
LimpaLinhas:    CMP     R1, MAX_I
                BR.Z    SairLimpaJan

                ; Percorrer colunas (dentro de cada linha)
                MOV     R2, R0
LimpaColunas:   MOV     R3, R1
                SHL     R3, 8
                ADD     R3, R2
                MOV     M[ControloJanela], R3
                MOV     R3, KeySpace
                MOV     M[EscritaJanela], R3
                INC     R2
                CMP     R2, MAX_J
                BR.NZ   LimpaColunas

                INC     R1
                BR      LimpaLinhas

SairLimpaJan:   POP     R3
                POP     R2
                POP     R1
                RET

;
; Splash Screen
;   Rotina que escreve a mensagem inicial de inicio de jogo.
;
;   Entrada:
;       Mensagens - MsgInicial, MsgGameOver, MsgGameOver2, MsgGameOver3
;
SplashScreen:   PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4

                ; Reset LCD
                CALL    ResetLCD
                ; Limpar a janela (corrigir)
                CALL    LimpaJanela

                ; Escrever mensagem inicial
                MOV     R1, MsgInicial
                MOV     R3, 0D18h
                PUSH    R1
                PUSH    R3
                CALL    EscreveString

                ; Escrever informacao de GameOver se for caso disso
                CMP     M[IsGameOver], R0
                JMP.Z   SairSplash
                MOV     R1, MsgGameOver
                MOV     R3, 0623h
                PUSH    R1
                PUSH    R3
                CALL    EscreveString

                ; Escrever texto da pontuacao
                MOV     R1, MsgGameOver2
                MOV     R3, 0822h
                PUSH    R1
                PUSH    R3
                CALL    EscreveString
                ; Escreve ContaPontos se tiver sido GameOver
                MOV     R1, M[ContaPontos]
                MOV     R3, 082Dh
CicloOver3:     MOV     R2, 000Ah   ; Base decimal
                DIV     R1, R2
                ADD     R2, 0030h
                MOV     M[ControloJanela], R3
                MOV     M[EscritaJanela], R2
                DEC     R3
                CMP     R1, R0
                BR.NZ   CicloOver3

                ; Escrever texto da pontuacao HighScore
                MOV     R1, MsgGameOver3
                MOV     R3, 091Eh
                PUSH    R1
                PUSH    R3
                CALL    EscreveString
                ; Escreve HighScore se tiver sido GameOver
                MOV     R1, M[HighScore]
                MOV     R3, 092Dh
CicloOver4:     MOV     R2, 000Ah   ; Base decimal
                DIV     R1, R2
                ADD     R2, 0030h
                MOV     M[ControloJanela], R3
                MOV     M[EscritaJanela], R2
                DEC     R3
                CMP     R1, R0
                BR.NZ   CicloOver4

SairSplash:     POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET


;
; Pinta Ecra de Jogo
;   Funcao que escreve os limites do jogo na janela e nave na posicao inicial.
;
PintaEcra:      PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4

                ; Limpar janela
                CALL    LimpaJanela

                ; Escrever linha de cima
                MOV     R1, Limite
                MOV     R4, R0
                MOV     M[ControloJanela], R4    ; Posicionar o cursor na primeira linha e coluna
                MOV     M[EscritaJanela], R1     ; Escrever primeiro limite
                MOV     R3, R0                   ; Indice j da janela
LinhaCima:      INC     R3
                MOV     R4, R3
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R1
                CMP     R3, MAX_J
                BR.NZ   LinhaCima

                ; Escrever linha de baixo
                MOV     R2, 1700h                ; Indice da ultima linha da janela
                MVBH    R3, R2
                MOV     R4, R3
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R1
                MOV     R4, M[ControloJanela]
LinhaBaixo:     DEC     R3
                MOV     R4, R3
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R1
                MOV     R4, M[ControloJanela]
                CMP     R3, R2
                BR.NZ   LinhaBaixo

                ; Pintar nave na posicao inicial
                CALL    PintaNave

                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;
; Pinta Nave
;   Rotina que desenha a nave numa determinada posicao da janela.
;
;   Entrada:
;       Caracteres - Canhao, Corpo, AsaEsquerda, AsaDireita
;
PintaNave:      PUSH    R1
                PUSH    R4

                ; Determina se ha colisoes na nova posicao
                CALL    ColisaoNave

                ; Desenha a nave na posicao guardada em memoria
                MOV     R1, Canhao
                MOV     R4, M[PosicaoNave]
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R1
                MOV     R1, Corpo
                DEC     R4
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R1
                MOV     R1, AsaEsquerda
                SUB     R4, 0100h
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R1
                MOV     R1, AsaDireita
                ADD     R4, 0200h
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R1

                ; Coloca posicao no LCD
                CALL    ActualizarLCD

                POP     R4
                POP     R1
                RET

;
; Limpa Nave
;   Rotina que limpa a nave da janela.
;
;   Entrada:
;       Enderecamento M[PosicaoNave] - Posicao da nave
;       Caracteres - KeySpace
;
LimpaNave:      PUSH    R3
                PUSH    R4

                ; Posicao e caractere de limpeza
                MOV     R3, KeySpace
                MOV     R4, M[PosicaoNave]

                ; Limpa nariz
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R3
                ; Limpa corpo
                DEC     R4
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R3
                ; Limpa asa esquerda
                SUB     R4, 0100h
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R3
                ; Limpa asa direita
                ADD     R4, 0200h
                MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R3

                POP     R4
                POP     R3
                RET

;
; Limpa Objecto
;   Rotina para remover a representacao de um objecto na janela.
;
;   Entrada:
;       Stack P3 - Posicao a limpar
;       Caractere - KeySpace
;
LimpaObjecto:   PUSH    R1  ; Caractere de limpeza
                PUSH    R2  ; Posicao a limpar
                MOV     R1, KeySpace
                MOV     R2, M[SP+4]

                ; Limpa posicao
                MOV     M[ControloJanela], R2
                MOV     M[EscritaJanela], R1

                POP     R2
                POP     R1
                RETN    1

;
; Escreve Explosao
;   Rotina para inserir uma explosao na pilha e na janela.
;
;   Entrada:
;       Stack P3 - Posicao a escrever
;       Caractere - KeyCross
;
EscExplosao:    PUSH    R1  ; Caractere de explosao
                PUSH    R2  ; Posicao a escrever
                MOV     R1, KeyCross
                MOV     R2, M[SP+4]

                ; Coloca explosao
                MOV     M[ControloJanela], R2
                MOV     M[EscritaJanela], R1

                ADD     R2, 8000h
                PUSH    R2
                CALL    PushObjStack

                POP     R2
                POP     R1
                RETN    1


;------------------------------------------------------------------------------;
; ESCRITA NO LCD                                                               ;
;------------------------------------------------------------------------------;

;
; Escrever Posicao no LCD
;   Rotina que escreve o valor da linha e da coluna, em base decimal, no LCD.
;
;   Entrada:
;       Caractere - KeySpace, StopStr
;       Mensagens - MsgLCDLinha, MsgLCDColuna
;
ResetLCD:       PUSH    R1  ; Cursor do LCD
                PUSH    R2
                PUSH    R3

                MOV     R1, 0200h
                MOV     R3, KeySpace
CleanLCD:       MOV     M[ControloLCD], R1
                MOV     M[EscritaLCD], R3
                INC     R1
                CMP     R1, 0220h
                BR.NZ   CleanLCD

                ; Escrever legenda linhas
                MOV     R1, 8000h
                MOV     R2, MsgLCDLinha
                MOV     R3, M[R2]
CicloLCD1:      MOV     M[ControloLCD], R1
                MOV     M[EscritaLCD], R3
                INC     R1
                INC     R2
                MOV     R3, M[R2]
                CMP     R3, StopStr
                BR.NZ   CicloLCD1

                ; Escrever legenda linhas
                MOV     R1, 8010h
                MOV     R2, MsgLCDColuna
                MOV     R3, M[R2]
CicloLCD2:      MOV     M[ControloLCD], R1
                MOV     M[EscritaLCD], R3
                INC     R1
                INC     R2
                MOV     R3, M[R2]
                CMP     R3, StopStr
                BR.NZ   CicloLCD2

                POP     R3
                POP     R2
                POP     R1
                RET

;
; Escrever Posicao no LCD
;   Rotina que escreve o valor da linha e da coluna, em base decimal, no LCD.
;
;   Entrada:
;       Enderecamento M[PosicaoNave] - Posicao actual da nave.
;
ActualizarLCD:  PUSH    R1
                PUSH    R2
                PUSH    R3

                ; Linha
                MOV     R2, 000Ah
                MOV     R1, 8008h
                MOV     M[ControloLCD], R1
                MVBH    R3, M[PosicaoNave]
                SHR     R3, 8
                DIV     R3, R2
                ADD     R3, 30h     ; Transforma em ASCII
                ADD     R2, 30h     ; Transforma em ASCII
                MOV     M[EscritaLCD], R2
                DEC     R1
                MOV     M[ControloLCD], R1
                MOV     M[EscritaLCD], R3

                ; Coluna
                MOV     R2, 000Ah
                MOV     R1, 8018h
                MOV     M[ControloLCD], R1
                MVBL    R3, M[PosicaoNave]
                DIV     R3, R2      ; Converte em decimal
                ADD     R3, 30h
                ADD     R2, 30h
                MOV     M[EscritaLCD], R2
                DEC     R1
                MOV     M[ControloLCD], R1
                MOV     M[EscritaLCD], R3

                POP     R3
                POP     R2
                POP     R1
                RET


;------------------------------------------------------------------------------;
; ESCRITA NO DISPLAY                                                           ;
;------------------------------------------------------------------------------;

;
; EscreveCont
;   Rotina que efectua a escrita do contador
;
;   Entrada:
;       EntradaDisplay - Porto de escrita
;       M[ContaPontos] - Pontos do jogador
;
DisplayCont:    PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4
                PUSH    R5

                MOV     R3, EntradaDisplay
                MOV     R1, M[ContaPontos]
CicloDisplay:   MOV     R2, 000Ah
                DIV     R1, R2
                MOV     M[R3], R2
                INC     R3
                CMP     R1, R0
                BR.NZ   CicloDisplay

                POP     R5
                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;
; Limpar Display
;   Rotina que coloca a pontuacao a zero para um novo jogo.
;
;   Entrada:
;       NUM_NIBBLES
;       EntradaDisplay - Porto de escrita
;
DisplayZero:    PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4
                PUSH    R5

                MOV     R2, NUM_NIBBLES
                MOV     R3, EntradaDisplay
CicloDisZero:   MOV     M[R3], R0
                INC     R3
                DEC     R2
                BR.NZ   CicloDisZero

                POP     R5
                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------;
; ACTIVACAO DOS LEDS                                                           ;
;------------------------------------------------------------------------------;

;
; Incrementar Pontuacao
;   Rotina que incrementa a pontuacao ao mesmo tempo que executa um "flash" dos
;   LEDs do P3.
;
;   Saida:
;       M[ContaPontos] - Pontos actualizados
;
IncrementaPont: PUSH    R1

                ; Incrementa o contador e o display
                INC     M[ContaPontos]
                CALL    DisplayCont

                ; LEDs ON
                MOV     R1, FFFFh
                MOV     M[EscritaLED], R1

                POP     R1
                RET



;------------------------------------------------------------------------------;
; OPERACOES DA PILHA DE OBJECTOS                                               ;
;------------------------------------------------------------------------------;

;
; Push para a Stack de Objectos
;   Introduz um elemento na stack reservada a objectos '*', 'o' e '-'.
;
;   Entrada:
;       Stack P3 - Objecto a inserir
;       M[ObjSP] - Pointer da pilha de objectos
;
PushObjStack:   PUSH    R1
                PUSH    R2

                ; Obter objecto codificado com tipo e posicao
                MOV     R1, M[SP+4]

                ; Coloca objecto na posicao livre seguinte
                MOV     R2, M[ObjSP]
                MOV     M[R2], R1
                INC     M[ObjSP]

                POP     R2
                POP     R1
                RETN    1

;
; Pop da Stack de Objectos
;   Altera o ObjSP para um valor inferior por uma unidade.
;
;   Saida:
;       M[ObjSP] - Pointer da pilha de objectos actualizado.
;
PopObjStack:    DEC     M[ObjSP]
                RET

;
; Remove Objecto da Pilha
;   Entrada:
;       Stack P3 - Objecto a remover
;       M[ObjSP] - Pointer da pilha de objectos
;
RemoveObjStack: PUSH    R1      ; Indice do ultimo objecto da pilha
                PUSH    R2      ; Indice do objecto a remover

                MOV     R1, M[ObjSP]
                DEC     R1
                MOV     R2, M[SP+4]

                ; Troca o objecto do topo da pilha pelo a remover
                ; Apenas se este nao estiver no topo da pilha
                CMP     R1, R2
                BR.Z    FinalPop
                MOV     R1, M[R1]
                MOV     M[R2], R1

                ; Pop the last object
FinalPop:       CALL    PopObjStack
                POP     R2
                POP     R1
                RETN    1

;------------------------------------------------------------------------------;
; ROTINAS DO TEMPO                                                             ;
;------------------------------------------------------------------------------;

;
; Move Tempo
;   Rotina que coordena todas as operacoes a realizar num determinado ciclo de
;   tempo.
;
;   Saida:
;       M[ContaEspaco] - Espacos desde o ultimo astro.
;
MoveTempo:      PUSH    R1

                ; LEDs OFF
                MOV     R1, R0
                MOV     M[EscritaLED], R1

                ; Activa/desactiva movimentacao de obj
                MOV     R1, 0001h
                XOR     M[MoveAstros], R1

                ; Mover todos os objectos da pilha de objectos
                CALL    MoveObjectos

                ; Disparar, se tiver sido accionado
                CMP     M[Disparo], R0
                CALL.NZ Disparar

                ; Inserir astro se estiver espacado o suficiente
                MOV     R1, M[ContaEspaco]
                CMP     R1, 0006h
                CALL.Z  InserirAstro
                ; Incrementa separador de obj.
                CMP     M[MoveAstros], R0
                BR.Z    SairTempo
                INC     M[ContaEspaco]

                ; Remover objetos por colisoes
SairTempo:      CALL    ColisaoObjs
                ; Determina se ocorrem colisoes com a nave
                CALL    ColisaoNave

                POP     R1
                RET

;
; Mover Objectos
;   Rotina de mover todos os objectos presentes na pilha.
;
;   Entrada:
;       M[ObjSP] - Pointer da pilha de objectos
;       ObjectStack
;   Saida:
;       M[Tempo] - Ciclos de tempo a realizar actualizado.
;
MoveObjectos:   PUSH    R1              ; Usado para SP dos Objectos
                PUSH    R2              ; Usado para posicao do objecto
                PUSH    R3

                DEC     M[Tempo]        ; Remove uma iteracao do tempo
                MOV     R1, M[ObjSP]    ; SP Objectos actual (primeira livre)

                ; Percorrer pilha de objectos
CicloObjectos:  CMP     R1, ObjectStack
                JMP.Z   SairMoveObj

                ; Selecciona o objecto seguinte da pilha
                DEC     R1
                MOV     R2, M[R1]

                ; Remove explosoes
                MOV     R3, R2
                ROLC    R3, 1
                BR.NC   TesteTiros
                SHR     R3, 1
                PUSH    R3
                CALL    LimpaObjecto
                PUSH    R1
                CALL    RemoveObjStack
                JMP     CicloObjectos

                ; Se for tiro, mover tiro
TesteTiros:     CMP     R2, 174Fh
                BR.NN   TesteAstros
                CALL    MoverTiro
                JMP     CicloObjectos

                ; Mexe astros se for um ciclo de movimento de astros
TesteAstros:    CMP     M[MoveAstros], R0  ; Mover astros activo?
                CALL.NZ MoverAstros
                JMP     CicloObjectos

SairMoveObj:    POP     R3
                POP     R2
                POP     R1
                RET

;
; Move Tiro
;   Rotina que move um tiro para a posicao seguinte a direita.
;
MoverTiro:      PUSH    R3

                ; Limpa objecto da janela
                PUSH    R2
                CALL    LimpaObjecto

                ; E possivelescrevr a nova posicao na janela?
                INC     R2
                MOV     R3, R2
                AND     R3, 00FFh
                CMP     R3, 004Eh
                BR.P    RemoveTiro      ; Sair caso nao seja

                ; Escrever tiro na janela
                MOV     R3, Tiro
                MOV     M[ControloJanela], R2
                MOV     M[EscritaJanela], R3

                ; Actualizar posicao na pilha
                MOV     M[R1], R2

                POP     R3
                RET

                ; Remove objecto da pilha
RemoveTiro:     PUSH    R1      ; Passa valor do indice da pilha
                CALL    RemoveObjStack
                POP     R3
                RET

;
; Move astros
;   Rotina que move um astro para a posicao seguinte a esquerda.
;
MoverAstros:    PUSH    R3
                PUSH    R4  ; Posicao do obj.
                PUSH    R5  ; Tipo do obj.

                ; Obter posicao
                MOV     R4, R2
                AND     R4, 1FFFh

                ; Limpa objecto da janela
                PUSH    R4
                CALL    LimpaObjecto

                ; Valida se pode ser escrito numa posicao anterior
                DEC     R4
                MOV     R3, R4
                AND     R3, 00FFh
                CMP     R3, R0
                BR.Z    RemoveAstro

                ; Obter tipo
                MOV     R5, R2
                AND     R5, E000h
                CMP     R5, 2000h
                BR.Z    AstroAsteroide
                MOV     R3, Buraco
                BR      EscreverAstro
AstroAsteroide: MOV     R3, Asteroide

                ; Escreve na posicao nova
EscreverAstro:  MOV     M[ControloJanela], R4
                MOV     M[EscritaJanela], R3

                ; Actualiza o valor na pilha
                DEC     R2
                MOV     M[R1], R2

                POP     R5
                POP     R4
                POP     R3
                RET

RemoveAstro:    PUSH    R1      ; Passa valor do indice da pilha
                CALL    RemoveObjStack
                POP     R5
                POP     R4
                POP     R3
                RET


;
; Inserir astros
;   Rotina que insere astro na janela e na pilha.
;
;   Entrada:
;       M[NumAleNorm] - Numero aleatorio normalizado para a dimensao da janela.
;
;   Saida:
;       M[ContaAsteroide] - Conta os asteroides inseridos para saber quando
;                           colocar um buraco negro.
;
InserirAstro:   PUSH    R1
                PUSH    R2  ; Posicao
                PUSH    R3  ; Tipo de obj. ('*' ou 'o')

                ; Reset do contador de espacamento
                MOV     M[ContaEspaco], R0

                ; Obter posicao em linha aleatoria
                MOV     R1, 004Eh
                MOV     R2, M[NumAleNorm]
                ROR     R2, 8
                MVBH    R1, R2
                MOV     R2, R1

                ; Obter tipo
                MOV     R3, M[ContaAsteroide]
                CMP     R3, 0003h
                BR.Z    InserirBuraco
                MOV     R1, Asteroide
                MOV     R3, 2000h
                INC     M[ContaAsteroide]
                BR      InsereAstro
InserirBuraco:  MOV     R1, Buraco
                MOV     R3, 4000h
                MOV     M[ContaAsteroide], R0

                ; Escrever na janela
InsereAstro:    MOV     M[ControloJanela], R2
                MOV     M[EscritaJanela], R1
                ADD     R2, R3
                PUSH    R2
                CALL    PushObjStack

                MOV     M[ContaEspaco], R0 ; Reset do contador
                POP     R3
                POP     R2
                POP     R1
                RET


;
; Disparar um tiro do "nariz"
;   Rotina que cria o objecto tiro, escreve na janela e insere na pilha de
;   objectos.
;
;   Entrada:
;       M[PosicaoNave] - Posicao actual da nave.
;
Disparar:       PUSH    R1                      ; Posicao da nave
                MOV     M[Disparo], R0
                MOV     R1, M[PosicaoNave]
                INC     R1

                ; Meter tiro na stack de objectos
                PUSH    R1
                CALL    PushObjStack
                ; Escrever tiro na janela
                MOV     M[ControloJanela], R1
                MOV     R1, Tiro
                MOV     M[EscritaJanela], R1

                POP     R1
                RET


;------------------------------------------------------------------------------;
; CALCULO DE COLISOES                                                          ;
;------------------------------------------------------------------------------;

;
; Colisoes nave
;   Rotina que determina se ha alguma colisao da nave com um objecto.
;
;   Entrada:
;       M[ObjSP] - Pointer da pilha de objectos.
;       M[PosicaoNave] - Posicao actual da nave.
;       ObjectStack
;
ColisaoNave:    PUSH    R1  ; Iterador da pilha de objectos
                PUSH    R2  ; Posicao da nave
                PUSH    R3  ; Posicao do objecto
                PUSH    R4
                PUSH    R5

                MOV     R1, M[ObjSP]
                MOV     R2, M[PosicaoNave]
CicloColNave:   CMP     R1, ObjectStack
                JMP.Z   SairColNave
                DEC     R1
                MOV     R3, M[R1]
                AND     R3, 1FFFh   ; Remove o tipo ficando so a posicao
                CMP     R2, R3
                JMP.Z   GameOver
                MOV     R4, R0
                MOV     R5, R0
                MVBL    R4, R2      ; Coluna Nave
                MVBL    R5, R3      ; Coluna Obj.
                DEC     R4
                CMP     R4, R5
                BR.NZ   CicloColNave

                ; Verificar se ha colisao no corpo e asas
                MOV     R4, R0
                MOV     R5, R0
                MVBH    R4, R2      ; Linha Nave
                MVBH    R5, R3      ; Linha Obj.
                SUB     R4, 0100h   ; Seleccionar linha da asa esquerda
                CMP     R5, R4
                JMP.Z   GameOver
                BR.N    CicloColNave
                ADD     R4, 0200h   ; Seleccionar linha da asa direita
                CMP     R5, R4
                JMP.Z   GameOver
                JMP.N   GameOver
                JMP     CicloColNave

SairColNave:    POP     R5
                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;
; Colisao entre Objectos
;   Entradas:
;       Stack P3 - nova posicao+tipo do objecto de referencia
;       Stack P3 - indice do objecto de referencia
;       M[ObjSP] - Pointer da pilha de objectos.
;       ObjectStack
;   Saidas:
;       Stack P3 - posicao+tipo inalterado ou 0, caso seja destruido
;
ColisaoObjs:    PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4
                PUSH    R5
                PUSH    R6
                PUSH    R7

                ; Indice da pilha de obj. para referencia
                MOV     R6, M[ObjSP]

CicloRef:       CMP     R6, ObjectStack
                JMP.Z   SairColObjs

                DEC     R6
                MOV     R1, M[ObjSP]

                ; Obter posicao e tipo do obj. de referencia
                MOV     R2, M[R6]
                MOV     R3, R2
                AND     R2, E000h   ; Tipo
                AND     R3, 1FFFh   ; Posicao

                ; Comparar apenas referencias que sao tiros
                CMP     R2, R0
                BR.NZ   CicloRef

CicloComp:      CMP     R1, ObjectStack
                JMP.Z   CicloRef

                DEC     R1

                ; Obter posicao e tipo do obj. de comparacao
                MOV     R4, M[R1]
                MOV     R5, R4
                AND     R4, E000h
                AND     R5, 1FFFh

                ; Saltar obj. se for do mesmo tipo (ambos tiro)
                CMP     R2, R4
                JMP.Z   CicloComp

                ; Verificar se ha colisao
                MOV     R7, R5
                SUB     R7, R3
                CMP     R7, R0
                BR.Z    DestroiObj
                DEC     R7
                CMP     R7, R0
                JMP.NZ  CicloComp

                ; Destroi referencia
DestroiObj:     PUSH    R6
                CALL    RemoveObjStack
                PUSH    R3
                CALL    LimpaObjecto
                ; Verifica se comparacao e asteroide, se sim, destroi
                CMP     R4, 2000h
                JMP.NZ  CicloRef

                ; Incrementar pontuacao
                CALL    IncrementaPont
                PUSH    R1
                CALL    RemoveObjStack
                PUSH    R5
                CALL    LimpaObjecto

                ; Escrever Explosao
                PUSH    R5
                CALL    EscExplosao
                JMP     CicloRef

SairColObjs:    POP     R7
                POP     R6
                POP     R5
                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;
; Game Over
;   Rotina de fim de jogo, altera a "flag" que indica que o jogador perdeu e
;   retorna ao inicio do jogo.
;
;   Saida:
;       M[IsGameOver] - 0001h a indicar que o jogo terminou com derrota.
;       M[HighScore] - HighScore actualizado.
;
GameOver:       PUSH    R1
                MOV     R1, 0001h
                MOV     M[IsGameOver], R1

                ; Actualiza HighScore
                MOV     R1, M[ContaPontos]
                CMP     R1, M[HighScore]
                BR.NP   SairGameOver
                MOV     M[HighScore], R1

SairGameOver:   POP     R1
                JMP     Reinicio

;------------------------------------------------------------------------------;
; CALCULO DE POSICOES                                                          ;
;------------------------------------------------------------------------------;

;
; Move posicao da nave para cima
;
MoveCima:       PUSH    R1

                ; Verifica existencia de espaco para movimentar
                MOV     R1, M[PosicaoNave]
                SUB     R1, 0100h
                CMP     R1, 0201h
                BR.N    ResetCima

                ; Rescreve nave na nova posicao
                CALL    LimpaNave
                MOV     M[PosicaoNave], R1
                CALL    PintaNave

                ; Decrementa movimentos para cima
                DEC     M[Cima]
                BR      SairMoveCima

                ; Impede acumulacao de movimentos sem espaco para executar
ResetCima:      MOV     M[Cima], R0

SairMoveCima:   POP     R1
                RET

;
; Move posicao da nave para baixo
;
MoveBaixo:      PUSH    R1

                ; Verifica existencia de espaco para movimentar
                MOV     R1, M[PosicaoNave]
                ADD     R1, 0100h
                CMP     R1, 154Eh
                BR.P    ResetBaixo

                ; Rescreve nave na nova posicao
                CALL    LimpaNave
                MOV     M[PosicaoNave], R1
                CALL    PintaNave

                ; Decrementa movimentos para Baixo
                DEC     M[Baixo]
                BR      SairMoveBaixo

                ; Impede acumulacao de movimentos sem espaco para executar
ResetBaixo:     MOV     M[Baixo], R0

SairMoveBaixo:  POP     R1
                RET

;
; Move posicao da nave para esquerda
;
MoveEsquerda:   PUSH    R1
                PUSH    R2

                ; Verifica existencia de espaco para movimentar
                MOV     R2, R0
                MOV     R1, M[PosicaoNave]
                MVBH    R2, R1
                INC     R2
                DEC     R1
                CMP     R1, R2
                BR.N    ResetEsq

                ; Rescreve nave na nova posicao
                CALL    LimpaNave
                MOV     M[PosicaoNave], R1
                CALL    PintaNave

                ; Decrementa movimentos para Esquerda
                DEC     M[Esquerda]
                BR      SairMoveEsq

                ; Impede acumulacao de movimentos sem espaco para executar
ResetEsq:       MOV     M[Esquerda], R0

SairMoveEsq:    POP     R2
                POP     R1
                RET

;
; Move posicao da nave para direita
;
MoveDireita:    PUSH    R1
                PUSH    R2

                ; Verifica existencia de espaco para movimentar
                MOV     R2, 004Eh
                MOV     R1, M[PosicaoNave]
                MVBH    R2, R1
                INC     R1
                CMP     R2, R1
                BR.N    ResetDireita

                ; Rescreve nave na nova posicao
                CALL    LimpaNave
                MOV     M[PosicaoNave], R1
                CALL    PintaNave

                ; Decrementa movimentos para Direita
                DEC     M[Direita]
                BR      SairMoveDir

                ; Impede acumulacao de movimentos sem espaco para executar
ResetDireita:   MOV     M[Direita], R0

SairMoveDir:    POP     R2
                POP     R1
                RET


;------------------------------------------------------------------------------;
; PROGRAMA PRINCIPAL                                                           ;
;------------------------------------------------------------------------------;

                ; Limpa a memoria do highscore de uma sessao anterior
Inicio:         MOV     M[HighScore], R0

Reinicio:       MOV     R7, SP_INIC           ; Inicializar Stack Pointer
                MOV     SP, R7
                MOV     R7, INIT_MASK         ; Inicializar mascara
                MOV     M[INIT_MASK_ADDR], R7

                CALL    SplashScreen
                ENI

GameLoop:       CMP     M[Cima], R0           ; Existem movimentos para cima?
                CALL.NZ MoveCima

                CMP     M[Baixo], R0          ; Existem movimentos para baixo?
                CALL.NZ MoveBaixo

                CMP     M[Esquerda], R0       ; Existem movimentos para a esquerda?
                CALL.NZ MoveEsquerda

                CMP     M[Direita], R0        ; Existem movimentos para a direita?
                CALL.NZ MoveDireita

                CMP     M[Tempo], R0          ; Andar no tempo?
                CALL.NZ MoveTempo

                CALL    GeradorNum            ; Gerador de numeros

                JMP     GameLoop

Fim:            BR      Fim
