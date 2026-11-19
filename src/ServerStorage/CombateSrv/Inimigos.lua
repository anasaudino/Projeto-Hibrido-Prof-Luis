-- Soldados da forca de recuperacao: modelo, IA (patrulha/perseguicao/ataque), dano, ragdoll.
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Combate.Config)

local Inimigos = {}
local ctx
local vivos = {}          -- [model] = rec
local pastaVivos, pastaMortos
local templates = {}
local tiposExternos = {}   -- [tipo] = { criarModelo = fn(cfg, api), cerebro = fn(rec, api) }

local ANIM = { idle = "rbxassetid://507766666", walk = "rbxassetid://507777826", run = "rbxassetid://507767714" }

local function cor(r, g, b) return Color3.fromRGB(r, g, b) end

local function soldar(a, b)
	local w = Instance.new("WeldConstraint") w.Part0 = a w.Part1 = b w.Parent = b
end

local function peca(parent, nome, size, cf, color, mat, props)
	local p = Instance.new("Part")
	p.Name = nome p.Size = size p.CFrame = cf p.Color = color p.Material = mat or Enum.Material.SmoothPlastic
	p.CanCollide = false p.Massless = true p.CanQuery = true p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	if props then for k, v in pairs(props) do p[k] = v end end
	p.Parent = parent
	return p
end

local function criarTemplate(tipo)
	local c = Config.Inimigos[tipo]
	local d = Instance.new("HumanoidDescription")
	local pesado = tipo == "Pesado" or tipo == "Boss"
	local farda = pesado and cor(34, 36, 40) or cor(46, 54, 58)
	d.HeadColor = cor(30, 32, 36) d.TorsoColor = farda d.LeftArmColor = farda d.RightArmColor = farda
	d.LeftLegColor = cor(36, 40, 44) d.RightLegColor = cor(36, 40, 44)
	local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15) end)
	if not ok then warn("[Inimigos] falhou criar rig: " .. tostring(model)) return nil end
	model.Name = tipo
	local head = model:FindFirstChild("Head")
	for _, x in ipairs(model:GetDescendants()) do
		if x:IsA("Decal") and x.Name == "face" then x:Destroy() end
		if x:IsA("Script") or x:IsA("LocalScript") then x:Destroy() end
	end
	-- capacete, visor, colete, arma
	local capacete = peca(model, "Capacete", Vector3.new(1.35, 1.05, 1.4), head.CFrame * CFrame.new(0, 0.28, 0.05), cor(40, 46, 44), Enum.Material.SmoothPlastic)
	local mesh = Instance.new("SpecialMesh") mesh.MeshType = Enum.MeshType.Sphere mesh.Parent = capacete
	soldar(head, capacete)
	local corVisor = tipo == "Elite" and cor(80, 170, 255) or cor(255, 40, 40)
	if tipo == "Elite" then for _, bp in ipairs(model:GetChildren()) do if bp:IsA("BasePart") and bp.Name ~= "HumanoidRootPart" and bp.Name ~= "Head" then bp.Color = cor(22, 24, 28) end end end
	local visor = peca(model, "Visor", Vector3.new(1.05, 0.22, 0.12), head.CFrame * CFrame.new(0, 0.12, -0.6), corVisor, Enum.Material.Neon)
	soldar(head, visor)
	local luzVisor = Instance.new("PointLight") luzVisor.Color = cor(255, 50, 40) luzVisor.Range = 5 luzVisor.Brightness = 0.8 luzVisor.Shadows = false luzVisor.Parent = visor
	local torso = model:FindFirstChild("UpperTorso")
	local colete = peca(model, "Colete", torso.Size * Vector3.new(1.12, 0.85, 1.25), torso.CFrame * CFrame.new(0, 0.05, 0), pesado and cor(60, 30, 30) or cor(64, 72, 60), Enum.Material.Fabric)
	soldar(torso, colete)
	if tipo == "Boss" then
		local nucleo = peca(model, "Nucleo", Vector3.new(0.9, 0.9, 0.3), colete.CFrame * CFrame.new(0, 0.1, -colete.Size.Z / 2 - 0.1), cor(255, 50, 40), Enum.Material.Neon)
		soldar(colete, nucleo)
		local ln = Instance.new("PointLight") ln.Color = cor(255, 60, 40) ln.Range = 10 ln.Brightness = 2 ln.Parent = nucleo
		local mochila = peca(model, "Reator", Vector3.new(1.6, 1.8, 0.9), colete.CFrame * CFrame.new(0, 0.1, colete.Size.Z / 2 + 0.45), cor(40, 40, 44), Enum.Material.Metal)
		soldar(colete, mochila)
		for _, lado in ipairs({ -1, 1 }) do
			local tubo = peca(model, "Tubo", Vector3.new(0.25, 1.4, 0.25), mochila.CFrame * CFrame.new(lado * 0.5, 0.9, 0), cor(255, 90, 40), Enum.Material.Neon)
			soldar(mochila, tubo)
		end
	end
	if pesado then
		for _, lado in ipairs({ -1, 1 }) do
			local ombro = model:FindFirstChild(lado < 0 and "LeftUpperArm" or "RightUpperArm")
			local o = peca(model, "Ombreira", Vector3.new(1.3, 0.5, 1.3), ombro.CFrame * CFrame.new(0, 0.45, 0), cor(60, 30, 30), Enum.Material.Metal)
			soldar(ombro, o)
		end
		local faixa = peca(model, "Faixa", Vector3.new(0.12, 0.25, 1.1), colete.CFrame * CFrame.new(0.3, 0.2, 0) * CFrame.Angles(0, math.pi / 2, 0), cor(230, 190, 40), Enum.Material.Neon)
		soldar(colete, faixa)
	end
	local mao = model:FindFirstChild("RightHand")
	local arma = Instance.new("Model") arma.Name = "Arma" arma.Parent = model
	local comp = tipo == "Boss" and 3.4 or (tipo == "Pesado" and 2.4 or 2.9)
	local corpo = peca(arma, "Corpo", Vector3.new(0.32, 0.5, comp), mao.CFrame * CFrame.new(0, -0.15, -0.1) * CFrame.Angles(math.rad(90), 0, 0) * CFrame.new(0, 0.1, comp * 0.3), cor(26, 27, 30), Enum.Material.Metal)
	soldar(mao, corpo)
	local cano = peca(arma, "Cano", Vector3.new(0.14, 0.14, 0.9), corpo.CFrame * CFrame.new(0, 0.08, comp / 2 + 0.4), cor(18, 18, 20), Enum.Material.Metal)
	soldar(corpo, cano)
	local pente = peca(arma, "Pente", Vector3.new(0.25, 0.7, 0.35), corpo.CFrame * CFrame.new(0, -0.5, 0.2) * CFrame.Angles(0.25, 0, 0), cor(30, 30, 32), Enum.Material.Metal)
	soldar(corpo, pente)
	local lanterna = peca(arma, "Lanterna", Vector3.new(0.2, 0.2, 0.3), corpo.CFrame * CFrame.new(0, -0.22, comp / 2 - 0.1), cor(240, 240, 220), Enum.Material.Neon)
	soldar(corpo, lanterna)
	local spot = Instance.new("SpotLight") spot.Face = Enum.NormalId.Front spot.Range = 22 spot.Angle = 40 spot.Brightness = 1.4 spot.Color = cor(255, 245, 225) spot.Shadows = true spot.Parent = lanterna
	local mz = Instance.new("Attachment") mz.Name = "Muzzle" mz.Position = Vector3.new(0, 0, 0.5) mz.Parent = cano
	-- humanoid
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.BreakJointsOnDeath = false hum.RequiresNeck = false
	hum.MaxHealth = c.Vida hum.Health = c.Vida hum.WalkSpeed = c.Velocidade
	if c.Escala ~= 1 then model:ScaleTo(c.Escala) end
	-- barra de vida
	local bb = Instance.new("BillboardGui") bb.Name = "BarraVida" bb.Size = UDim2.fromOffset(70, 14) bb.StudsOffsetWorldSpace = Vector3.new(0, 2.2 * c.Escala, 0)
	bb.AlwaysOnTop = true bb.MaxDistance = 90 bb.LightInfluence = 0 bb.Enabled = false bb.Parent = head
	local fundo = Instance.new("Frame") fundo.Size = UDim2.fromScale(1, 0.45) fundo.Position = UDim2.fromScale(0, 0.55) fundo.BackgroundColor3 = cor(20, 16, 22) fundo.BorderSizePixel = 0 fundo.Parent = bb
	local rastro = Instance.new("Frame") rastro.Name = "Rastro" rastro.Size = UDim2.fromScale(1, 1) rastro.BackgroundColor3 = cor(255, 230, 230) rastro.BorderSizePixel = 0 rastro.Parent = fundo
	local barra = Instance.new("Frame") barra.Name = "Barra" barra.Size = UDim2.fromScale(1, 1) barra.BackgroundColor3 = cor(230, 50, 60) barra.BorderSizePixel = 0 barra.Parent = fundo
	local nome = Instance.new("TextLabel") nome.Size = UDim2.fromScale(1, 0.5) nome.BackgroundTransparency = 1 nome.Font = Enum.Font.GothamBold nome.TextSize = 9
	nome.TextColor3 = cor(255, 220, 220) nome.TextStrokeTransparency = 0.3 nome.Text = tipo == "Boss" and "SENTINELA-01" or (tipo == "Pesado" and "CONTENÇÃO" or (tipo == "Elite" and "ELITE" or "SOLDADO")) nome.Parent = bb
	model:SetAttribute("Inimigo", tipo)
	return model
