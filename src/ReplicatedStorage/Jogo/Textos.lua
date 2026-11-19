-- TODOS os textos da historia. Editem a vontade (mantenham os ids).
local T = {}

T.Titulo = "PROJETO HÍBRIDO"
T.Subtitulo = "título provisório"
T.Equipe = { "Ana Luiza Saudino Bispo de Souza", "Mateus Felipe Sbaraglini Saluceste", "Emanuel Sandoval", "Luigi Stangherlin" }
T.Disciplina = "Desenvolvimento de Jogos — 2026"

T.Capitulos = {
	[1] = { "PRÓLOGO / CAPÍTULO 1", "O ÚLTIMO SUJEITO" },
	[2] = { "CAPÍTULO 2", "O PROJETO" },
	[3] = { "CAPÍTULO 3", "RECUPERAÇÃO" },
	[4] = { "CAPÍTULO 4", "A DIRETORA" },
	[5] = { "CAPÍTULO 5", "O VIGIA" },
}

-- ===== DOCUMENTOS =====
T.Docs = {
	f1_protocolo = { titulo = "Protocolo de Contenção — Ala C", data = "03/02/1986", autor = "Setor de Neurocinética",
		texto = "1. Os sujeitos da Ala C devem ser chamados SOMENTE pelo código de identificação.\n2. Desenhos e objetos pessoais são permitidos desde que não façam referência ao local de origem.\n3. Qualquer menção a \"pais\", \"casa\" ou \"voltar\" deve ser registrada e reportada à Dra. Carter.\n4. O sujeito JANE-01 NÃO participa das atividades coletivas. Isolamento permanente no subnível B2.\n\nA supressão é para o bem deles." },
	f1_incidente = { titulo = "Relatório de Incidente 0417", data = "12/09/1985", autor = "Segurança — Turno C",
		texto = "Durante a troca de turno, três sujeitos da Ala C foram encontrados de mãos dadas diante da porta de contenção, voltados para o subnível.\nQuando perguntados, responderam em uníssono: \"ele está sozinho lá embaixo\".\n\nA Dra. Carter ordenou reforço no campo de supressão do B2. Nenhuma outra explicação foi registrada." },
	f2_programa = { titulo = "Programa de Hibridização — Resumo", data = "CLASSIFICADO", autor = "Dr. Marcus Hale",
		texto = "Seres da outra dimensão não sobrevivem indefinidamente em nosso mundo. Humanos expostos diretamente à energia do portal adoecem.\n\nObjetivo: produzir um organismo viável nos DOIS ambientes. Uma ponte.\n\nResultado: um único sucesso. Código JANE-01.\nRecomendação: manter o sujeito sob supressão contínua até a fase II." },
	f2_prontuario = { titulo = "Prontuário — JANE-01", data = "Atualizado 11/03/1986", autor = "Enfermaria B2",
		texto = "Idade aparente: 13 anos.\nMassa corporal: abaixo do esperado (sedação prolongada).\nMarcas de sensores: braços e pescoço.\n\nOrigem materna: HUMANA.\nOrigem paterna: EXTRADIMENSIONAL.\n\nSEÇÃO \"GENITORES\" — ACESSO RESTRITO (nível acima de Diretoria)." },
	f2_nota_carter = { titulo = "Nota interna — Dra. E. Carter", data = "02/03/1986", autor = "Evelyn Carter",
		texto = "Reitero pela quinta vez: JANE-01 é o sujeito mais instável desta instalação.\nDeve permanecer sedado sempre que não estiver em teste.\n\nNão me peçam para esquecer o que aconteceu com o Simon." },
	f3_tecnico = { titulo = "Diário do técnico de manutenção", data = "Noite do ataque", autor = "R. Ortiz",
		texto = "Os geradores caíram às 22h40. Ouvi passos no teto. Grandes demais pra ser gente.\n\nUma delas passou por mim no corredor. Não me atacou. Olhou pra mim... e seguiu pro Setor de Contenção.\nJuro que ela carregava uma criança no colo como se fosse filho dela." },
	f3_ordem = { titulo = "Ordem de Serviço — Recuperação", data = "HOJE", autor = "Cmd. Rebecca Ward",
		texto = "Prioridade 1: recuperar JANE-01 VIVO.\nPrioridade 2: recolher ou destruir todos os registros do Programa Híbrido.\nPrioridade 3: eliminar qualquer entidade dimensional remanescente.\n\nAutorizado o uso de força contra o sujeito, desde que não letal." },
	f4_autorizacoes = { titulo = "Autorizações assinadas — E. Carter", data = "1985–1986", autor = "Diretoria",
		texto = "— Aumento da sedação do JANE-01: APROVADO.\n— Reforço do campo de supressão B2: APROVADO.\n— Solicitação de transferência do sujeito: NEGADA pelo Dr. Hale.\n— Solicitação de ENCERRAMENTO do sujeito: NEGADA pelo Dr. Hale.\n\nObservação de Hale, à mão: \"Ela não sabe. E não pode saber.\"" },
	f4_reeve = { titulo = "Relatório do Teste 22 — Dr. Simon Reeve", data = "14/08/1984", autor = "Simon Reeve",
		texto = "Solicito interrupção imediata do teste de sobrecarga. O sujeito está chorando e pedindo para parar.\nOs sinais vitais estão fora do limite.\n\n[anotação posterior] Pedido negado por M. Hale. Teste continuado.\n\n[laudo] Óbito do Dr. Reeve por descarga telecinética às 16h02." },
	f4_codigo_a = { titulo = "Arquivo Genético — Acesso (parte 1)", data = "—", autor = "Sistema", texto = "Código de acesso do arquivo genético, primeira metade:\n\n(Os números só aparecem sob o ECO)", eco = "7 3" },
	f4_codigo_b = { titulo = "Arquivo Genético — Acesso (parte 2)", data = "—", autor = "Sistema", texto = "Código de acesso do arquivo genético, segunda metade:\n\n(Os números só aparecem sob o ECO)", eco = "1 9" },
	f4_genetico = { titulo = "PROCEDÊNCIA GENÉTICA — JANE-01", data = "SIGILO MÁXIMO", autor = "Programa Híbrido",
		texto = "CÓDIGO PATERNO: entidade adulta capturada nº 1 — designação VAEL.\n\nCÓDIGO MATERNO: CARTER, EVELYN M.\n\nMaterial obtido pelo programa de preservação genética de funcionários expostos à radiação dimensional. Doadora NÃO informada. Amostra registrada como \"inutilizada\".\n\nAcesso bloqueado a todos os diretores da ala de testes." },
	f5_fase2 = { titulo = "PROGRAMA HÍBRIDO — FASE II", data = "—", autor = "—", texto = "Sujeitos em gestação: 3.\nLocal: Instalação 9.\n\n[registros parcialmente apagados]" },
}

