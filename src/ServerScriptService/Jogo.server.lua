-- Orquestrador da campanha: menu, checkpoints, prompts, gatilhos, historia, transicao de fases.
-- Cada fase tem um modulo em ServerStorage.Jogo.Fases.FaseN com: acoes, gatilhos, aoCarregar, aposPedra, arenaLimpa.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Meta = require(SS.CombateSrv.Meta)
local Textos = require(RS.Jogo.Textos)
local RH = RS.Jogo.Remotes.Historia
local RMenu = RS.Jogo.Remotes.Menu
local AVISO = RS:WaitForChild("AvisoJogador")
local EV = SS.Jogo.Eventos
local FASES = workspace:WaitForChild("Fases")
-- copia intacta do mapa: "Novo Jogo" depois de jogar precisa das pedras, portas e caixotes de volta
local FASES_ORIGINAL = FASES:Clone()
local mundoSujo = false

local api = {}
local MENU_CF = CFrame.new(6, 3, 13.5)
local modulos = {}
-- recarregar: os modulos guardam a referencia do modelo da fase, entao exigem uma copia nova
local function carregarModulos(recarregar)
	table.clear(modulos)
	for _, m in ipairs(SS.Jogo.Fases:GetChildren()) do
		local ok, mod = pcall(require, recarregar and m:Clone() or m)
		if ok then modulos[m.Name] = mod else warn("[Jogo] erro no modulo " .. m.Name .. ": " .. tostring(mod)) end
	end
end
carregarModulos(false)

local function faseDe(inst)
	while inst and inst.Parent ~= FASES do inst = inst.Parent end
	return inst
end
local function numFase(model) return model and tonumber(model.Name:match("^Fase(%d+)")) end
local function modFase(n) return modulos["Fase" .. tostring(n)] end
local function faseModel(n) for _, f in ipairs(FASES:GetChildren()) do if numFase(f) == n then return f end end end

-- ===================== API pros modulos =====================
function api.camp(p) return Meta.camp(p) end
function api.flag(p, k) local c = Meta.camp(p) return c and c.flags[k] == true end
function api.marcar(p, k) local c = Meta.camp(p) if c then c.flags[k] = true Meta.sujar(p) end end
function api.objetivo(p, t) p:SetAttribute("Objetivo", t) end
function api.aviso(p, t) AVISO:FireClient(p, t) end
function api.historia(p, tipo, ...) RH:FireClient(p, tipo, ...) end

local function duracao(lista) local d = 0 for _, f in ipairs(lista) do d += f[3] or 3 end return d end
function api.falas(p, lista, esperar)
	if type(lista) == "string" then lista = Textos.Radio[lista] or Textos.Gravacoes[lista] end
	if not lista then return end
	RH:FireClient(p, "legendas", lista)
	if esperar then task.wait(duracao(lista)) end
end
function api.gravacao(p, id, esperar) api.falas(p, Textos.Gravacoes[id], esperar) end
function api.radio(p, id, esperar) api.falas(p, Textos.Radio[id], esperar) end

function api.doc(p, id)
	local c = Meta.camp(p)
	if c and not c.docs[id] then c.docs[id] = true Meta.sujar(p) end
	local lidos = {} if c then for k in pairs(c.docs) do table.insert(lidos, k) end end
	p:SetAttribute("Docs", HttpService:JSONEncode(lidos))
	RH:FireClient(p, "documento", id)
end

function api.fade(p, preto, dur, texto, sub) RH:FireClient(p, "fade", preto, dur, texto, sub) if dur then task.wait(dur) end end

function api.congelar(p, sim)
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if r then r.Anchored = sim end
	p:SetAttribute("Congelado", sim)
end

-- cutscene: def = { tomadas = {{ de = CFrame, ate = CFrame, dur = s }}, falas = {...} ou id, barras = true }
function api.cutscene(p, def)
	api.congelar(p, true)
	local total = 0
	for _, t in ipairs(def.tomadas) do total += t.dur end
	local falas = def.falas
	if type(falas) == "string" then falas = Textos.Gravacoes[falas] or Textos.Radio[falas] end
	RH:FireClient(p, "cutscene", def.tomadas, falas)
	task.wait(total + 0.2)
	api.congelar(p, false)
