-- Efeitos visuais do combate (roda no CLIENTE). Tudo local: nao replica.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Config = require(script.Parent.Config)

local VFX = {}
local PSI, PSI2 = Config.CorPsi, Config.CorPsiClara
local TEX = {
	brilho = "rbxasset://textures/particles/sparkles_main.dds",
	onda = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	fumaca = "rbxasset://textures/particles/smoke_main.dds",
	faisca = "rbxasset://textures/particles/fire_sparks_main.dds",
	nucleo = "rbxasset://textures/particles/explosion01_core_main.dds",
	implosao = "rbxasset://textures/particles/explosion01_implosion_main.dds",
	glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
}

local pasta
local function folder()
	if not pasta or not pasta.Parent then
		pasta = Instance.new("Folder")
		pasta.Name = "EfeitosLocais"
		pasta.Parent = workspace
	end
	return pasta
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
	p.Material = Enum.Material.Neon p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	p.Parent = folder()
	return p
end

local function ancora(pos)
	local p = part({ Size = Vector3.one * 0.1, Transparency = 1, CFrame = CFrame.new(pos) })
	local a = Instance.new("Attachment") a.Parent = p
	return p, a
end

local function emissor(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false e.LightEmission = 1 e.LockedToPart = false
	for k, v in pairs(props) do e[k] = v end
	e.Parent = parent
	return e
end

local function seq(a, b) return NumberSequence.new(a, b) end
local function cseq(a, b) return ColorSequence.new(a, b or a) end

function VFX.Som(id, pos, volume, pitch)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id s.Volume = volume or 0.6 s.PlaybackSpeed = pitch or 1
	s.RollOffMaxDistance = 120 s.RollOffMinDistance = 10
	if pos then
		local p = ancora(pos) s.Parent = p Debris:AddItem(p, 6)
	else
		s.Parent = folder() Debris:AddItem(s, 6)
	end
	s:Play()
	return s
end

-- ===== camera =====
local tremor = 0
local fovBase
function VFX.Tremer(forca) tremor = math.max(tremor, forca) end
function VFX.SocoFOV(delta)
	local cam = workspace.CurrentCamera
	fovBase = fovBase or cam.FieldOfView
	cam.FieldOfView = fovBase + delta
	TweenService:Create(cam, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { FieldOfView = fovBase }):Play()
end
RunService:BindToRenderStep("TremorCombate", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if tremor > 0.01 then
		local t = os.clock() * 40
		local cam = workspace.CurrentCamera
		cam.CFrame = cam.CFrame * CFrame.Angles(math.noise(t, 1) * tremor * 0.03, math.noise(t, 2) * tremor * 0.03, math.noise(t, 3) * tremor * 0.02)
		tremor = tremor * math.exp(-dt * 9)
	end
end)

-- ===== projetil psiquico =====
local bolts = {}
function VFX.Bolt(id, origem, dir, vel, alcance, cor)
	cor = cor or PSI
	local nucleo = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.55, Color = PSI2, CFrame = CFrame.new(origem) })
	local aura = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 1.5, Color = cor, Material = Enum.Material.ForceField, Transparency = 0, CFrame = CFrame.new(origem) })
	local a0 = Instance.new("Attachment") a0.Position = Vector3.new(0, 0.35, 0) a0.Parent = nucleo
	local a1 = Instance.new("Attachment") a1.Position = Vector3.new(0, -0.35, 0) a1.Parent = nucleo
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0 tr.Attachment1 = a1 tr.Lifetime = 0.16 tr.LightEmission = 1 tr.FaceCamera = true
	tr.Color = cseq(PSI2, cor) tr.Transparency = seq(0.1, 1) tr.WidthScale = seq(1, 0.1)
	tr.Parent = nucleo
	local luz = Instance.new("PointLight") luz.Color = cor luz.Range = 9 luz.Brightness = 2 luz.Shadows = false luz.Parent = nucleo
	local fagulha = emissor(a0, { Texture = TEX.brilho, Color = cseq(PSI2, cor), Size = seq(0.5, 0), Lifetime = NumberRange.new(0.15, 0.3), Rate = 60, Speed = NumberRange.new(0.5, 2), SpreadAngle = Vector2.new(180, 180), Transparency = seq(0, 1) })
	fagulha.Enabled = true
	bolts[id] = { nucleo = nucleo, aura = aura, pos = origem, dir = dir.Unit, vel = vel, resto = alcance }
end

function VFX.BoltFim(id, pos)
	local b = bolts[id]
	if not b then return end
	bolts[id] = nil
	if pos then b.nucleo.Position = pos end
	b.aura:Destroy()
	for _, c in ipairs(b.nucleo:GetDescendants()) do if c:IsA("ParticleEmitter") then c.Enabled = false end end
	b.nucleo.Transparency = 1
	Debris:AddItem(b.nucleo, 0.4)
