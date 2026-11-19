-- FASE 2 — Ala de Pesquisa (Capitulo 2: O Projeto)
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local F = {}
local FASE = workspace:WaitForChild("Fases"):WaitForChild("Fase2")
local GP = FASE:WaitForChild("Gameplay")
local OZ = 500
local function V(x, y, z) return Vector3.new(x, y, z + OZ) end

F.acoes = {}
function F.acoes.Cartao(p, prompt, api)
	prompt.Enabled = false
	for _, n in ipairs({ "Cartao", "CartaoFaixa" }) do local x = GP:FindFirstChild(n) if x then x:Destroy() end end
	api.marcar(p, "f2_cartao")
	api.porta(2, "Porta_Modulo02", false)
	api.aviso(p, "Cartão de acesso nível 2")
	api.objetivo(p, "Use o cartão no Módulo 02 (sul do corredor)")
end

F.gatilhos = {}
function F.gatilhos.chegada(p, api)
	api.objetivo(p, "Explore a Ala de Pesquisa. Procure um cartão de acesso.")
end

local function memoriaVisivel(on, tempo)
	local pasta = GP:FindFirstChild("MemoriaTeste")
	if not pasta then return end
	for _, x in ipairs(pasta:GetDescendants()) do
		if x:IsA("BasePart") then
			TweenService:Create(x, TweenInfo.new(tempo or 1), { Transparency = on and (x:GetAttribute("MemTransp") or 0.5) or 1 }):Play()
		end
	end
end

function F.gatilhos.memoria(p, api)
	api.historia(p, "flash", 1.2, Color3.new(1, 1, 1))
	memoriaVisivel(true, 1.5)
	-- a descarga telecinetica no fim da memoria
	task.delay(11.5, function()
		api.historia(p, "flash", 0.8, Color3.fromRGB(200, 150, 255))
		local pasta = GP:FindFirstChild("MemoriaTeste")
		local j = pasta and pasta:FindFirstChild("JaneCrianca")
		local ut = j and j:FindFirstChild("UpperTorso")
		if ut then game:GetService("ReplicatedStorage").Combate.Remotes.VFX:FireAllClients("explosao", ut.Position, 12) end
	end)
	api.cutscene(p, {
		tomadas = {
			{ de = CFrame.lookAt(V(40, 8, 16), V(46, 3, 22)), ate = CFrame.lookAt(V(42, 6, 18), V(46, 4, 22.5)), dur = 7 },
			{ de = CFrame.lookAt(V(46, 5, 17), V(46, 5, 23)), ate = CFrame.lookAt(V(46, 5, 19), V(46, 5.5, 23)), dur = 6 },
		},
		falas = "f2_memoria",
	})
	memoriaVisivel(false, 1.5)
	api.historia(p, "flash", 1.5, Color3.fromRGB(200, 150, 255))
	api.aviso(p, "Uma memória... do teste que matou o Dr. Reeve.")
end

local vaelCamara
function F.gatilhos.observacao(p, api)
	vaelCamara = api.Vael.criar(CFrame.new(V(55, 6, -32)) * CFrame.Angles(0, 0, 0), FASE)
	if vaelCamara then vaelCamara.ancorar(true) vaelCamara.olharPara(V(55, 6, -10)) end
	for _, l in ipairs(FASE.Props.Iluminacao:GetDescendants()) do
		if l.Name == "Luminaria" and (l.Position - V(55, 11, -9)).Magnitude < 20 then l:AddTag("LuzPiscando") end
	end
	api.cutscene(p, {
		tomadas = {
			{ de = CFrame.lookAt(V(55, 6, -4), V(55, 6, -30)), ate = CFrame.lookAt(V(55, 6, -12), V(55, 7, -32)), dur = 4 },
			{ de = CFrame.lookAt(V(55, 7, -16), V(55, 8, -32)), ate = CFrame.lookAt(V(55, 7.5, -17), V(55, 8.5, -32)), dur = 3 },
		},
		falas = "f2_vael",
	})
	local vidro = FASE.Estrutura.Observacao:FindFirstChild("VidroObservacao")
	if vidro then
		vidro.Color = Color3.fromRGB(110, 130, 140)
		for i = 1, 7 do
			local r = Instance.new("Part") r.Name = "Trinca" r.Anchored = true r.CanCollide = false r.Material = Enum.Material.SmoothPlastic
			r.Color = Color3.fromRGB(230, 240, 245) r.Size = Vector3.new(math.random(20, 60) / 10, 0.05, 0.05)
			r.CFrame = CFrame.new(V(55, 6, -17.7)) * CFrame.Angles(0, 0, i * 0.9 + math.random()) * CFrame.new(r.Size.X / 2, 0, 0)
			r.Parent = FASE.Estrutura.Observacao
		end
	end
	api.historia(p, "flash", 0.4, Color3.fromRGB(255, 60, 60))
	if vaelCamara then vaelCamara.sumir(0.4) end
	api.objetivo(p, "CORRA. Pegue o corredor ao leste.")
end

