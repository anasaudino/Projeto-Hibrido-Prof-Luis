-- Controles e efeitos do combate (cliente).
-- Botao esquerdo (segurar): Pulso Telecinetico   |   F: Onda de Impulso   |   Q: Dash (arvore)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(RS:WaitForChild("Combate"):WaitForChild("Config"))
local VFX = require(RS.Combate:WaitForChild("VFX"))
local Rem = RS.Combate:WaitForChild("Remotes")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local segurando = false
local ultimoTiro = 0
local ultimoEnvio = 0
local poseAte = 0

local function char() return player.Character end
local function hrp() local c = char() return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = char() return c and c:FindFirstChildOfClass("Humanoid") end
local function ativo() local h = hum() return player:GetAttribute("PoderAtracao") == true and h and h.Health > 0 end

-- ===== mira =====
local function pontoMira()
	local m = UIS:GetMouseLocation()
	local ray = camera:ViewportPointToRay(m.X, m.Y)
	local rp = RaycastParams.new()
	local excl = { char() }
	for _, n in ipairs({ "EfeitosLocais", "Orbes", "Cadaveres" }) do local f = workspace:FindFirstChild(n) if f then table.insert(excl, f) end end
	rp.FilterDescendantsInstances = excl
	rp.RespectCanCollide = false
	local r = workspace:Raycast(ray.Origin, ray.Direction * 400, rp)
	if not r then return ray.Origin + ray.Direction * 400 end
	local p = r.Position
	if r.Normal.Y > 0.7 then
		-- mirou no chao: sobe pra altura do peito (senao o pulso afunda no piso)
		p = Vector3.new(p.X, p.Y + 2.6, p.Z)
	end
	return p
end

-- ===== pose do braco (procedural) =====
local c0 = {}
-- rig antigo (Motor6D.C0) ou novo (AnimationConstraint -> Attachment0.CFrame)
local function junta(nome)
	local c = char() if not c then return end
	local alt = nome:gsub("(%l)(%u)", "%1 %2")
	for _, m in ipairs(c:GetDescendants()) do
		if m.Name == nome or m.Name == alt then
			if m:IsA("Motor6D") then return m, "C0" end
			if m:IsA("AnimationConstraint") and m.Attachment0 then return m.Attachment0, "CFrame" end
		end
	end
end
local function guardarC0()
	c0 = {}
	for _, n in ipairs({ "RightShoulder", "LeftShoulder", "Waist", "Neck", "RightElbow", "LeftElbow", "RightHip", "LeftHip", "RightKnee", "LeftKnee" }) do local o, prop = junta(n) if o then c0[n] = { m = o, prop = prop, c0 = o[prop] } end end
end
local function tj(j, t, cf, style) TweenService:Create(j.m, TweenInfo.new(t, style or Enum.EasingStyle.Quad), { [j.prop] = cf }):Play() end
local function poseAtirar(on)
	local rs = c0.RightShoulder
	if not rs or not rs.m.Parent then return end
	local alvo = on and rs.c0 * CFrame.Angles(math.rad(88), 0, math.rad(-6)) or rs.c0
	tj(rs, on and 0.08 or 0.25, alvo)
	local ls = c0.LeftShoulder
	if ls then tj(ls, 0.25, on and ls.c0 * CFrame.Angles(math.rad(25), 0, math.rad(10)) or ls.c0) end
end
local function poseOnda()
	local rs, ls = c0.RightShoulder, c0.LeftShoulder
	if not rs or not ls then return end
	tj(rs, 0.1, rs.c0 * CFrame.Angles(math.rad(40), 0, math.rad(85)), Enum.EasingStyle.Back)
	tj(ls, 0.1, ls.c0 * CFrame.Angles(math.rad(40), 0, math.rad(-85)), Enum.EasingStyle.Back)
	task.delay(0.35, function() tj(rs, 0.3, rs.c0) tj(ls, 0.3, ls.c0) end)
end

