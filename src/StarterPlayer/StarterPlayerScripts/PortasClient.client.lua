-- Animacao das portas (CLIENTE): destrave, deslize com amortecimento, ar pneumatico, som e luz.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local SOM_ABRIR = "rbxassetid://9125646252"
local SOM_TRAVA = "rbxassetid://220025689"
local FUMACA = "rbxasset://textures/particles/smoke_main.dds"

local function som(parent, id, vol, pitch)
	local s = Instance.new("Sound") s.SoundId = id s.Volume = vol s.PlaybackSpeed = pitch
	s.RollOffMinDistance = 6 s.RollOffMaxDistance = 60 s.Parent = parent
	s:Play() Debris:AddItem(s, 3)
end

local function jatoDeAr(part, baixo)
	local a = Instance.new("Attachment")
	a.Parent = part
	a.Position = Vector3.new(0, baixo and -part.Size.Y / 2 + 0.3 or part.Size.Y / 2 - 0.3, 0)
	local e = Instance.new("ParticleEmitter")
	e.Texture = FUMACA e.Color = ColorSequence.new(Color3.fromRGB(230, 235, 240))
	e.Size = NumberSequence.new(0.6, 2.2) e.Transparency = NumberSequence.new(0.55, 1)
	e.Lifetime = NumberRange.new(0.4, 0.8) e.Speed = NumberRange.new(3, 6) e.SpreadAngle = Vector2.new(70, 20)
	e.Drag = 4 e.LightEmission = 0.2 e.Enabled = false e.Parent = a
	e.EmissionDirection = baixo and Enum.NormalId.Bottom or Enum.NormalId.Top
	e:Emit(10)
	Debris:AddItem(a, 1.2)
end

local registros = {}

local function aplicar(r, aberta, instantaneo)
	r.token += 1
	local meu = r.token
	for _, t in ipairs(r.tweens) do t:Cancel() end
	table.clear(r.tweens)
	if instantaneo then
		for _, f in ipairs(r.folhas) do f.part.CFrame = aberta and f.aberto or f.fechado end
		return
	end
	local principal = r.folhas[1] and r.folhas[1].part
	if aberta then
		-- 1) destrave: tranco pequeno pro lado contrario
		if principal then som(principal, SOM_TRAVA, 0.35, 0.55) end
		for _, f in ipairs(r.folhas) do
			local dir = (f.aberto.Position - f.fechado.Position)
			local recuo = dir.Magnitude > 0 and -dir.Unit * 0.12 or Vector3.zero
			local t = TweenService:Create(f.part, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = f.fechado + recuo })
			table.insert(r.tweens, t) t:Play()
		end
		task.wait(0.09)
		if r.token ~= meu then return end
		-- 2) ar pneumatico + deslize com amortecimento
		if principal then som(principal, SOM_ABRIR, 0.45, 1.45) end
		for _, f in ipairs(r.folhas) do
			jatoDeAr(f.part, true)
			local t = TweenService:Create(f.part, TweenInfo.new(r.tempo, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { CFrame = f.aberto })
			table.insert(r.tweens, t) t:Play()
		end
	else
		if principal then som(principal, SOM_ABRIR, 0.3, 1.1) end
		for _, f in ipairs(r.folhas) do
			local t = TweenService:Create(f.part, TweenInfo.new(r.tempo * 0.9, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), { CFrame = f.fechado })
			table.insert(r.tweens, t) t:Play()
		end
		task.wait(r.tempo * 0.9)
		if r.token ~= meu then return end
		-- batida de fechamento: pequeno repique
		if principal then som(principal, SOM_TRAVA, 0.45, 0.45) end
		for _, f in ipairs(r.folhas) do
			local dir = (f.aberto.Position - f.fechado.Position)
			local rep = dir.Magnitude > 0 and dir.Unit * 0.08 or Vector3.zero
			f.part.CFrame = f.fechado + rep
			local t = TweenService:Create(f.part, TweenInfo.new(0.18, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { CFrame = f.fechado })
			table.insert(r.tweens, t) t:Play()
			jatoDeAr(f.part, true)
		end
	end
end

local function registrar(m)
	if registros[m] or not m:IsDescendantOf(workspace) then return end
	local r = { model = m, folhas = {}, tweens = {}, token = 0, tempo = math.clamp((m:GetAttribute("Tempo") or 0.6) * 0.9, 0.35, 0.8) }
	for _, c in ipairs(m:GetChildren()) do
		if c:IsA("BasePart") and c:GetAttribute("Folha") then
			local abrir = c:GetAttribute("Abrir") or Vector3.zero
			table.insert(r.folhas, { part = c, fechado = c.CFrame, aberto = c.CFrame + abrir })
		end
	end
	registros[m] = r
	if m:GetAttribute("Aberta") then aplicar(r, true, true) end
	m:GetAttributeChangedSignal("Aberta"):Connect(function()
		task.spawn(aplicar, r, m:GetAttribute("Aberta") == true, false)
	end)
end

for _, m in ipairs(CollectionService:GetTagged("PortaFase")) do task.spawn(registrar, m) end
CollectionService:GetInstanceAddedSignal("PortaFase"):Connect(function(m) task.defer(registrar, m) end)