end

RunService.Heartbeat:Connect(function(dt)
	for id, b in pairs(bolts) do
		local passo = b.vel * dt
		b.pos += b.dir * passo
		b.resto -= passo
		b.nucleo.CFrame = CFrame.lookAt(b.pos, b.pos + b.dir)
		b.aura.CFrame = b.nucleo.CFrame * CFrame.Angles(0, 0, os.clock() * 20)
		if b.resto <= 0 then VFX.BoltFim(id) end
	end
end)

-- ===== impactos =====
function VFX.Impacto(pos, grande, cor)
	cor = cor or PSI
	local p, a = ancora(pos)
	emissor(a, { Texture = TEX.brilho, Color = cseq(PSI2, cor), Size = seq(grande and 1.4 or 0.9, 0), Lifetime = NumberRange.new(0.2, 0.45), Speed = NumberRange.new(10, 26), SpreadAngle = Vector2.new(180, 180), Drag = 6, Transparency = seq(0, 1) }):Emit(grande and 26 or 14)
	emissor(a, { Texture = TEX.onda, Color = cseq(cor), Size = seq(0.5, grande and 7 or 4.5), Lifetime = NumberRange.new(0.25), Speed = NumberRange.new(0), Transparency = seq(0.1, 1), Orientation = Enum.ParticleOrientation.FacingCamera }):Emit(1)
	local flash = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * (grande and 2.4 or 1.6), Color = PSI2, CFrame = CFrame.new(pos) })
	TweenService:Create(flash, TweenInfo.new(0.18), { Size = Vector3.one * (grande and 4 or 2.8), Transparency = 1 }):Play()
	local l = Instance.new("PointLight") l.Color = cor l.Range = grande and 16 or 10 l.Brightness = 3 l.Parent = flash
	TweenService:Create(l, TweenInfo.new(0.25), { Brightness = 0 }):Play()
	Debris:AddItem(flash, 0.3) Debris:AddItem(p, 1)
end

function VFX.Numero(pos, valor, critico, cor)
	local p = ancora(pos + Vector3.new(math.random(-10, 10) / 10, 1, math.random(-10, 10) / 10))
	local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(120, 50) bb.AlwaysOnTop = true bb.LightInfluence = 0 bb.Adornee = p bb.Parent = p
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack t.Text = critico and (tostring(valor) .. "!") or tostring(valor)
	t.TextColor3 = cor or (critico and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(245, 240, 255))
	t.TextStrokeTransparency = 0 t.TextStrokeColor3 = Color3.fromRGB(40, 10, 60)
	t.TextSize = critico and 34 or 24 t.Parent = bb
	local us = Instance.new("UIScale") us.Scale = 1.6 us.Parent = t
	TweenService:Create(us, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(p, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { CFrame = p.CFrame + Vector3.new(0, 3, 0) }):Play()
	task.delay(0.45, function()
		TweenService:Create(t, TweenInfo.new(0.35), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	Debris:AddItem(p, 0.9)
end

function VFX.Piscar(model)
	if not model or not model.Parent then return end
	local h = Instance.new("Highlight")
	h.FillColor = Color3.new(1, 1, 1) h.FillTransparency = 0.15 h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded h.Parent = model
	TweenService:Create(h, TweenInfo.new(0.14), { FillTransparency = 1 }):Play()
	Debris:AddItem(h, 0.16)
end

function VFX.Onda(pos, raio)
	local chao = pos - Vector3.new(0, 2.6, 0)
	local anel = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 2, 2), Color = PSI, CFrame = CFrame.new(chao) * CFrame.Angles(0, 0, math.pi / 2) })
	TweenService:Create(anel, TweenInfo.new(0.35, Enum.EasingStyle.Quart), { Size = Vector3.new(0.15, raio * 2, raio * 2), Transparency = 1 }):Play()
	local esfera = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 2, Color = PSI, Material = Enum.Material.ForceField, CFrame = CFrame.new(pos) })
	TweenService:Create(esfera, TweenInfo.new(0.4, Enum.EasingStyle.Quart), { Size = Vector3.one * raio * 2 }):Play()
	task.delay(0.25, function() TweenService:Create(esfera, TweenInfo.new(0.2), { Transparency = 1 }):Play() end)
	local p, a = ancora(chao + Vector3.new(0, 0.5, 0))
	emissor(a, { Texture = TEX.fumaca, Color = cseq(Color3.fromRGB(120, 90, 160)), Size = seq(2, 5), Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(raio * 1.4, raio * 2), SpreadAngle = Vector2.new(5, 180), Drag = 5, Transparency = seq(0.5, 1), LightEmission = 0.2, EmissionDirection = Enum.NormalId.Front }):Emit(40)
	emissor(a, { Texture = TEX.brilho, Color = cseq(PSI2, PSI), Size = seq(1.2, 0), Lifetime = NumberRange.new(0.3, 0.6), Speed = NumberRange.new(20, 40), SpreadAngle = Vector2.new(180, 180), Drag = 4 }):Emit(40)
	local luz = Instance.new("PointLight") luz.Color = PSI luz.Range = raio * 1.6 luz.Brightness = 4 luz.Parent = esfera
	TweenService:Create(luz, TweenInfo.new(0.45), { Brightness = 0 }):Play()
	Debris:AddItem(anel, 0.5) Debris:AddItem(esfera, 0.5) Debris:AddItem(p, 1.2)
