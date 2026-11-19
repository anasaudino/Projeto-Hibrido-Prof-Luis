-- Combate roguelike: poderes do Jane, projeteis, mutacoes (por run), arvore (permanente), orbes, arenas + bosses.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Config = require(RS.Combate.Config)
local ARENAS = require(RS.Combate.Arenas)
local Rem = RS.Combate.Remotes
local Inimigos = require(SS.CombateSrv.Inimigos)
local Meta = require(SS.CombateSrv.Meta)
local FASES = workspace:WaitForChild("Fases")
local AVISO = RS:WaitForChild("AvisoJogador")
local EV = SS:WaitForChild("Jogo"):WaitForChild("Eventos")

Players.RespawnTime = 3

local estado = {}
local function fx(tipo, ...) Rem.VFX:FireAllClients(tipo, ...) end
local function aviso(p, t) AVISO:FireClient(p, t) end
local function pedras(p) return p:GetAttribute("Pedras") or 0 end
local function hum(p) return p.Character and p.Character:FindFirstChildOfClass("Humanoid") end
local function hrp(p) return p.Character and p.Character:FindFirstChild("HumanoidRootPart") end

local pastaOrbes = workspace:FindFirstChild("Orbes") or Instance.new("Folder")
pastaOrbes.Name = "Orbes" pastaOrbes.Parent = workspace

-- ===================== stats =====================
local function statsBase(p)
	local s = {
		dano = Config.Pulso.Dano, danoMult = 1, recarga = Config.Pulso.Recarga, projeteis = 1, perfurar = 0, ricochete = 0,
		critico = 0.05, critMult = 2, vampiro = 0, ondaMult = 1, ondaRecarga = Config.Onda.Recarga, atordoar = 0, implosao = false,
		febre = 0, barreira = false, focoMax = Config.Jogador.Foco, focoRegen = Config.Jogador.FocoRegen,
		vidaMax = Config.Jogador.Vida, veloc = 1, cartas = 3,
		dash = false, dashRecarga = Config.Dash.Recarga, dashInvuln = Config.Dash.Invuln, segundaChance = false, ima = 1, orbeCura = 0,
	}
	Meta.aplicar(p, s)
	local n = pedras(p)
	if n >= 3 then s.ondaMult += 0.3 end
	if n >= 7 then s.danoMult += 0.5 s.focoRegen *= 2 s.recarga *= 0.8 s.perfurar += 1 end
	return s
end

local APLICAR = {
	dano = function(s) s.danoMult += 0.2 end,
	cadencia = function(s) s.recarga *= 0.85 end,
	vida = function(s) s.vidaMax += 25 end,
	foco = function(s) s.focoMax += 30 end,
	regen = function(s) s.focoRegen *= 1.4 end,
	veloc = function(s) s.veloc += 0.12 end,
	perfurar = function(s) s.perfurar += 1 end,
	multi = function(s) s.projeteis += 1 end,
	critico = function(s) s.critico += 0.15 end,
	vampiro = function(s) s.vampiro += 2 end,
	ondamaior = function(s) s.ondaMult += 0.35 s.ondaRecarga = math.max(2.5, s.ondaRecarga - 1) end,
	atordoar = function(s) s.atordoar = 0.6 end,
	ricochete = function(s) s.ricochete += 2 end,
	implosao = function(s) s.implosao = true end,
	febre = function(s) s.febre += 8 end,
	barreira = function(s) s.barreira = true end,
}

local function novoEstado(p)
	return { s = statsBase(p), buffs = {}, foco = Config.Jogador.Foco, ultimoGasto = 0, cdPulso = 0, cdOnda = 0, cdDash = 0, cdEco = 0, invulAte = 0,
		kills = 0, escudoPronto = true, segundaUsada = false, essenciaRun = 0, ult = 0 }
end

local function recalcular(p)
	local st = estado[p] if not st then return end
	st.s = statsBase(p)
	for id, n in pairs(st.buffs) do for _ = 1, n do APLICAR[id](st.s) end end
	st.s.ondaRecarga = math.max(2, st.s.ondaRecarga)
	st.s.dashRecarga = math.max(0.8, st.s.dashRecarga)
end

local function sincronizar(p)
	local st = estado[p] if not st then return end
	p:SetAttribute("FocoMax", st.s.focoMax)
	p:SetAttribute("RecargaPulso", st.s.recarga)
	p:SetAttribute("Foco", math.floor(st.foco))
	p:SetAttribute("Kills", st.kills)
	p:SetAttribute("Buffs", HttpService:JSONEncode(st.buffs))
	p:SetAttribute("Escudo", st.s.barreira and st.escudoPronto or false)
	p:SetAttribute("TemDash", st.s.dash)
	p:SetAttribute("DashRecarga", st.s.dashRecarga)
	p:SetAttribute("OndaRecarga", st.s.ondaRecarga)
	p:SetAttribute("SegundaChance", st.s.segundaChance and not st.segundaUsada)
	p:SetAttribute("Ult", math.floor(st.ult or 0))
end

local function aplicarPersonagem(p)
	local st = estado[p] local h = hum(p)
	if not st or not h then return end
	local k = h.Health / math.max(h.MaxHealth, 1)
	h.MaxHealth = st.s.vidaMax
	h.Health = math.max(1, st.s.vidaMax * k)
	h.WalkSpeed = Config.Jogador.Velocidade * st.s.veloc
	sincronizar(p)
end

local function gastar(st, custo)
	if st.foco < custo then return false end
	st.foco -= custo
	st.ultimoGasto = os.clock()
	return true
end

