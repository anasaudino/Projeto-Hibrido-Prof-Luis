-- Numeros do combate roguelike. Mexa aqui pra balancear.
local Config = {}

Config.Jogador = {
	Vida = 100,
	Foco = 100,
	FocoRegen = 22,      -- por segundo
	FocoAtraso = 0.5,    -- segundos sem gastar antes de regenerar
	Velocidade = 16,
}

Config.Pulso = {        -- botao esquerdo (segurar = rajada)
	Dano = 22,
	Recarga = 0.28,
	Custo = 4,
	Velocidade = 150,
	Alcance = 120,
	Raio = 1.1,
	Leque = 9,          -- graus entre projeteis extras
}

Config.Onda = {         -- tecla F
	Dano = 34,
	Raio = 16,
	Recarga = 6,
	Custo = 30,
	Empurrao = 70,
}

Config.Inimigos = {
	Soldado = { Essencia = 3, Vida = 80, Velocidade = 13, Distancia = 22, Alcance = 60, Mira = 0.65, Rajada = 3, DanoTiro = 6, Espalhar = 2.2, Recarga = 2.1, Escala = 1, Orbes = 2 },
	Pesado  = { Essencia = 8, Vida = 240, Velocidade = 9, Distancia = 12, Alcance = 34, Mira = 0.9, Rajada = 1, Chumbos = 6, DanoTiro = 5, Espalhar = 7, Recarga = 2.6, Escala = 1.22, Orbes = 5 },
}

Config.Inimigos.Boss = { Essencia = 60, Vida = 2200, Velocidade = 11, Distancia = 18, Alcance = 70, Mira = 0.9, Rajada = 1, DanoTiro = 8, Espalhar = 1, Recarga = 1.8, Escala = 1.65, Orbes = 16, Nome = "SENTINELA-01" }

-- ===== inimigos mecanicos / bosses das fases seguintes =====
Config.Inimigos.Torreta = { Essencia = 4, Vida = 130, Velocidade = 0, Distancia = 0, Alcance = 60, Mira = 0.8, Rajada = 4, DanoTiro = 5, Espalhar = 3, Recarga = 2.4, Escala = 1, Orbes = 2, Fixo = true, Mecanico = true, Levitavel = false }
Config.Inimigos.Drone = { Essencia = 3, Vida = 60, Velocidade = 16, Distancia = 18, Alcance = 55, Mira = 0.6, Rajada = 2, DanoTiro = 6, Espalhar = 2, Recarga = 2.0, Escala = 1, Orbes = 1, Voador = true, Mecanico = true, Levitavel = false }
Config.Inimigos.GeradorEscudo = { Essencia = 5, Vida = 280, Velocidade = 0, Distancia = 0, Alcance = 0, Mira = 1, Rajada = 0, DanoTiro = 0, Espalhar = 0, Recarga = 99, Escala = 1, Orbes = 3, Fixo = true, Mecanico = true, Levitavel = false, RaioExplosao = 8 }
Config.Inimigos.Cerbero = { Boss = true, Essencia = 70, Vida = 2600, Velocidade = 0, Distancia = 0, Alcance = 80, Mira = 0.9, Rajada = 1, DanoTiro = 9, Espalhar = 1, Recarga = 2, Escala = 1, Orbes = 18, Fixo = true, Mecanico = true, Levitavel = false, RaioExplosao = 14,
	Nome = "NÚCLEO CÉRBERO", Titulo = "Sistema Automático de Contenção", Chegada = " foi ativado" }
Config.Inimigos.Escudeiro = { Boss = true, Essencia = 80, Vida = 2800, Velocidade = 12, Distancia = 14, Alcance = 50, Mira = 0.8, Rajada = 1, Chumbos = 7, DanoTiro = 6, Espalhar = 8, Recarga = 2, Escala = 1.55, Orbes = 18, Levitavel = true,
	Nome = "TENENTE KESSLER", Titulo = "Escudo Balístico Mk. IV", Chegada = " entrou na sala" }
Config.Inimigos.Espectro = { Boss = true, Essencia = 90, Vida = 2400, Velocidade = 20, Distancia = 10, Alcance = 40, Mira = 0.5, Rajada = 1, DanoTiro = 8, Espalhar = 1, Recarga = 2, Escala = 1.1, Orbes = 18, Levitavel = true,
	Nome = "ESPECTRO", Titulo = "Operador de Camuflagem Óptica — use o ECO", Chegada = " está na sala. Você não vai vê-lo." }