end

function VFX.Explosao(pos, raio)
	local p, a = ancora(pos)
	emissor(a, { Texture = TEX.implosao, Color = cseq(PSI2, PSI), Size = seq(raio * 0.4, raio * 1.2), Lifetime = NumberRange.new(0.3), Speed = NumberRange.new(0), Transparency = seq(0.1, 1) }):Emit(2)
	emissor(a, { Texture = TEX.brilho, Color = cseq(PSI2, PSI), Size = seq(1.5, 0), Lifetime = NumberRange.new(0.3, 0.7), Speed = NumberRange.new(15, 35), SpreadAngle = Vector2.new(180, 180), Drag = 5 }):Emit(35)
	local s = part({ Shape = Enum.PartType.Ball, Size = Vector3.one, Color = PSI, Material = Enum.Material.ForceField, CFrame = CFrame.new(pos) })
	TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Quart), { Size = Vector3.one * raio * 2, Transparency = 1 }):Play()
	Debris:AddItem(s, 0.35) Debris:AddItem(p, 1)
end

-- ===== inimigos =====
function VFX.Clarao(pos)
	local f = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.9, Color = Color3.fromRGB(255, 210, 120), CFrame = CFrame.new(pos) })
	local l = Instance.new("PointLight") l.Color = Color3.fromRGB(255, 190, 110) l.Range = 12 l.Brightness = 3 l.Parent = f
	TweenService:Create(f, TweenInfo.new(0.06), { Transparency = 1, Size = Vector3.one * 1.6 }):Play()
	Debris:AddItem(f, 0.08)
end

function VFX.Tracante(de, ate)
	local d = (ate - de)
	local t = part({ Size = Vector3.new(0.09, 0.09, d.Magnitude), Color = Color3.fromRGB(255, 200, 120), CFrame = CFrame.lookAt(de + d / 2, ate) })
	TweenService:Create(t, TweenInfo.new(0.09), { Transparency = 1, Size = Vector3.new(0.02, 0.02, d.Magnitude) }):Play()
	Debris:AddItem(t, 0.1)
	local p, a = ancora(ate)
	emissor(a, { Texture = TEX.faisca, Color = cseq(Color3.fromRGB(255, 200, 120)), Size = seq(0.3, 0), Lifetime = NumberRange.new(0.1, 0.25), Speed = NumberRange.new(8, 16), SpreadAngle = Vector2.new(60, 60) }):Emit(5)
	Debris:AddItem(p, 0.5)
end

-- laser vermelho de mira: segue o alvo e trava no fim
function VFX.Laser(cano, alvo, duracao)
	if not cano or not alvo then return end
	local a0 = cano
	local p1, a1 = ancora(alvo.Position)
	local b = Instance.new("Beam")
	b.Attachment0 = a0 b.Attachment1 = a1 b.Width0 = 0.08 b.Width1 = 0.08 b.FaceCamera = true
	b.Color = cseq(Color3.fromRGB(255, 40, 40)) b.LightEmission = 1 b.Transparency = seq(0.1, 0.1)
	b.Parent = p1
	local ponto = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.35, Color = Color3.fromRGB(255, 50, 50), CFrame = CFrame.new(alvo.Position) })
	local t0 = os.clock()
	local con
	con = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - t0) / duracao
		if k >= 1 or not alvo.Parent or not a0.Parent then
			con:Disconnect() p1:Destroy() ponto:Destroy()
			return
		end
		if k < 0.8 then p1.Position = alvo.Position + Vector3.new(0, 0.3, 0) end
		ponto.Position = p1.Position
		b.Width0 = 0.05 + k * 0.12 b.Width1 = b.Width0
		b.Transparency = seq(0.4 - k * 0.4, 0.4 - k * 0.4)
	end)
end

function VFX.Alcapao(pos)
	local teto = pos + Vector3.new(0, 12.5, 0)
	local cone = part({ Size = Vector3.new(3.2, 12.5, 3.2), Color = Color3.fromRGB(255, 60, 50), Transparency = 0.8, CFrame = CFrame.new(pos + Vector3.new(0, 6, 0)) })
	TweenService:Create(cone, TweenInfo.new(1.2), { Transparency = 1 }):Play()
	local p, a = ancora(teto)
	emissor(a, { Texture = TEX.fumaca, Color = cseq(Color3.fromRGB(90, 90, 95)), Size = seq(1.5, 4), Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(2, 6), SpreadAngle = Vector2.new(40, 40), Acceleration = Vector3.new(0, -6, 0), Transparency = seq(0.3, 1), LightEmission = 0, EmissionDirection = Enum.NormalId.Bottom }):Emit(18)
	Debris:AddItem(cone, 1.3) Debris:AddItem(p, 2)