-- ===================== mutacoes =====================
local function sortearBuffs(st, n, soEpico, evitar)
	local pool = {}
	for _, b in ipairs(Config.Buffs) do
		if (st.buffs[b.id] or 0) < b.max and (not soEpico or b.rar ~= "Comum") and not (evitar and table.find(evitar, b.id)) then table.insert(pool, b) end
	end
	local escolhidos = {}
	for _ = 1, n do
		local total = 0
		for _, b in ipairs(pool) do total += Config.Raridades[b.rar].Peso * (soEpico and b.rar == "Epico" and 4 or 1) end
		if total <= 0 then break end
		local r = math.random() * total
		for i, b in ipairs(pool) do
			r -= Config.Raridades[b.rar].Peso * (soEpico and b.rar == "Epico" and 4 or 1)
			if r <= 0 then table.insert(escolhidos, b.id) table.remove(pool, i) break end
		end
	end
	return escolhidos
end

local function oferecer(p, titulo, soEpico)
	local st = estado[p] if not st then return end
	local ids = sortearBuffs(st, st.s.cartas, soEpico)
	if #ids == 0 then return end
	st.ofertas = ids st.ofertaTitulo = titulo st.ofertaEpico = soEpico
	st.escolha = st.escolha or Instance.new("BindableEvent")
	Rem.OferecerBuffs:FireClient(p, titulo, ids, st.buffs, Config.Rerolar)
	return st.escolha.Event:Wait()
end

local function aplicarEscolha(p, id)
	local st = estado[p]
	st.ofertas = nil
	st.buffs[id] = (st.buffs[id] or 0) + 1
	recalcular(p)
	aplicarPersonagem(p)
	if id == "vida" then local h = hum(p) if h then h.Health = math.min(h.MaxHealth, h.Health + 25) end end
	local b = Config.BuffPorId[id]
	fx("buff", p.Character, Config.Raridades[b.rar].Cor)
	aviso(p, "Mutação: " .. b.nome)
	if st.escolha then st.escolha:Fire(id) end
end

Rem.EscolherBuff.OnServerEvent:Connect(function(p, id)
	local st = estado[p]
	if not st or not st.ofertas or typeof(id) ~= "string" or not table.find(st.ofertas, id) then return end
	aplicarEscolha(p, id)
end)

Rem.Rerolar.OnServerEvent:Connect(function(p)
	local st = estado[p]
	if not st or not st.ofertas then return end
	if not Meta.gastar(p, Config.Rerolar) then aviso(p, "Essência insuficiente pra rerolar") return end
	local novas = sortearBuffs(st, st.s.cartas, st.ofertaEpico, st.ofertas)
	if #novas == 0 then novas = sortearBuffs(st, st.s.cartas, st.ofertaEpico) end
	st.ofertas = novas
	Rem.OferecerBuffs:FireClient(p, st.ofertaTitulo, novas, st.buffs, Config.Rerolar)
end)

-- ===================== arvore =====================
local arenaAtiva = nil -- id da arena em combate
Rem.ComprarNo.OnServerEvent:Connect(function(p, id)
	if typeof(id) ~= "string" or not estado[p] then return end
	if arenaAtiva then aviso(p, "Não dá pra evoluir no meio do combate") return end
	local ok, err = Meta.comprar(p, id)
	if ok then
		recalcular(p) aplicarPersonagem(p)
		fx("buff", p.Character, Config.Ramos[1].cor)
		aviso(p, "Desbloqueado: " .. Config.NoPorId[id].nome)
	else
		aviso(p, err or "Não foi possível")
	end
end)

-- ===================== orbes =====================
local orbes = {}
local function criarOrbe(pos)
	local o = Instance.new("Part")
	o.Shape = Enum.PartType.Ball o.Size = Vector3.one * 0.7 o.Material = Enum.Material.Neon o.Color = Config.CorPsi
	o.Anchored = true o.CanCollide = false o.CanQuery = false o.CastShadow = false
	local l = Instance.new("PointLight") l.Color = Config.CorPsi l.Range = 5 l.Brightness = 1.5 l.Parent = o
	local rp = RaycastParams.new() rp.FilterDescendantsInstances = { Inimigos.pasta(), Inimigos.pastaMortos(), pastaOrbes } rp.RespectCanCollide = true
	local r = workspace:Raycast(pos, Vector3.new(0, -14, 0), rp)
	local chao = r and r.Position.Y + 0.9 or pos.Y - 2.2
	local alvo = Vector3.new(pos.X + (math.random() - 0.5) * 6, chao, pos.Z + (math.random() - 0.5) * 6)
	o.Position = pos o.Parent = pastaOrbes
	TweenService:Create(o, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), { Position = alvo }):Play()
	orbes[o] = { base = alvo, t0 = os.clock() + 0.5 }
end

-- ===================== projeteis =====================
local bolts, proxId = {}, 0
local paramsInimigo = RaycastParams.new()
paramsInimigo.FilterType = Enum.RaycastFilterType.Include

local function paramsMundo()
	local rp = RaycastParams.new()
	local excl = { Inimigos.pasta(), Inimigos.pastaMortos(), pastaOrbes }
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(excl, p.Character) end end
	rp.FilterDescendantsInstances = excl rp.RespectCanCollide = true
	return rp
end

local function modeloInimigo(inst)
	local pasta = Inimigos.pasta()
	while inst and inst.Parent ~= pasta do inst = inst.Parent end
	return inst
end

local function novoBolt(p, origem, dir, extra)
	proxId += 1
	local st = estado[p]
	local b = {
		id = proxId, p = p, pos = origem, dir = dir.Unit, vel = Config.Pulso.Velocidade, resto = Config.Pulso.Alcance,
		perfurar = extra and extra.perfurar or st.s.perfurar, ric = extra and extra.ric or st.s.ricochete, acertou = extra and extra.acertou or {},
	}
	bolts[b.id] = b
	fx("bolt", b.id, origem, b.dir, b.vel, b.resto)
	return b