end

-- juntas: funciona com rig antigo (Motor6D.C0) e rig novo (AnimationConstraint -> Attachment0.CFrame)
local function juntas(model)
	local t = {}
	for _, m in ipairs(model:GetDescendants()) do
		if m:IsA("Motor6D") then t[m.Name] = { obj = m, prop = "C0" }
		elseif m:IsA("AnimationConstraint") and m.Attachment0 then t[m.Name] = { obj = m.Attachment0, prop = "CFrame" } end
	end
	return t
end
local function setJ(j, cf) j.obj[j.prop] = cf end
local function tweenJ(j, t, cf, style) TweenService:Create(j.obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad), { [j.prop] = cf }):Play() end

-- ===== animacao procedural =====
local function pose(rec, nome, tempo)
	local m = rec.motores
	if not (rec.c0.RightShoulder and rec.c0.LeftShoulder and rec.c0.Waist) then return end
	local alvo = {}
	if nome == "mirar" then
		alvo.RightShoulder = rec.c0.RightShoulder * CFrame.Angles(math.rad(90), 0, 0)
		alvo.LeftShoulder = rec.c0.LeftShoulder * CFrame.Angles(math.rad(80), 0, math.rad(-38))
		alvo.Waist = rec.c0.Waist * CFrame.Angles(0, math.rad(-12), 0)
	else
		alvo.RightShoulder = rec.c0.RightShoulder alvo.LeftShoulder = rec.c0.LeftShoulder alvo.Waist = rec.c0.Waist
	end
	for k, cf in pairs(alvo) do
		if m[k] then tweenJ(m[k], tempo or 0.2, cf) end
	end
end

local function coice(rec)
	local ombro = rec.motores.RightShoulder
	if not ombro then return end
	local base = rec.mirando and rec.c0.RightShoulder * CFrame.Angles(math.rad(90), 0, 0) or rec.c0.RightShoulder
	setJ(ombro, base * CFrame.Angles(math.rad(14), 0, 0))
	tweenJ(ombro, 0.09, base)
end

local function tranco(rec, dir)
	local w = rec.motores.Waist
	if not w then return end
	local base = rec.c0.Waist * (rec.mirando and CFrame.Angles(0, math.rad(-12), 0) or CFrame.new())
	setJ(w, base * CFrame.Angles(math.rad(-16), math.rad(math.random(-10, 10)), 0))
	tweenJ(w, 0.22, base, Enum.EasingStyle.Back)
end