end

function VFX.Poeira(pos)
	local p, a = ancora(pos)
	emissor(a, { Texture = TEX.fumaca, Color = cseq(Color3.fromRGB(150, 150, 150)), Size = seq(1, 3.5), Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(10, 180), Drag = 5, Transparency = seq(0.4, 1), LightEmission = 0, EmissionDirection = Enum.NormalId.Top }):Emit(16)
	Debris:AddItem(p, 1.2)
end

function VFX.Dissolver(model)
	local tronco = model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart")
	if not tronco then return end
	local a = Instance.new("Attachment") a.Parent = tronco
	emissor(a, { Texture = TEX.brilho, Color = cseq(PSI2, PSI), Size = seq(0.8, 0), Lifetime = NumberRange.new(0.6, 1.1), Speed = NumberRange.new(1, 4), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 6, 0) }):Emit(40)
	emissor(a, { Texture = TEX.fumaca, Color = cseq(Color3.fromRGB(60, 30, 80)), Size = seq(1.5, 3), Lifetime = NumberRange.new(0.8, 1.2), Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 4, 0), Transparency = seq(0.4, 1), LightEmission = 0.3 }):Emit(14)
end

-- ===== jogador =====
function VFX.Conjurar(mao)
	if not mao then return end
	local p, a = ancora(mao.Position)
	emissor(a, { Texture = TEX.glow, Color = cseq(PSI2, PSI), Size = seq(1.8, 0), Lifetime = NumberRange.new(0.15), Speed = NumberRange.new(0), Transparency = seq(0, 1) }):Emit(1)
	emissor(a, { Texture = TEX.brilho, Color = cseq(PSI2, PSI), Size = seq(0.5, 0), Lifetime = NumberRange.new(0.15, 0.3), Speed = NumberRange.new(4, 9), SpreadAngle = Vector2.new(180, 180) }):Emit(6)
	Debris:AddItem(p, 0.5)
end

function VFX.Buff(char, cor)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	cor = cor or PSI
	local col = part({ Size = Vector3.new(4, 0.2, 4), Shape = Enum.PartType.Cylinder, Color = cor, CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
	col.Size = Vector3.new(0.2, 3, 3)
	TweenService:Create(col, TweenInfo.new(0.6, Enum.EasingStyle.Quart), { Size = Vector3.new(0.1, 12, 12), Transparency = 1 }):Play()
	local _, a = ancora(hrp.Position - Vector3.new(0, 2.5, 0))
	emissor(a, { Texture = TEX.brilho, Color = cseq(Color3.new(1, 1, 1), cor), Size = seq(0.7, 0), Lifetime = NumberRange.new(0.8, 1.3), Speed = NumberRange.new(4, 10), SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, 8, 0), EmissionDirection = Enum.NormalId.Top }):Emit(50)
	Debris:AddItem(col, 0.7) Debris:AddItem(a.Parent, 2)
end

function VFX.Escudo(char, ativo)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local s = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 7, Color = Color3.fromRGB(120, 200, 255), Material = Enum.Material.ForceField, CFrame = hrp.CFrame })
	TweenService:Create(s, TweenInfo.new(0.4), { Size = Vector3.one * (ativo and 8 or 10), Transparency = 1 }):Play()
	Debris:AddItem(s, 0.45)
end

-- ===== avisos do chefe (telegrafia) =====
local VERM = Color3.fromRGB(255, 45, 40)
local function chaoY(pos)
	local rp = RaycastParams.new() rp.RespectCanCollide = true
	local ex = {} for _, n in ipairs({ "Inimigos", "Cadaveres", "EfeitosLocais", "Orbes" }) do local f = workspace:FindFirstChild(n) if f then table.insert(ex, f) end end
	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do if p.Character then table.insert(ex, p.Character) end end
	rp.FilterDescendantsInstances = ex
	local r = workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -20, 0), rp)
	return r and r.Position.Y or pos.Y
end

function VFX.AvisoLinhas(origem, fins, dur)
	local y = chaoY(origem) + 0.08
	for _, fim in ipairs(fins) do
		local a = Vector3.new(origem.X, y, origem.Z) local b = Vector3.new(fim.X, y, fim.Z)
		local d = b - a
		local l = part({ Size = Vector3.new(0.35, 0.05, d.Magnitude), Color = VERM, Transparency = 0.7, CFrame = CFrame.lookAt(a + d / 2, b) })
		TweenService:Create(l, TweenInfo.new(dur * 0.9), { Transparency = 0.1, Size = Vector3.new(1.1, 0.05, d.Magnitude) }):Play()
		Debris:AddItem(l, dur + 0.05)
	end
