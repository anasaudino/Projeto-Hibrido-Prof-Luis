-- BOSS FINAL: CMD. REBECCA WARD no exotraje ARGOS.
-- Fase 1: metralhadora em leque + misseis. Fase 2: investidas + reforcos. Fase 3: o VAEL aparece e segura o exotraje.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

local function falar(lista)
	local r = RS:FindFirstChild("Jogo") and RS.Jogo.Remotes:FindFirstChild("Historia")
	if r then r:FireAllClients("legendas", lista) end
end

return {
	tipo = "Ward",
	criarModelo = function(cfg, api)
		local model = api.criarHumanoide("Pesado")
		model.Name = "Ward"
		local escala = cfg.Escala / 1.22
		model:ScaleTo(model:GetScale() * escala)
		local c = api.cor
		for _, bp in ipairs(model:GetChildren()) do
			if bp:IsA("BasePart") and bp.Name ~= "HumanoidRootPart" then bp.Color = c(70, 74, 80) bp.Material = Enum.Material.Metal end
		end
		local torso = model:FindFirstChild("UpperTorso")
		local ts = torso.Size
		local cab = api.peca(model, "Cabine", Vector3.new(ts.X * 0.55, ts.Y * 0.45, 0.3), torso.CFrame * CFrame.new(0, ts.Y * 0.1, -ts.Z / 2 - 0.2), c(255, 150, 60), Enum.Material.Neon)
		api.soldar(torso, cab)
		local l = Instance.new("PointLight") l.Color = c(255, 150, 60) l.Range = 16 l.Brightness = 2 l.Parent = cab
		for _, lado in ipairs({ -1, 1 }) do
			local ombro = model:FindFirstChild(lado < 0 and "LeftUpperArm" or "RightUpperArm")
			local canhao = api.peca(model, "Canhao", Vector3.new(ombro.Size.X * 0.8, ombro.Size.X * 0.8, ts.Z * 1.6), ombro.CFrame * CFrame.new(0, ombro.Size.Y * 0.55, -ts.Z * 0.2), c(40, 42, 46), Enum.Material.Metal)
			api.soldar(ombro, canhao)
			local ponta = api.peca(model, "PontaCanhao", Vector3.new(ombro.Size.X * 0.5, ombro.Size.X * 0.5, 0.2), canhao.CFrame * CFrame.new(0, 0, -canhao.Size.Z / 2), c(255, 80, 40), Enum.Material.Neon)
			api.soldar(canhao, ponta)
		end
		local bb = model:FindFirstChild("BarraVida", true) if bb then bb:Destroy() end
		return model
	end,

	cerebro = function(rec, api)
		local ctx = api.ctx()
		local model = rec.model
		local vivo = function() return model.Parent and not rec.morto end
		task.wait(1)
		falar({ { "CMD. REBECCA WARD", "Chega de fugir, garoto. Você é propriedade deste programa.", 3.5 } })
		task.wait(1.5)
		local vaelUsado = false
		while vivo() do
			if rec.trocarFase then
				rec.trocarFase = false
				rec.invuln = true
				ctx.fx("rugido", rec.hrp.Position, 22)
				if rec.fase == 2 then
					ctx.fx("banner", "CMD. REBECCA WARD", "FASE 2 — exotraje em sobrecarga")
					falar({ { "CMD. REBECCA WARD", "Equipe, fogo de cobertura! NÃO acertem o garoto.", 3 } })
					ctx.reforcos(3, "Elite")
					rec.cfg = table.clone(rec.cfg) rec.cfg.Velocidade += 3 rec.hum.WalkSpeed = rec.cfg.Velocidade
					task.wait(1.2)
					rec.invuln = false
				else
					ctx.fx("banner", "CMD. REBECCA WARD", "FASE 3 — ...o que é AQUILO?")
					falar({ { "CMD. REBECCA WARD", "O que— SOLTA O TRAJE! SOLTA!", 3 } })
					-- o Vael aparece e segura o exotraje
					local ok, Vael = pcall(require, SS.Jogo.Vael)
					if ok and not vaelUsado then
						vaelUsado = true
						local pos = rec.hrp.CFrame * CFrame.new(0, 0, 6)
						ctx.fx("teleporte", pos.Position - Vector3.new(0, 5, 0))
						local v = Vael.criar(CFrame.lookAt(pos.Position, rec.hrp.Position), model.Parent.Parent)
						if v then
							v.ancorar(true)
							v.maoNoVidro()
							rec.hrp.Anchored = true
							rec.invuln = false
							ctx.fx("banner", "O VAEL ESTÁ SEGURANDO O EXOTRAJE", "ATAQUE AGORA!")
							local t0 = os.clock()
							while os.clock() - t0 < 7 and vivo() do
								rec.hrp.CFrame = rec.hrp.CFrame * CFrame.Angles(0, math.sin(os.clock() * 20) * 0.02, 0)
								task.wait(0.05)
							end
							rec.hrp.Anchored = false
							v.sumir(1)
						end
					end
					rec.invuln = false
					rec.cfg = table.clone(rec.cfg) rec.cfg.Velocidade += 3 rec.hum.WalkSpeed = rec.cfg.Velocidade
				end
			end
			local player, char, alvo = api.alvoJogador()
			if not alvo then task.wait(0.3) continue end
			local opcoes = { "leque", "granadas" }
			if rec.fase >= 2 then table.insert(opcoes, "investida") table.insert(opcoes, "investida") end
			if rec.fase >= 3 then table.insert(opcoes, "granadas") table.insert(opcoes, "leque") end
			local atk = opcoes[math.random(1, #opcoes)]
			rec.atacando = true
			local ok, e = pcall(api.ATAQUES[atk], rec, player, char, alvo)
			if not ok then warn("[Ward] " .. atk .. ": " .. tostring(e)) end
			if atk == "leque" and rec.fase >= 2 and vivo() then task.wait(0.3) pcall(api.ATAQUES.leque, rec, player, char, alvo) end
			rec.atacando = false rec.mirando = false
			if rec.hum.Parent then rec.hum.AutoRotate = true rec.hum.WalkSpeed = rec.cfg.Velocidade end
			local fim = os.clock() + (rec.fase >= 3 and 0.9 or 1.4)
			while os.clock() < fim and vivo() and not rec.trocarFase do
				local d = alvo.Position - rec.hrp.Position
				local dirU = api.plano(d).Magnitude > 0.1 and api.plano(d).Unit or Vector3.xAxis
				local dist = api.plano(d).Magnitude
				local lateral = Vector3.new(-dirU.Z, 0, dirU.X) * (rec.lado or 1) * 8
				api.andarPara(rec, dist > 26 and rec.hrp.Position + dirU * 8 or rec.hrp.Position + lateral)
				task.wait(0.2)
			end
			if math.random() < 0.5 then rec.lado = -(rec.lado or 1) end
		end
		falar({ { "CMD. REBECCA WARD", "...isso... não acabou.", 2.5 } })
	end,
}
