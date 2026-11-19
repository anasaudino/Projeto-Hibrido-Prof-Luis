local function novaBase(nome, tamanho)
	local m = Instance.new("Model") m.Name = nome
	local hrp = Instance.new("Part") hrp.Name = "HumanoidRootPart" hrp.Size = tamanho or Vector3.new(2, 2, 2) hrp.Transparency = 1
	hrp.Anchored = true hrp.CanCollide = false hrp.CFrame = CFrame.new() hrp.Parent = m
	local hum = Instance.new("Humanoid") hum.RequiresNeck = false hum.BreakJointsOnDeath = false hum.Parent = m
	m.PrimaryPart = hrp
	return m, hrp, hum
end
local function P(api, m, hrp, nome, cf, sz, cor, mat, ex)
	local p = api.peca(m, nome, sz, cf, cor, mat, ex)
	p.Anchored = false p.Massless = true p.CanCollide = false
	api.soldar(hrp, p)
	return p
end
return {
	tipo = "Drone",
	criarModelo = function(cfg, api)
		local c = api.cor
		local m, hrp = novaBase("Drone", Vector3.new(2, 2, 2))
		local corpo = P(api, m, hrp, "Head", CFrame.new(), Vector3.new(2, 2, 2), c(50, 54, 60), Enum.Material.Metal, { Shape = Enum.PartType.Ball })
		P(api, m, hrp, "Anel", CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.3, 3.2, 3.2), c(200, 204, 200), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
		local olho = P(api, m, hrp, "Olho", CFrame.new(0, 0.1, -0.95), Vector3.new(0.7, 0.7, 0.2), c(255, 40, 40), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		local l = Instance.new("PointLight") l.Color = c(255, 50, 40) l.Range = 8 l.Brightness = 1.2 l.Parent = olho
		for _, x in ipairs({ -1.7, 1.7 }) do
			P(api, m, hrp, "Braco", CFrame.new(x * 0.6, 0, 0), Vector3.new(1.4, 0.2, 0.3), c(80, 86, 90), Enum.Material.Metal)
			P(api, m, hrp, "Rotor", CFrame.new(x, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.1, 1.8, 1.8), c(160, 170, 175), Enum.Material.Glass, { Shape = Enum.PartType.Cylinder, Transparency = 0.5 })
		end
		local arma = Instance.new("Model") arma.Name = "Arma" arma.Parent = m
		local cano = api.peca(arma, "Cano", Vector3.new(0.25, 0.25, 1), CFrame.new(0, -0.8, -0.8), c(30, 30, 34), Enum.Material.Metal)
		cano.Anchored = false cano.Massless = true api.soldar(hrp, cano)
		local mz = Instance.new("Attachment") mz.Name = "Muzzle" mz.Position = Vector3.new(0, 0, -0.5) mz.Parent = cano
		return m
	end,
	cerebro = function(rec, api)
		local hrp = rec.hrp
		local ang = math.random() * math.pi * 2
		rec.proxAtaque = os.clock() + 1 + math.random()
		while rec.model.Parent and not rec.morto do
			local player, char, alvo = api.alvoJogador()
			if not alvo then task.wait(0.3) continue end
			if rec.levitadoAte and rec.levitadoAte > os.clock() then task.wait(0.1) continue end
			local agora = os.clock()
			local olho = hrp.Position
			local ve = api.temVisao(olho, alvo.Position, char)
			if ve and (alvo.Position - olho).Magnitude <= rec.cfg.Alcance and agora >= rec.proxAtaque and rec.atordoadoAte < agora then
				rec.atacando = true
				pcall(api.atacarPadrao, rec, player, char, alvo)
				rec.atacando = false
			else
				ang += 0.04 * rec.lado
				local alvoPos = alvo.Position + Vector3.new(math.cos(ang) * rec.cfg.Distancia, 5 + math.sin(agora * 1.3), math.sin(ang) * rec.cfg.Distancia)
				local dir = alvoPos - olho
				if dir.Magnitude > 0.2 then
					local passo = math.min(dir.Magnitude, rec.cfg.Velocidade * 0.05)
					local r = workspace:Raycast(olho, dir.Unit * (passo + 1.6), api.paramsMundo())
					if not r then
						hrp.CFrame = CFrame.lookAt(olho + dir.Unit * passo, Vector3.new(alvo.Position.X, olho.Y, alvo.Position.Z)) * CFrame.Angles(0, 0, math.sin(agora * 2) * 0.1)
					else
						rec.lado = -rec.lado
					end
				end
				task.wait(0.05)
			end
		end
	end,
}