end

function VFX.AvisoFaixa(de, ate, largura, dur)
	local y = chaoY(de) + 0.08
	local a = Vector3.new(de.X, y, de.Z) local b = Vector3.new(ate.X, y, ate.Z)
	local d = b - a
	local base = part({ Size = Vector3.new(largura, 0.05, d.Magnitude), Color = VERM, Transparency = 0.8, CFrame = CFrame.lookAt(a + d / 2, b) })
	local enche = part({ Size = Vector3.new(largura, 0.06, 0.1), Color = VERM, Transparency = 0.35, CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -0.05) })
	TweenService:Create(enche, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = Vector3.new(largura, 0.06, d.Magnitude), CFrame = CFrame.lookAt(a + d / 2, b) }):Play()
	Debris:AddItem(base, dur + 0.05) Debris:AddItem(enche, dur + 0.05)
end

function VFX.AvisoCirculo(pos, raio, dur)
	local y = chaoY(pos) + 0.08
	local c = CFrame.new(pos.X, y, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
	local anel = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.05, raio * 2, raio * 2), Color = VERM, Transparency = 0.75, CFrame = c })
	local enche = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.06, 0.2, 0.2), Color = VERM, Transparency = 0.3, CFrame = c })
	TweenService:Create(enche, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = Vector3.new(0.06, raio * 2, raio * 2) }):Play()
	-- granada caindo
	local g = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.7, Color = Color3.fromRGB(40, 40, 40), Material = Enum.Material.Metal, CFrame = CFrame.new(pos.X, y + 14, pos.Z) })
	local led = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.3, Color = VERM, CFrame = g.CFrame })
	TweenService:Create(g, TweenInfo.new(dur * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(pos.X, y + 0.35, pos.Z) }):Play()
	TweenService:Create(led, TweenInfo.new(dur * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(pos.X, y + 0.6, pos.Z) }):Play()
	Debris:AddItem(anel, dur + 0.05) Debris:AddItem(enche, dur + 0.05) Debris:AddItem(g, dur + 0.05) Debris:AddItem(led, dur + 0.05)
end

function VFX.ExplosaoVermelha(pos, raio)
	local y = chaoY(pos)
	local c = Vector3.new(pos.X, y + 1, pos.Z)
	local p, a = ancora(c)
	emissor(a, { Texture = TEX.nucleo, Color = ColorSequence.new(Color3.fromRGB(255, 220, 150), Color3.fromRGB(255, 80, 30)), Size = seq(raio * 0.6, raio * 1.3), Lifetime = NumberRange.new(0.25, 0.35), Speed = NumberRange.new(0), Transparency = seq(0, 1) }):Emit(3)
	emissor(a, { Texture = TEX.fumaca, Color = cseq(Color3.fromRGB(70, 60, 60)), Size = seq(2, 6), Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(6, 14), SpreadAngle = Vector2.new(180, 180), Drag = 3, Transparency = seq(0.3, 1), LightEmission = 0, Acceleration = Vector3.new(0, 5, 0) }):Emit(20)
	emissor(a, { Texture = TEX.faisca, Color = cseq(Color3.fromRGB(255, 200, 100)), Size = seq(0.5, 0), Lifetime = NumberRange.new(0.3, 0.7), Speed = NumberRange.new(20, 40), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -40, 0) }):Emit(30)
	local l = Instance.new("PointLight") l.Color = Color3.fromRGB(255, 120, 50) l.Range = raio * 3 l.Brightness = 5 l.Parent = p
	TweenService:Create(l, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	Debris:AddItem(p, 1.6)
	VFX.Som("rbxasset://sounds/impact_explosion_03.mp3", c, 0.7, 0.9 + math.random() * 0.2)
end

function VFX.Rugido(pos, raio)
	local anel = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2, 2), Color = VERM, CFrame = CFrame.new(pos - Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
	TweenService:Create(anel, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { Size = Vector3.new(0.1, raio * 2, raio * 2), Transparency = 1 }):Play()
	local esf = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 3, Color = VERM, Material = Enum.Material.ForceField, CFrame = CFrame.new(pos) })
	TweenService:Create(esf, TweenInfo.new(0.5, Enum.EasingStyle.Quart), { Size = Vector3.one * raio * 2, Transparency = 1 }):Play()
	Debris:AddItem(anel, 0.55) Debris:AddItem(esf, 0.55)
	VFX.Som("rbxasset://sounds/impact_explosion_03.mp3", pos, 0.9, 0.55)
end