local pousando = false
RunService.RenderStepped:Connect(function()
	local r, h = hrp(), hum()
	if not r or not h then return end
	local agora = os.clock()
	if agora < poseAte then
		if not pousando then pousando = true h.AutoRotate = false poseAtirar(true) end
		local alvo = pontoMira()
		local plano = Vector3.new(alvo.X, r.Position.Y, alvo.Z)
		if (plano - r.Position).Magnitude > 0.5 then
			local atual = r.CFrame
			local desejado = CFrame.lookAt(r.Position, plano)
			r.CFrame = atual:Lerp(desejado, 0.45)
		end
	elseif pousando then
		pousando = false h.AutoRotate = true poseAtirar(false)
	end
end)

-- ===== disparo =====
local function atirar()
	if not ativo() or player:GetAttribute("EmUlt") then return end
	local agora = os.clock()
	local rec = player:GetAttribute("RecargaPulso") or Config.Pulso.Recarga
	if agora - ultimoEnvio < rec * 0.95 then return end
	if (player:GetAttribute("Foco") or 0) < Config.Pulso.Custo then return end
	ultimoEnvio = agora
	poseAte = agora + 0.45
	Rem.Acao:FireServer("Pulso", pontoMira())
end

UIS.InputBegan:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if gp then return end
		segurando = true
		atirar()
	elseif not gp and input.KeyCode == Enum.KeyCode.V then
		if not ativo() or player:GetAttribute("EmUlt") then return end
		if (player:GetAttribute("Ult") or 0) < 100 then return end
		Rem.Acao:FireServer("Ultimate")
	elseif not gp and input.KeyCode == Enum.KeyCode.R then
		if not ativo() then return end
		if (player:GetAttribute("Pedras") or 0) < 4 then return end
		local m = UIS:GetMouseLocation()
		local ray = camera:ViewportPointToRay(m.X, m.Y)
		local rp = RaycastParams.new()
		local excl = { char() }
		for _, n in ipairs({ "EfeitosLocais", "Orbes", "Cadaveres" }) do local f = workspace:FindFirstChild(n) if f then table.insert(excl, f) end end
		rp.FilterDescendantsInstances = excl
		local r = workspace:Raycast(ray.Origin, ray.Direction * 200, rp)
		poseAte = os.clock() + 0.6
		Rem.Acao:FireServer("Levitar", r and r.Instance, pontoMira())
	elseif not gp and input.KeyCode == Enum.KeyCode.G then
		if not ativo() or (player:GetAttribute("Pedras") or 0) < 5 then return end
		if workspace:GetServerTimeNow() < (player:GetAttribute("EcoPronto") or 0) then return end
		Rem.Acao:FireServer("Eco")
	elseif not gp and input.KeyCode == Enum.KeyCode.Q then
		if not ativo() or not player:GetAttribute("TemDash") then return end
		if workspace:GetServerTimeNow() < (player:GetAttribute("DashPronto") or 0) - 0.1 then return end
		if (player:GetAttribute("Foco") or 0) < Config.Dash.Custo then return end
		local r, h = hrp(), hum()
		local dir = h.MoveDirection.Magnitude > 0.1 and h.MoveDirection or r.CFrame.LookVector
		dir = Vector3.new(dir.X, 0, dir.Z).Unit
		-- o personagem eh do cliente: o impulso tem que ser aplicado aqui
		local att = Instance.new("Attachment") att.Parent = r
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = att lv.MaxForce = math.huge lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		lv.PrimaryTangentAxis = Vector3.xAxis lv.SecondaryTangentAxis = Vector3.zAxis
		lv.PlaneVelocity = Vector2.new(dir.X, dir.Z) * Config.Dash.Forca
		lv.Parent = r
		task.delay(Config.Dash.Duracao, function() lv:Destroy() att:Destroy() end)
		VFX.SocoFOV(6)
		Rem.Acao:FireServer("Dash")
	elseif not gp and input.KeyCode == Enum.KeyCode.F then
		if not ativo() then return end
		local pronta = player:GetAttribute("OndaPronta") or 0
		if workspace:GetServerTimeNow() < pronta then return end
		poseOnda()
		Rem.Acao:FireServer("Onda")
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then segurando = false end
end)
RunService.Heartbeat:Connect(function() if segurando then atirar() end end)

player.CharacterAdded:Connect(function(c)
	c:WaitForChild("Humanoid")
	task.wait(0.5)
	guardarC0()
end)
if player.Character then task.spawn(function() task.wait(0.5) guardarC0() end) end

