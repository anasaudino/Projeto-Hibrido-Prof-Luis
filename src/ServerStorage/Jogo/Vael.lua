-- VAEL — o Vigia. Ser da outra dimensao, pai biologico do Jane. So aparece em eventos roteirizados.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Vael = {}
local template

local function criarTemplate()
	local d = Instance.new("HumanoidDescription")
	local cor = Color3.fromRGB(16, 14, 20)
	d.HeadColor = cor d.TorsoColor = cor d.LeftArmColor = cor d.RightArmColor = cor d.LeftLegColor = cor d.RightLegColor = cor
	d.WidthScale = 0.7 d.DepthScale = 0.75 d.HeightScale = 1.05 d.HeadScale = 0.85 d.ProportionScale = 1 d.BodyTypeScale = 1
	local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15) end)
	if not ok then warn("[Vael] " .. tostring(model)) return end
	model.Name = "Vael"
	for _, x in ipairs(model:GetDescendants()) do
		if x:IsA("Decal") then x:Destroy()
		elseif x:IsA("Script") or x:IsA("LocalScript") then x:Destroy()
		elseif x:IsA("BasePart") then x.Material = Enum.Material.SmoothPlastic x.Color = cor x.Reflectance = 0.08 end
	end
	model:ScaleTo(1.75)
	-- bracos mais longos
	for _, n in ipairs({ "LeftLowerArm", "RightLowerArm" }) do local p = model:FindFirstChild(n) if p then p.Size = p.Size * Vector3.new(0.85, 1.35, 0.85) end end
	local head = model.Head
	for _, x in ipairs({ -0.22, 0.22 }) do
		local o = Instance.new("Part") o.Name = "Olho" o.Size = Vector3.new(0.22, 0.12, 0.05) * 1.75 o.Material = Enum.Material.Neon
		o.Color = Color3.fromRGB(255, 110, 100) o.CanCollide = false o.Massless = true o.CastShadow = false
		o.CFrame = head.CFrame * CFrame.new(x * 1.75, 0.1 * 1.75, -head.Size.Z / 2 - 0.02) o.Parent = model
		local w = Instance.new("WeldConstraint") w.Part0 = head w.Part1 = o w.Parent = o
	end
	local luz = Instance.new("PointLight") luz.Color = Color3.fromRGB(255, 90, 80) luz.Range = 8 luz.Brightness = 1 luz.Parent = head
	local torso = model.UpperTorso
	local a = Instance.new("Attachment") a.Parent = torso
	local pe = Instance.new("ParticleEmitter") pe.Name = "Fumaca"
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds" pe.Color = ColorSequence.new(Color3.fromRGB(10, 8, 14))
	pe.Size = NumberSequence.new(2, 5) pe.Transparency = NumberSequence.new(0.5, 1) pe.Lifetime = NumberRange.new(1.5, 2.5)
	pe.Rate = 8 pe.Speed = NumberRange.new(0.5, 1.5) pe.SpreadAngle = Vector2.new(180, 180) pe.LightEmission = 0 pe.Parent = a
	local h = model:FindFirstChildOfClass("Humanoid")
	h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	h.WalkSpeed = 15 h.MaxHealth = math.huge h.Health = math.huge h.BreakJointsOnDeath = false
	return model
end

function Vael.criar(cf, parent)
	template = template or criarTemplate()
	if not template then return end
	local model = template:Clone()
	model:PivotTo(cf)
	model.Parent = parent or workspace
	local hum = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart")
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") and not p.Anchored then pcall(p.SetNetworkOwner, p, nil) end end
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local tracks = {}
	for k, id in pairs({ idle = "rbxassetid://507766666", walk = "rbxassetid://507777826" }) do
		local an = Instance.new("Animation") an.AnimationId = id
		local ok, t = pcall(function() return animator:LoadAnimation(an) end)
		if ok then tracks[k] = t t.Looped = true end
	end
	if tracks.idle then tracks.idle:Play() tracks.idle:AdjustSpeed(0.5) end
	hum.Running:Connect(function(v)
		local t = tracks.walk if not t then return end
		if v > 0.5 and not t.IsPlaying then t:Play(0.3) elseif v <= 0.5 and t.IsPlaying then t:Stop(0.4) end
		if t.IsPlaying then t:AdjustSpeed(v / 16) end
	end)
	local ent = { model = model, hum = hum, hrp = hrp, ativo = true }

	function ent.olharPara(pos)
		hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(pos.X, hrp.Position.Y, pos.Z))
	end
	function ent.andar(pos, vel)
		hum.WalkSpeed = vel or 12
		hum:MoveTo(pos)
	end
	function ent.parar() hum:MoveTo(hrp.Position) end
	function ent.ancorar(sim) hrp.Anchored = sim end
	function ent.sumir(tempo)
		ent.ativo = false
		tempo = tempo or 1.2
		for _, p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then TweenService:Create(p, TweenInfo.new(tempo), { Transparency = 1 }):Play()
			elseif p:IsA("Light") then TweenService:Create(p, TweenInfo.new(tempo), { Brightness = 0 }):Play()
			elseif p:IsA("ParticleEmitter") then p.Rate = 40 task.delay(0.3, function() p.Enabled = false end) end
		end
		task.delay(tempo + 2, function() model:Destroy() end)
	end
	-- persegue o jogador; retorna "pegou" ou "parou"
	function ent.perseguir(p, o)
		o = o or {}
		hum.WalkSpeed = o.vel or 15
		local t0 = os.clock()
		while ent.ativo and model.Parent do
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if not r then return "parou" end
			if o.parar and o.parar() then ent.parar() return "parou" end
			local d = (r.Position - hrp.Position)
			if Vector3.new(d.X, 0, d.Z).Magnitude < (o.alcance or 4.5) then ent.parar() return "pegou" end
			hum:MoveTo(r.Position)
			if o.limite and os.clock() - t0 > o.limite then return "parou" end
			task.wait(0.15)
		end
		return "parou"
	end
	-- toca na superficie (mao no vidro)
	function ent.maoNoVidro()
		for _, x in ipairs(model:GetDescendants()) do
			if x:IsA("AnimationConstraint") and x.Name == "RightShoulder" and x.Attachment0 then
				TweenService:Create(x.Attachment0, TweenInfo.new(1.2, Enum.EasingStyle.Sine), { CFrame = x.Attachment0.CFrame * CFrame.Angles(math.rad(95), 0, 0) }):Play()
			end
		end
	end
	return ent
end

return Vael