end

local function acertar(b, model, pos)
	local st = estado[b.p] if not st then return end
	local s = st.s
	local crit = math.random() < s.critico
	local dano = s.dano * s.danoMult * (crit and s.critMult or 1)
	fx("impacto", pos, crit)
	Inimigos.dano(model, dano, { critico = crit, dir = b.dir, forca = 45, atordoar = s.atordoar, queima = s.febre, dono = b.p, projetil = true })
	if not b.p:GetAttribute("EmUlt") then st.ult = math.min(100, (st.ult or 0) + dano / 22) b.p:SetAttribute("Ult", math.floor(st.ult)) end
	if s.vampiro > 0 then local h = hum(b.p) if h and h.Health > 0 then h.Health = math.min(h.MaxHealth, h.Health + s.vampiro) end end
end

local function ricochetear(b, pos)
	if b.ric <= 0 then return end
	local melhor, md = nil, 36
	for _, rec in ipairs(Inimigos.vivos()) do
		if not b.acertou[rec.model] then
			local d = (rec.hrp.Position - pos).Magnitude
			if d < md then melhor, md = rec, d end
		end
	end
	if melhor then
		local copia = {} for k, v in pairs(b.acertou) do copia[k] = v end
		novoBolt(b.p, pos, (melhor.hrp.Position + Vector3.new(0, 0.5, 0)) - pos, { perfurar = 0, ric = b.ric - 1, acertou = copia })
	end
end

-- objetos levitados pelo jogador (seguem na frente dele)
local segurando = {} -- [player] = { tipo, alvo(part/model), rec }

RunService.Heartbeat:Connect(function(dt)
	if next(bolts) then
		paramsInimigo.FilterDescendantsInstances = { Inimigos.pasta() }
		local pm = paramsMundo()
		for id, b in pairs(bolts) do
			local passo = b.vel * dt
			local desloc = b.dir * passo
			local r1 = workspace:Spherecast(b.pos, Config.Pulso.Raio, desloc, paramsInimigo)
			local r2 = workspace:Raycast(b.pos, desloc, pm)
			local model = r1 and modeloInimigo(r1.Instance)
			if r1 and model and not b.acertou[model] and (not r2 or r1.Distance <= r2.Distance) then
				b.acertou[model] = true
				acertar(b, model, r1.Position)
				if b.perfurar > 0 then
					b.perfurar -= 1
					b.pos = r1.Position b.resto -= r1.Distance
				else
					bolts[id] = nil
					fx("boltFim", id, r1.Position)
					ricochetear(b, r1.Position)
				end
			elseif r2 then
				bolts[id] = nil
				fx("boltFim", id, r2.Position)
				fx("impacto", r2.Position + r2.Normal * 0.2, false)
			else
				b.pos += desloc
				b.resto -= passo
				if b.resto <= 0 then bolts[id] = nil fx("boltFim", id) end
			end
		end
	end
	local agora = os.clock()
	for o, d in pairs(orbes) do
		if not o.Parent then orbes[o] = nil continue end
		if agora < d.t0 then continue end
		local alvo, dono
		for _, p in ipairs(Players:GetPlayers()) do
			local r = hrp(p) local h = hum(p) local st = estado[p]
			if r and h and h.Health > 0 and st and (r.Position - o.Position).Magnitude < Config.Orbe.Ima * st.s.ima then alvo, dono = r, p end
		end
		if alvo then
			local dir = alvo.Position - o.Position
			if dir.Magnitude < 2.2 then
				orbes[o] = nil o:Destroy()
				local st = estado[dono] local h = hum(dono)
				if h then h.Health = math.min(h.MaxHealth, h.Health + Config.Orbe.Cura + (st and st.s.orbeCura or 0)) end
				if st then st.foco = math.min(st.s.focoMax, st.foco + Config.Orbe.Foco) end
				Rem.VFX:FireClient(dono, "coletar")
			else
				o.Position += dir.Unit * math.min(dir.Magnitude, (22 + (agora - d.t0) * 30) * dt)
			end
		else
			o.Position = d.base + Vector3.new(0, math.sin(agora * 3 + d.base.X) * 0.25, 0)
		end
	end
	-- objetos segurados pela levitacao
	for p, s in pairs(segurando) do
		local r = hrp(p) local st = estado[p]
		if not r or not st or not s.alvo.Parent then segurando[p] = nil p:SetAttribute("Segurando", nil) continue end
		if s.tipo == "objeto" then
			st.foco -= 5 * dt st.ultimoGasto = os.clock()
			local alvoCF = CFrame.new(r.Position + r.CFrame.LookVector * 6 + Vector3.new(0, 1.5 + math.sin(agora * 3) * 0.3, 0)) * CFrame.Angles(0, agora * 0.8, 0)
			local atual = s.alvo:GetPivot()
			s.alvo:PivotTo(atual:Lerp(alvoCF, math.min(1, dt * 8)))
			if st.foco <= 0 then st.foco = 0 s.soltar() end
		end
	end
end)

-- ===================== eventos de combate =====================
local function explodir(p, pos, raio, dano)
	fx("explosao", pos, raio)
	for _, rec in ipairs(Inimigos.vivos()) do
		local d = rec.hrp.Position - pos
		if d.Magnitude <= raio then
			Inimigos.dano(rec.model, dano, { dir = d.Magnitude > 0.1 and d.Unit or Vector3.new(0, 1, 0), empurrao = 40, forca = 70, dono = p })
		end
	end
end