-- ===== jogador: dash =====
function VFX.Dash(char)
	if not char then return end
	for i = 0, 3 do
		task.delay(i * 0.04, function()
			for _, bp in ipairs(char:GetChildren()) do
				if bp:IsA("BasePart") and bp.Name ~= "HumanoidRootPart" and bp.Transparency < 1 then
					local g = part({ Size = bp.Size, CFrame = bp.CFrame, Color = PSI, Material = Enum.Material.ForceField, Transparency = 0.2 })
					TweenService:Create(g, TweenInfo.new(0.35), { Transparency = 1 }):Play()
					Debris:AddItem(g, 0.4)
				end
			end
		end)
	end
end

function VFX.SegundaChance(char)
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local s = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 2, Color = Color3.fromRGB(255, 230, 140), Material = Enum.Material.ForceField, CFrame = hrp.CFrame })
	TweenService:Create(s, TweenInfo.new(0.7, Enum.EasingStyle.Quart), { Size = Vector3.one * 26, Transparency = 1 }):Play()
	Debris:AddItem(s, 0.75)
	VFX.Buff(char, Color3.fromRGB(255, 220, 120))
end

function VFX.Texto3D(pos, texto, cor, tamanho)
	local p = ancora(pos)
	local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(160, 40) bb.AlwaysOnTop = true bb.LightInfluence = 0 bb.Adornee = p bb.Parent = p
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1 t.Font = Enum.Font.GothamBlack
	t.Text = texto t.TextColor3 = cor t.TextSize = tamanho or 20 t.TextStrokeTransparency = 0.2 t.Parent = bb
	TweenService:Create(p, TweenInfo.new(1.1, Enum.EasingStyle.Quad), { CFrame = p.CFrame + Vector3.new(0, 3.5, 0) }):Play()
	task.delay(0.6, function() TweenService:Create(t, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play() end)
	Debris:AddItem(p, 1.2)
end

-- ===== morte do chefe: camera lenta =====
function VFX.BossMorto(pos)
	local Lighting = game:GetService("Lighting")
	local cc = Instance.new("ColorCorrectionEffect") cc.Brightness = 0.4 cc.Contrast = 0.3 cc.Saturation = -0.6 cc.TintColor = Color3.fromRGB(255, 230, 230) cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(1.6, Enum.EasingStyle.Quad), { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }):Play()
	Debris:AddItem(cc, 1.7)
	VFX.SocoFOV(-18)
	VFX.Tremer(4)
	for i = 0, 4 do
		task.delay(i * 0.18, function()
			VFX.ExplosaoVermelha(pos + Vector3.new(math.random(-4, 4), math.random(0, 4), math.random(-4, 4)), 6)
		end)
	end
	task.delay(0.9, function() VFX.Explosao(pos, 16) end)
end

function VFX.Faisca(pos)
	local p, a = ancora(pos)
	emissor(a, { Texture = TEX.faisca, Color = cseq(Color3.fromRGB(200, 230, 255)), Size = seq(0.4, 0), Lifetime = NumberRange.new(0.15, 0.35), Speed = NumberRange.new(12, 25), SpreadAngle = Vector2.new(70, 70) }):Emit(14)
	Debris:AddItem(p, 0.6)
	VFX.Som("rbxassetid://220025689", pos, 0.5, 1.8)
end

function VFX.Teleporte(pos)
	local col = part({ Size = Vector3.new(0.2, 3, 3), Shape = Enum.PartType.Cylinder, Color = Color3.fromRGB(255, 70, 60), Transparency = 0.2, CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2) })
	TweenService:Create(col, TweenInfo.new(0.6, Enum.EasingStyle.Quart), { Size = Vector3.new(14, 0.3, 0.3), Transparency = 1, CFrame = CFrame.new(pos + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.pi / 2) }):Play()
	local _, a = ancora(pos)
	emissor(a, { Texture = TEX.brilho, Color = cseq(Color3.fromRGB(255, 120, 100)), Size = seq(0.6, 0), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(4, 10), SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, 10, 0), EmissionDirection = Enum.NormalId.Top }):Emit(30)
	Debris:AddItem(col, 0.7) Debris:AddItem(a.Parent, 1.2)
end