end

function api.porta(nomeFase, nome, trancada)
	local f = type(nomeFase) == "number" and faseModel(nomeFase) or nomeFase
	local d = f and f:FindFirstChild("Portas") and f.Portas:FindFirstChild(nome)
	if d then d:SetAttribute("Trancada", trancada) end
	return d
end

function api.cpCFrame(n, id)
	local f = faseModel(n)
	local cp = f and f:FindFirstChild("Gameplay") and f.Gameplay:FindFirstChild("Checkpoints") and f.Gameplay.Checkpoints:FindFirstChild(id)
	return cp and cp.CFrame
end

function api.checkpoint(p, n, id)
	local c = Meta.camp(p) if not c then return end
	c.fase = n c.cp = id
	p:SetAttribute("Fase", n)
	Meta.sujar(p)
	task.spawn(Meta.salvar, p)
end

function api.teleportar(p, cf)
	local ch = p.Character
	if ch and cf then ch:PivotTo(cf + Vector3.new(0, 3, 0)) end
end

function api.setPedras(p, n)
	local c = Meta.camp(p)
	if c then c.pedras = math.max(c.pedras, n) end
	p:SetAttribute("Pedras", c and c.pedras or n)
	if (c and c.pedras or n) >= 1 then p:SetAttribute("PoderAtracao", true) end
end

-- entra numa fase (novo, continuar ou elevador)
function api.irFase(p, n, id, comCartao)
	id = id or "inicio"
	mundoSujo = true
	local mod = modFase(n)
	if comCartao ~= false then
		local cap = Textos.Capitulos[n]
		api.fade(p, true, 0.8)
		RH:FireClient(p, "capitulo", cap and cap[1] or ("FASE " .. n), cap and cap[2] or "")
	end
	api.checkpoint(p, n, id)
	local cf = api.cpCFrame(n, id)
	api.teleportar(p, cf)
	local objAntes = Meta.camp(p) and Meta.camp(p).obj
	p:SetAttribute("Objetivo", nil)
	if mod and mod.aoCarregar then task.spawn(function() local ok, e = pcall(mod.aoCarregar, p, api, id) if not ok then warn("[Jogo] aoCarregar " .. n .. ": " .. tostring(e)) end end) end
	task.delay(1, function()
		if (p:GetAttribute("Objetivo") or "") == "" then
			local padrao = mod and mod.objetivoPadrao and select(2, pcall(mod.objetivoPadrao, p, api))
			if type(padrao) == "string" then p:SetAttribute("Objetivo", padrao)
			elseif objAntes then p:SetAttribute("Objetivo", objAntes) end
		end
	end)
	if comCartao ~= false then task.wait(2.6) api.fade(p, false, 1) end
end

-- ===================== prompts =====================
local ocupado = {}
local GENERICAS = {}

function GENERICAS.Documento(p, prompt)
	local id = prompt:GetAttribute("Doc") or prompt.Parent:GetAttribute("Doc")
	api.doc(p, id)
	local d = Textos.Docs[id]
	if d and d.eco then
		if (p:GetAttribute("EcoAte") or 0) > workspace:GetServerTimeNow() then
			api.marcar(p, "eco_" .. id)
			api.aviso(p, "Sob o ECO, números aparecem: " .. d.eco)
		else
			api.aviso(p, "Tem algo apagado nesta folha... (tente com o ECO)")
		end
	end
	local modD = modFase(numFase(faseDe(prompt)))
	if modD and modD.aposDocumento then task.spawn(modD.aposDocumento, p, id, api) end
end
function GENERICAS.Gravacao(p, prompt)
	local id = prompt:GetAttribute("Grav") or prompt.Parent:GetAttribute("Grav")
	api.gravacao(p, id)
	api.marcar(p, "grav_" .. tostring(id))
end
function GENERICAS.Desenho(p, prompt)
	prompt.Enabled = false
	local peca = prompt.Parent
	api.marcar(p, "des_" .. peca:GetFullName())
	peca:Destroy()
	local n = (p:GetAttribute("Desenhos") or 0) + 1
	p:SetAttribute("Desenhos", n)
	api.aviso(p, ("Desenho encontrado (%d)"):format(n))
