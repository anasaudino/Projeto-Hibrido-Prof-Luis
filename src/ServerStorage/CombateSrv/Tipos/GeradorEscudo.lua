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
	tipo = "GeradorEscudo",
	criarModelo = function(cfg, api)
		local c = api.cor
		local m, hrp = novaBase("GeradorEscudo")
		P(api, m, hrp, "Base", CFrame.new(0, -0.3, 0), Vector3.new(3.4, 1.4, 3.4), c(60, 64, 70), Enum.Material.Metal)
		P(api, m, hrp, "Coluna", CFrame.new(0, 2.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(4.4, 1.4, 1.4), c(120, 126, 130), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
		for i = 0, 2 do P(api, m, hrp, "Bobina", CFrame.new(0, 1.2 + i * 1.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.4, 2.2, 2.2), c(170, 110, 60), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder }) end
		local topo = P(api, m, hrp, "Head", CFrame.new(0, 5.2, 0), Vector3.new(1.8, 1.8, 1.8), c(90, 220, 255), Enum.Material.Neon, { Shape = Enum.PartType.Ball })
		local l = Instance.new("PointLight") l.Color = c(90, 220, 255) l.Range = 12 l.Brightness = 1.5 l.Parent = topo
		local a = Instance.new("Attachment") a.Name = "Feixe" a.Parent = topo
		return m
	end,
}