-- fio psiquico entre a mao do Jane e o alvo levitado
function VFX.Levitar(alvo, char)
	if not alvo or not char then return end
	local mao = char:FindFirstChild("RightHand") or char:FindFirstChild("HumanoidRootPart")
	if not mao then return end
	local a0 = Instance.new("Attachment") a0.Parent = mao
	local a1 = Instance.new("Attachment") a1.Parent = alvo
	local b = Instance.new("Beam") b.Attachment0 = a0 b.Attachment1 = a1 b.Width0 = 0.3 b.Width1 = 1.2 b.FaceCamera = true
	b.Color = cseq(PSI2, PSI) b.LightEmission = 1 b.Transparency = seq(0.2, 0.5) b.CurveSize0 = 2 b.CurveSize1 = -2 b.Segments = 20
	b.Texture = "rbxasset://textures/particles/sparkles_main.dds" b.TextureSpeed = 2 b.TextureLength = 3
	b.Parent = a1
	local aura = emissor(a1, { Texture = TEX.glow, Color = cseq(PSI2, PSI), Size = seq(2.5, 0), Lifetime = NumberRange.new(0.4), Rate = 20, Speed = NumberRange.new(0), Transparency = seq(0.3, 1) })
	aura.Enabled = true
	local luz = Instance.new("PointLight") luz.Color = PSI luz.Range = 10 luz.Brightness = 1.5 luz.Parent = alvo
	VFX.Som("rbxassetid://9125646252", alvo.Position, 0.5, 1.1)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 6 and alvo.Parent do
			task.wait(0.1)
			local seg = game:GetService("Players").LocalPlayer:GetAttribute("Segurando")
			if os.clock() - t0 > 2.3 and not seg then break end
		end
		a0:Destroy() a1:Destroy() luz:Destroy()
	end)
end

-- ECO: tela dessaturada, inimigos em vermelho, interagiveis em amarelo, coisas escondidas aparecem
local ecoAte = 0
function VFX.Eco(dur)
	local Lighting = game:GetService("Lighting")
	ecoAte = os.clock() + dur
	local cc = Instance.new("ColorCorrectionEffect") cc.Name = "EcoCC" cc.Saturation = 0 cc.TintColor = Color3.new(1, 1, 1) cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(0.4), { Saturation = -0.85, TintColor = Color3.fromRGB(190, 215, 255), Contrast = 0.15 }):Play()
	VFX.SocoFOV(-6)
	VFX.Som("rbxassetid://9125647212", nil, 0.6, 0.7)
	local hls = {}
	local function marcar(inst, cor)
		local h = Instance.new("Highlight") h.FillColor = cor h.OutlineColor = cor h.FillTransparency = 0.75 h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = inst table.insert(hls, h)
	end
	local ini = workspace:FindFirstChild("Inimigos")
	if ini then for _, e in ipairs(ini:GetChildren()) do marcar(e, Color3.fromRGB(255, 60, 60)) end end
	local r = game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local escondidos = {}
	local fases = workspace:FindFirstChild("Fases")
	if fases and r then
		for _, d in ipairs(fases:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.Enabled and d.Parent:IsA("BasePart") and (d.Parent.Position - r.Position).Magnitude < 90 then
				marcar(d.Parent, d:GetAttribute("Acao") == "Memoria" and Color3.fromRGB(120, 230, 255) or Color3.fromRGB(255, 220, 80))
			elseif d:IsA("BasePart") and d:GetAttribute("SoEco") and (d.Position - r.Position).Magnitude < 120 then
				table.insert(escondidos, { d, d.Transparency })
				d.Transparency = d:GetAttribute("SoEco") == true and 0.15 or d:GetAttribute("SoEco")
				for _, g in ipairs(d:GetChildren()) do if g:IsA("SurfaceGui") or g:IsA("BillboardGui") then g.Enabled = true end end
			end
		end
	end
	task.delay(dur, function()
		TweenService:Create(cc, TweenInfo.new(0.5), { Saturation = 0, TintColor = Color3.new(1, 1, 1), Contrast = 0 }):Play()
		game:GetService("Debris"):AddItem(cc, 0.6)
		for _, h in ipairs(hls) do h:Destroy() end
		for _, e in ipairs(escondidos) do
			e[1].Transparency = e[2]
			for _, g in ipairs(e[1]:GetChildren()) do if g:IsA("SurfaceGui") or g:IsA("BillboardGui") then g.Enabled = false end end
		end
	end)
end
function VFX.EcoAtivo() return os.clock() < ecoAte end

function VFX.AnelChoque(pos, raioMax, dur)
	local anel = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 4, 4), Color = Color3.fromRGB(255, 120, 60), Transparency = 0.2, CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
	local miolo = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.7, 3, 3), Color = Color3.fromRGB(40, 36, 40), Material = Enum.Material.SmoothPlastic, Transparency = 0, CFrame = anel.CFrame * CFrame.new(0.05, 0, 0) })
	TweenService:Create(anel, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = Vector3.new(0.6, raioMax * 2 + 2, raioMax * 2 + 2), Transparency = 0.6 }):Play()
	TweenService:Create(miolo, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = Vector3.new(0.7, raioMax * 2 - 1, raioMax * 2 - 1) }):Play()
	task.delay(dur, function() TweenService:Create(anel, TweenInfo.new(0.2), { Transparency = 1 }):Play() miolo:Destroy() end)
	Debris:AddItem(anel, dur + 0.3)
	VFX.Poeira(pos + Vector3.new(0, 0.5, 0))
	VFX.Som("rbxasset://sounds/impact_explosion_03.mp3", pos, 0.9, 0.7)