-- perseguicao: o Vael aparece atras e segue ate a porta do fim do corredor B
function F.gatilhos.perseguicao(p, api)
	for _, l in ipairs(FASE.Props.LuzesCorredorB:GetDescendants()) do if l.Name == "Luminaria" then l:AddTag("LuzPiscando") end end
	api.objetivo(p, "CORRA até a porta no fim do corredor!")
	api.falas(p, { { "JANE", "Não não não não—", 2 } })
	local tentativas = 0
	while not api.flag(p, "g_porta_fechou") and tentativas < 6 do
		tentativas += 1
		local v = api.Vael.criar(CFrame.new(V(56, 5, 5)) * CFrame.Angles(0, -math.pi / 2, 0), FASE)
		if not v then return end
		task.wait(0.4)
		local res = v.perseguir(p, { vel = 16.5, alcance = 4.5, parar = function() return api.flag(p, "g_porta_fechou") end })
		if res == "pegou" then
			api.historia(p, "flash", 0.3, Color3.fromRGB(0, 0, 0))
			api.fade(p, true, 0.4, "Ele te alcançou...")
			v.model:Destroy()
			api.teleportar(p, CFrame.new(V(79, 1, 2)) * CFrame.Angles(0, 0, 0))
			task.wait(1.2)
			api.fade(p, false, 0.8)
		else
			-- porta fechou: ele para no vidro
			v.andar(V(79, 0, -61), 14)
			task.wait(2.5)
			v.parar()
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if r then v.olharPara(r.Position) end
			v.maoNoVidro()
			task.wait(4)
			v.sumir(2)
			return
		end
	end
end

function F.gatilhos.porta_fechou(p, api)
	api.porta(2, "Porta_Perseguicao", true)
	api.checkpoint(p, 2, "arena")
	api.falas(p, { { "JANE", "Ele... não tentou quebrar a porta.", 3 }, { "JANE", "Só ficou olhando.", 2.5 } })
end

function F.aposPedra(p, api, n)
	if n == 2 then
		api.objetivo(p, "Algo se move na Sala de Observação...")
	elseif n == 3 then
		api.checkpoint(p, 2, "modulo3")
		api.objetivo(p, "Use a Onda (F) nos caixotes que bloqueiam o corredor norte")
	end
end

F.arenaLimpa = {}
F.arenaLimpa.Contencao = function(p, api)
	api.objetivo(p, "Pegue a pedra no Módulo 03 (leste da arena)")
end

function F.empurrado(p, obj, api)
	if api.flag(p, "f2_caixas") then return end
	api.marcar(p, "f2_caixas")
	api.objetivo(p, "Siga até o elevador")
	task.delay(5, function()
		for _, c in ipairs(GP.Caixotes:GetChildren()) do if c:IsA("BasePart") then c.CanCollide = false TweenService:Create(c, TweenInfo.new(1), { Transparency = 1 }):Play() end end
	end)
end

function F.podeSair(p, api)
	if not api.flag(p, "pedra_3") then return false, "Ainda falta a pedra do Módulo 03." end
	return true
end

function F.aoCarregar(p, api, cp)
	if api.flag(p, "f2_cartao") then api.porta(2, "Porta_Modulo02", false) for _, n in ipairs({ "Cartao", "CartaoFaixa" }) do local x = GP:FindFirstChild(n) if x then x:Destroy() end end end
	if api.flag(p, "pedra_2") and GP:FindFirstChild("Pedra_02") then GP.Pedra_02:Destroy() end
	if api.flag(p, "pedra_3") and GP:FindFirstChild("Pedra_03") then GP.Pedra_03:Destroy() end
	if api.flag(p, "g_porta_fechou") then api.porta(2, "Porta_Perseguicao", true) end
	if api.flag(p, "arena_Contencao") then for _, n in ipairs({ "Porta_Perseguicao", "Porta_Modulo03", "Porta_CorredorC" }) do api.porta(2, n, false) end end
	if api.flag(p, "f2_caixas") and GP:FindFirstChild("Caixotes") then GP.Caixotes:ClearAllChildren() end
	if cp == "inicio" then
		api.objetivo(p, "Explore a Ala de Pesquisa. Procure um cartão de acesso.")
		api.falas(p, { { "JANE", "A Ala de Pesquisa... eu já estive aqui.", 3 }, { "JANE", "Muitas vezes.", 2 } })
	end
end

function F.objetivoPadrao(p, api)
	local f = function(k) return api.flag(p, k) end
	if not f("f2_cartao") then return "Explore a Ala de Pesquisa. Procure um cartão de acesso." end
	if not f("pedra_2") then return "Use o cartão no Módulo 02 (sul do corredor)" end
	if not f("g_observacao") then return "Algo se move na Sala de Observação..." end
	if not f("g_porta_fechou") then return "CORRA. Pegue o corredor ao leste." end
	if not f("arena_Contencao") then return "Destrua o sistema de contenção" end
	if not f("pedra_3") then return "Pegue a pedra no Módulo 03 (leste da arena)" end
	if not f("f2_caixas") then return "Use a Onda (F) nos caixotes que bloqueiam o corredor norte" end
	return "Siga até o elevador"
end

return F