local function aoMatar(rec, info)
	local p = info and info.dono or Players:GetPlayers()[1]
	local st = p and estado[p]
	local pos = rec.hrp.Position
	for _ = 1, rec.cfg.Orbes or 1 do criarOrbe(pos) end
	if st then
		st.kills += 1
		if not p:GetAttribute("EmUlt") then st.ult = math.min(100, (st.ult or 0) + 7) end
		local ganho = Meta.ganhar(p, rec.cfg.Essencia or 1)
		st.essenciaRun += ganho
		Rem.VFX:FireClient(p, "essencia", pos, math.floor(ganho + 0.5))
		sincronizar(p)
		if st.s.implosao then
			task.delay(0.15, function() explodir(p, pos, 11, 35 * st.s.danoMult) end)
		end
	end
end

local function danoJogador(p, dano, de)
	local st = estado[p] local h = hum(p)
	if not h or h.Health <= 0 or p:GetAttribute("Congelado") then return end
	if st and os.clock() < st.invulAte then Rem.VFX:FireClient(p, "esquivou") return end
	if st and st.s.barreira and st.escudoPronto then
		st.escudoPronto = false
		fx("escudo", p.Character, false)
		sincronizar(p)
		task.delay(6, function()
			if estado[p] == st and st.s.barreira then st.escudoPronto = true fx("escudo", p.Character, true) sincronizar(p) end
		end)
		return
	end
	if st and st.s.segundaChance and not st.segundaUsada and dano >= h.Health then
		st.segundaUsada = true
		h.Health = h.MaxHealth * 0.5
		st.invulAte = os.clock() + 1.5
		fx("segundaChance", p.Character)
		aviso(p, "SEGUNDA CHANCE")
		sincronizar(p)
		return
	end
	h:TakeDamage(dano)
	Rem.VFX:FireClient(p, "danoJogador", dano, de)
end

-- ===================== arenas =====================
local arena = { token = 0 }
local faseModelCache = {}
local function faseModel(n) for _, f in ipairs(FASES:GetChildren()) do if tonumber(f.Name:match("^Fase(%d+)")) == n then return f end end end

local luzesArena = {}
local function coletarLuzes(id, def)
	if luzesArena[id] then return luzesArena[id] end
	local t = {}
	local f = faseModel(def.fase)
	if f then
		for _, l in ipairs(f:GetDescendants()) do
			if l:IsA("BasePart") and l.Name == "Luminaria" then
				local p = l.Position
				if p.X > def.min.X and p.X < def.max.X and p.Z > def.min.Z and p.Z < def.max.Z and p.Y > def.min.Y and p.Y < def.max.Y + 2 then
					local sl = l:FindFirstChildOfClass("SurfaceLight")
					t[l] = { cor = l.Color, luz = sl and sl.Color, br = sl and sl.Brightness }
				end
			end
		end
	end
	luzesArena[id] = t
	return t
end

local alarme = Instance.new("Sound")
alarme.Name = "Alarme" alarme.SoundId = Config.Sons.Alarme alarme.Looped = true alarme.Volume = 0.3 alarme.RollOffMaxDistance = 160
local alarmePart = Instance.new("Part") alarmePart.Anchored = true alarmePart.CanCollide = false alarmePart.CanQuery = false alarmePart.Transparency = 1 alarmePart.Size = Vector3.one alarmePart.Name = "AlarmeArena" alarmePart.Parent = workspace
alarme.Parent = alarmePart

local corAlarme = Color3.fromRGB(255, 80, 70)
local function luzesAlarme(id, def, on, cor)
	for l, o in pairs(coletarLuzes(id, def)) do
		local sl = l:FindFirstChildOfClass("SurfaceLight")
		if on then l.Color = cor or corAlarme if sl then sl.Color = cor or corAlarme end
		else l.Color = o.cor if sl then sl.Color = o.luz sl.Brightness = o.br end end
	end
	if on then alarmePart.Position = (def.min + def.max) / 2 if not alarme.IsPlaying then alarme:Play() end else alarme:Stop() end
end

task.spawn(function()
	local t = 0
	while true do
		task.wait(0.05)
		if arenaAtiva then
			t += 0.05
			local k = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 5))
			for l, o in pairs(luzesArena[arenaAtiva] or {}) do local sl = l:FindFirstChildOfClass("SurfaceLight") if sl then sl.Brightness = (o.br or 0.7) * k * 1.3 end end
		end
	end
end)

local function portasArena(def, trancar)
	local f = faseModel(def.fase)
	for _, n in ipairs(def.portas or {}) do
		local d = f and f:FindFirstChild("Portas") and f.Portas:FindFirstChild(n)
		if d then d:SetAttribute("Trancada", trancar) end
	end
end

local function dentroArena(def, pos)
	return pos.X > def.min.X and pos.X < def.max.X and pos.Y > def.min.Y and pos.Y < def.max.Y and pos.Z > def.min.Z and pos.Z < def.max.Z
end

local function resetArena()
	arena.token += 1
	if arenaAtiva then
		local def = ARENAS[arenaAtiva]
		luzesAlarme(arenaAtiva, def, false)
		portasArena(def, false)
		arenaAtiva = nil
	end
	for _, q in ipairs(Players:GetPlayers()) do q:SetAttribute("EmArena", nil) end
	Inimigos.limpar()
	for o in pairs(orbes) do o:Destroy() end
	orbes = {}
	for id in pairs(bolts) do bolts[id] = nil end
	for p, s in pairs(segurando) do if s.soltar then pcall(s.soltar) end end
end