local function tocarAnims(rec)
	local animator = rec.hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", rec.hum)
	rec.anims = {}
	for k, id in pairs(ANIM) do
		local a = Instance.new("Animation") a.AnimationId = id
		local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
		if ok then rec.anims[k] = tr tr.Priority = Enum.AnimationPriority.Core end
	end
	if rec.anims.idle then rec.anims.idle.Looped = true rec.anims.idle:Play() end
	rec.hum.Running:Connect(function(v)
		local andando = v > 0.5
		local tr = rec.anims.walk
		if not tr then return end
		if andando and not tr.IsPlaying then tr.Looped = true tr:Play(0.2) elseif not andando and tr.IsPlaying then tr:Stop(0.25) end
		if tr.IsPlaying then tr:AdjustSpeed(v / 14) end
	end)
end

-- ===== util =====
local function alvoJogador()
	for _, p in ipairs(Players:GetPlayers()) do
		local ch = p.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 then return p, ch, hrp end
	end
end

local function paramsMundo()
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = { pastaVivos, pastaMortos, workspace:FindFirstChild("EfeitosServidor") }
	rp.RespectCanCollide = true
	return rp
end

local function temVisao(de, ate, charAlvo)
	local rp = paramsMundo()
	local d = ate - de
	local r = workspace:Raycast(de, d, rp)
	return (not r) or (charAlvo and r.Instance:IsDescendantOf(charAlvo))
end