Config.Inimigos.Ward = { Boss = true, Essencia = 150, Vida = 4200, Velocidade = 10, Distancia = 20, Alcance = 80, Mira = 0.9, Rajada = 1, DanoTiro = 9, Espalhar = 1, Recarga = 1.6, Escala = 2.1, Orbes = 30, Levitavel = false,
	Nome = "CMD. REBECCA WARD", Titulo = "Exotraje de Contenção ARGOS", Chegada = " entrou no exotraje" }
Config.Inimigos.Elite = { Essencia = 6, Vida = 150, Velocidade = 15, Distancia = 16, Alcance = 60, Mira = 0.55, Rajada = 4, DanoTiro = 6, Espalhar = 1.8, Recarga = 1.8, Escala = 1.05, Orbes = 3 }

Config.Boss = {
	Leque = { Linhas = 7, Abertura = 70, Dano = 10, Aviso = 0.95 },
	Investida = { Aviso = 1.0, Largura = 6, Dano = 26, Velocidade = 75, Alcance = 46 },
	Granadas = { Qtd = 4, Raio = 7, Aviso = 1.3, Dano = 22 },
	Fases = { 0.66, 0.33 },
}

Config.Dash = { Recarga = 2.4, Custo = 10, Forca = 95, Duracao = 0.16, Invuln = 0.25 }

Config.Orbe = { Cura = 5, Foco = 12, Ima = 16 }
Config.Rerolar = 10       -- custo em Essencia pra trocar as cartas

-- Arvore de habilidades PERMANENTE (compra com Essencia, vale pra todas as runs)
Config.Ramos = {
	{ id = "Mente", cor = Color3.fromRGB(190, 110, 255), desc = "Dano e crítico" },
	{ id = "Corpo", cor = Color3.fromRGB(255, 110, 110), desc = "Vida e mobilidade" },
	{ id = "Foco",  cor = Color3.fromRGB(90, 190, 255),  desc = "Energia e recursos" },
}
Config.Arvore = {
	{ id = "m1", ramo = "Mente", tier = 1, custo = 20,  nome = "Mente Focada",     desc = "+10% de dano." },
	{ id = "m2", ramo = "Mente", tier = 2, custo = 35,  req = "m1", nome = "Pontaria",       desc = "+6% de chance de crítico." },
	{ id = "m3", ramo = "Mente", tier = 3, custo = 60,  req = "m2", nome = "Sobrecarga",     desc = "Críticos causam x2,5 em vez de x2." },
	{ id = "m4", ramo = "Mente", tier = 3, custo = 80,  req = "m2", nome = "Pulso Duplo",    desc = "Toda run começa com +1 projétil." },
	{ id = "m5", ramo = "Mente", tier = 4, custo = 120, req = "m4", nome = "Mente Ampla",    desc = "Escolha entre 4 mutações em vez de 3." },
	{ id = "c1", ramo = "Corpo", tier = 1, custo = 25,  nome = "Salto Psíquico",   desc = "Desbloqueia o DASH (tecla Q)." },
	{ id = "c2", ramo = "Corpo", tier = 2, custo = 30,  req = "c1", nome = "Vigor",          desc = "+20 de vida máxima." },
	{ id = "c3", ramo = "Corpo", tier = 2, custo = 50,  req = "c1", nome = "Esquiva",        desc = "Dash deixa invulnerável por mais tempo e recarrega 1s mais rápido." },
	{ id = "c4", ramo = "Corpo", tier = 3, custo = 40,  req = "c2", nome = "Passo Fantasma", desc = "+10% de velocidade." },
	{ id = "c5", ramo = "Corpo", tier = 4, custo = 150, req = "c4", nome = "Segunda Chance", desc = "Uma vez por run, volta com 50% da vida em vez de morrer." },
	{ id = "f1", ramo = "Foco",  tier = 1, custo = 20,  nome = "Reserva",          desc = "+20 de Foco máximo." },
	{ id = "f2", ramo = "Foco",  tier = 2, custo = 35,  req = "f1", nome = "Fluxo",          desc = "Foco regenera 25% mais rápido." },
	{ id = "f3", ramo = "Foco",  tier = 2, custo = 45,  req = "f1", nome = "Onda Precoce",   desc = "Onda recarrega 1,5s mais rápido." },
	{ id = "f4", ramo = "Foco",  tier = 3, custo = 40,  req = "f2", nome = "Ímã",            desc = "Orbes vêm de 2x mais longe e curam +3." },
	{ id = "f5", ramo = "Foco",  tier = 4, custo = 90,  req = "f4", nome = "Colheita",       desc = "+50% de Essência por abate." },
}
Config.NoPorId = {}
for _, n in ipairs(Config.Arvore) do Config.NoPorId[n.id] = n end