-- ===== GRAVACOES (legendas em sequencia) =====
-- cada fala: { quem, texto, segundos }
T.Gravacoes = {
	f1_ataque = {
		{ "GRAVAÇÃO 03:12", "[Câmera 7 — Corredor da Ala C]", 2.5 },
		{ "GRAVAÇÃO 03:12", "Figuras altas atravessam o corredor. Elas não atacam os guardas que fogem.", 4 },
		{ "GRAVAÇÃO 03:12", "Uma delas arranca a porta do dormitório 02... e se abaixa diante de uma criança.", 4.5 },
		{ "GRAVAÇÃO 03:12", "A imagem falha antes de mostrar o que acontece depois.", 3 },
	},
	f2_carter = {
		{ "DRA. EVELYN CARTER", "Diário de pesquisa, dia 412.", 2.5 },
		{ "DRA. EVELYN CARTER", "JANE-01 reagiu de novo. Três monitores queimaram quando eu entrei na sala.", 4 },
		{ "DRA. EVELYN CARTER", "Ele me olha como se esperasse alguma coisa de mim. Não sei o quê.", 4 },
		{ "DRA. EVELYN CARTER", "Aumentem a sedação.", 2.5 },
	},
	f2_memoria = {
		{ "DR. SIMON REEVE", "Marcus, pare. Ele é uma criança!", 3 },
		{ "DR. MARCUS HALE", "Ele é uma ponte, Simon. Continue a carga.", 3 },
		{ "JANE (criança)", "Por favor... tá doendo...", 3 },
		{ "DR. SIMON REEVE", "Desliga! DESLIGA ISSO—", 2.5 },
	},
	f3_eco = {
		{ "MEMÓRIA", "Uma criatura adulta abre a cela. Ajoelha-se.", 3.5 },
		{ "MEMÓRIA", "Abraça a criança antes de atravessar o corredor.", 3.5 },
		{ "JANE", "...eles não vieram atacar. Vieram buscar os filhos.", 4 },
		{ "JANE", "E ninguém veio me buscar.", 3 },
	},
	f4_video = {
		{ "VÍDEO — ARQUIVO", "Sala da Diretoria, 1985.", 2 },
		{ "DRA. EVELYN CARTER", "Não entendo por que o governo insiste em preservar um sujeito tão perigoso.", 4 },
		{ "DR. MARCUS HALE", "A origem dele é mais importante do que você imagina, Evelyn.", 4 },
		{ "DR. MARCUS HALE", "Mais do que você imagina.", 2.5 },
	},
	f4_revelacao = {
		{ "SISTEMA", "Material reprodutivo obtido pelo programa de preservação...", 3.5 },
		{ "SISTEMA", "...doadora: CARTER, EVELYN M. Doadora não informada.", 3.5 },
		{ "JANE", "A mulher que mais me odiou...", 3 },
		{ "JANE", "...é minha mãe.", 3 },
	},
	f4_evelyn = {
		{ "DRA. EVELYN CARTER", "Quem está nesse terminal? Identifique-se.", 3 },
		{ "JANE", "Você sabia?", 2 },
		{ "DRA. EVELYN CARTER", "Isso é falso. Hale falsificou isso. Isso é... isso não pode...", 4 },
		{ "DRA. EVELYN CARTER", "...Treze anos. Eu passei treze anos—", 3 },
		{ "DRA. EVELYN CARTER", "[a transmissão é cortada]", 2 },
	},
	f5_vael = {
		{ "VAEL", "...", 2 },
		{ "JANE", "Você não ficou pra me caçar.", 3 },
		{ "JANE", "Você ficou porque sentia que eu estava aqui.", 3.5 },
		{ "VAEL", "[toca o próprio peito. A mesma luz aparece nos braços de Jane]", 3.5 },
	},
	f5_final = {
		{ "CMD. REBECCA WARD", "Afaste-se dessa coisa, garoto. Agora.", 3 },
		{ "JANE", "Essa coisa é meu pai.", 3 },
		{ "DRA. EVELYN CARTER", "[pelo alto-falante] ...Jane.", 2.5 },
		{ "JANE", "Tchau, mãe.", 2.5 },
	},
}