end
function GENERICAS.Memoria(p, prompt)
	if (p:GetAttribute("EcoAte") or 0) < workspace:GetServerTimeNow() then
		api.aviso(p, "Tem algo aqui... só dá pra ver com o ECO (tecla G)")
		return
	end
	prompt.Enabled = false
	api.gravacao(p, prompt:GetAttribute("Grav") or prompt.Parent:GetAttribute("Grav"), true)
	api.marcar(p, "mem_" .. tostring(prompt.Parent.Name))
	local modM = modFase(numFase(faseDe(prompt)))
	if modM and modM.aposMemoria then task.spawn(modM.aposMemoria, p, api) end
end
local PODERES = { "ATRAÇÃO — Pulso Telecinético (botão esquerdo)", "IMPULSO — Onda (tecla F)", "IMPULSO AMPLIADO — a Onda derruba e arremessa objetos pesados",
	"LEVITAÇÃO — tecla R em objetos marcados", "ECO — tecla G revela o que está escondido", "LEVITAÇÃO DE SERES — R num soldado, R de novo pra arremessar", "DESPERTAR — a supressão acabou" }
function GENERICAS.Pedra(p, prompt)
	prompt.Enabled = false
	local peca = prompt.Parent
	local modelo = peca:FindFirstAncestorOfClass("Model") or peca
	local n = modelo:GetAttribute("Numero") or peca:GetAttribute("Numero") or 1
	for _, x in ipairs(modelo:GetDescendants()) do
		if x:IsA("BasePart") then TweenService:Create(x, TweenInfo.new(0.8), { Transparency = 1, Size = x.Size * 0.3 }):Play()
		elseif x:IsA("Light") then TweenService:Create(x, TweenInfo.new(0.8), { Brightness = 0 }):Play() end
	end
	task.delay(0.9, function() modelo:Destroy() end)
	api.setPedras(p, n)
	api.marcar(p, "pedra_" .. n)
	RH:FireClient(p, "pedra", n, PODERES[n])
	EV.PedraRemovida:Fire(p, n)
	local f = faseDe(peca) or faseModel(Meta.camp(p).fase)
	local mod = modFase(numFase(f))
	if mod and mod.aposPedra then task.spawn(mod.aposPedra, p, api, n) end
end
function GENERICAS.Elevador(p, prompt)
	local destino = prompt:GetAttribute("Destino") or prompt.Parent:GetAttribute("Destino")
	if not destino then return end
	local f = faseDe(prompt)
	local mod = modFase(numFase(f))
	if mod and mod.podeSair then
		local ok, msg = mod.podeSair(p, api)
		if not ok then api.aviso(p, msg or "Ainda não.") return end
	end
	if not faseModel(destino) then api.aviso(p, "Esse andar ainda não existe.") return end
	prompt.Enabled = false
	api.irFase(p, destino, "inicio")
	task.delay(5, function() prompt.Enabled = true end)
end

local function ligar(prompt)
	if not prompt:IsA("ProximityPrompt") or prompt:GetAttribute("_ligado") then return end
	local acao = prompt:GetAttribute("Acao")
	if not acao then return end
	prompt:SetAttribute("_ligado", true)
	prompt.Triggered:Connect(function(p)
		if ocupado[prompt] then return end
		ocupado[prompt] = true
		local f = faseDe(prompt)
		local mod = modFase(numFase(f))
		local fn = (mod and mod.acoes and mod.acoes[acao]) or GENERICAS[acao]
		if fn then
			local ok, err = pcall(fn, p, prompt, api)
			if not ok then warn("[Jogo] acao " .. acao .. ": " .. tostring(err)) end
		end
		ocupado[prompt] = nil
	end)
end
for _, d in ipairs(FASES:GetDescendants()) do ligar(d) end
FASES.DescendantAdded:Connect(ligar)

