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
	tipo = "Torreta",
	criarModelo = function(cfg, api)
		local c = api.cor
		local m, hrp = novaBase("Torreta")
		P(api, m, hrp, "Base", CFrame.new(0, -0.4, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(1.2, 3.2, 3.2), c(60, 64, 70), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		P(api, m, hrp, "Coluna", CFrame.new(0, 0.9, 0), Vector3.new(1, 1.6, 1), c(90, 96, 100), Enum.Material.Metal)
		local head = P(api, m, hrp, "Head", CFrame.new(0, 2.2, 0), Vector3.new(2.2, 1.3, 2.4), c(200, 204, 200), Enum.Material.SmoothPlastic)
		P(api, m, hrp, "Faixa", CFrame.new(0, 2.2, 0), Vector3.new(2.25, 0.3, 2.45), c(220, 180, 40), Enum.Material.SmoothPlastic)
		local olho = P(api, m, hrp, "Olho", CFrame.new(0, 2.45, -1.22), Vector3.new(0.9, 0.3, 0.1), c(255, 40, 40), Enum.Material.Neon)
		local l = Instance.new("PointLight") l.Color = c(255, 50, 40) l.Range = 7 l.Brightness = 1 l.Parent = olho
		local arma = Instance.new("Model") arma.Name = "Arma" arma.Parent = m
		for _, x in ipairs({ -0.45, 0.45 }) do
			local cano = api.peca(arma, x < 0 and "Cano" or "Cano2", Vector3.new(0.3, 0.3, 1.8), CFrame.new(x, 2.0, -1.9), c(30, 30, 34), Enum.Material.Metal)
			cano.Anchored = false cano.Massless = true api.soldar(hrp, cano)
			if x < 0 then local mz = Instance.new("Attachment") mz.Name = "Muzzle" mz.Position = Vector3.new(0.45, 0, -0.9) mz.Parent = cano end
		end
		return m
	end,
}
