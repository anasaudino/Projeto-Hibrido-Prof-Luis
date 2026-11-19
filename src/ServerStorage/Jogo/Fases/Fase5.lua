-- FASE 5 — Setor de Contencao e Sala do Portal (Capitulo 5: O Vigia + Final)
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Inimigos = require(SS.CombateSrv.Inimigos)
local Meta = require(SS.CombateSrv.Meta)
local F = {}
local FASE = workspace:WaitForChild("Fases"):WaitForChild("Fase5")
local GP = FASE:WaitForChild("Gameplay")
local OZ = 2000
local function V(x, y, z) return Vector3.new(x, y, z + OZ) end
local C = V(118, 0, -85)
local vaelAliado

local function abrirEntulho(instantaneo)
	local ent = GP:FindFirstChild("EntulhoPortal")
	if ent then
		for _, b in ipairs(ent:GetChildren()) do
			if b:IsA("BasePart") then
				if instantaneo then b:Destroy() else
					b.Anchored = false b:ApplyImpulse((Vector3.new(math.random() - 0.5, 0.6, math.random() - 0.5) * 80 + Vector3.new(40, 0, 0)) * b.AssemblyMass)
					task.delay(3, function() if b.Parent then TweenService:Create(b, TweenInfo.new(1), { Transparency = 1 }):Play() b.CanCollide = false task.delay(1.1, function() b:Destroy() end) end end)
				end
			end
		end
	end
end
local function ligarTrava(i)
	local t = GP:FindFirstChild("Trava" .. i)
	if not t then return end
	local led = t:FindFirstChild("Led") if led then led.Color = Color3.fromRGB(60, 230, 120) end
	local pr = t:FindFirstChildWhichIsA("ProximityPrompt", true) if pr then pr.Enabled = false end
end
local function abrirNucleo()
	local esc = GP:FindFirstChild("EscudoNucleo") if esc then TweenService:Create(esc, TweenInfo.new(1.5), { Transparency = 1 }):Play() esc.CanCollide = false end
	local pd = GP:FindFirstChild("Pedra_07")
	local pr = pd and pd:FindFirstChildWhichIsA("ProximityPrompt", true) if pr then pr.Enabled = true end
end
local function membrana(on)
	local mb = GP:FindFirstChild("Membrana")
	if mb then
		TweenService:Create(mb, TweenInfo.new(2), { Transparency = on and 0.05 or 0.6, Color = on and Color3.fromRGB(190, 120, 255) or Color3.fromRGB(40, 10, 70) }):Play()
	end
end

F.acoes = {}
function F.acoes.Trava5(p, prompt, api)
	local id = prompt:GetAttribute("Id")
	ligarTrava(id)
	api.marcar(p, "f5_trava" .. id)
	local n = 0 for i = 1, 3 do if api.flag(p, "f5_trava" .. i) then n += 1 end end
	api.aviso(p, ("Trava %d/3 desligada"):format(n))
	-- a contencao reage
	local rv = RS.Combate.Remotes.VFX
	for k = 1, 2 do
		local a = math.random() * math.pi * 2
		local pos = C + Vector3.new(math.cos(a) * 24, 20, math.sin(a) * 24)
		rv:FireAllClients("alcapao", Vector3.new(pos.X, 0, pos.Z))
		task.delay(0.8, function() Inimigos.criar(n >= 3 and "Elite" or "Soldado", pos) end)
	end
	if n >= 3 then
		abrirNucleo()
		api.objetivo(p, "O núcleo abriu. Pegue a SÉTIMA pedra.")
	else
		api.objetivo(p, ("Desligue as travas do portal (%d/3)"):format(n))
	end
end