-- ===================== gatilhos de area =====================
local gatilhos = {}
local function registrarGatilho(part)
	if part:IsA("BasePart") and part:GetAttribute("Gatilho") then table.insert(gatilhos, part) end
end
for _, d in ipairs(FASES:GetDescendants()) do registrarGatilho(d) end
FASES.DescendantAdded:Connect(registrarGatilho)

local function dentro(part, pos)
	local l = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(l.X) <= h.X and math.abs(l.Y) <= h.Y and math.abs(l.Z) <= h.Z
end

task.spawn(function()
	while true do
		task.wait(0.2)
		for _, p in ipairs(Players:GetPlayers()) do
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			local c = Meta.camp(p)
			if r and c and not p:GetAttribute("NoMenu") then
				for _, g in ipairs(gatilhos) do
					if g.Parent then
						local id = g:GetAttribute("Gatilho")
						local chave = "g_" .. id
						if not c.flags[chave] and dentro(g, r.Position) then
							local req = g:GetAttribute("RequerFlag")
							if not req or c.flags[req] then
								c.flags[chave] = true Meta.sujar(p)
								local mod = modFase(numFase(faseDe(g)))
								local fn = mod and mod.gatilhos and mod.gatilhos[id]
								if fn then task.spawn(function() local ok, e = pcall(fn, p, api, g) if not ok then warn("[Jogo] gatilho " .. id .. ": " .. tostring(e)) end end) end
							end
						end
					end
				end
			end
		end
	end
end)

-- ===================== arena limpa (vem do CombateServer) =====================
EV.ArenaLimpa.Event:Connect(function(p, id, faseN)
	api.marcar(p, "arena_" .. id)
	local antes = p:GetAttribute("Objetivo")
	local mod = modFase(faseN)
	if mod and mod.arenaLimpa and mod.arenaLimpa[id] then task.spawn(mod.arenaLimpa[id], p, api) end
	task.delay(0.5, function()
		if p:GetAttribute("Objetivo") == antes and mod and mod.objetivoPadrao then
			local ok, t = pcall(mod.objetivoPadrao, p, api)
			if ok and type(t) == "string" and t ~= "" then p:SetAttribute("Objetivo", t) end
		end
	end)
end)

EV.Empurrado.Event:Connect(function(p, obj)
	local mod = modFase(numFase(faseDe(obj)))
	if mod and mod.empurrado then task.spawn(mod.empurrado, p, obj, api) end
end)
EV.Encaixe.Event:Connect(function(p, nome, obj)
	local mod = modFase(numFase(faseDe(obj)))
	if mod and mod.encaixe then task.spawn(mod.encaixe, p, nome, obj, api) end
end)
api.Vael = require(SS.Jogo.Vael)

-- ===================== marcador de objetivo =====================
local function pos(n, ...)
	local f = faseModel(n)
	local x = f
	for _, nome in ipairs({ ... }) do x = x and x:FindFirstChild(nome) end
	if not x then return nil end
	if x:IsA("BasePart") then return x.Position end
	if x:IsA("Model") then return x:GetPivot().Position end
end
local function travaMaisPerto(p)
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	local melhor, md
	for i = 1, 3 do
		if not api.flag(p, "f5_trava" .. i) then
			local q = pos(5, "Gameplay", "Trava" .. i, "Console")
			if q then local d = r and (q - r.Position).Magnitude or 0 if not md or d < md then melhor, md = q, d end end
		end
	end
	return melhor