local function spawnComAviso(tipo, sp, meu, alturaTeto)
	local def = Config.Inimigos[tipo] or {}
	local chao = Vector3.new(sp.X, sp.Y - 10, sp.Z)
	local rp = RaycastParams.new() rp.RespectCanCollide = true rp.FilterDescendantsInstances = { Inimigos.pasta() }
	local r = workspace:Raycast(sp, Vector3.new(0, -30, 0), rp)
	if r then chao = r.Position end
	if def.Voador or def.Fixo then
		fx("teleporte", chao + Vector3.new(0, 1, 0))
		task.delay(0.6, function() if arena.token == meu then Inimigos.criar(tipo, def.Fixo and (chao + Vector3.new(0, 1, 0)) or sp) end end)
	else
		fx("alcapao", chao)
		task.delay(0.8, function()
			if arena.token ~= meu then return end
			Inimigos.criar(tipo, sp)
			task.delay(0.55, function() fx("poeira", chao + Vector3.new(0, 0.3, 0)) end)
		end)
	end
end

local function pontoLonge(def, p, usados)
	local r = hrp(p)
	local opcoes = {}
	for k, sp in ipairs(def.spawns) do
		if not (usados and usados[k]) and (not r or (Vector3.new(sp.X, 0, sp.Z) - Vector3.new(r.Position.X, 0, r.Position.Z)).Magnitude > 12) then table.insert(opcoes, k) end
	end
	if #opcoes == 0 then for k in ipairs(def.spawns) do table.insert(opcoes, k) end end
	local k = opcoes[math.random(1, #opcoes)]
	if usados then usados[k] = true end
	return def.spawns[k]
end

Inimigos.init({
	fx = fx, aoMatar = aoMatar, danoJogador = danoJogador,
	empurrar = function(p, v) Rem.VFX:FireClient(p, "empurrao", v) end,
	reforcos = function(n, tipo)
		local p = Players:GetPlayers()[1]
		local def = arenaAtiva and ARENAS[arenaAtiva]
		if not def then return end
		local meu = arena.token
		local usados = {}
		for _ = 1, n do spawnComAviso(tipo or def.reforco or "Soldado", pontoLonge(def, p, usados), meu) task.wait(0.3) end
	end,
	arenaAtual = function() return arenaAtiva and ARENAS[arenaAtiva] end,
})

local function esperarLimpo(meu)
	task.wait(1.2)
	while arena.token == meu and #Inimigos.vivos() > 0 do task.wait(0.25) end
	return arena.token == meu
end

local function rodarArena(p, id)
	local def = ARENAS[id]
	arenaAtiva = id
	arena.token += 1
	local meu = arena.token
	portasArena(def, true)
	luzesAlarme(id, def, true)
	p:SetAttribute("EmArena", id)
	p:SetAttribute("Objetivo", def.objetivo or "Sobreviva à equipe de contenção")
	fx("banner", def.titulo or "CONTENÇÃO ATIVADA", def.sub or "")
	task.wait(2.2)
	local totalOndas = #def.ondas + (def.boss and 1 or 0)
	for i, onda in ipairs(def.ondas) do
		if arena.token ~= meu then return end
		fx("banner", ("ONDA %d / %d"):format(i, totalOndas), "")
		task.wait(1.4)
		local usados = {}
		for _, tipo in ipairs(onda) do
			if arena.token ~= meu then return end
			spawnComAviso(tipo, pontoLonge(def, p, usados), meu)
			task.wait(0.55)
		end
		if not esperarLimpo(meu) then return end
		task.wait(0.8)
		fx("banner", "ONDA LIMPA", "Escolha uma mutação")
		task.wait(0.8)
		oferecer(p, "ESCOLHA UMA MUTAÇÃO")
		if arena.token ~= meu then return end
		task.wait(0.6)
	end
	if def.boss then
		if arena.token ~= meu then return end
		local bcfg = Config.Inimigos[def.boss.tipo]
		luzesAlarme(id, def, true, Color3.fromRGB(255, 40, 30))
		fx("banner", "⚠  ALERTA  ⚠", (bcfg.Nome or def.boss.tipo) .. (bcfg.Chegada or " está chegando"))
		fx("bossChegando", def.boss.pos)
		task.wait(2.6)
		if arena.token ~= meu then return end
		if bcfg.Fixo or bcfg.Voador then fx("teleporte", def.boss.pos) else fx("alcapao", def.boss.pos - Vector3.new(0, 11, 0)) end
		task.wait(0.8)
		Inimigos.criar(def.boss.tipo, def.boss.pos)
		task.delay(0.7, function() fx("poeira", def.boss.pos - Vector3.new(0, 10.5, 0)) fx("tremer", def.boss.pos, 3) end)
		fx("banner", bcfg.Nome or def.boss.tipo, bcfg.Titulo or "")
		if not esperarLimpo(meu) then return end
		task.wait(1.5)
		local bonus = Meta.ganhar(p, 20)
		aviso(p, ("Área limpa: +%d Essência"):format(math.floor(bonus)))
		oferecer(p, "RECOMPENSA DO CHEFE", true)
		if arena.token ~= meu then return end
	end
	luzesAlarme(id, def, false)
	portasArena(def, false)
	arenaAtiva = nil
	p:SetAttribute("EmArena", nil)
	fx("banner", "ÁREA LIMPA", def.fim or "A contenção recuou... por enquanto")
	EV.ArenaLimpa:Fire(p, id, def.fase)
	Meta.salvar(p)
end

task.spawn(function()
	while true do
		task.wait(0.2)
		if not arenaAtiva then
			for _, p in ipairs(Players:GetPlayers()) do
				local r = hrp(p) local h = hum(p) local st = estado[p]
				local camp = Meta.camp(p)
				if r and h and h.Health > 0 and st and not st.ofertas and camp and not p:GetAttribute("NoMenu") then
					for id, def in pairs(ARENAS) do
						if pedras(p) >= (def.requerPedras or 0) and not camp.flags["arena_" .. id] and (not def.requerFlag or camp.flags[def.requerFlag]) and dentroArena(def, r.Position) then
							task.spawn(rodarArena, p, id)
							break
						end
					end
				end
				if arenaAtiva then break end
			end
		end
	end
end)

-- ===================== poderes =====================
local function podeUsar(p)
	local st = estado[p] local h = hum(p)
	return st and h and h.Health > 0 and pedras(p) >= 1 and not p:GetAttribute("Congelado")
end

local acoes = {}
function acoes.Pulso(p, mira)
	if typeof(mira) ~= "Vector3" or mira ~= mira then return end
	if not podeUsar(p) then return end
	local st = estado[p]
	local agora = os.clock()
	if agora < st.cdPulso then return end
	if segurando[p] and segurando[p].tipo == "inimigo" and pedras(p) >= 6 then segurando[p].arremessar(mira) return end
	if not gastar(st, Config.Pulso.Custo) then return end
	st.cdPulso = agora + st.s.recarga
	local r = hrp(p)
	local mao = p.Character:FindFirstChild("RightHand") or p.Character:FindFirstChild("Right Arm")
	local origem = (mao and mao.Position or r.Position + Vector3.new(0, 1, 0)) + r.CFrame.LookVector * 1.2
	local dir = mira - origem
	if dir.Magnitude < 1 then dir = r.CFrame.LookVector end
	local n = st.s.projeteis
	local passo = math.rad(Config.Pulso.Leque)
	for i = 1, n do
		local ang = (i - (n + 1) / 2) * passo
		novoBolt(p, origem, (CFrame.fromAxisAngle(Vector3.yAxis, ang) * dir.Unit))
	end
	fx("conjurar", p.Character)
	sincronizar(p)
end

function acoes.Onda(p)
	if not podeUsar(p) then return end
	if pedras(p) < 2 then aviso(p, "Você ainda não tem esse poder (Pedra 2)") return end
	local st = estado[p]
	local agora = os.clock()
	if agora < st.cdOnda then return end
	if not gastar(st, Config.Onda.Custo) then aviso(p, "Foco insuficiente") return end
	st.cdOnda = agora + st.s.ondaRecarga
	p:SetAttribute("OndaPronta", workspace:GetServerTimeNow() + st.s.ondaRecarga)
	local r = hrp(p)
	local raio = Config.Onda.Raio * st.s.ondaMult
	local dano = Config.Onda.Dano * st.s.ondaMult * st.s.danoMult
	fx("onda", p.Character, r.Position, raio)
	for _, rec in ipairs(Inimigos.vivos()) do
		local d = rec.hrp.Position - r.Position
		local plano = Vector3.new(d.X, 0, d.Z)
		if plano.Magnitude <= raio then
			Inimigos.dano(rec.model, dano, { dir = plano.Magnitude > 0.1 and plano.Unit or r.CFrame.LookVector, empurrao = Config.Onda.Empurrao, derrubar = pedras(p) >= 3, forca = 90, dono = p })
		end
	end
	local avisou = false
	for _, obj in ipairs(workspace:GetPartBoundsInRadius(r.Position, raio + 4)) do
		if obj:GetAttribute("Empurravel") and obj.Anchored then
			if pedras(p) >= 3 then
				obj.Anchored = false
				local d = obj.Position - r.Position
				local dir = Vector3.new(d.X, 0, d.Z)
				dir = dir.Magnitude > 0.1 and dir.Unit or r.CFrame.LookVector
				obj:ApplyImpulse((dir * 90 + Vector3.new(0, 35, 0)) * obj.AssemblyMass)
				EV.Empurrado:Fire(p, obj)
			elseif not avisou then
				avisou = true
				aviso(p, "Pesado demais... sua Onda ainda é fraca (Pedra 3)")
			end
		end
	end
	sincronizar(p)
end

function acoes.Dash(p)
	if not podeUsar(p) then return end
	local st = estado[p]
	if not st.s.dash then return end
	local agora = os.clock()
	if agora < st.cdDash - 0.15 then return end
	if not gastar(st, Config.Dash.Custo) then return end
	st.cdDash = agora + st.s.dashRecarga
	st.invulAte = agora + st.s.dashInvuln
	p:SetAttribute("DashPronto", workspace:GetServerTimeNow() + st.s.dashRecarga)
	fx("dash", p.Character)
	sincronizar(p)
end

function acoes.Eco(p)
	if not podeUsar(p) then return end
	if pedras(p) < 5 then aviso(p, "Você ainda não tem esse poder (Pedra 5)") return end
	local st = estado[p]
	local agora = os.clock()
	if agora < st.cdEco then return end
	if not gastar(st, 25) then aviso(p, "Foco insuficiente") return end
	st.cdEco = agora + 10
	local ate = workspace:GetServerTimeNow() + 7
	p:SetAttribute("EcoAte", ate)
	p:SetAttribute("EcoPronto", workspace:GetServerTimeNow() + 10)
	Rem.VFX:FireClient(p, "eco", 7)
	sincronizar(p)
end

-- R: levitar objeto marcado (puzzle) ou inimigo. Com a Pedra 6, R de novo / clique arremessa o inimigo.
function acoes.Levitar(p, alvo, mira)
	if not podeUsar(p) then return end
	if pedras(p) < 4 then aviso(p, "Você ainda não tem esse poder (Pedra 4)") return end
	local st = estado[p]
	local r = hrp(p)
	local s = segurando[p]
	if s then
		if s.tipo == "inimigo" and pedras(p) >= 6 and typeof(mira) == "Vector3" then s.arremessar(mira) else s.soltar() end
		return
	end
	if typeof(alvo) ~= "Instance" or not alvo:IsDescendantOf(workspace) then return end
	-- objeto levitavel?
	local obj = alvo
	while obj and obj ~= workspace and not obj:GetAttribute("Levitavel") do obj = obj.Parent end
	if obj and obj ~= workspace and obj:GetAttribute("Levitavel") then
		local pos = obj:GetPivot().Position
		if (pos - r.Position).Magnitude > 30 then aviso(p, "Longe demais") return end
		if st.foco < 10 then aviso(p, "Foco insuficiente") return end
		for _, x in ipairs(obj:IsA("BasePart") and { obj } or obj:GetDescendants()) do if x:IsA("BasePart") then x.Anchored = true x.CanCollide = false end end
		local reg = { tipo = "objeto", alvo = obj }
		function reg.soltar()
			segurando[p] = nil p:SetAttribute("Segurando", nil)
			local encaixe = obj:GetAttribute("Encaixe")
			local f = obj:FindFirstAncestorWhichIsA("Model")
			local sock
			if encaixe then
				for _, x in ipairs(FASES:GetDescendants()) do if x.Name == encaixe and x:IsA("BasePart") then sock = x break end end
			end
			if sock and (sock.Position - obj:GetPivot().Position).Magnitude < 9 then
				TweenService:Create(Instance.new("CFrameValue"), TweenInfo.new(0), {}):Play()
				obj:PivotTo(sock.CFrame)
				obj:SetAttribute("Levitavel", nil)
				fx("impacto", sock.Position, true)
				EV.Encaixe:Fire(p, encaixe, obj)
			else
				local rp = RaycastParams.new() rp.FilterDescendantsInstances = { obj, p.Character } rp.RespectCanCollide = true
				local hit = workspace:Raycast(obj:GetPivot().Position, Vector3.new(0, -20, 0), rp)
				local base = obj:IsA("BasePart") and obj.Size.Y / 2 or (select(2, obj:GetBoundingBox())).Y / 2
				if hit then obj:PivotTo(CFrame.new(hit.Position + Vector3.new(0, base, 0)) * (obj:GetPivot() - obj:GetPivot().Position)) end
			end
			for _, x in ipairs(obj:IsA("BasePart") and { obj } or obj:GetDescendants()) do if x:IsA("BasePart") then x.CanCollide = true end end
		end
		segurando[p] = reg
		p:SetAttribute("Segurando", "objeto")
		fx("levitar", obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"), p.Character)
		return
	end
	-- inimigo?
	local model = modeloInimigo(alvo)
	local rec = model and Inimigos.rec(model)
	if not rec then return end
	if rec.cfg.Levitavel == false or (rec.boss and not rec.cfg.Levitavel) then aviso(p, "Não dá pra levitar isso") return end
	if (rec.hrp.Position - r.Position).Magnitude > 40 then aviso(p, "Longe demais") return end
	if not gastar(st, 25) then aviso(p, "Foco insuficiente") return end
	local dur = pedras(p) >= 6 and 4 or 2.2
	Inimigos.levitar(model, dur)
	fx("levitar", rec.hrp, p.Character)
	if pedras(p) >= 6 then
		local reg = { tipo = "inimigo", alvo = model }
		function reg.soltar() segurando[p] = nil p:SetAttribute("Segurando", nil) end
		function reg.arremessar(ponto)
			segurando[p] = nil p:SetAttribute("Segurando", nil)
			Inimigos.arremessar(model, ponto, function(pos)
				explodir(p, pos, 9, 55 * st.s.danoMult)
			end)
		end
		segurando[p] = reg
		p:SetAttribute("Segurando", "inimigo")
		task.delay(dur, function() if segurando[p] == reg then reg.soltar() end end)
	end
end

-- V: ULTIMATE "Colapso Psiquico" — explosao mental, estrangula todos no ar e esmaga no chao
local ULT = { Raio = 46, Subida = 1.35, NoAr = 2.3 }
function acoes.Ultimate(p)
	if not podeUsar(p) or p:GetAttribute("EmUlt") then return end
	local st = estado[p]
	if (st.ult or 0) < 100 then return end
	st.ult = 0
	p:SetAttribute("EmUlt", true)
	sincronizar(p)
	st.invulAte = os.clock() + ULT.Subida + ULT.NoAr + 2
	local r = hrp(p)
	local centro = r.Position
	fx("ultInicio", p.Character)
	task.wait(ULT.Subida)
	fx("ultExplosao", p.Character, centro, ULT.Raio)
	local erguidos, bosses = {}, {}
	for _, rec in ipairs(Inimigos.vivos()) do
		if (rec.hrp.Position - centro).Magnitude <= ULT.Raio then
			if rec.boss then
				table.insert(bosses, rec)
				rec.atordoadoAte = os.clock() + ULT.NoAr + 1.5
				Inimigos.dano(rec.model, rec.hum.MaxHealth * 0.06, { dono = p, semTranco = false })
			elseif rec.cfg.Mecanico then
				Inimigos.dano(rec.model, 70 * st.s.danoMult, { dono = p, dir = (rec.hrp.Position - centro).Unit, forca = 60 })
			elseif Inimigos.estrangular(rec.model, centro) then
				table.insert(erguidos, rec)
			end
		end
	end
	task.wait(ULT.NoAr)
	fx("ultBatida", p.Character, centro)
	for _, rec in ipairs(erguidos) do
		task.spawn(Inimigos.esmagar, rec.model, 120 * st.s.danoMult + rec.hum.MaxHealth * 0.35, { dono = p })
	end
	for _, rec in ipairs(bosses) do
		if rec.model.Parent then Inimigos.dano(rec.model, rec.hum.MaxHealth * 0.1 * st.s.danoMult, { dono = p, dir = Vector3.new(0, -1, 0), forca = 40 }) end
	end
	task.wait(1.1)
	p:SetAttribute("EmUlt", false)
end

Rem.Acao.OnServerEvent:Connect(function(p, nome, ...)
	if typeof(nome) ~= "string" or not acoes[nome] then return end
	acoes[nome](p, ...)
end)

task.spawn(function()
	while true do
		local dt = task.wait(0.1)
		for p, st in pairs(estado) do
			if os.clock() - st.ultimoGasto > Config.Jogador.FocoAtraso and st.foco < st.s.focoMax then
				st.foco = math.min(st.s.focoMax, st.foco + st.s.focoRegen * dt)
			end
			if p:GetAttribute("Foco") ~= math.floor(st.foco) then p:SetAttribute("Foco", math.floor(st.foco)) end
		end
	end
end)

-- ===================== ciclo de vida =====================
local function onPersonagem(p, char)
	local h = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	aplicarPersonagem(p)
	local st = estado[p]
	if st then st.foco = st.s.focoMax st.escudoPronto = true end
	h.Died:Connect(function()
		local run = estado[p]
		Rem.VFX:FireClient(p, "morte", run and run.kills or 0, run and math.floor(run.essenciaRun) or 0)
		segurando[p] = nil
		p:SetAttribute("EmUlt", false)
		estado[p] = novoEstado(p)
		sincronizar(p)
		resetArena()
		Meta.salvar(p)
	end)
end

local function onJogador(p)
	Meta.carregar(p)
	estado[p] = novoEstado(p)
	sincronizar(p)
	local ultimo = pedras(p)
	p:GetAttributeChangedSignal("Pedras"):Connect(function()
		local n = pedras(p)
		recalcular(p) aplicarPersonagem(p)
		if n > ultimo and not p:GetAttribute("NoMenu") then
			ultimo = n
			task.delay(2.5, function() oferecer(p, "MUTAÇÃO DESPERTADA") end)
		end
		ultimo = math.max(ultimo, n)
	end)
	p.CharacterAdded:Connect(function(c) onPersonagem(p, c) end)
	if p.Character then task.spawn(onPersonagem, p, p.Character) end
end
Players.PlayerAdded:Connect(onJogador)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onJogador, p) end
Players.PlayerRemoving:Connect(function(p) estado[p] = nil segurando[p] = nil Meta.soltar(p) end)

-- Novo Jogo: o mapa foi trocado, entao larga arena, inimigos, luzes em cache e a run atual
EV:WaitForChild("ResetMundo").Event:Connect(function()
	resetArena()
	table.clear(luzesArena)
	for _, p in ipairs(Players:GetPlayers()) do estado[p] = novoEstado(p) sincronizar(p) end
end)

-- ===================== debug (so Studio) =====================
if RunService:IsStudio() then
	local bf = SS:FindFirstChild("DebugCombate") or Instance.new("BindableFunction")
	bf.Name = "DebugCombate"
	bf.OnInvoke = function(cmd, p, a, b)
		p = p or Players:GetPlayers()[1]
		local st = estado[p]
		if cmd == "poder" then p:SetAttribute("Pedras", math.max(pedras(p), a or 1)) p:SetAttribute("PoderAtracao", true) return true
		elseif cmd == "pulso" then acoes.Pulso(p, a) return true
		elseif cmd == "onda" then acoes.Onda(p) return true
		elseif cmd == "dash" then acoes.Dash(p) return true
		elseif cmd == "eco" then acoes.Eco(p) return true
		elseif cmd == "levitar" then acoes.Levitar(p, a, b) return true
		elseif cmd == "ofertas" then return st and st.ofertas
		elseif cmd == "estado" then return { arena = arenaAtiva or "idle", vivos = #Inimigos.vivos(), foco = st and st.foco, kills = st and st.kills, buffs = st and HttpService:JSONEncode(st.buffs), ofertas = st and st.ofertas and table.concat(st.ofertas, ","), essencia = Meta.essencia(p) }
		elseif cmd == "pegar" then if st and st.ofertas then local id = a or st.ofertas[1] aplicarEscolha(p, id) return id end
		elseif cmd == "essencia" then Meta.ganhar(p, a or 100) return Meta.essencia(p)
		elseif cmd == "comprar" then local ok, err = Meta.comprar(p, a) if ok then recalcular(p) aplicarPersonagem(p) end return ok, err
		elseif cmd == "stats" then return st and HttpService:JSONEncode(st.s)
		elseif cmd == "criar" then return Inimigos.criar(a or "Soldado", b) ~= nil
		elseif cmd == "vivos" then local t = {} for _, r in ipairs(Inimigos.vivos()) do table.insert(t, { r.tipo, r.hrp.Position, r.hum.Health, r.fase }) end return t
		elseif cmd == "pularOndas" then for _, d in pairs(ARENAS) do d.ondas = {} end return true
		elseif cmd == "semBoss" then for _, d in pairs(ARENAS) do d.boss = nil end return true
		elseif cmd == "arena" then task.spawn(rodarArena, p, a) return true
		elseif cmd == "reset" then resetArena() return true
		elseif cmd == "ult" then st.ult = 100 sincronizar(p) return true
		elseif cmd == "usarUlt" then task.spawn(acoes.Ultimate, p) return true
		elseif cmd == "imortal" then local h = hum(p) h.MaxHealth = 1e6 h.Health = 1e6 return true
		end
	end
	bf.Parent = SS
end