-- ===== ULTIMATE (lado do jogador): poses, camera e tela =====
local ULT = {}
local R = math.rad
local ultTela, ultBordas, ultCC, ultBlur, ultSalvo, ultPulsando
local function montarTela()
	if ultTela and ultTela.Parent then return end
	ultTela = Instance.new("ScreenGui") ultTela.Name = "UltTela" ultTela.IgnoreGuiInset = true ultTela.DisplayOrder = 30 ultTela.ResetOnSpawn = false
	ultTela.Parent = player:WaitForChild("PlayerGui")
	ultBordas = {}
	for i, d in ipairs({ { UDim2.fromScale(1, 0.35), UDim2.fromScale(0, 0), 90 }, { UDim2.fromScale(1, 0.35), UDim2.fromScale(0, 0.65), 270 }, { UDim2.fromScale(0.28, 1), UDim2.fromScale(0, 0), 0 }, { UDim2.fromScale(0.28, 1), UDim2.fromScale(0.72, 0), 180 } }) do
		local f = Instance.new("Frame") f.Size = d[1] f.Position = d[2] f.BackgroundColor3 = Color3.fromRGB(170, 0, 20) f.BackgroundTransparency = 1 f.BorderSizePixel = 0 f.Parent = ultTela
		local g = Instance.new("UIGradient") g.Rotation = d[3] g.Transparency = NumberSequence.new(0, 1) g.Parent = f
		ultBordas[i] = f
	end
	local flash = Instance.new("Frame") flash.Name = "Flash" flash.Size = UDim2.fromScale(1, 1) flash.BackgroundColor3 = Color3.new(1, 1, 1) flash.BackgroundTransparency = 1 flash.BorderSizePixel = 0 flash.Parent = ultTela
end
local function flashTela(cor, t)
	local f = ultTela and ultTela:FindFirstChild("Flash") if not f then return end
	f.BackgroundColor3 = cor f.BackgroundTransparency = 0.05
	TweenService:Create(f, TweenInfo.new(t or 0.5), { BackgroundTransparency = 1 }):Play()
end
local function pose(nome, cf, t, estilo)
	local j = c0[nome] if not j or not j.m.Parent then return end
	tj(j, t or 0.3, cf and j.c0 * cf or j.c0, estilo)
end

function ULT.inicio()
	local h, r = hum(), hrp()
	if not h or not r then return end
	montarTela()
	guardarC0()
	ultSalvo = { ws = h.WalkSpeed, jh = h.JumpHeight, hip = h.HipHeight, ar = h.AutoRotate }
	h.WalkSpeed = 0 h.JumpHeight = 0 h.AutoRotate = false
	-- dor: maos na cabeca, cai de joelhos
	pose("RightShoulder", CFrame.Angles(R(135), 0, R(-30)), 0.35, Enum.EasingStyle.Back)
	pose("LeftShoulder", CFrame.Angles(R(135), 0, R(30)), 0.35, Enum.EasingStyle.Back)
	pose("RightElbow", CFrame.Angles(R(125), 0, 0), 0.35)
	pose("LeftElbow", CFrame.Angles(R(125), 0, 0), 0.35)
	pose("Neck", CFrame.Angles(R(-28), 0, 0), 0.4)
	pose("Waist", CFrame.Angles(R(-22), 0, 0), 0.5)
	task.delay(0.35, function()
		pose("RightHip", CFrame.Angles(R(10), 0, 0), 0.35) pose("LeftHip", CFrame.Angles(R(10), 0, 0), 0.35)
		pose("RightKnee", CFrame.Angles(R(-100), 0, 0), 0.35) pose("LeftKnee", CFrame.Angles(R(-100), 0, 0), 0.35)
		TweenService:Create(h, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { HipHeight = math.max(0.2, ultSalvo.hip - 1.7) }):Play()
		VFX.Som("rbxassetid://220025689", r.Position, 0.7, 0.35)
		VFX.Tremer(1.2)
	end)
	-- camera: close no rosto, subindo tensao
	camera.CameraType = Enum.CameraType.Scriptable
	local base = r.CFrame
	camera.CFrame = CFrame.lookAt((base * CFrame.new(1.4, 0.2, -6)).Position, (base * CFrame.new(0, 0.8, 0)).Position)
	TweenService:Create(camera, TweenInfo.new(1.35, Enum.EasingStyle.Sine, Enum.EasingDirection.In), { CFrame = CFrame.lookAt((base * CFrame.new(0.8, -0.4, -3.6)).Position, (base * CFrame.new(0, 0.5, 0)).Position), FieldOfView = 58 }):Play()
	-- tela: bordas vermelhas pulsando, sem cor, borrada, coracao batendo
	ultCC = Instance.new("ColorCorrectionEffect") ultCC.Parent = game:GetService("Lighting")
	TweenService:Create(ultCC, TweenInfo.new(1.2), { Saturation = -0.75, TintColor = Color3.fromRGB(255, 190, 190), Contrast = 0.25 }):Play()
	ultBlur = Instance.new("BlurEffect") ultBlur.Size = 0 ultBlur.Parent = game:GetService("Lighting")
	TweenService:Create(ultBlur, TweenInfo.new(1.3), { Size = 6 }):Play()
	ultPulsando = true
	task.spawn(function()
		local t0 = os.clock()
		while ultPulsando do
			local k = math.min(1, (os.clock() - t0) / 1.3)
			local pulso = 0.5 + 0.5 * math.sin(os.clock() * (8 + k * 10))
			for _, f in ipairs(ultBordas) do f.BackgroundTransparency = math.clamp(0.85 - k * 0.55 - pulso * 0.2, 0.05, 1) end
			VFX.Tremer(0.2 + k * 0.9)
			task.wait()
		end
	end)
	for i = 0, 2 do task.delay(i * 0.42, function() VFX.Som("rbxassetid://220025689", nil, 0.5 + i * 0.15, 0.3) end) end