end
local guiar
local function segurandoObjeto(p) return p:GetAttribute("Segurando") == "objeto" end
local ALVOS = {
	["Encontre um jeito de abrir a porta"] = function() return pos(1, "Gameplay", "AlavancaEmergencia", "Base") end,
	["Tire o que está bloqueando a passagem"] = function() return pos(1, "Gameplay", "CarrinhoTombado", "Corpo") end,
	["Encontre a saída da Ala Infantil"] = function() return pos(1, "Gameplay", "Pedra_01", "Cristal") end,
	["Volte pra Sala Arco-Íris"] = function() return Vector3.new(198, 16, 8) end,
	["Use a mente (Pulso) no fusível atrás da grade — E"] = function() return pos(1, "Gameplay", "Fusivel") end,
	["Instale o fusível no painel da porta"] = function() return pos(1, "Gameplay", "PainelEnergiaSaida", "Caixa") end,
	["Vá até o elevador"] = function() return pos(1, "Gameplay", "PainelElevador", "Painel") end,
	["Use o painel do elevador (E)"] = function() return pos(1, "Gameplay", "PainelElevador", "Painel") end,
	["Explore a Ala de Pesquisa. Procure um cartão de acesso."] = function() return pos(2, "Gameplay", "Cartao") end,
	["Use o cartão no Módulo 02 (sul do corredor)"] = function() return pos(2, "Gameplay", "Pedra_02", "Cristal") end,
	["Algo se move na Sala de Observação..."] = function() return pos(2, "Gameplay", "G_Observacao") end,
	["CORRA. Pegue o corredor ao leste."] = function() return pos(2, "Gameplay", "G_Perseguicao") end,
	["CORRA até a porta no fim do corredor!"] = function() return pos(2, "Portas", "Porta_Perseguicao") end,
	["Pegue a pedra no Módulo 03 (leste da arena)"] = function() return pos(2, "Gameplay", "Pedra_03", "Cristal") end,
	["Use a Onda (F) nos caixotes que bloqueiam o corredor norte"] = function() return pos(2, "Gameplay", "Caixotes", "CaixotePesado") end,
	["Siga até o elevador"] = function() return pos(2, "Gameplay", "PainelElevador", "Painel") end,
	["Encontre o Módulo 04 no Depósito (norte)"] = function() return pos(3, "Gameplay", "Pedra_04", "Cristal") end,
	["Gerador A: aponte pra célula no alto e aperte R (Levitar). Solte perto do encaixe."] = function(p) return segurandoObjeto(p) and pos(3, "Gameplay", "EncaixeCelula") or pos(3, "Gameplay", "CelulaEnergia") end,
	["Falta religar o Gerador A (célula de energia)"] = function(p) return segurandoObjeto(p) and pos(3, "Gameplay", "EncaixeCelula") or pos(3, "Gameplay", "CelulaEnergia") end,
	["A Contenção (sul) e o corredor leste abriram."] = function() return pos(3, "Portas", "Porta_Contencao") end,
	["Pegue a pedra do Módulo 05 (fundo da Contenção)"] = function() return pos(3, "Gameplay", "Pedra_05", "Cristal") end,
	["Aperte G (ECO). Alguma coisa aconteceu nesta sala."] = function() return pos(3, "Gameplay", "MemoriaEco", "PontoMemoria") end,
	["Religue o Gerador B (leste). Só UMA alavanca é a certa — o ECO (G) mostra qual."] = function() return pos(3, "Props", "GeradorB", "Painel") end,
	["Os dois geradores voltaram. Atravesse a Doca de Carga (norte)."] = function() return pos(3, "Portas", "Porta_Patio") end,
	["Pegue o elevador de carga"] = function() return pos(3, "Gameplay", "PainelElevador", "Painel") end,
	["Descubra por que seu prontuário é secreto. Comece pela Diretoria."] = function() return pos(4, "Gameplay", "Doc_Autorizacoes") end,
	["O código está em duas folhas com números apagados (Diretoria e Arquivo Geral). Leia-as com o ECO (G)."] = function(p) return (not api.flag(p, "eco_f4_codigo_a")) and pos(4, "Gameplay", "Doc_CodigoA") or pos(4, "Gameplay", "Doc_CodigoB") end,
	["A trava saiu. Falta o código do teclado (leia as folhas com o ECO)."] = function(p) return (not api.flag(p, "eco_f4_codigo_a")) and pos(4, "Gameplay", "Doc_CodigoA") or pos(4, "Gameplay", "Doc_CodigoB") end,
	["Use o código no teclado do Arquivo Genético"] = function() return pos(4, "Gameplay", "Teclado") end,
	["A porta está travada por dentro. Levite a trava (R) pra fora e solte no chão marcado."] = function(p) return segurandoObjeto(p) and pos(4, "Gameplay", "SocketTrava") or pos(4, "Gameplay", "TravaPorta") end,
	["Entre no Arquivo Genético"] = function() return pos(4, "Gameplay", "Pedra_06", "Cristal") end,
	["Abra o arquivo de procedência genética (terminal azul)"] = function() return pos(4, "Gameplay", "TerminalGenetico") end,
	["Use o intercomunicador. Ela precisa saber."] = function() return pos(4, "Gameplay", "Intercom") end,
	["Saia pelo Salão da Diretoria (leste do corredor)"] = function() return pos(4, "Portas", "Porta_Salao") end,
	["Pegue o elevador até a Sala do Portal"] = function() return pos(4, "Gameplay", "PainelElevador", "Painel") end,
	["Chegue à Sala do Portal"] = function() return pos(5, "Portas", "Porta_Celas") end,
	["Siga pela galeria de celas (norte)"] = function() return pos(5, "Gameplay", "G_Beco") end,
	["Ele está aqui de novo. CORRA pro fundo da galeria."] = function() return pos(5, "Gameplay", "G_Beco") end,
	["Ele abriu o caminho. Desligue as 3 travas do portal."] = travaMaisPerto,
	["O núcleo abriu. Pegue a SÉTIMA pedra."] = function() return pos(5, "Gameplay", "Pedra_07", "Cristal") end,
	["Estabilize o portal (segure E no centro)"] = function() return pos(5, "Gameplay", "PontoEstabilizar") end,
}
local function centroArena(id)
	local def = require(game:GetService("ReplicatedStorage").Combate.Arenas)[id]
	if not def then return nil end
	local c = (def.min + def.max) / 2
	return Vector3.new(c.X, def.min.Y + 4, c.Z)
