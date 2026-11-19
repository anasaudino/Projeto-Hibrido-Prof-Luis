-- FASE 3 — Manutencao e Geradores (Capitulo 3: Recuperacao)
local TweenService = game:GetService("TweenService")
local SS = game:GetService("ServerStorage")
local Inimigos = require(SS.CombateSrv.Inimigos)
local F = {}
local FASE = workspace:WaitForChild("Fases"):WaitForChild("Fase3")
local GP = FASE:WaitForChild("Gameplay")
local OZ = 1000
local function V(x, y, z) return Vector3.new(x, y, z + OZ) end
local VERDE = Color3.fromRGB(60, 230, 120)

local function ligarGerador(nomeLed)
	local led = FASE:FindFirstChild(nomeLed, true)
	if led then led.Color = VERDE end
end

local function geradorA(p, api)
	ligarGerador("LedGeradorA")
	local enc = GP:FindFirstChild("EncaixeCelula") if enc then enc.Transparency = 1 end
	api.porta(3, "Porta_Contencao", false)
	api.porta(3, "Porta_Leste", false)
end
local function geradores(p, api)
	ligarGerador("LedGeradorB")
	for i = 1, 4 do local a = GP:FindFirstChild("AlavancaB" .. i) local pr = a and a:FindFirstChildWhichIsA("ProximityPrompt", true) if pr then pr.Enabled = false end end
	if api.flag(p, "f3_geradorA") then
		api.marcar(p, "f3_geradores")
		api.porta(3, "Porta_Patio", false)
	end
end

F.acoes = {}
function F.acoes.AlavancaB(p, prompt, api)
	local haste = prompt.Parent.Parent:FindFirstChild("Haste")
	if haste then TweenService:Create(haste, TweenInfo.new(0.3, Enum.EasingStyle.Back), { CFrame = haste.CFrame * CFrame.Angles(0, 0, 1) + Vector3.new(0, -0.5, 0) }):Play() end
	if prompt:GetAttribute("Certa") then
		api.marcar(p, "f3_geradorB")
		geradores(p, api)
		api.aviso(p, "Gerador B religado!")
		if api.flag(p, "f3_geradores") then api.objetivo(p, "Os dois geradores voltaram. Atravesse a Doca de Carga (norte).")
		else api.objetivo(p, "Falta religar o Gerador A (célula de energia)") end
	else
		prompt.Enabled = false
		api.aviso(p, "ALAVANCA ERRADA — alarme disparado!")
		api.historia(p, "flash", 0.5, Color3.fromRGB(255, 40, 40))
		for i = 1, 2 do
			local pos = V(95 + i * 6, 12, -50)
			game:GetService("ReplicatedStorage").Combate.Remotes.VFX:FireAllClients("alcapao", V(95 + i * 6, 0, -50))
			task.delay(0.8, function() Inimigos.criar("Soldado", pos) end)
		end
		task.delay(6, function() if prompt.Parent then prompt.Enabled = true end
			local haste2 = prompt.Parent.Parent:FindFirstChild("Haste")
			if haste2 then TweenService:Create(haste2, TweenInfo.new(0.3), { CFrame = haste2.CFrame * CFrame.Angles(0, 0, -1) + Vector3.new(0, 0.5, 0) }):Play() end
		end)
	end
end

F.gatilhos = {}
function F.gatilhos.vael_salva(p, api)
	api.radio(p, "f3_criatura")
	local sold = Inimigos.criar("Soldado", V(52, 3, 36))
	task.wait(2.2)
	if not sold or not sold.Parent then return end
	local pos = sold:GetPivot().Position
	game:GetService("ReplicatedStorage").Combate.Remotes.VFX:FireAllClients("teleporte", pos + Vector3.new(0, -2, 3))
	local v = api.Vael.criar(CFrame.new(pos + Vector3.new(0, 3, 3.5)) * CFrame.Angles(0, math.pi, 0), FASE)
	task.wait(0.4)
	if sold.Parent and sold.Parent.Name == "Inimigos" then
		Inimigos.dano(sold, 9999, { dir = Vector3.new(0, 0.3, -1).Unit, forca = 120 })
	end
	api.historia(p, "flash", 0.3, Color3.fromRGB(255, 60, 60))
	if v then
		local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if r then v.olharPara(r.Position) end
		task.wait(2.5)
		api.falas(p, { { "JANE", "Ele... me salvou?", 2.5 } })
		task.wait(0.5)
		v.sumir(1.5)
	end
	api.objetivo(p, "Pegue a pedra do Módulo 05 (fundo da Contenção)")