end

function ULT.explosao(pos)
	local h, r = hum(), hrp()
	ultPulsando = false
	flashTela(Color3.fromRGB(235, 215, 255), 0.7)
	VFX.Tremer(5) VFX.SocoFOV(16)
	if ultCC then TweenService:Create(ultCC, TweenInfo.new(0.4), { Saturation = -0.2, TintColor = Color3.fromRGB(225, 205, 255), Contrast = 0.1 }):Play() end
	if ultBlur then TweenService:Create(ultBlur, TweenInfo.new(0.4), { Size = 0 }):Play() end
	for _, f in ipairs(ultBordas or {}) do f.BackgroundColor3 = Color3.fromRGB(120, 40, 200) TweenService:Create(f, TweenInfo.new(0.8), { BackgroundTransparency = 0.6 }):Play() end
	-- corpo solta: cabeca pra tras, bracos abertos
	pose("Neck", CFrame.Angles(R(25), 0, 0), 0.12)
	pose("Waist", CFrame.Angles(R(12), 0, 0), 0.12)
	pose("RightShoulder", CFrame.Angles(R(40), 0, R(-85)), 0.12) pose("LeftShoulder", CFrame.Angles(R(40), 0, R(85)), 0.12)
	pose("RightElbow", nil, 0.12) pose("LeftElbow", nil, 0.12)
	-- camera abre: mostra todo mundo subindo
	if r then
		local base = r.CFrame
		camera.CFrame = CFrame.lookAt((base * CFrame.new(-6, 5, 11)).Position, (base * CFrame.new(0, 4, -12)).Position)
		TweenService:Create(camera, TweenInfo.new(2.3, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt((base * CFrame.new(5, 8, 13)).Position, (base * CFrame.new(0, 5, -12)).Position), FieldOfView = 72 }):Play()
	end
	task.wait(1.1)
	-- ergue o braco direito: segura todos no ar
	pose("RightShoulder", CFrame.Angles(R(175), 0, R(-5)), 0.35, Enum.EasingStyle.Back)
	pose("LeftShoulder", CFrame.Angles(R(30), 0, R(40)), 0.35)
	pose("Neck", CFrame.Angles(R(10), 0, 0), 0.35)
	pose("RightHip", CFrame.Angles(R(35), 0, 0), 0.4) pose("LeftHip", CFrame.Angles(R(-10), 0, 0), 0.4)
	pose("RightKnee", CFrame.Angles(R(-70), 0, 0), 0.4) pose("LeftKnee", CFrame.Angles(R(-95), 0, 0), 0.4)
	if h and ultSalvo then TweenService:Create(h, TweenInfo.new(0.4), { HipHeight = math.max(0.2, ultSalvo.hip - 0.9) }):Play() end
	VFX.Tremer(1.5)