end
for id, def in pairs(require(game:GetService("ReplicatedStorage").Combate.Arenas)) do
	local t = def.objetivo or "Sobreviva à equipe de contenção"
	if not ALVOS[t] then ALVOS[t] = function() return centroArena(id) end end
end
ALVOS["Soldados no subsolo. Sobreviva."] = function() return centroArena("Galeria") end
ALVOS["Algo grande está chegando."] = function() return centroArena("Final") end
local PFS = game:GetService("PathfindingService")
local function portasNoPathfinding()
	for _, f in ipairs(FASES:GetChildren()) do
		local portas = f:FindFirstChild("Portas")
		for _, x in ipairs(portas and portas:GetDescendants() or {}) do
			if x:IsA("BasePart") and x.Name ~= "Batente" and not x:FindFirstChildOfClass("PathfindingModifier") then
				local m = Instance.new("PathfindingModifier") m.PassThrough = true m.Parent = x
			end
		end
	end
end
portasNoPathfinding()
local rpGuia = RaycastParams.new() rpGuia.RespectCanCollide = true
local calculando = {}
local VOLTA = { Vector3.zero, Vector3.new(4, 0, 0), Vector3.new(-4, 0, 0), Vector3.new(0, 0, 4), Vector3.new(0, 0, -4), Vector3.new(7, 0, 7), Vector3.new(-7, 0, -7), Vector3.new(7, 0, -7), Vector3.new(-7, 0, 7) }
local function chao(v)
	rpGuia.FilterType = Enum.RaycastFilterType.Exclude
	local ex = { workspace.CurrentCamera }
	for _, f in ipairs(FASES:GetChildren()) do local pt = f:FindFirstChild("Portas") if pt then table.insert(ex, pt) end end
	rpGuia.FilterDescendantsInstances = ex
	local r = workspace:Raycast(v + Vector3.new(0, 3, 0), Vector3.new(0, -40, 0), rpGuia)
	return r and r.Position + Vector3.new(0, 2.5, 0) or v
end
local function livre(a, b, ch)
	rpGuia.FilterType = Enum.RaycastFilterType.Exclude
	rpGuia.FilterDescendantsInstances = { ch, workspace.CurrentCamera }
	return workspace:Raycast(a, b - a, rpGuia) == nil