-- ===== movimento =====
local function andarPara(rec, destino)
	local hrp = rec.hrp
	local agora = os.clock()
	local rp = paramsMundo()
	local d = destino - hrp.Position
	local livre = not workspace:Raycast(hrp.Position, Vector3.new(d.X, 0, d.Z), rp)
	if livre then
		rec.caminho = nil
		rec.hum:MoveTo(destino)
		return
	end
	if not rec.caminho or agora > rec.proxCaminho then
		rec.proxCaminho = agora + 0.9
		local path = PathfindingService:CreatePath({ AgentRadius = 1.6, AgentHeight = 5.5, AgentCanJump = false, WaypointSpacing = 4 })
		local ok = pcall(function() path:ComputeAsync(hrp.Position, destino) end)
		if ok and path.Status == Enum.PathStatus.Success then
			rec.caminho = path:GetWaypoints() rec.wp = 2
		else
			rec.caminho = nil rec.hum:MoveTo(destino) return
		end
	end
	local wps = rec.caminho
	if wps and wps[rec.wp] then
		local wp = wps[rec.wp].Position
		if (Vector3.new(wp.X, 0, wp.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude < 2.5 then rec.wp += 1 end
		if wps[rec.wp] then rec.hum:MoveTo(wps[rec.wp].Position) end
	end
end

local function virarPara(rec, pos)
	local hrp = rec.hrp
	local alvo = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
	if (alvo - hrp.Position).Magnitude > 0.1 then
		hrp.CFrame = CFrame.lookAt(hrp.Position, alvo)
	end
end

-- ===== ataque =====
local function atacar(rec, player, char, alvoHrp)
	rec.atacando = true
	local c = rec.cfg
	rec.hum:MoveTo(rec.hrp.Position)
	rec.hum.AutoRotate = false
	rec.mirando = true
	pose(rec, "mirar", 0.18)
	local cano = rec.model.Arma.Cano
	ctx.fx("laser", cano.Muzzle, alvoHrp, c.Mira)
	local t0 = os.clock()
	local mira = alvoHrp.Position
	while os.clock() - t0 < c.Mira do
		if not rec.model.Parent or rec.hum.Health <= 0 then return end
		if rec.atordoadoAte > os.clock() then rec.atacando = false rec.mirando = false pose(rec, "neutro") rec.hum.AutoRotate = true return end
		if os.clock() - t0 < c.Mira * 0.8 and alvoHrp.Parent then mira = alvoHrp.Position + Vector3.new(0, 0.3, 0) end
		virarPara(rec, mira)
		task.wait(0.03)
	end
	local rp = paramsMundo()
	for i = 1, c.Rajada do
		if not rec.model.Parent or rec.hum.Health <= 0 then return end
		local origem = cano.Muzzle.WorldPosition
		local base = (mira - origem).Unit
		local tiros = c.Chumbos or 1
		for _ = 1, tiros do
			local espalha = math.rad(c.Espalhar)
			local dir = (CFrame.lookAt(Vector3.zero, base) * CFrame.Angles((math.random() - 0.5) * 2 * espalha, (math.random() - 0.5) * 2 * espalha, 0)).LookVector
			local r = workspace:Raycast(origem, dir * 120, rp)
			local fim = r and r.Position or origem + dir * 120
			-- o corpo inteiro do Jane conta (bracos nao tem colisao no rig)
			local rc
			if char then
				local ip = RaycastParams.new()
				ip.FilterType = Enum.RaycastFilterType.Include
				ip.FilterDescendantsInstances = { char }
				rc = workspace:Raycast(origem, dir * 120, ip)
			end
			if rc and (not r or rc.Distance <= r.Distance + 0.05) then
				fim = rc.Position
				ctx.danoJogador(player, c.DanoTiro, origem)
			end
			ctx.fx("tiro", origem, fim)
		end
		coice(rec)
		task.wait(0.11)
	end
	task.wait(0.25)
	rec.mirando = false
	pose(rec, "neutro", 0.3)
	rec.hum.AutoRotate = true
	rec.proxAtaque = os.clock() + c.Recarga * (0.8 + math.random() * 0.45)
	rec.atacando = false
end

-- ===== morte =====
local function ragdoll(model, impulso)
	-- rig novo: os BallSocket ja existem; so desliga as AnimationConstraint
	for _, x in ipairs(model:GetDescendants()) do
		if x:IsA("AnimationConstraint") then x.Enabled = false
		elseif x:IsA("BallSocketConstraint") then x.Enabled = true end
	end
	for _, m in ipairs(model:GetDescendants()) do
		if m:IsA("Motor6D") and m.Name ~= "Root" then
			local a0 = Instance.new("Attachment") a0.CFrame = m.C0 a0.Parent = m.Part0
			local a1 = Instance.new("Attachment") a1.CFrame = m.C1 a1.Parent = m.Part1
			local b = Instance.new("BallSocketConstraint") b.Attachment0 = a0 b.Attachment1 = a1
			b.LimitsEnabled = true b.UpperAngle = 50 b.TwistLimitsEnabled = true b.TwistLowerAngle = -40 b.TwistUpperAngle = 40
			b.Parent = m.Part1
			m.Enabled = false
		end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Parent == model and p.Name ~= "HumanoidRootPart" then p.CanCollide = true p.Massless = false end
	end
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CanCollide = false end
	local torso = model:FindFirstChild("UpperTorso")
	if torso and impulso then torso:ApplyImpulse(impulso * torso.AssemblyMass) end
end

local function morrer(rec, info)
	if rec.morto then return end
	rec.morto = true
	vivos[rec.model] = nil
	local model = rec.model
	model.Parent = pastaMortos
	local bb = model:FindFirstChild("BarraVida", true) if bb then bb:Destroy() end
	local visor = model:FindFirstChild("Visor") if visor then visor.Color = Color3.fromRGB(40, 20, 20) visor.Material = Enum.Material.SmoothPlastic local l = visor:FindFirstChildOfClass("PointLight") if l then l:Destroy() end end
	local lant = model:FindFirstChild("Arma") and model.Arma:FindFirstChild("Lanterna") if lant then local s = lant:FindFirstChildOfClass("SpotLight") if s then s:Destroy() end end
	for _, tr in pairs(rec.anims or {}) do tr:Stop(0) end
	local dir = (info and info.dir) or Vector3.new(0, 0, 0)
	if rec.cfg.Mecanico then
		ctx.fx("explosaoVermelha", rec.hrp.Position, rec.cfg.RaioExplosao or 6)
		for _, x in ipairs(model:GetDescendants()) do
			if x:IsA("WeldConstraint") or x:IsA("Weld") then x:Destroy() end
		end
		for _, x in ipairs(model:GetDescendants()) do
			if x:IsA("BasePart") and x.Name ~= "HumanoidRootPart" then
				x.Anchored = false x.CanCollide = true
				x:ApplyImpulse((Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.4, math.random() - 0.5) * 60 + dir * 20) * x.AssemblyMass)
			elseif x:IsA("Light") then x.Enabled = false end
		end
	else
		rec.hum:ChangeState(Enum.HumanoidStateType.Physics)
		ragdoll(model, dir * (info and info.forca or 35) + Vector3.new(0, 18, 0))
	end
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") and not p.Anchored then pcall(p.SetNetworkOwner, p, nil) end end
	if rec.boss then ctx.fx("bossMorto", rec.hrp.Position) end
	ctx.aoMatar(rec, info)
	task.delay(2.2, function() if model.Parent then ctx.fx("dissolver", model) end end)
	task.delay(2.4, function()
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then TweenService:Create(p, TweenInfo.new(0.8), { Transparency = 1 }):Play() end
		end
	end)
	task.delay(3.4, function() model:Destroy() end)
end

-- ===== BOSS: SENTINELA-01 =====
local function distSegmento(p, a, b)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (a + ab * t - p).Magnitude
end

local function plano(v) return Vector3.new(v.X, 0, v.Z) end

local function limiteParede(de, dir, alcance)
	local r = workspace:Raycast(de, dir * alcance, paramsMundo())
	if r then return de + dir * math.max(0, r.Distance - 3) end
	return de + dir * alcance
end

local ATAQUES = {}

function ATAQUES.leque(rec, player, char, alvoHrp)
	local B = Config.Boss.Leque
	rec.hum:MoveTo(rec.hrp.Position) rec.hum.AutoRotate = false
	virarPara(rec, alvoHrp.Position)
	rec.mirando = true pose(rec, "mirar", 0.2)
	local origem = rec.hrp.Position + Vector3.new(0, 0.5, 0)
	local base = plano(alvoHrp.Position - origem)
	base = base.Magnitude > 0.1 and base.Unit or rec.hrp.CFrame.LookVector
	local dirs = {}
	for i = 1, B.Linhas do
		local ang = math.rad(-B.Abertura / 2 + (i - 1) * B.Abertura / (B.Linhas - 1))
		table.insert(dirs, (CFrame.fromAxisAngle(Vector3.yAxis, ang) * base))
	end
	local fins = {}
	for i, d in ipairs(dirs) do fins[i] = limiteParede(origem, d, 70) end
	ctx.fx("avisoLinhas", origem, fins, B.Aviso)
	task.wait(B.Aviso)
	if rec.morto then return end
	local acertou = false
	for i, fim in ipairs(fins) do
		ctx.fx("tiro", rec.model.Arma.Cano.Muzzle.WorldPosition, fim + Vector3.new(0, 0, 0))
		if not acertou and char and char:FindFirstChild("HumanoidRootPart") then
			local ph = char.HumanoidRootPart.Position
			if distSegmento(Vector3.new(ph.X, origem.Y, ph.Z), origem, fim) < 1.9 then
				acertou = true
				ctx.danoJogador(player, B.Dano, origem)
			end
		end
	end
	ctx.fx("tremer", rec.hrp.Position, 1.2)
	coice(rec)
	task.wait(0.35)
	rec.mirando = false pose(rec, "neutro", 0.3) rec.hum.AutoRotate = true
end

function ATAQUES.investida(rec, player, char, alvoHrp)
	local B = Config.Boss.Investida
	rec.hum:MoveTo(rec.hrp.Position) rec.hum.AutoRotate = false
	local de = rec.hrp.Position
	local dir = plano(alvoHrp.Position - de)
	dir = dir.Magnitude > 0.1 and dir.Unit or rec.hrp.CFrame.LookVector
	local alcance = math.min(B.Alcance, plano(alvoHrp.Position - de).Magnitude + 14)
	local ate = limiteParede(de, dir, alcance)
	virarPara(rec, ate)
	ctx.fx("avisoFaixa", de, ate, B.Largura, B.Aviso)
	-- agacha pra carregar
	local w = rec.motores.Waist
	if w then tweenJ(w, 0.3, rec.c0.Waist * CFrame.Angles(math.rad(22), 0, 0)) end
	task.wait(B.Aviso)
	if rec.morto then return end
	if w then tweenJ(w, 0.15, rec.c0.Waist) end
	rec.hum.WalkSpeed = B.Velocidade
	rec.hum:MoveTo(ate)
	local t0 = os.clock()
	local acertou = false
	while os.clock() - t0 < 1.0 do
		if rec.morto then return end
		if char and char:FindFirstChild("HumanoidRootPart") and not acertou then
			local ph = char.HumanoidRootPart.Position
			if plano(ph - rec.hrp.Position).Magnitude < B.Largura * 0.6 + 1 then
				acertou = true
				ctx.danoJogador(player, B.Dano, rec.hrp.Position)
				ctx.empurrar(player, dir * 70 + Vector3.new(0, 35, 0))
			end
		end
		if plano(ate - rec.hrp.Position).Magnitude < 3 then break end
		task.wait(0.03)
	end
	rec.hum.WalkSpeed = rec.cfg.Velocidade
	rec.hum:MoveTo(rec.hrp.Position)
	ctx.fx("poeira", rec.hrp.Position - Vector3.new(0, 4, 0))
	ctx.fx("tremer", rec.hrp.Position, 1.5)
	-- janela de punicao: fica tonto
	rec.hum.AutoRotate = true
	ctx.fx("numero", rec.hrp.Position + Vector3.new(0, 5, 0), "ATORDOADO", false, Color3.fromRGB(255, 220, 90))
	task.wait(1.1)
end

function ATAQUES.granadas(rec, player, char, alvoHrp)
	local B = Config.Boss.Granadas
	rec.hum:MoveTo(rec.hrp.Position)
	virarPara(rec, alvoHrp.Position)
	local ls = rec.motores.LeftShoulder
	if ls then tweenJ(ls, 0.2, rec.c0.LeftShoulder * CFrame.Angles(math.rad(160), 0, 0)) end
	local chao = alvoHrp.Position.Y - 3
	local pontos = { Vector3.new(alvoHrp.Position.X, chao, alvoHrp.Position.Z) }
	local qtd = B.Qtd + (rec.fase >= 3 and 2 or 0)
	for _ = 2, qtd do
		local a = math.random() * math.pi * 2
		local r = 6 + math.random() * 8
		table.insert(pontos, Vector3.new(alvoHrp.Position.X + math.cos(a) * r, chao, alvoHrp.Position.Z + math.sin(a) * r))
	end
	for _, p in ipairs(pontos) do ctx.fx("avisoCirculo", p, B.Raio, B.Aviso) end
	task.wait(0.3)
	if ls then tweenJ(ls, 0.25, rec.c0.LeftShoulder) end
	task.wait(B.Aviso - 0.3)
	if rec.morto then return end
	local acertou = false
	for _, p in ipairs(pontos) do
		ctx.fx("explosaoVermelha", p, B.Raio)
		if not acertou and char and char:FindFirstChild("HumanoidRootPart") then
			if plano(char.HumanoidRootPart.Position - p).Magnitude < B.Raio then
				acertou = true
				ctx.danoJogador(player, B.Dano, p)
			end
		end
	end
	task.wait(0.4)
end

local function transicao(rec, player, char)
	rec.invuln = true
	rec.hum:MoveTo(rec.hrp.Position)
	ctx.fx("banner", Config.Inimigos.Boss.Nome, "FASE " .. rec.fase .. (rec.fase == 3 and "  —  FÚRIA" or ""))
	local w = rec.motores.Waist
	if w then tweenJ(w, 0.25, rec.c0.Waist * CFrame.Angles(math.rad(-25), 0, 0), Enum.EasingStyle.Back) end
	task.wait(0.5)
	ctx.fx("rugido", rec.hrp.Position, 20)
	if char and char:FindFirstChild("HumanoidRootPart") then
		local d = plano(char.HumanoidRootPart.Position - rec.hrp.Position)
		if d.Magnitude < 20 then ctx.empurrar(player, (d.Magnitude > 0.1 and d.Unit or Vector3.xAxis) * 80 + Vector3.new(0, 30, 0)) end
	end
	ctx.reforcos(rec.fase == 2 and 2 or 3)
	task.wait(0.8)
	if w then tweenJ(w, 0.4, rec.c0.Waist) end
	rec.cfg = table.clone(rec.cfg)
	rec.cfg.Velocidade += 3
	rec.hum.WalkSpeed = rec.cfg.Velocidade
	task.wait(0.6)
	rec.invuln = false
end

local function cerebroBoss(rec)
	task.wait(1.8)
	while rec.model.Parent and not rec.morto do
		local player, char, alvoHrp = alvoJogador()
		if not alvoHrp then task.wait(0.3) continue end
		if rec.trocarFase then
			rec.trocarFase = false
			transicao(rec, player, char)
			continue
		end
		local opcoes = { "leque", "leque" }
		if rec.fase >= 2 then table.insert(opcoes, "investida") table.insert(opcoes, "investida") table.insert(opcoes, "granadas") end
		if rec.fase >= 3 then table.insert(opcoes, "granadas") table.insert(opcoes, "investida") end
		local atk = opcoes[math.random(1, #opcoes)]
		if atk == rec.ultimoAtk then atk = opcoes[math.random(1, #opcoes)] end
		rec.ultimoAtk = atk
		rec.atacando = true
		local ok, err = pcall(ATAQUES[atk], rec, player, char, alvoHrp)
		if not ok then warn("[Boss] " .. atk .. ": " .. tostring(err)) end
		rec.atacando = false rec.mirando = false
		if rec.hum.Parent then rec.hum.AutoRotate = true rec.hum.WalkSpeed = rec.cfg.Velocidade end
		-- reposiciona entre ataques
		local fim = os.clock() + (rec.fase == 3 and 0.8 or rec.fase == 2 and 1.2 or 1.6)
		while os.clock() < fim and not rec.morto and not rec.trocarFase do
			local d = alvoHrp.Position - rec.hrp.Position
			local dirU = plano(d).Magnitude > 0.1 and plano(d).Unit or Vector3.xAxis
			local lateral = Vector3.new(-dirU.Z, 0, dirU.X) * (rec.lado or 1) * 7
			local dist = plano(d).Magnitude
			local destino = dist > 22 and rec.hrp.Position + dirU * 8 + lateral * 0.3 or (dist < 12 and rec.hrp.Position - dirU * 6 or rec.hrp.Position + lateral)
			andarPara(rec, destino)
			task.wait(0.2)
		end
		if math.random() < 0.5 then rec.lado = -(rec.lado or 1) end
	end
end

-- ===== API =====
function Inimigos.init(contexto)
	ctx = contexto
	pastaVivos = workspace:FindFirstChild("Inimigos") or Instance.new("Folder")
	pastaVivos.Name = "Inimigos" pastaVivos.Parent = workspace
	pastaMortos = workspace:FindFirstChild("Cadaveres") or Instance.new("Folder")
	pastaMortos.Name = "Cadaveres" pastaMortos.Parent = workspace
	local pastaTipos = script.Parent:FindFirstChild("Tipos")
	if pastaTipos then
		for _, mod in ipairs(pastaTipos:GetChildren()) do
			local ok, def = pcall(require, mod)
			if ok and def.tipo then tiposExternos[def.tipo] = def else warn("[Inimigos] tipo " .. mod.Name .. ": " .. tostring(def)) end
		end
	end
	for tipo, cfg in pairs(Config.Inimigos) do
		local ext = tiposExternos[tipo]
		if ext and ext.criarModelo then
			local ok, mdl = pcall(ext.criarModelo, cfg, Inimigos.api)
			if ok and mdl then
				mdl:SetAttribute("Inimigo", tipo)
				local h = mdl:FindFirstChildOfClass("Humanoid")
				if h then h.MaxHealth = cfg.Vida h.Health = cfg.Vida h.BreakJointsOnDeath = false h.RequiresNeck = false h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
				templates[tipo] = mdl
			else warn("[Inimigos] modelo " .. tipo .. ": " .. tostring(mdl)) end
		else
			templates[tipo] = criarTemplate(tipo)
		end
	end
	RunService.Heartbeat:Connect(function() end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			Inimigos._tick()
		end
	end)
end

function Inimigos.pasta() return pastaVivos end
function Inimigos.pastaMortos() return pastaMortos end

function Inimigos.criar(tipo, pos)
	local t = templates[tipo]
	if not t then return nil end
	local model = t:Clone()
	model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.random() * math.pi * 2, 0))
	model.Parent = pastaVivos
	local hum = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart")
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") and not p.Anchored then pcall(p.SetNetworkOwner, p, nil) end end
	local rec = {
		model = model, hum = hum, hrp = hrp, tipo = tipo, cfg = Config.Inimigos[tipo],
		motores = juntas(model), c0 = {}, proxAtaque = os.clock() + 1 + math.random(), atacando = false,
		atordoadoAte = 0, queimaAte = 0, queimaDps = 0, proxQueima = 0, lado = math.random() < 0.5 and -1 or 1, proxLado = 0,
		proxCaminho = 0,
	}
	for k, j in pairs(rec.motores) do rec.c0[k] = j.obj[j.prop] end
	vivos[model] = rec
	tocarAnims(rec)
	hum.Died:Connect(function() morrer(rec, rec.ultimoGolpe) end)
	local ext = tiposExternos[tipo]
	if rec.cfg.Fixo or rec.cfg.Voador then rec.hrp.Anchored = true end
	if ext and ext.cerebro then
		rec.cerebro = true rec.fase = 1 rec.lado = 1
		if rec.cfg.Boss then
			rec.boss = true
			model:SetAttribute("Boss", rec.cfg.Nome or tipo)
			local bb = model:FindFirstChild("BarraVida", true) if bb then bb:Destroy() end
		end
		task.spawn(function()
			local ok, err = pcall(ext.cerebro, rec, Inimigos.api)
			if not ok and not rec.morto then warn("[Inimigos] cerebro " .. tipo .. ": " .. tostring(err)) end
		end)
	elseif tipo == "Boss" then
		rec.boss = true rec.fase = 1 rec.lado = 1
		model:SetAttribute("Boss", Config.Inimigos.Boss.Nome)
		local bb = model:FindFirstChild("BarraVida", true) if bb then bb:Destroy() end
		task.spawn(cerebroBoss, rec)
	end
	return model
end

function Inimigos.vivos()
	local t = {}
	for m, rec in pairs(vivos) do if not rec.morto then table.insert(t, rec) end end
	return t
end

function Inimigos.rec(model) return vivos[model] end

function Inimigos.dano(model, valor, info)
	local rec = vivos[model]
	if not rec or rec.morto then return false end
	info = info or {}
	if rec.levitadoAte and rec.levitadoAte > os.clock() then valor *= 1.5 end
	if rec.escudoFrontal and info.projetil and info.dir and rec.escudoAtivo then
		local frente = rec.hrp.CFrame.LookVector
		if frente:Dot(-info.dir) > 0.35 then
			ctx.fx("numero", rec.hrp.Position + Vector3.new(0, 4, 0), "BLOQUEADO", false, Color3.fromRGB(170, 190, 210))
			ctx.fx("faisca", rec.hrp.Position + frente * 2)
			return false
		end
	end
	if rec.boss then
		if rec.invuln then ctx.fx("numero", rec.hrp.Position + Vector3.new(0, 4, 0), "IMUNE", false, Color3.fromRGB(180, 180, 190)) return false end
		info.atordoar = nil info.derrubar = nil
		if info.empurrao then info.empurrao = info.empurrao * 0.15 end
	end
	rec.ultimoGolpe = info
	local hum = rec.hum
	valor = math.floor(valor + 0.5)
	local head = model:FindFirstChild("Head")
	ctx.fx("numero", (head and head.Position or rec.hrp.Position), valor, info.critico, info.cor)
	if not info.semTranco then ctx.fx("piscar", model) tranco(rec) end
	if info.atordoar and info.atordoar > 0 then rec.atordoadoAte = os.clock() + info.atordoar end
	if info.queima and info.queima > 0 then rec.queimaAte = os.clock() + 3 rec.queimaDps = math.max(rec.queimaDps, info.queima) end
	if info.empurrao and info.dir then
		rec.hrp:ApplyImpulse((info.dir.Unit * info.empurrao + Vector3.new(0, info.empurrao * 0.35, 0)) * rec.hrp.AssemblyMass)
		if info.derrubar then
			hum:ChangeState(Enum.HumanoidStateType.FallingDown)
			rec.atordoadoAte = math.max(rec.atordoadoAte, os.clock() + 0.9)
			task.delay(0.9, function() if hum.Health > 0 then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end end)
		end
	end
	hum:TakeDamage(valor)
	if rec.boss then
		local k = hum.Health / hum.MaxHealth
		local limite = Config.Boss.Fases[rec.fase]
		if limite and k <= limite and hum.Health > 0 then rec.fase += 1 rec.trocarFase = true end
	end
	local bb = not rec.boss and model:FindFirstChild("BarraVida", true)
	if bb then
		bb.Enabled = true
		local k = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		local fundo = bb:FindFirstChildOfClass("Frame")
		fundo.Barra.Size = UDim2.fromScale(k, 1)
		TweenService:Create(fundo.Rastro, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.15), { Size = UDim2.fromScale(k, 1) }):Play()
	end
	return hum.Health <= 0
end

function Inimigos.levitar(model, dur)
	local rec = vivos[model]
	if not rec or rec.morto then return end
	rec.levitadoAte = os.clock() + dur
	rec.atacando = false rec.mirando = false
	local hrp = rec.hrp
	local base = hrp.CFrame
	hrp.Anchored = true
	local token = {} rec.tokenLev = token
	TweenService:Create(hrp, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { CFrame = base + Vector3.new(0, 5, 0) }):Play()
	task.spawn(function()
		local t0 = os.clock()
		while rec.tokenLev == token and not rec.morto and os.clock() - t0 < dur do
			task.wait(0.05)
			if os.clock() - t0 > 0.5 then hrp.CFrame = hrp.CFrame * CFrame.Angles(0.02, 0.05, 0.01) end
		end
		if rec.tokenLev ~= token or rec.morto or not model.Parent then return end
		if not rec.cfg.Fixo and not rec.cfg.Voador then hrp.Anchored = false end
		rec.hum:ChangeState(Enum.HumanoidStateType.FallingDown)
		task.delay(0.7, function()
			if rec.morto then return end
			Inimigos.dano(model, 15, { semTranco = true })
			if rec.hum.Health > 0 then rec.hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
		end)
	end)
end

function Inimigos.arremessar(model, ponto, aoBater)
	local rec = vivos[model]
	if not rec or rec.morto then return end
	rec.tokenLev = {}
	local hrp = rec.hrp
	local de = hrp.Position
	local dir = (ponto - de)
	if dir.Magnitude < 1 then dir = hrp.CFrame.LookVector end
	dir = dir.Unit
	local alcance = math.min((ponto - de).Magnitude, 45)
	local r = workspace:Raycast(de, dir * alcance, paramsMundo())
	local ate = r and (r.Position - dir * 2) or (de + dir * alcance)
	hrp.Anchored = true
	local t = TweenService:Create(hrp, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(ate) * CFrame.Angles(math.pi / 2, 0, 0) })
	t:Play()
	t.Completed:Wait()
	if aoBater then aoBater(ate) end
	if model.Parent and not rec.morto then
		hrp.Anchored = false
		rec.levitadoAte = 0
		Inimigos.dano(model, 70, { dir = dir, forca = 80 })
	end
end

-- ===== ULTIMATE: estrangular no ar e esmagar no chao =====
local function poseEstrangulado(rec, t)
	local c0, j = rec.c0, rec.motores
	local R = math.rad
	local alvos = {
		RightShoulder = c0.RightShoulder and c0.RightShoulder * CFrame.Angles(R(115), 0, R(-35)),
		LeftShoulder = c0.LeftShoulder and c0.LeftShoulder * CFrame.Angles(R(115), 0, R(35)),
		RightElbow = c0.RightElbow and c0.RightElbow * CFrame.Angles(R(115), 0, 0),
		LeftElbow = c0.LeftElbow and c0.LeftElbow * CFrame.Angles(R(115), 0, 0),
		Neck = c0.Neck and c0.Neck * CFrame.Angles(R(25), 0, 0),
		Waist = c0.Waist and c0.Waist * CFrame.Angles(R(12), 0, 0),
	}
	for k, cf in pairs(alvos) do if cf and j[k] then tweenJ(j[k], t or 0.35, cf, Enum.EasingStyle.Back) end end
end
local function poseNormal(rec, t)
	for k, j in pairs(rec.motores) do if rec.c0[k] then tweenJ(j, t or 0.25, rec.c0[k]) end end
end

function Inimigos.estrangular(model, centro)
	local rec = vivos[model]
	if not rec or rec.morto then return false end
	rec.estrangulado = true
	rec.levitadoAte = os.clock() + 30
	rec.atacando = false rec.mirando = false
	local token = {} rec.tokenLev = token
	local hrp = rec.hrp
	hrp.Anchored = true
	for _, tr in pairs(rec.anims or {}) do tr:Stop(0.2) end
	local frente = Vector3.new(centro.X, hrp.Position.Y, centro.Z)
	local subir = 6 + math.random() * 3
	local base = CFrame.lookAt(hrp.Position, frente)
	TweenService:Create(hrp, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = base + Vector3.new(0, subir, 0) }):Play()
	poseEstrangulado(rec, 0.4)
	-- pernas se debatendo + corpo tremendo
	task.spawn(function()
		local t0 = os.clock()
		while rec.tokenLev == token and not rec.morto and model.Parent do
			local t = os.clock() - t0
			local R = math.rad
			for _, lado in ipairs({ "Left", "Right" }) do
				local hip, knee = rec.motores[lado .. "Hip"], rec.motores[lado .. "Knee"]
				local fase = lado == "Left" and 0 or math.pi
				if hip and rec.c0[lado .. "Hip"] then setJ(hip, rec.c0[lado .. "Hip"] * CFrame.Angles(R(20 + math.sin(t * 14 + fase) * 25), 0, 0)) end
				if knee and rec.c0[lado .. "Knee"] then setJ(knee, rec.c0[lado .. "Knee"] * CFrame.Angles(R(-25 - math.abs(math.sin(t * 14 + fase)) * 35), 0, 0)) end
			end
			if t > 0.9 then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.sin(t * 30) * 0.015, math.sin(t * 23) * 0.02) end
			task.wait(0.03)
		end
	end)
	return true
