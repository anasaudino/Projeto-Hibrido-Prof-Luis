-- BOSS FASE 2: NUCLEO CERBERO — maquina fixa. Imune enquanto houver geradores de escudo.
-- Lasers giratorios rentes ao chao (pule!), granadas, leque e drones de reforco.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local function novaBase(nome)
	local m = Instance.new("Model") m.Name = nome
	local hrp = Instance.new("Part") hrp.Name = "HumanoidRootPart" hrp.Size = Vector3.new(4, 4, 4) hrp.Transparency = 1
	hrp.Anchored = true hrp.CanCollide = false hrp.CFrame = CFrame.new() hrp.Parent = m
	local hum = Instance.new("Humanoid") hum.RequiresNeck = false hum.BreakJointsOnDeath = false hum.Parent = m
	m.PrimaryPart = hrp
	return m, hrp, hum
end

return {
	tipo = "Cerbero",
	criarModelo = function(cfg, api)
		local c = api.cor
		local m, hrp = novaBase("Cerbero")
		local function P(nome, cf, sz, cor, mat, ex)
			local p = api.peca(m, nome, sz, cf, cor, mat, ex) p.Anchored = false p.Massless = true p.CanCollide = false api.soldar(hrp, p) return p
		end
		P("Plataforma", CFrame.new(0, -5.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(1, 12, 12), c(50, 54, 60), Enum.Material.DiamondPlate, { Shape = Enum.PartType.Cylinder, CanCollide = true })
		P("Pilar", CFrame.new(0, -2.5, 0), Vector3.new(3, 5, 3), c(90, 96, 100), Enum.Material.Metal)
		local nucleo = P("Head", CFrame.new(0, 1, 0), Vector3.new(4.5, 4.5, 4.5), c(255, 50, 40), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		local l = Instance.new("PointLight") l.Color = c(255, 60, 40) l.Range = 26 l.Brightness = 2.5 l.Parent = nucleo
		for i = 0, 3 do
			local a = i * math.pi / 2
			P("Garra", CFrame.new(math.cos(a) * 3.3, 1, math.sin(a) * 3.3) * CFrame.Angles(0, -a, 0), Vector3.new(0.8, 6, 1.2), c(70, 74, 80), Enum.Material.Metal)
		end
		P("Anel", CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.6, 8.5, 8.5), c(200, 204, 200), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, Transparency = 0.2 })
		local escudo = P("Escudo", CFrame.new(0, 1, 0), Vector3.new(11, 11, 11), c(90, 220, 255), Enum.Material.ForceField, { Shape = Enum.PartType.Ball, Transparency = 1 })
		local arma = Instance.new("Model") arma.Name = "Arma" arma.Parent = m
		local cano = api.peca(arma, "Cano", Vector3.new(0.6, 0.6, 2.4), CFrame.new(0, 1, -3.4), c(30, 30, 34), Enum.Material.Metal)
		cano.Anchored = false cano.Massless = true api.soldar(hrp, cano)
		local mz = Instance.new("Attachment") mz.Name = "Muzzle" mz.Position = Vector3.new(0, 0, -1.2) mz.Parent = cano
		return m
	end,

	cerebro = function(rec, api)
		local ctx = api.ctx()
		local hrp = rec.hrp
		local model = rec.model
		local nucleo = model:FindFirstChild("Head")
		local escudo = model:FindFirstChild("Escudo")
		local centro = hrp.Position
		local rp = api.paramsMundo()
		local r = workspace:Raycast(centro, Vector3.new(0, -20, 0), rp)
		local chao = r and r.Position.Y or centro.Y - 6
		local vivo = function() return model.Parent and not rec.morto end

		-- ===== escudo / geradores =====
		local geradores = {}
		local feixes = {}
		local function ligarEscudo(n, raio)
			rec.invuln = true
			escudo.Transparency = 0.1
			ctx.fx("banner", "ESCUDO ATIVO", "Destrua os geradores")
			for i = 1, n do
				local a = (i - 1) * (math.pi * 2 / n) + math.random() * 0.4
				local pos = Vector3.new(centro.X + math.cos(a) * raio, chao + 1, centro.Z + math.sin(a) * raio)
				ctx.fx("teleporte", pos)
				local g = api.criar("GeradorEscudo", pos)
				if g then
					table.insert(geradores, g)
					local a0 = Instance.new("Attachment") a0.Parent = nucleo
					local a1 = g:FindFirstChild("Head") and g.Head:FindFirstChild("Feixe")
					if a1 then
						local b = Instance.new("Beam") b.Attachment0 = a0 b.Attachment1 = a1 b.Width0 = 0.6 b.Width1 = 0.6 b.FaceCamera = true
						b.LightEmission = 1 b.Color = ColorSequence.new(Color3.fromRGB(90, 220, 255)) b.Transparency = NumberSequence.new(0.2)
						b.Texture = "rbxasset://textures/particles/sparkles_main.dds" b.TextureSpeed = 3 b.Parent = a0
						feixes[g] = a0
					end
				end
			end
		end
		local function checarEscudo()
			local vivos = 0
			for i = #geradores, 1, -1 do
				local g = geradores[i]
				local h = g.Parent and g:FindFirstChildOfClass("Humanoid")
				if not g.Parent or g.Parent.Name ~= "Inimigos" or not h or h.Health <= 0 then
					if feixes[g] then feixes[g]:Destroy() feixes[g] = nil end
					table.remove(geradores, i)
				else vivos += 1 end
			end
			if rec.invuln and vivos == 0 then
				rec.invuln = false
				escudo.Transparency = 1
				ctx.fx("banner", "ESCUDO DESATIVADO", "O núcleo está exposto!")
				ctx.fx("explosao", nucleo.Position, 10)
			end
		end

		-- ===== lasers giratorios =====
		local lasers = {}
		local velLaser = 0.55
		local function criarLasers(n)
			for _, l in ipairs(lasers) do l:Destroy() end
			lasers = {}
			for i = 1, n do
				local p = Instance.new("Part") p.Name = "LaserGiratorio" p.Anchored = true p.CanCollide = false p.CanQuery = false p.CastShadow = false
				p.Material = Enum.Material.Neon p.Color = Color3.fromRGB(255, 40, 40) p.Size = Vector3.new(0.35, 0.35, 30)
				p.Parent = model
				local luz = Instance.new("SurfaceLight") luz.Face = Enum.NormalId.Top luz.Color = Color3.fromRGB(255, 40, 40) luz.Range = 6 luz.Brightness = 2 luz.Parent = p
				table.insert(lasers, p)
			end
		end
		local ang = 0
		local cdLaser = {}
		local con
		con = RunService.Heartbeat:Connect(function(dt)
			if not vivo() then con:Disconnect() for _, l in ipairs(lasers) do l:Destroy() end return end
			ang += velLaser * dt
			local n = #lasers
			for i, l in ipairs(lasers) do
				local a = ang + (i - 1) * (math.pi * 2 / n)
				local dir = Vector3.new(math.cos(a), 0, math.sin(a))
				local ini = Vector3.new(centro.X, chao + 1.5, centro.Z) + dir * 6.5
				l.CFrame = CFrame.lookAt(ini + dir * 15, ini + dir * 30)
				for _, p in ipairs(Players:GetPlayers()) do
					local ph = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if ph and (cdLaser[p] or 0) < os.clock() and ph.Position.Y - chao < 4.4 then
						local d = api.distSegmento(Vector3.new(ph.Position.X, chao + 1.5, ph.Position.Z), ini, ini + dir * 30)
						if d < 1.3 then
							cdLaser[p] = os.clock() + 0.8
							ctx.danoJogador(p, 14, ph.Position - dir * 2)
							ctx.fx("faisca", ph.Position)
						end
					end
				end
			end
		end)

		-- ===== ciclo =====
		task.wait(1.5)
		ligarEscudo(3, 17)
		criarLasers(1)
		ctx.fx("banner", "PULE OS LASERS", "Eles giram rentes ao chão")
		local proxDrone = os.clock() + 8
		while vivo() do
			checarEscudo()
			if rec.trocarFase then
				rec.trocarFase = false
				ctx.fx("rugido", nucleo.Position, 22)
				if rec.fase == 2 then
					ctx.fx("banner", "NÚCLEO CÉRBERO", "FASE 2 — reforçando escudo")
					ligarEscudo(2, 14)
					criarLasers(2) velLaser = 0.7
				else
					ctx.fx("banner", "NÚCLEO CÉRBERO", "FASE 3 — SOBRECARGA")
					criarLasers(3) velLaser = 0.95
					nucleo.Color = Color3.fromRGB(255, 120, 40)
				end
			end
			local player, char, alvo = api.alvoJogador()
			if alvo then
				local drones = 0
				for _, r in ipairs(api.vivos()) do if r.tipo == "Drone" then drones += 1 end end
				if os.clock() > proxDrone and drones < 3 then
					proxDrone = os.clock() + (rec.fase >= 3 and 9 or 13)
					for _ = 1, (rec.fase >= 2 and 2 or 1) do
						local a = math.random() * math.pi * 2
						local pos = Vector3.new(centro.X + math.cos(a) * 20, chao + 8, centro.Z + math.sin(a) * 20)
						ctx.fx("teleporte", Vector3.new(pos.X, chao + 1, pos.Z))
						task.delay(0.6, function() if vivo() then api.criar("Drone", pos) end end)
					end
				end
				local atk = (math.random() < 0.55) and "granadas" or "leque"
				rec.atacando = true
				local ok, e = pcall(api.ATAQUES[atk], rec, player, char, alvo)
				if not ok then warn("[Cerbero] " .. atk .. ": " .. tostring(e)) end
				rec.atacando = false
			end
			local espera = rec.fase >= 3 and 1.4 or (rec.fase == 2 and 2 or 2.6)
			local t0 = os.clock()
			while os.clock() - t0 < espera and vivo() do checarEscudo() task.wait(0.2) end
		end
		for _, g in ipairs(geradores) do if g.Parent then local h = g:FindFirstChildOfClass("Humanoid") if h then h.Health = 0 end end end
	end,
}