Config.Raridades = {
	Comum = { Peso = 60, Cor = Color3.fromRGB(150, 170, 185) },
	Raro  = { Peso = 30, Cor = Color3.fromRGB(80, 150, 255) },
	Epico = { Peso = 10, Cor = Color3.fromRGB(190, 90, 255) },
}

-- Buffs (mutacoes do Jane). max = quantas vezes pode empilhar.
Config.Buffs = {
	{ id = "dano",      nome = "Mente Afiada",      rar = "Comum", max = 5, sigla = "DN", desc = "+20% de dano em tudo." },
	{ id = "cadencia",  nome = "Reflexo Neural",    rar = "Comum", max = 4, sigla = "RF", desc = "Pulso recarrega 15% mais rápido." },
	{ id = "vida",      nome = "Pele Resistente",   rar = "Comum", max = 5, sigla = "VD", desc = "+25 de vida máxima e cura 25." },
	{ id = "foco",      nome = "Reserva Psíquica",  rar = "Comum", max = 4, sigla = "FC", desc = "+30 de Foco máximo." },
	{ id = "regen",     nome = "Respiração Calma",  rar = "Comum", max = 4, sigla = "RG", desc = "Foco regenera 40% mais rápido." },
	{ id = "veloc",     nome = "Passos Leves",      rar = "Comum", max = 3, sigla = "VL", desc = "+12% de velocidade." },
	{ id = "perfurar",  nome = "Perfuração",        rar = "Raro",  max = 3, sigla = "PF", desc = "O Pulso atravessa +1 inimigo." },
	{ id = "multi",     nome = "Estilhaço",         rar = "Raro",  max = 3, sigla = "ES", desc = "+1 projétil em leque." },
	{ id = "critico",   nome = "Olho Interior",     rar = "Raro",  max = 4, sigla = "CR", desc = "+15% de chance de crítico (dano x2)." },
	{ id = "vampiro",   nome = "Sifão",             rar = "Raro",  max = 3, sigla = "SF", desc = "Cada acerto cura 2 de vida." },
	{ id = "ondamaior", nome = "Onda Maior",        rar = "Raro",  max = 3, sigla = "OM", desc = "Onda: +35% de raio e dano, -1s de recarga." },
	{ id = "atordoar",  nome = "Choque",            rar = "Raro",  max = 1, sigla = "CH", desc = "O Pulso atordoa por 0,6s e cancela a mira." },
	{ id = "ricochete", nome = "Ricochete Mental",  rar = "Epico", max = 2, sigla = "RC", desc = "O Pulso salta pra +2 inimigos próximos." },
	{ id = "implosao",  nome = "Implosão",          rar = "Epico", max = 1, sigla = "IM", desc = "Inimigos mortos explodem (dano em área)." },
	{ id = "febre",     nome = "Febre Psíquica",    rar = "Epico", max = 2, sigla = "FB", desc = "Acertos queimam: 8 de dano/s por 3s." },
	{ id = "barreira",  nome = "Barreira",          rar = "Epico", max = 1, sigla = "BR", desc = "Um escudo bloqueia 1 tiro a cada 6s." },
}
Config.BuffPorId = {}
for _, b in ipairs(Config.Buffs) do Config.BuffPorId[b.id] = b end

Config.Sons = {
	Pulso = "rbxassetid://9125648149",
	Onda = "rbxasset://sounds/impact_explosion_03.mp3",
	Tiro = "rbxassetid://6975483207",
	Acerto = "rbxassetid://220025689",
	Alarme = "rbxassetid://9125265825",
	Buff = "rbxassetid://9125647212",
}

Config.CorPsi = Color3.fromRGB(170, 110, 255)
Config.CorPsiClara = Color3.fromRGB(235, 215, 255)

return Config
