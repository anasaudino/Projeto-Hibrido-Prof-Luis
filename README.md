# Projeto Híbrido

Jogo single-player de **terror psicológico, ficção científica e ação** feito no **Roblox Studio**, desenvolvido para a disciplina de Desenvolvimento de Jogos (2026).

Jane, um garoto de 13 anos mantido como cobaia em um laboratório secreto, desperta sozinho depois de um ataque de seres de outra dimensão. Ao longo de um prólogo e cinco capítulos, ele remove as sete pedras do sistema que suprimia seus poderes, enfrenta a força militar que veio recuperá-lo e descobre que o ataque foi, na verdade, um resgate — e quem são seus pais.

**Equipe:** Ana Luiza Saudino Bispo de Souza · Mateus Felipe Sbaraglini Saluceste · Emanuel Sandoval · Luigi Stangherlin

---

## Conteúdo do repositório

| Caminho | O que é |
|---|---|
| [`jogo/Projeto Hibrido - Jogo.rbxl`](jogo/) | **O jogo completo** (mapa, personagens, interface e scripts). É este arquivo que se abre no Roblox Studio. |
| [`docs/GDD Projeto Hibrido.pdf`](docs/) | Game Design Document atualizado, nas normas da ABNT, com a história de começo, meio e fim. |
| [`src/`](src/) | Cópia de leitura de todos os 32 scripts do jogo, na mesma estrutura do Explorer do Studio. |

> A pasta `src/` serve para ler e revisar o código no GitHub. **O jogo roda a partir do `.rbxl`**: alterar um arquivo em `src/` não muda o jogo.

---

## Requisitos

- **Roblox Studio** instalado (gratuito): <https://create.roblox.com/docs/studio/setup>
- **Conta Roblox** para entrar no Studio.
- **Computador Windows ou macOS** com **teclado e mouse**. O jogo não foi feito para celular nem para controle.
- Placa de vídeo comum já basta. Se o jogo ficar lento, abaixe a qualidade gráfica do Studio em *File → Studio Settings → Rendering*.

Não é preciso instalar nada além do Roblox Studio. O jogo não usa plugins nem pacotes externos.

---

## Como abrir e jogar

1. Baixe o repositório: botão **Code → Download ZIP** no GitHub, ou `git clone`.
2. Abra o **Roblox Studio** e entre com a sua conta.
3. Vá em **File → Open from File…** e escolha `jogo/Projeto Hibrido - Jogo.rbxl`.
4. Clique em **Play** (ou aperte **F5**).
5. No menu inicial, clique em **NOVO JOGO**.
6. Para sair do teste, clique em **Stop** (ou aperte **Shift+F5**).

A campanha completa leva entre 60 e 90 minutos. Use fones de ouvido: o som faz parte do terror.

### Sobre o save

O progresso (capítulo, pedras, Essência e Árvore da Mente) é salvo no **DataStore** do Roblox, que só funciona em jogos **publicados**. Abrindo o `.rbxl` direto do arquivo, o jogo funciona normalmente, mas **o progresso não é guardado entre uma sessão e outra**: é preciso jogar do começo a cada Play.

Para testar o save: publique o place na sua conta (*File → Publish to Roblox*) e ative *Game Settings → Security → Enable Studio Access to API Services*.

---

## Controles

| Tecla | Ação | Disponível a partir de |
|---|---|---|
| W A S D | Andar | início |
| Espaço | Pular | início |
| Mouse | Olhar em volta | início |
| E | Interagir, ler documentos (no final, segurar para estabilizar o portal) | início |
| Clique esquerdo | Pulso telecinético (segurar = rajada) | Pedra 1 |
| F | Onda (explosão em área) | Pedra 2 |
| R | Levitar objetos; depois, erguer e arremessar soldados | Pedra 4 |
| G | Eco (revela inimigos, memórias e números escondidos) | Pedra 5 |
| Q | Dash | nó "Salto Psíquico" da Árvore |
| V | Ultimate "Colapso Psíquico" | medidor cheio |
| T | Árvore da Mente | início |
| 1 2 3 | Escolher mutação | depois de ondas e chefes |
| **P** | **Pausa** (Arquivos, volume, legendas, câmera) | início |

> A pausa é no **P**: dentro do Studio, o **Esc** é usado pelo próprio Roblox.