end

function VFX.UltExplosao(pos, raio)
	local branco = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 4, Color = Color3.new(1, 1, 1), CFrame = CFrame.new(pos) })
	TweenService:Create(branco, TweenInfo.new(0.35, Enum.EasingStyle.Quart), { Size = Vector3.one * 26, Transparency = 1 }):Play()
	Debris:AddItem(branco, 0.4)
	for i = 0, 2 do
		task.delay(i * 0.12, function()
			local esf = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 3, Color = i == 1 and PSI2 or PSI, Material = Enum.Material.ForceField, CFrame = CFrame.new(pos) })
			TweenService:Create(esf, TweenInfo.new(0.9 + i * 0.2, Enum.EasingStyle.Quart), { Size = Vector3.one * raio * 2 * (1 - i * 0.18), Transparency = 1 }):Play()
			Debris:AddItem(esf, 1.3)
			local anel = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 3, 3), Color = PSI2, CFrame = CFrame.new(pos - Vector3.new(0, 2.6 - i * 1.4, 0)) * CFrame.Angles(0, 0, math.pi / 2) })
			TweenService:Create(anel, TweenInfo.new(0.8, Enum.EasingStyle.Quart), { Size = Vector3.new(0.08, raio * 2, raio * 2), Transparency = 1 }):Play()
			Debris:AddItem(anel, 0.9)
		end)
	end
	-- raios de energia saindo do Jane
	for i = 1, 16 do
		local ang = (i / 16) * math.pi * 2 + math.random() * 0.2
		local dir = Vector3.new(math.cos(ang), (math.random() - 0.3) * 0.6, math.sin(ang)).Unit
		local comp = raio * (0.5 + math.random() * 0.5)
		local r = part({ Size = Vector3.new(0.25, 0.25, 1), Color = PSI2, CFrame = CFrame.lookAt(pos, pos + dir) })
		TweenService:Create(r, TweenInfo.new(0.35, Enum.EasingStyle.Quart), { Size = Vector3.new(0.12, 0.12, comp), CFrame = CFrame.lookAt(pos + dir * comp / 2, pos + dir * comp) }):Play()
		task.delay(0.3, function() TweenService:Create(r, TweenInfo.new(0.4), { Transparency = 1 }):Play() end)
		Debris:AddItem(r, 0.8)
	end
	local p, a = ancora(pos)
	emissor(a, { Texture = TEX.brilho, Color = cseq(Color3.new(1, 1, 1), PSI), Size = seq(1.6, 0), Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(30, 70), SpreadAngle = Vector2.new(180, 180), Drag = 3 }):Emit(90)
	emissor(a, { Texture = TEX.implosao, Color = cseq(PSI2, PSI), Size = seq(8, raio * 1.4), Lifetime = NumberRange.new(0.45), Speed = NumberRange.new(0), Transparency = seq(0, 1) }):Emit(3)
	emissor(a, { Texture = TEX.fumaca, Color = cseq(Color3.fromRGB(120, 90, 170)), Size = seq(3, 9), Lifetime = NumberRange.new(0.9, 1.5), Speed = NumberRange.new(25, 45), SpreadAngle = Vector2.new(8, 180), Drag = 4, Transparency = seq(0.5, 1), LightEmission = 0.3, EmissionDirection = Enum.NormalId.Front }):Emit(50)
	local luz = Instance.new("PointLight") luz.Color = PSI luz.Range = 60 luz.Brightness = 8 luz.Parent = p
	TweenService:Create(luz, TweenInfo.new(1.2), { Brightness = 0 }):Play()
	Debris:AddItem(p, 2)
	VFX.Som("rbxasset://sounds/impact_explosion_03.mp3", pos, 1, 0.55)
	VFX.Som("rbxassetid://9125647212", pos, 0.9, 0.6)
end

-- aura roxa em volta do inimigo sendo estrangulado
function VFX.AuraEstrangulado(model, dur)
	local torso = model and (model:FindFirstChild("UpperTorso") or model:FindFirstChild("HumanoidRootPart"))
	if not torso then return end
	local a = Instance.new("Attachment") a.Parent = torso
	local e = emissor(a, { Texture = TEX.glow, Color = cseq(PSI2, PSI), Size = seq(3, 0.5), Lifetime = NumberRange.new(0.3, 0.5), Rate = 25, Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Transparency = seq(0.4, 1) })
	e.Enabled = true
	local h = Instance.new("Highlight") h.FillColor = PSI h.OutlineColor = PSI2 h.FillTransparency = 0.75 h.OutlineTransparency = 0.2 h.DepthMode = Enum.HighlightDepthMode.Occluded h.Parent = model
	task.delay(dur, function() e.Enabled = false h:Destroy() Debris:AddItem(a, 1) end)
end

return VFX