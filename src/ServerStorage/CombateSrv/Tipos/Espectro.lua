-- BOSS FASE 4: ESPECTRO — camuflagem optica. Invisivel, exceto quando ataca ou sob o ECO (G).
-- Teleporta pras costas do Jane e corta; lanca facas em leque; na fase 2 chama elites; na 3 fica mais rapido.
return {
	tipo = "Espectro",
	criarModelo = function(cfg, api)
		local model = api.criarHumanoide("Elite")
		model.Name = "Espectro"
		local c = api.cor
		for _, bp in ipairs(model:GetChildren()) do
			if bp:IsA("BasePart") and bp.Name ~= "HumanoidRootPart" then bp.Color = c(14, 16, 22) end
		end
		local visor = model:FindFirstChild("Visor") if visor then visor.Color = c(170, 110, 255) end
		local torso = model:FindFirstChild("UpperTorso")
		local manto = api.peca(model, "Manto", torso.Size * Vector3.new(1.3, 2.4, 1.3), torso.CFrame * CFrame.new(0, -torso.Size.Y * 0.6, 0.2), c(20, 20, 28), Enum.Material.Fabric)
		api.soldar(torso, manto)
		local arma = model:FindFirstChild("Arma") if arma then arma:Destroy() end
		local mao = model:FindFirstChild("RightHand")
		local lam = api.peca(model, "Lamina", Vector3.new(0.15, 0.4, 3), mao.CFrame * CFrame.new(0, -0.2, -1.4), c(200, 160, 255), Enum.Material.Neon)
		api.soldar(mao, lam)
		local a = Instance.new("Model") a.Name = "Arma" a.Parent = model
		local cano = api.peca(a, "Cano", Vector3.new(0.2, 0.2, 0.2), mao.CFrame, c(0, 0, 0), Enum.Material.SmoothPlastic, { Transparency = 1 })
		api.soldar(mao, cano)
		local mz = Instance.new("Attachment") mz.Name = "Muzzle" mz.Parent = cano
		local bb = model:FindFirstChild("BarraVida", true) if bb then bb:Destroy() end
		model:SetAttribute("Invisivel", true)
		return model
	end,

	cerebro = function(rec, api)
		local ctx = api.ctx()
		local model = rec.model
		local hrp = rec.hrp
		local vivo = function() return model.Parent and not rec.morto end
		local function visivel(sim) model:SetAttribute("Invisivel", not sim) end
		visivel(false)

		local function corte(player, char, alvo)
			local atras = alvo.CFrame * CFrame.new(0, 0, 5.5)
			ctx.fx("faisca", hrp.Position)
			model:PivotTo(CFrame.lookAt(atras.Position, alvo.Position))
			ctx.fx("faisca", hrp.Position)
			visivel(true)
			ctx.fx("numero", hrp.Position + Vector3.new(0, 4, 0), "!!", false, Color3.fromRGB(255, 70, 70))
			local rs = rec.motores.RightShoulder
			if rs then api.tweenJ(rs, 0.35, rec.c0.RightShoulder * CFrame.Angles(math.rad(150), 0, 0)) end
			task.wait(rec.fase >= 3 and 0.45 or 0.6)
			if not vivo() then return end
			if rs then api.tweenJ(rs, 0.08, rec.c0.RightShoulder * CFrame.Angles(math.rad(-20), 0, math.rad(20))) end
			local ph = char:FindFirstChild("HumanoidRootPart")
			if ph and (ph.Position - hrp.Position).Magnitude < 7.5 then
				ctx.danoJogador(player, 18, hrp.Position)
				ctx.empurrar(player, (ph.Position - hrp.Position).Unit * 40 + Vector3.new(0, 20, 0))
			end
			ctx.fx("faisca", hrp.Position + hrp.CFrame.LookVector * 3)
			task.wait(0.3)
			if rs then api.tweenJ(rs, 0.3, rec.c0.RightShoulder) end
			visivel(false)
		end

		local function facas(player, char, alvo)
			visivel(true)
			rec.hum:MoveTo(hrp.Position)
			api.virarPara(rec, alvo.Position)
			local origem = hrp.Position + Vector3.new(0, 1, 0)
			local base = api.plano(alvo.Position - origem)
			base = base.Magnitude > 0.1 and base.Unit or hrp.CFrame.LookVector
			local fins = {}
			for i = 1, 5 do
				local ang = math.rad(-24 + (i - 1) * 12)
				table.insert(fins, api.limiteParede(origem, CFrame.fromAxisAngle(Vector3.yAxis, ang) * base, 45))
			end
			ctx.fx("avisoLinhas", origem, fins, 0.55)
			task.wait(0.55)
			if not vivo() then return end
			local acertou = false
			for _, fim in ipairs(fins) do
				ctx.fx("tiro", origem, fim)
				local ph = char:FindFirstChild("HumanoidRootPart")
				if ph and not acertou and api.distSegmento(Vector3.new(ph.Position.X, origem.Y, ph.Position.Z), origem, fim) < 1.6 then
					acertou = true
					ctx.danoJogador(player, 9, origem)
				end
			end
			task.wait(0.25)
			visivel(false)
		end

		task.wait(1.2)
		while vivo() do
			if rec.levitadoAte and rec.levitadoAte > os.clock() then visivel(true) task.wait(0.2) continue end
			if rec.trocarFase then
				rec.trocarFase = false
				visivel(true)
				ctx.fx("rugido", hrp.Position, 16)
				if rec.fase == 2 then
					ctx.fx("banner", "ESPECTRO", "FASE 2 — ele não está sozinho")
					ctx.reforcos(2, "Elite")
				else
					ctx.fx("banner", "ESPECTRO", "FASE 3 — mais rápido")
					rec.cfg = table.clone(rec.cfg) rec.cfg.Velocidade = 26
				end
				task.wait(1)
				visivel(false)
			end
			local player, char, alvo = api.alvoJogador()
			if not alvo then task.wait(0.3) continue end
			rec.atacando = true
			local ok, e = pcall(math.random() < 0.6 and corte or facas, player, char, alvo)
			if not ok then warn("[Espectro] " .. tostring(e)) end
			if rec.fase >= 3 and vivo() and math.random() < 0.5 then pcall(corte, player, char, alvo) end
			rec.atacando = false
			local fim = os.clock() + (rec.fase >= 3 and 1.2 or 2)
			rec.hum.WalkSpeed = rec.cfg.Velocidade
			while os.clock() < fim and vivo() and not rec.trocarFase do
				local d = alvo.Position - hrp.Position
				local dirU = api.plano(d).Magnitude > 0.1 and api.plano(d).Unit or Vector3.xAxis
				local lateral = Vector3.new(-dirU.Z, 0, dirU.X) * (rec.lado or 1) * 10
				api.andarPara(rec, alvo.Position - dirU * 14 + lateral)
				task.wait(0.2)
			end
			if math.random() < 0.4 then rec.lado = -(rec.lado or 1) end
		end
		model:SetAttribute("Invisivel", false)
	end,
}