end
function guiar(p, alvo)
	local ch = p.Character
	local r = ch and ch:FindFirstChild("HumanoidRootPart")
	if not alvo or not r then p:SetAttribute("ObjetivoGuia", nil) p:SetAttribute("ObjetivoDist", nil) return end
	if calculando[p] then return end
	calculando[p] = true
	task.spawn(function()
		local olho = r.Position + Vector3.new(0, 1.5, 0)
		local guia, dist = alvo, (alvo - r.Position).Magnitude
		p:SetAttribute("ObjetivoRota", "linha")
		if not livre(olho, alvo, ch) then
			local path = PFS:CreatePath({ AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 4 })
			local ok = pcall(function() path:ComputeAsync(r.Position, alvo) end)
			local achou = ok and path.Status == Enum.PathStatus.Success
			if not achou then
				for _, o in ipairs(VOLTA) do
					ok = pcall(function() path:ComputeAsync(r.Position, chao(alvo + o)) end)
					achou = ok and path.Status == Enum.PathStatus.Success
					if achou then break end
				end
			end
			p:SetAttribute("ObjetivoRota", achou and "rota" or "falhou")
			if achou then
				local wps = path:GetWaypoints()
				local total, ant = 0, r.Position
				for _, w in ipairs(wps) do total += (w.Position - ant).Magnitude ant = w.Position end
				dist = total + (alvo - ant).Magnitude
				local esc
				for i = 2, #wps do
					local w = wps[i].Position + Vector3.new(0, 2.5, 0)
					if (w - r.Position).Magnitude > 60 or not livre(olho, w, ch) then break end
					esc = w
				end
				if esc and #wps > 1 and (esc - (wps[#wps].Position + Vector3.new(0, 2.5, 0))).Magnitude > 3 then guia = esc end
			end
		end
		calculando[p] = nil
		if p.Parent then
			p:SetAttribute("ObjetivoGuia", guia)
			p:SetAttribute("ObjetivoDist", dist)
		end
	end)
end
local function atualizarAlvo(p)
	local t = p:GetAttribute("Objetivo")
	local c = Meta.camp(p)
	if c and t and t ~= "" and c.obj ~= t and not p:GetAttribute("NoMenu") then c.obj = t Meta.sujar(p) end
	local fn = t and ALVOS[t]
	if not fn and t and t:find("^Desligue as travas do portal") then fn = travaMaisPerto end
	local ok, alvo = pcall(function() return fn and not p:GetAttribute("EmArena") and fn(p) end)
	alvo = ok and typeof(alvo) == "Vector3" and alvo or nil
	p:SetAttribute("ObjetivoAlvo", alvo)
	guiar(p, alvo)
end
Players.PlayerAdded:Connect(function(p) p:GetAttributeChangedSignal("Objetivo"):Connect(function() atualizarAlvo(p) end) end)
for _, p in ipairs(Players:GetPlayers()) do p:GetAttributeChangedSignal("Objetivo"):Connect(function() atualizarAlvo(p) end) end
-- flags podem mudar o alvo sem mudar o texto (ex.: travas, folhas do codigo)
task.spawn(function() while true do task.wait(0.6) for _, p in ipairs(Players:GetPlayers()) do atualizarAlvo(p) end end end)

-- ===================== reset do mundo =====================
-- troca as fases pela copia intacta; gatilhos e prompts se religam pelo DescendantAdded
local function resetMundo()
	EV.ResetMundo:Fire()
	table.clear(gatilhos)
	table.clear(ocupado)
	for _, f in ipairs(FASES:GetChildren()) do f:Destroy() end
	for _, f in ipairs(FASES_ORIGINAL:GetChildren()) do
		f:Clone().Parent = FASES
		task.wait()
	end
	carregarModulos(true)
	portasNoPathfinding()
	mundoSujo = false
end

-- ===================== menu / entrada =====================
local function aplicarCamp(p)
	local c = Meta.camp(p)
	p:SetAttribute("Fase", c.fase)
	api.setPedras(p, c.pedras)
	if c.pedras < 1 then p:SetAttribute("PoderAtracao", nil) end
	local lidos = {} for k in pairs(c.docs) do table.insert(lidos, k) end
	p:SetAttribute("Docs", HttpService:JSONEncode(lidos))
	p:SetAttribute("TemSave", c.iniciado)