function F.acoes.Estabilizar(p, prompt, api)
	prompt.Enabled = false
	api.marcar(p, "f5_estabilizou")
	api.historia(p, "flash", 1.2, Color3.fromRGB(220, 170, 255))
	membrana(true)
	if vaelAliado then vaelAliado.ancorar(false) vaelAliado.andar(C + Vector3.new(0, 3, -6), 8) end
	api.cutscene(p, {
		tomadas = {
			{ de = CFrame.lookAt(C + Vector3.new(0, 6, 22), C + Vector3.new(0, 12, -6)), ate = CFrame.lookAt(C + Vector3.new(0, 8, 14), C + Vector3.new(0, 13, -6)), dur = 7 },
			{ de = CFrame.lookAt(C + Vector3.new(-14, 4, 6), C + Vector3.new(0, 4, 0)), ate = CFrame.lookAt(C + Vector3.new(-10, 5, 2), C + Vector3.new(0, 5, -4)), dur = 7 },
		},
		falas = "f5_final",
	})
	api.fade(p, true, 1.5, "")
	api.teleportar(p, api.cpCFrame(5, "outro"))
	api.congelar(p, true)
	api.fade(p, false, 1.5)
	local O = V(600, 60, 0)
	api.cutscene(p, {
		tomadas = {
			{ de = CFrame.lookAt(O + Vector3.new(0, 4, 40), O + Vector3.new(0, 30, -110)), ate = CFrame.lookAt(O + Vector3.new(0, 10, 26), O + Vector3.new(0, 40, -110)), dur = 7 },
			{ de = CFrame.lookAt(O + Vector3.new(20, 30, 50), O + Vector3.new(0, 0, 25)), ate = CFrame.lookAt(O + Vector3.new(30, 60, 60), O + Vector3.new(0, 0, 0)), dur = 6 },
		},
		falas = { { "", "Pela primeira vez, Jane vê o céu do lugar de onde veio.", 5 }, { "", "O laboratório ficou pra trás.", 4 } },
	})
	api.congelar(p, true)
	api.historia(p, "creditos", 24)
	task.wait(26)
	api.doc(p, "f5_fase2")
	local c = Meta.camp(p)
	if c then c.zerado = true c.fase = 5 c.cp = "portal" Meta.sujar(p) Meta.salvar(p) end
	task.wait(8)
	api.fade(p, true, 1)
	p:SetAttribute("NoMenu", true)
	api.historia(p, "menu")
end

F.gatilhos = {}
function F.gatilhos.perseguicao5(p, api)
	api.objetivo(p, "Ele está aqui de novo. CORRA pro fundo da galeria.")
	api.falas(p, { { "JANE", "De novo não...", 2 } })
	local v = api.Vael.criar(CFrame.new(V(78, 5, 10)) * CFrame.Angles(0, 0, 0), FASE)
	if not v then return end
	task.wait(1)
	local res = v.perseguir(p, { vel = 14, alcance = 4.5, parar = function() return api.flag(p, "g_beco") end })
	v.parar()
	if not api.flag(p, "g_beco") then api.marcar(p, "g_beco") end
	F.reconhecimento(p, api, v)
end

function F.gatilhos.beco(p, api)
	-- a perseguicao detecta a flag e chama o reconhecimento
end

function F.reconhecimento(p, api, v)
	if api.flag(p, "f5_reconhecimento") then return end
	api.marcar(p, "f5_reconhecimento")
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if r and v then v.olharPara(r.Position) v.andar(r.Position + (v.hrp.Position - r.Position).Unit * 6, 6) end
	task.wait(1.5)
	if v then v.parar() v.ancorar(true) end
	local vp = v and v.hrp.Position or V(78, 5, -80)
	api.cutscene(p, {
		tomadas = {
			{ de = CFrame.lookAt(vp + Vector3.new(6, 2, 4), vp + Vector3.new(0, 3, 0)), ate = CFrame.lookAt(vp + Vector3.new(4, 1, 3), vp + Vector3.new(0, 4, 0)), dur = 7 },
			{ de = CFrame.lookAt(vp + Vector3.new(-8, 5, 10), vp + Vector3.new(0, 2, -6)), ate = CFrame.lookAt(vp + Vector3.new(-6, 4, 7), vp + Vector3.new(0, 2, -6)), dur = 6.5 },
		},
		falas = "f5_vael",
	})
	api.historia(p, "flash", 1, Color3.fromRGB(255, 120, 100))
	-- o Vael abre o caminho
	if v then v.ancorar(false) v.andar(V(82, 3, -83), 10) end
	task.wait(2)
	abrirEntulho(false)
	RS.Combate.Remotes.VFX:FireAllClients("explosaoVermelha", V(84, 2, -83), 8)
	api.porta(5, "Porta_Portal", false)
	if v then task.wait(1) v.andar(C + Vector3.new(-10, 3, 14), 10) task.wait(4) v.parar() v.ancorar(true) end
	vaelAliado = v
	api.checkpoint(p, 5, "celas")
	api.objetivo(p, "Ele abriu o caminho. Desligue as 3 travas do portal.")
