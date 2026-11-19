-- Arenas de combate por fase. A arena liga quando o jogador entra na regiao (min/max) com pedras suficientes.
-- ondas: lista de listas de tipos. boss: { tipo, pos }. portas: nomes em workspace.Fases.FaseN.Portas
local V = Vector3.new
return {
	ArcoIris = {
		fase = 1, requerPedras = 1, min = V(171, 13, -13), max = V(225, 30, 28),
		portas = { "Porta_EntradaArcoIris", "Porta_Modulo" },
		spawns = { V(182, 24, -9), V(198, 24, -9), V(178, 24, 26), V(201, 24, 25), V(190, 24, 4), V(214, 24, 8) },
		ondas = { { "Soldado", "Soldado", "Soldado" }, { "Soldado", "Soldado", "Pesado", "Soldado" } },
		boss = { tipo = "Boss", pos = V(198, 25, 8) },
		titulo = "CONTENÇÃO ATIVADA", sub = "Eles vieram buscar você",
	},	Contencao = {
		fase = 2, requerPedras = 2, requerFlag = "g_porta_fechou", min = V(55, -1, 385), max = V(105, 20, 433),
		portas = { "Porta_Perseguicao", "Porta_Modulo03", "Porta_CorredorC" },
		spawns = { V(67, 8, 392), V(93, 8, 392), V(67, 8, 426), V(93, 8, 426), V(86, 8, 430), V(80, 8, 388), V(61, 8, 409), V(99, 8, 409) },
		ondas = { { "Torreta", "Torreta", "Drone", "Drone" }, { "Drone", "Drone", "Drone", "Torreta", "Torreta" } },
		boss = { tipo = "Cerbero", pos = V(80, 6, 409) }, reforco = "Drone",
		titulo = "PROTOCOLO CÉRBERO", sub = "Contenção automática ativada", objetivo = "Destrua o sistema de contenção", fim = "O sistema de contenção caiu",
	},	Galeria = {
		fase = 3, requerPedras = 3, min = V(14, -1, 997), max = V(92, 18, 1012),
		portas = { "Porta_Elev3", "Porta_Deposito", "Porta_GeradorA" },
		spawns = { V(30, 14, 1004), V(46, 14, 1006), V(64, 14, 1004), V(76, 14, 1006), V(88, 14, 1004), V(40, 14, 1004) },
		ondas = { { "Soldado", "Soldado", "Soldado" }, { "Soldado", "Elite", "Soldado", "Pesado" } },
		titulo = "EQUIPE ALFA", sub = "A força de recuperação chegou", objetivo = "Sobreviva à Equipe Alfa", fim = "A Equipe Alfa foi contida",
	},
	Patio = {
		fase = 3, requerPedras = 5, requerFlag = "f3_geradores", min = V(78, -1, 876), max = V(128, 22, 926),
		portas = { "Porta_Patio", "Porta_ElevF3" },
		spawns = { V(84, 18, 880), V(116, 18, 882), V(97, 18, 921), V(122, 18, 920), V(103, 18, 915), V(103, 18, 882) },
		ondas = { { "Soldado", "Elite", "Soldado", "Pesado" } },
		boss = { tipo = "Escudeiro", pos = V(103, 14, 900) }, reforco = "Soldado",
		titulo = "DOCA DE CARGA", sub = "Eles fecharam a saída", objetivo = "Derrote o Tenente Kessler", fim = "O elevador de carga está livre",
	},	Salao = {
		fase = 4, requerPedras = 6, requerFlag = "f4_evelyn", min = V(83, -1, 1481), max = V(132, 18, 1530),
		portas = { "Porta_Salao", "Porta_ElevF4" },
		spawns = { V(88, 13, 1484), V(126, 13, 1484), V(88, 13, 1526), V(126, 13, 1526), V(107, 13, 1522), V(107, 13, 1486) },
		ondas = { { "Elite", "Elite", "Soldado", "Soldado" } },
		boss = { tipo = "Espectro", pos = V(107, 12, 1505) }, reforco = "Elite",
		titulo = "UNIDADE ESPECTRO", sub = "Você não vai vê-los chegando", objetivo = "Sobreviva à Unidade Espectro (use o ECO)", fim = "A Unidade Espectro caiu",
	},	Bloqueio = {
		fase = 5, requerPedras = 6, min = V(14, -1, 1998), max = V(70, 16, 2012),
		portas = { "Porta_Elev5", "Porta_Celas" },
		spawns = { V(20, 12, 2008), V(32, 12, 2005), V(44, 12, 2006), V(55, 12, 2004), V(66, 12, 2004), V(47, 12, 2009) },
		ondas = { { "Soldado", "Elite", "Soldado" }, { "Elite", "Pesado", "Elite", "Soldado" } },
		titulo = "BLOQUEIO MILITAR", sub = "A instalação está sendo selada", objetivo = "Rompa o bloqueio", fim = "O caminho pras celas está livre",
	},
	Final = {
		fase = 5, requerPedras = 7, requerFlag = "f5_despertar", min = V(88, -1, 1880), max = V(148, 28, 1950),
		portas = { "Porta_Portal" },
		spawns = { V(95, 20, 1885), V(141, 20, 1885), V(95, 20, 1945), V(141, 20, 1945), V(118, 20, 1888), V(100, 20, 1915) },
		ondas = {},
		boss = { tipo = "Ward", pos = V(118, 20, 1942) }, reforco = "Elite",
		titulo = "ARGOS", sub = "O exotraje entrou na sala", objetivo = "Derrote a Comandante Ward", fim = "Acabou.",
	},
}