end

RMenu.OnServerEvent:Connect(function(p, escolha)
	local c = Meta.camp(p)
	if not c then return end
	if escolha == "sair" and not p:GetAttribute("NoMenu") then
		p:SetAttribute("NoMenu", true)
		Meta.salvar(p)
		p:SetAttribute("TemSave", c.iniciado)
		local ch = p.Character
		if ch then ch:PivotTo(MENU_CF) api.congelar(p, true) end
		return
	end
	if not p:GetAttribute("NoMenu") then return end
	if escolha == "novo" then
		if mundoSujo then resetMundo() end
		Meta.resetCamp(p)
		c = Meta.camp(p)
		c.iniciado = true
		aplicarCamp(p)
		p:SetAttribute("NoMenu", false)
		api.congelar(p, false)
		api.irFase(p, 1, "inicio")
		local mod = modFase(1)
		if mod and mod.prologo then task.spawn(mod.prologo, p, api) end
	elseif escolha == "sair" then
		return
	elseif escolha == "continuar" and c.iniciado then
		aplicarCamp(p)
		p:SetAttribute("NoMenu", false)
		api.congelar(p, false)
		api.irFase(p, c.fase, c.cp)
	end
end)

Players.PlayerAdded:Connect(function(p)
	p:SetAttribute("NoMenu", true)
	local t0 = os.clock()
	while not Meta.camp(p) and os.clock() - t0 < 15 do task.wait(0.1) end
	if Meta.camp(p) then aplicarCamp(p) end
	p.CharacterAdded:Connect(function(ch)
		local r = ch:WaitForChild("HumanoidRootPart")
		task.wait()
		if p:GetAttribute("NoMenu") then
			ch:PivotTo(MENU_CF) r.Anchored = true
		else
			local c = Meta.camp(p)
			if c then
				local cf = api.cpCFrame(c.fase, c.cp)
				api.teleportar(p, cf)
				local mod = modFase(c.fase)
				if mod and mod.aoRenascer then task.spawn(mod.aoRenascer, p, api) end
			end
		end
	end)
	if p.Character then local r = p.Character:FindFirstChild("HumanoidRootPart") if r then p.Character:PivotTo(MENU_CF) r.Anchored = true end end
end)

-- ===================== debug =====================
if game:GetService("RunService"):IsStudio() then
	local bf = SS:FindFirstChild("DebugJogo") or Instance.new("BindableFunction")
	bf.Name = "DebugJogo"
	bf.OnInvoke = function(cmd, p, a, b)
		p = p or Players:GetPlayers()[1]
		if cmd == "menu" then RMenu.OnServerEvent:Wait() return true
		elseif cmd == "novo" then
			if mundoSujo then resetMundo() end
			local c = Meta.camp(p) Meta.resetCamp(p) c = Meta.camp(p) c.iniciado = true aplicarCamp(p)
			p:SetAttribute("NoMenu", false) api.congelar(p, false) api.irFase(p, a or 1, b or "inicio", false) return true
		elseif cmd == "fase" then p:SetAttribute("NoMenu", false) api.congelar(p, false) api.setPedras(p, (a or 1) - 1 >= 1 and ({ 0, 1, 3, 5, 6 })[a] or 0) api.irFase(p, a, b or "inicio", false) return true
		elseif cmd == "pedras" then api.setPedras(p, a) return true
		elseif cmd == "camp" then local c = Meta.camp(p) local fl = {} for k in pairs(c.flags) do table.insert(fl, k) end return HttpService:JSONEncode({ fase = c.fase, cp = c.cp, pedras = c.pedras, flags = fl })
		elseif cmd == "acionar" then
			local prompt = a
			local f = faseDe(prompt)
			local mod = modFase(numFase(f))
			local acao = prompt:GetAttribute("Acao")
			local fn = (mod and mod.acoes and mod.acoes[acao]) or GENERICAS[acao]
			return pcall(fn, p, prompt, api)
		elseif cmd == "gatilho" then
			local mod = modFase(a) return pcall(mod.gatilhos[b], p, api)
		end
	end
	bf.Parent = SS
end