end

function F.aposPedra(p, api, n)
	if n ~= 7 then return end
	api.checkpoint(p, 5, "portal")
	for _, d in ipairs(GP.Flutuar:GetChildren()) do
		if d:IsA("BasePart") then
			TweenService:Create(d, TweenInfo.new(4, Enum.EasingStyle.Sine), { CFrame = d.CFrame + Vector3.new(0, math.random(4, 9), 0) * 1 }):Play()
		end
	end
	local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	local pp = r and r.Position or C
	api.cutscene(p, {
		tomadas = {
			{ de = CFrame.lookAt(pp + Vector3.new(8, 3, 8), pp), ate = CFrame.lookAt(pp + Vector3.new(-8, 5, 8), pp), dur = 7 },
		},
		falas = { { "JANE", "As pedras não me deram poderes novos.", 3.5 }, { "JANE", "Elas só... tiraram as correntes.", 3.5 } },
	})
	api.marcar(p, "f5_despertar")
	api.objetivo(p, "Algo grande está chegando.")
end

F.arenaLimpa = {}
F.arenaLimpa.Bloqueio = function(p, api)
	api.checkpoint(p, 5, "celas")
	api.objetivo(p, "Siga pela galeria de celas (norte)")
end
F.arenaLimpa.Final = function(p, api)
	membrana(true)
	local est = GP:FindFirstChild("PontoEstabilizar")
	local pr = est and est:FindFirstChildWhichIsA("ProximityPrompt") if pr then pr.Enabled = true end
	if not vaelAliado then vaelAliado = api.Vael.criar(CFrame.new(C + Vector3.new(-8, 4, 10)), FASE) end
	api.falas(p, { { "JANE", "O portal... ele tá tentando abrir de novo.", 3 }, { "JANE", "Eu consigo segurar. Eu sou a ponte.", 3 } })
	api.objetivo(p, "Estabilize o portal (segure E no centro)")
end

function F.aoCarregar(p, api, cp)
	for i = 1, 3 do if api.flag(p, "f5_trava" .. i) then ligarTrava(i) end end
	if api.flag(p, "f5_trava1") and api.flag(p, "f5_trava2") and api.flag(p, "f5_trava3") then abrirNucleo() end
	if api.flag(p, "pedra_7") and GP:FindFirstChild("Pedra_07") then GP.Pedra_07:Destroy() end
	if api.flag(p, "arena_Bloqueio") then api.porta(5, "Porta_Celas", false) end
	if api.flag(p, "f5_reconhecimento") then
		abrirEntulho(true)
		api.porta(5, "Porta_Portal", false)
		if not vaelAliado then vaelAliado = api.Vael.criar(CFrame.new(C + Vector3.new(-10, 4, 14)), FASE) if vaelAliado then vaelAliado.ancorar(true) end end
	end
	if api.flag(p, "arena_Final") then F.arenaLimpa.Final(p, api) end
	if cp == "inicio" then
		api.falas(p, { { "JANE", "A Sala do Portal fica depois das celas.", 3 }, { "JANE", "É lá que está a última pedra.", 2.5 } })
		api.objetivo(p, "Chegue à Sala do Portal")
	end
end

function F.objetivoPadrao(p, api)
	local f = function(k) return api.flag(p, k) end
	if not f("arena_Bloqueio") then return "Chegue à Sala do Portal" end
	if not f("f5_reconhecimento") then return "Siga pela galeria de celas (norte)" end
	local n = 0 for i = 1, 3 do if f("f5_trava" .. i) then n += 1 end end
	if n < 3 then return ("Desligue as travas do portal (%d/3)"):format(n) end
	if not f("pedra_7") then return "O núcleo abriu. Pegue a SÉTIMA pedra." end
	if not f("arena_Final") then return "Algo grande está chegando." end
	return "Estabilize o portal (segure E no centro)"
end

return F