end

function Inimigos.esmagar(model, dano, info)
	local rec = vivos[model]
	if not rec or rec.morto then return end
	rec.tokenLev = {}
	local hrp = rec.hrp
	local rp = paramsMundo()
	local r = workspace:Raycast(hrp.Position, Vector3.new(0, -40, 0), rp)
	local chao = r and r.Position.Y or hrp.Position.Y - 8
	local alvo = CFrame.new(hrp.Position.X, chao + 1.2, hrp.Position.Z) * (hrp.CFrame - hrp.Position) * CFrame.Angles(math.rad(-80), 0, 0)
	local t = TweenService:Create(hrp, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = alvo })
	t:Play() t.Completed:Wait()
	ctx.fx("poeira", Vector3.new(hrp.Position.X, chao + 0.3, hrp.Position.Z))
	ctx.fx("anelChoque", Vector3.new(hrp.Position.X, chao, hrp.Position.Z), 7, 0.35)
	rec.estrangulado = false
	rec.levitadoAte = os.clock() + 1.4
	if not rec.cfg.Fixo and not rec.cfg.Voador then hrp.Anchored = false end
	poseNormal(rec, 0.2)
	info = info or {}
	info.dir = Vector3.new(0, -1, 0) info.forca = 20 info.semTranco = true
	local morreu = Inimigos.dano(model, dano, info)
	if not morreu and rec.hum.Health > 0 then
		rec.hum:ChangeState(Enum.HumanoidStateType.FallingDown)
		task.delay(1.3, function() if rec.hum.Health > 0 then rec.hum:ChangeState(Enum.HumanoidStateType.GettingUp) if rec.anims and rec.anims.idle then rec.anims.idle:Play() end end end)
	end