O movimento realista da câmera (inclinação ao virar, balanço dos passos) pode ser desligado em *Configurações* no menu inicial ou em *Câmera* na pausa.

---

## Estrutura da história

| Ato | Capítulos | O que acontece |
|---|---|---|
| **Começo** | Prólogo e Cap. 1 — O Último Sujeito | O ataque, o despertar na câmara B2, a Ala Infantil vazia, a 1ª pedra e a primeira arena (SENTINELA-01). |
| **Meio** | Cap. 2 — O Projeto · Cap. 3 — Recuperação · Cap. 4 — A Diretora | O Programa Híbrido, a perseguição de Vael, a memória do resgate e a revelação: Evelyn Carter é a mãe de Jane e Vael é o pai. |
| **Fim** | Cap. 5 — O Vigia · Final — Entre Dois Mundos | Vael reconhece o filho, a 7ª pedra, a batalha contra a Comandante Ward no exotraje ARGOS e a travessia do portal. Cena pós-créditos. |

Os detalhes completos (personagens, cenários, mecânicas, chefes, mutações e Árvore da Mente) estão no [GDD](docs/).

---

## Organização do código

O jogo segue a separação padrão do Roblox entre servidor e cliente:

```
src/
├── ServerScriptService/        scripts do servidor (rodam ao iniciar o jogo)
│   ├── Jogo                    orquestrador da campanha: menu, fases, checkpoints, cutscenes, reset do mundo
│   ├── CombateServer           poderes de Jane, arenas, chefes, mutações e Árvore da Mente
│   └── PortasFase              portas trancadas/abertas por fase
├── ServerStorage/              módulos do servidor (o cliente não enxerga)
│   ├── Jogo/Fases/Fase1..5     ações, gatilhos e objetivos de cada capítulo
│   ├── Jogo/Vael               aparições roteirizadas do Vael
│   ├── CombateSrv/Inimigos     IA e dano dos inimigos
│   ├── CombateSrv/Tipos/*      comportamento de cada tipo especial e chefe
│   ├── CombateSrv/Meta         progresso permanente e save (DataStore)
│   ├── Ferramentas/Kit         kit usado para construir os mapas por script (só no Studio)
│   └── MapaAntigo/…            controlador de portas do mapa antigo (fora de uso, guardado como referência)
├── ReplicatedStorage/          módulos compartilhados entre servidor e cliente
│   ├── Jogo/Textos             TODOS os textos da história: documentos, gravações, rádio e créditos
│   ├── Combate/Config          números de balanceamento (vida, dano, recargas, mutações, Árvore)
│   ├── Combate/Arenas          definição das arenas por fase (ondas, chefe, portas)
│   └── Combate/VFX             efeitos visuais dos poderes
├── StarterGui/                 interface (LocalScripts)
│   ├── HUD_Historia/Historia   menu inicial, pausa, documentos, legendas, cutscenes e créditos
│   ├── HUD_Combate/HUD         vida, foco, poderes, cartas de mutação e Árvore da Mente
│   └── HUD_Objetivo/…          caixa de objetivo no canto da tela
└── StarterPlayer/
    ├── StarterPlayerScripts/   CombateClient (entrada dos poderes), CameraRealista, PortasClient, LuzesPiscando
    └── StarterCharacterScripts/Health
```

Extensões em `src/`: `.server.lua` = Script (servidor), `.client.lua` = LocalScript (cliente), `.lua` = ModuleScript.

Para mexer na história ou no balanceamento sem tocar na lógica, os pontos de entrada são `ReplicatedStorage/Jogo/Textos` e `ReplicatedStorage/Combate/Config`.

---

## Atalhos para testar (só no Studio)

Para pular direto para um capítulo durante o teste:

1. Aperte **Play** e passe do menu inicial.
2. Na aba **Test**, troque a visão de **Client** para **Server**.
3. Na **Command Bar** (*View → Command Bar*), rode, por exemplo:

```lua
game.ServerStorage.DebugJogo:Invoke("fase", nil, 3)   -- vai para o Capítulo 3 com as pedras dos capítulos anteriores
```

Esses comandos só existem dentro do Studio (`RunService:IsStudio()`) e não ficam disponíveis no jogo publicado.