-- ===== RADIO / FALAS AO VIVO =====
T.Radio = {
	f1_federais = {
		{ "RÁDIO — INTERCEPTADO", "...equipes federais a caminho da instalação. ETA: quarenta minutos.", 3.5 },
		{ "RÁDIO — INTERCEPTADO", "Prioridade absoluta: recuperar qualquer sujeito restante. Código JANE-01.", 4 },
	},
	f1_pedra = {
		{ "JANE", "[uma dor de cabeça fortíssima]", 2.5 },
		{ "JANE", "...o que é isso? Eu consigo... sentir as coisas.", 3.5 },
	},
	f2_vael = {
		{ "JANE", "O que é aquilo?!", 2 },
	},
	f3_ward = {
		{ "CMD. REBECCA WARD", "Equipe Alfa, entrem. O sujeito deve ser recuperado VIVO.", 3.5 },
		{ "CMD. REBECCA WARD", "Todo registro sensível deve ser recolhido ou destruído.", 3.5 },
	},
	f3_criatura = {
		{ "SOLDADO — RÁDIO", "Contato! A criatura ainda está dentro do complexo! Ela—", 3 },
		{ "SOLDADO — RÁDIO", "[estática]", 2 },
	},
	f5_bloqueio = {
		{ "CMD. REBECCA WARD", "Instalação em bloqueio total. Se a recuperação falhar, selamos tudo.", 4 },
		{ "CMD. REBECCA WARD", "Com ele dentro.", 2.5 },
	},
}

T.Creditos = {
	"PROJETO HÍBRIDO",
	"",
	"Um jogo de",
	"Ana Luiza Saudino Bispo de Souza",
	"Mateus Felipe Sbaraglini Saluceste",
	"Emanuel Sandoval",
	"Luigi Stangherlin",
	"",
	"Disciplina: Desenvolvimento de Jogos — 2026",
	"",
	"Feito no Roblox Studio",
	"",
	"Obrigado por jogar.",
}

return T