end

function Inimigos.limpar()
	for m, rec in pairs(vivos) do rec.morto = true m:Destroy() end
	vivos = {}
	for _, m in ipairs(pastaMortos:GetChildren()) do m:Destroy() end
end

function Inimigos._tick()
	local player, char, alvoHrp = alvoJogador()
	local agora = os.clock()
	for model, rec in pairs(vivos) do
		if rec.morto or not model.Parent then continue end
		if rec.levitadoAte and rec.levitadoAte > agora then continue end
		if rec.boss or rec.cerebro then
			if rec.queimaAte > agora and agora >= rec.proxQueima then
				rec.proxQueima = agora + 0.5
				Inimigos.dano(model, rec.queimaDps * 0.5, { semTranco = true, cor = Color3.fromRGB(255, 150, 60) })
			end
			continue
		end
		-- queimadura
		if rec.queimaAte > agora and agora >= rec.proxQueima then
			rec.proxQueima = agora + 0.5
			Inimigos.dano(model, rec.queimaDps * 0.5, { semTranco = true, cor = Color3.fromRGB(255, 150, 60) })
			if rec.morto then continue end
		end
		if not alvoHrp or rec.atacando or rec.atordoadoAte > agora then continue end
		local c = rec.cfg
		local olho = (model:FindFirstChild("Head") or rec.hrp).Position
		local d = alvoHrp.Position - rec.hrp.Position
		local dist = Vector3.new(d.X, 0, d.Z).Magnitude
		local ve = temVisao(olho, alvoHrp.Position, char)
		if ve then rec.ultimoVisto = alvoHrp.Position end
		if ve and dist <= c.Alcance and agora >= rec.proxAtaque then
			task.spawn(function()
				local ok, err = pcall(atacar, rec, player, char, alvoHrp)
				if not ok then
					warn("[Inimigos] ataque: " .. tostring(err))
					rec.atacando = false rec.mirando = false
					if rec.hum.Parent then rec.hum.AutoRotate = true end
					rec.proxAtaque = os.clock() + 2
				end
			end)
			continue
		end
		-- posicionamento: mantem distancia preferida e anda de lado
		local destino
		if not ve then
			destino = rec.ultimoVisto or alvoHrp.Position
		else
			local plano = Vector3.new(d.X, 0, d.Z)
			local dirU = plano.Magnitude > 0.1 and plano.Unit or Vector3.new(1, 0, 0)
			if agora > rec.proxLado then rec.lado = -rec.lado rec.proxLado = agora + 1.5 + math.random() * 2 end
			local lateral = Vector3.new(-dirU.Z, 0, dirU.X) * rec.lado * 6
			if dist > c.Distancia + 6 then
				destino = rec.hrp.Position + dirU * math.min(dist - c.Distancia, 10) + lateral * 0.4
			elseif dist < c.Distancia - 6 then
				destino = rec.hrp.Position - dirU * 6 + lateral * 0.5
			else
				destino = rec.hrp.Position + lateral
			end
		end
		if c.Fixo then continue end
		rec.hum.WalkSpeed = c.Velocidade
		andarPara(rec, destino)
	end
end

-- API pros modulos de tipos (bosses/mecanicos)
Inimigos.api = {
	ctx = function() return ctx end,
	cor = cor, peca = peca, soldar = soldar,
	pose = pose, tweenJ = tweenJ, setJ = setJ, coice = coice,
	virarPara = virarPara, andarPara = andarPara, alvoJogador = alvoJogador,
	paramsMundo = paramsMundo, temVisao = temVisao, plano = plano, limiteParede = limiteParede, distSegmento = distSegmento,
	ATAQUES = ATAQUES, atacarPadrao = atacar, criarHumanoide = criarTemplate,
	dano = function(...) return Inimigos.dano(...) end, criar = function(...) return Inimigos.criar(...) end,
	vivos = function() return Inimigos.vivos() end,
}
return Inimigos