end

function F.aposMemoria(p, api)
	if not api.flag(p, "f3_geradorB") then api.objetivo(p, "Religue o Gerador B (leste). Só UMA alavanca é a certa — o ECO (G) mostra qual.") end
end

function F.aposPedra(p, api, n)
	if n == 4 then
		api.checkpoint(p, 3, "deposito")
		api.objetivo(p, "Gerador A: aponte pra célula no alto e aperte R (Levitar). Solte perto do encaixe.")
	elseif n == 5 then
		api.checkpoint(p, 3, "contencao")
		api.objetivo(p, "Aperte G (ECO). Alguma coisa aconteceu nesta sala.")
	end
end

function F.encaixe(p, nome, obj, api)
	if nome ~= "EncaixeCelula" then return end
	api.marcar(p, "f3_geradorA")
	geradorA(p, api)
	api.aviso(p, "Gerador A religado!")
	if api.flag(p, "f3_geradorB") then geradores(p, api) api.objetivo(p, "Os dois geradores voltaram. Atravesse a Doca de Carga (norte).")
	else api.objetivo(p, "A Contenção (sul) e o corredor leste abriram.") end
end

F.arenaLimpa = {}
F.arenaLimpa.Galeria = function(p, api)
	api.objetivo(p, "Encontre o Módulo 04 no Depósito (norte)")
end
F.arenaLimpa.Patio = function(p, api)
	api.objetivo(p, "Pegue o elevador de carga")
end

function F.podeSair(p, api)
	if not api.flag(p, "arena_Patio") then return false, "O elevador está travado." end
	return true
end

function F.aoCarregar(p, api, cp)
	if api.flag(p, "pedra_4") and GP:FindFirstChild("Pedra_04") then GP.Pedra_04:Destroy() end
	if api.flag(p, "pedra_5") and GP:FindFirstChild("Pedra_05") then GP.Pedra_05:Destroy() end
	if api.flag(p, "f3_geradorA") then
		geradorA(p, api)
		local cel = GP:FindFirstChild("CelulaEnergia") local enc = GP:FindFirstChild("EncaixeCelula")
		if cel and enc then cel:PivotTo(enc.CFrame) cel:SetAttribute("Levitavel", nil) end
	end
	if api.flag(p, "f3_geradorB") then geradores(p, api) end
	if api.flag(p, "arena_Patio") then api.porta(3, "Porta_ElevF3", false) api.porta(3, "Porta_Patio", false) end
	if cp == "inicio" then
		api.radio(p, "f3_ward")
		api.objetivo(p, "Soldados no subsolo. Sobreviva.")
	end
end

function F.objetivoPadrao(p, api)
	local f = function(k) return api.flag(p, k) end
	if not f("arena_Galeria") then return "Soldados no subsolo. Sobreviva." end
	if not f("pedra_4") then return "Encontre o Módulo 04 no Depósito (norte)" end
	if not f("f3_geradorA") then return "Gerador A: aponte pra célula no alto e aperte R (Levitar). Solte perto do encaixe." end
	if not f("pedra_5") then return "Pegue a pedra do Módulo 05 (fundo da Contenção)" end
	if not f("mem_PontoMemoria") then return "Aperte G (ECO). Alguma coisa aconteceu nesta sala." end
	if not f("f3_geradorB") then return "Religue o Gerador B (leste). Só UMA alavanca é a certa — o ECO (G) mostra qual." end
	if not f("arena_Patio") then return "Os dois geradores voltaram. Atravesse a Doca de Carga (norte)." end
	return "Pegue o elevador de carga"
end

return F
