-- BOSS FASE 3: TENENTE KESSLER — escudo balistico que bloqueia tiros de frente.
-- LEVITAR (R) arranca o escudo por alguns segundos. Investida deixa ele sem guarda. Pisao = onda no chao (pule).
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

return {
	tipo = "Escudeiro",
	criarModelo = function(cfg, api)
		local model = api.criarHumanoide("Pesado")
		model.Name = "Escudeiro"
		local c = api.cor
		local torso = model:FindFirstChild("UpperTorso")
		local escala = cfg.Escala / 1.22
		if escala ~= 1 then model:ScaleTo(model:GetScale() * escala) end
		torso = model:FindFirstChild("UpperTorso")
		local ts = torso.Size
		local escudo = api.peca(model, "EscudoBalistico", Vector3.new(ts.X * 2.1, ts.Y * 3.2, 0.35), torso.CFrame * CFrame.new(0, -ts.Y * 0.5, -ts.Z / 2 - 1.1), c(40, 44, 50), Enum.Material.Metal, { CanCollide = false })
		api.soldar(torso, escudo)
		local visor = api.peca(model, "VisorEscudo", Vector3.new(escudo.Size.X * 0.7, escudo.Size.Y * 0.14, 0.4), escudo.CFrame * CFrame.new(0, escudo.Size.Y * 0.28, 0), c(120, 170, 200), Enum.Material.Glass, { Transparency = 0.3 })
		api.soldar(escudo, visor)
		local faixa = api.peca(model, "FaixaEscudo", Vector3.new(escudo.Size.X * 0.9, 0.35, 0.42), escudo.CFrame * CFrame.new(0, -escudo.Size.Y * 0.15, 0), c(230, 190, 40), Enum.Material.Neon)
		api.soldar(escudo, faixa)
		local g = Instance.new("SurfaceGui") g.Face = Enum.NormalId.Front g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 30 g.Parent = escudo
		local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 0.25) t.Position = UDim2.fromScale(0, 0.62) t.BackgroundTransparency = 1 t.TextColor3 = c(230, 230, 230)
		t.Font = Enum.Font.GothamBlack t.Text = "CONTENÇÃO" t.TextWrapped = true t.TextScaled = true t.Parent = g
		local bb = model:FindFirstChild("BarraVida", true) if bb then bb:Destroy() end
		return model
	end,

	cerebro = function(rec, api)
		local ctx = api.ctx()
		local model = rec.model
		local escudo = model:FindFirstChild("EscudoBalistico")
		rec.escudoFrontal = true
		rec.escudoAtivo = true
		local soltou = false
		local vivo = function() return model.Parent and not rec.morto end

		local function largarEscudo(tempo)
			if not escudo or not escudo.Parent or not rec.escudoAtivo then return end
			rec.escudoAtivo = false
			for _, x in ipairs(escudo:GetDescendants()) do if x:IsA("WeldConstraint") and (x.Part0 ~= escudo and x.Part1 == escudo) then x.Enabled = false end end
			for _, w in ipairs(escudo:GetChildren()) do if w:IsA("WeldConstraint") then w.Enabled = false end end
			escudo.CanCollide = true
			escudo.Massless = false
			ctx.fx("numero", rec.hrp.Position + Vector3.new(0, 6, 0), "SEM ESCUDO!", false, Color3.fromRGB(255, 220, 90))
			ctx.fx("faisca", escudo.Position)
			if tempo then
				task.delay(tempo, function()
					if not vivo() or rec.furia then return end
					local torso = model:FindFirstChild("UpperTorso")
					escudo.CanCollide = false escudo.Massless = true
					escudo.CFrame = torso.CFrame * CFrame.new(0, -torso.Size.Y * 0.5, -torso.Size.Z / 2 - 1.1)
					for _, w in ipairs(escudo:GetChildren()) do if w:IsA("WeldConstraint") then w.Enabled = true end end
					rec.escudoAtivo = true
					ctx.fx("numero", rec.hrp.Position + Vector3.new(0, 6, 0), "ESCUDO ERGUIDO", false, Color3.fromRGB(170, 190, 210))
				end)
			end
		end

		-- pisao: onda no chao que se expande (pule!)
		local function pisao(player, char)
			rec.hum:MoveTo(rec.hrp.Position)
			local w = rec.motores.Waist
			ctx.fx("avisoCirculo", rec.hrp.Position - Vector3.new(0, 4, 0), 5, 0.8)
			if w then api.tweenJ(w, 0.4, rec.c0.Waist * CFrame.Angles(math.rad(-20), 0, 0)) end
			rec.hrp:ApplyImpulse(Vector3.new(0, 60, 0) * rec.hrp.AssemblyMass)
			task.wait(0.8)
			if not vivo() then return end
			if w then api.tweenJ(w, 0.1, rec.c0.Waist * CFrame.Angles(math.rad(25), 0, 0)) end
			local centro = rec.hrp.Position
			local rp = api.paramsMundo()
			local r = workspace:Raycast(centro, Vector3.new(0, -20, 0), rp)
			local chao = r and r.Position.Y or centro.Y - 5
			local raioMax, dur = 26, 1.1
			ctx.fx("anelChoque", Vector3.new(centro.X, chao, centro.Z), raioMax, dur)
			ctx.fx("tremer", centro, 2.2)
			local t0 = os.clock()
			local acertou = false
			while os.clock() - t0 < dur and not acertou do
				local raio = 2 + (raioMax - 2) * ((os.clock() - t0) / dur)
				local ph = char and char:FindFirstChild("HumanoidRootPart")
				if ph and ph.Position.Y - chao < 4.4 then
					local d = api.plano(ph.Position - centro).Magnitude
					if math.abs(d - raio) < 1.6 then
						acertou = true
						ctx.danoJogador(player, 20, centro)
						ctx.empurrar(player, api.plano(ph.Position - centro).Unit * 50 + Vector3.new(0, 30, 0))
					end
				end
				task.wait(0.03)
			end
			if w then api.tweenJ(w, 0.4, rec.c0.Waist) end
			task.wait(0.4)
		end

		local function escopeta(player, char, alvo)
			pcall(api.atacarPadrao, rec, player, char, alvo)
		end

		local function investida(player, char, alvo)
			api.ATAQUES.investida(rec, player, char, alvo)
		end

		task.wait(1.5)
		while vivo() do
			-- levitado: escudo cai
			if rec.levitadoAte and rec.levitadoAte > os.clock() then
				largarEscudo(not rec.furia and 5 or nil)
				task.wait(0.2)
				continue
			end
			if rec.trocarFase then
				rec.trocarFase = false
				rec.invuln = true
				ctx.fx("rugido", rec.hrp.Position, 18)
				if rec.fase == 2 then
					ctx.fx("banner", "TENENTE KESSLER", "FASE 2 — reforços a caminho")
					ctx.reforcos(2, "Soldado")
				else
					ctx.fx("banner", "TENENTE KESSLER", "FASE 3 — ele largou o escudo. FÚRIA")
					rec.furia = true
					largarEscudo(nil)
					rec.cfg = table.clone(rec.cfg) rec.cfg.Velocidade += 5 rec.cfg.Recarga = 1.2
					rec.hum.WalkSpeed = rec.cfg.Velocidade
					ctx.reforcos(2, "Elite")
				end
				task.wait(1.2)
				rec.invuln = false
			end
			local player, char, alvo = api.alvoJogador()
			if not alvo then task.wait(0.3) continue end
			local dist = api.plano(alvo.Position - rec.hrp.Position).Magnitude
			local opcoes = { "escopeta", "escopeta", "investida" }
			if dist < 16 then table.insert(opcoes, "pisao") table.insert(opcoes, "pisao") end
			if rec.fase >= 2 then table.insert(opcoes, "pisao") table.insert(opcoes, "investida") end
			local atk = opcoes[math.random(1, #opcoes)]
			rec.atacando = true
			local guarda = rec.escudoAtivo
			if atk == "escopeta" then escopeta(player, char, alvo)
			elseif atk == "investida" then
				investida(player, char, alvo)
				-- depois da investida fica sem guarda um instante
				if guarda and not rec.furia then rec.escudoAtivo = false ctx.fx("numero", rec.hrp.Position + Vector3.new(0, 6, 0), "GUARDA ABERTA", false, Color3.fromRGB(255, 220, 90)) task.wait(1.4) if vivo() and escudo.Parent and not rec.furia and not (rec.levitadoAte and rec.levitadoAte > os.clock()) then rec.escudoAtivo = true end end
			else pisao(player, char) end
			rec.atacando = false rec.mirando = false
			if rec.hum.Parent then rec.hum.AutoRotate = true rec.hum.WalkSpeed = rec.cfg.Velocidade end
			-- anda em direcao ao jogador com o escudo na frente
			local fim = os.clock() + (rec.furia and 0.8 or 1.5)
			while os.clock() < fim and vivo() and not rec.trocarFase do
				local d = alvo.Position - rec.hrp.Position
				local dirU = api.plano(d).Magnitude > 0.1 and api.plano(d).Unit or Vector3.xAxis
				local dd = api.plano(d).Magnitude
				local destino = dd > rec.cfg.Distancia and rec.hrp.Position + dirU * 8 or rec.hrp.Position + Vector3.new(-dirU.Z, 0, dirU.X) * 5 * (rec.lado or 1)
				api.andarPara(rec, destino)
				task.wait(0.2)
			end
		end
	end,
}