end

function ULT.batida(pos)
	local h, r = hum(), hrp()
	-- baixa o braco com tudo
	pose("RightShoulder", CFrame.Angles(R(45), 0, R(-10)), 0.1, Enum.EasingStyle.Quad)
	pose("Waist", CFrame.Angles(R(-25), 0, 0), 0.1)
	pose("Neck", CFrame.Angles(R(-15), 0, 0), 0.1)
	task.wait(0.15)
	flashTela(Color3.fromRGB(170, 100, 255), 0.5)
	VFX.Tremer(6) VFX.SocoFOV(-12)
	VFX.Som("rbxasset://sounds/impact_explosion_03.mp3", nil, 1, 0.45)
	task.wait(0.85)
	-- volta ao normal
	for _, n in ipairs({ "RightShoulder", "LeftShoulder", "Waist", "Neck", "RightElbow", "LeftElbow", "RightHip", "LeftHip", "RightKnee", "LeftKnee" }) do pose(n, nil, 0.35) end
	if h and ultSalvo then
		TweenService:Create(h, TweenInfo.new(0.35), { HipHeight = ultSalvo.hip }):Play()
		h.WalkSpeed = ultSalvo.ws h.JumpHeight = ultSalvo.jh h.AutoRotate = ultSalvo.ar
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	if ultCC then TweenService:Create(ultCC, TweenInfo.new(0.6), { Saturation = 0, TintColor = Color3.new(1, 1, 1), Contrast = 0 }):Play() game:GetService("Debris"):AddItem(ultCC, 0.7) ultCC = nil end
	if ultBlur then ultBlur:Destroy() ultBlur = nil end
	for _, f in ipairs(ultBordas or {}) do TweenService:Create(f, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play() f.BackgroundColor3 = Color3.fromRGB(170, 0, 20) end
end

-- ===== efeitos vindos do servidor =====
local S = Config.Sons
local function perto(pos, d) local r = hrp() return r and (r.Position - pos).Magnitude < (d or 40) end

local tratar = {
	bolt = function(id, origem, dir, vel, alcance) VFX.Bolt(id, origem, dir, vel, alcance) end,
	boltFim = function(id, pos) VFX.BoltFim(id, pos) end,
	impacto = function(pos, crit) VFX.Impacto(pos, crit) if crit then VFX.Tremer(0.5) end end,
	numero = function(pos, v, crit, cor) VFX.Numero(pos, v, crit, cor) VFX.Som(S.Acerto, pos, crit and 0.7 or 0.45, crit and 0.8 or (0.95 + math.random() * 0.2)) end,
	piscar = function(model) VFX.Piscar(model) end,
	onda = function(ch, pos, raio)
		VFX.Onda(pos, raio) VFX.Som(S.Onda, pos, 0.8, 1.25)
		if ch == char() then VFX.Tremer(2.2) VFX.SocoFOV(8) end
	end,
	explosao = function(pos, raio) VFX.Explosao(pos, raio) VFX.Som(S.Onda, pos, 0.6, 1.6) if perto(pos, 30) then VFX.Tremer(1.2) end end,
	tiro = function(de, ate) VFX.Clarao(de) VFX.Tracante(de, ate) VFX.Som(S.Tiro, de, 0.4, 0.9 + math.random() * 0.2) end,
	laser = function(cano, alvo, dur) VFX.Laser(cano, alvo, dur) end,
	alcapao = function(pos) VFX.Alcapao(pos) end,
	poeira = function(pos) VFX.Poeira(pos) if perto(pos, 30) then VFX.Tremer(0.5) end end,
	dissolver = function(model) VFX.Dissolver(model) end,
	conjurar = function(ch)
		if not ch then return end
		local mao = ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm")
		VFX.Conjurar(mao)
		VFX.Som(S.Pulso, mao and mao.Position, 0.35, 1.3 + math.random() * 0.25)
		if ch == char() then VFX.Tremer(0.25) end
	end,
	buff = function(ch, cor) VFX.Buff(ch, cor) VFX.Som(S.Buff, nil, 0.6, 1.1) end,
	escudo = function(ch, ativo) VFX.Escudo(ch, ativo) end,
	danoJogador = function(dano, de) VFX.Tremer(0.8 + dano / 10) end,
	coletar = function() VFX.Som(S.Buff, nil, 0.25, 2.2) end,
	dash = function(ch) VFX.Dash(ch) VFX.Som(S.Pulso, nil, 0.4, 0.8) end,
	empurrao = function(v)
		local r = hrp() if not r then return end
		r.AssemblyLinearVelocity = v
		local h = hum() if h then h:ChangeState(Enum.HumanoidStateType.Freefall) end
		VFX.Tremer(1.5)
	end,
	essencia = function(pos, n) VFX.Texto3D(pos + Vector3.new(0, 2, 0), "+" .. n .. " essência", Color3.fromRGB(110, 230, 255), 22) end,
	esquivou = function() local r = hrp() if r then VFX.Texto3D(r.Position + Vector3.new(0, 3, 0), "ESQUIVOU", Color3.fromRGB(200, 240, 255), 18) end end,
	segundaChance = function(ch) VFX.SegundaChance(ch) VFX.Tremer(2) end,
	avisoLinhas = function(o, fins, d) VFX.AvisoLinhas(o, fins, d) end,
	avisoFaixa = function(a, b, l, d) VFX.AvisoFaixa(a, b, l, d) end,
	avisoCirculo = function(p, r, d) VFX.AvisoCirculo(p, r, d) end,
	explosaoVermelha = function(p, r) VFX.ExplosaoVermelha(p, r) if perto(p, 25) then VFX.Tremer(1.3) end end,
	rugido = function(p, r) VFX.Rugido(p, r) VFX.Tremer(2.5) VFX.SocoFOV(10) end,
	tremer = function(p, f) if perto(p, 60) then VFX.Tremer(f or 1) end end,
	bossChegando = function(p) for i = 0, 5 do task.delay(i * 0.4, function() VFX.Tremer(0.6 + i * 0.25) end) end end,
	bossMorto = function(p) VFX.BossMorto(p) end,
	faisca = function(p) VFX.Faisca(p) end,
	teleporte = function(p) VFX.Teleporte(p) end,
	levitar = function(alvo, ch) VFX.Levitar(alvo, ch) end,
	eco = function(d) VFX.Eco(d) end,
	anelChoque = function(p, r, d) VFX.AnelChoque(p, r, d) end,
	ultInicio = function(ch) if ch == char() then task.spawn(ULT.inicio) end end,
	ultExplosao = function(ch, pos, raio)
		VFX.UltExplosao(pos, raio)
		local ini = workspace:FindFirstChild("Inimigos")
		if ini then for _, m in ipairs(ini:GetChildren()) do local r = m:FindFirstChild("HumanoidRootPart") if r and (r.Position - pos).Magnitude <= raio and not m:GetAttribute("Boss") then VFX.AuraEstrangulado(m, 2.6) end end end
		if ch == char() then task.spawn(ULT.explosao, pos) else VFX.Tremer(2) end
	end,
	ultBatida = function(ch, pos) if ch == char() then task.spawn(ULT.batida, pos) else VFX.Tremer(3) end end,
}
Rem.VFX.OnClientEvent:Connect(function(tipo, ...)
	local f = tratar[tipo]
	if f then
		local ok, err = pcall(f, ...)
		if not ok then warn("[VFX] " .. tipo .. ": " .. tostring(err)) end
	end
end)

-- inimigos invisiveis (Espectro): quase transparentes, a nao ser sob o ECO ou quando atacam
RunService.RenderStepped:Connect(function()
	local ini = workspace:FindFirstChild("Inimigos")
	if not ini then return end
	local eco = VFX.EcoAtivo()
	for _, e in ipairs(ini:GetChildren()) do
		if e:GetAttribute("Invisivel") ~= nil then
			local alvo = (e:GetAttribute("Invisivel") and not eco) and 0.94 or 0
			for _, x in ipairs(e:GetDescendants()) do
				if x:IsA("BasePart") or x:IsA("Decal") then x.LocalTransparencyModifier = alvo end
			end
		end
	end
end)
