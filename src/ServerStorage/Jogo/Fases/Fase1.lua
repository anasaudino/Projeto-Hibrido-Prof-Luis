-- FASE 1 — Ala Infantil (Prologo + Capitulo 1)
local TweenService = game:GetService("TweenService")
local F = {}
local FASE = workspace:WaitForChild("Fases"):WaitForChild("Fase1")
local GP = FASE:WaitForChild("Gameplay")

local function tweenModel(model, alvo, tempo)
	local v = Instance.new("CFrameValue") v.Value = model:GetPivot()
	v.Changed:Connect(function(cf) model:PivotTo(cf) end)
	local t = TweenService:Create(v, TweenInfo.new(tempo, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = alvo })
	t:Play() t.Completed:Once(function() v:Destroy() end)
	return t
end
local CARRINHO_FIM = CFrame.new(27, 1.75, 5.4) * CFrame.Angles(0, math.pi / 2, 0)

local function desligarPrompt(inst) local pr = inst and inst:FindFirstChildWhichIsA("ProximityPrompt", true) if pr then pr.Enabled = false end end

F.acoes = {}
function F.acoes.Alavanca(p, prompt, api)
	prompt.Enabled = false
	local haste = GP.AlavancaEmergencia:FindFirstChild("Haste")
	if haste then TweenService:Create(haste, TweenInfo.new(0.4, Enum.EasingStyle.Back), { CFrame = haste.CFrame * CFrame.Angles(0, 0, 1.0) + Vector3.new(0, -0.6, 0) }):Play() end
	api.porta(1, "Porta_CamaraJane", false)
	api.marcar(p, "f1_alavanca")
	api.objetivo(p, "Tire o que está bloqueando a passagem")
end
function F.acoes.Carrinho(p, prompt, api)
	prompt.Enabled = false
	local cart = GP.CarrinhoTombado
	cart.Corpo.CanCollide = false
	tweenModel(cart, CARRINHO_FIM, 0.9).Completed:Wait()
	cart.Corpo.CanCollide = true
	api.marcar(p, "f1_carrinho")
	api.objetivo(p, "Encontre a saída da Ala Infantil")
end
function F.acoes.Fusivel(p, prompt, api)
	if (p:GetAttribute("Pedras") or 0) < 1 then api.aviso(p, "Está atrás da grade... sua mão não alcança.") return end
	prompt.Enabled = false
	local fus = prompt.Parent
	local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	TweenService:Create(fus, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { CFrame = fus.CFrame + Vector3.new(-1.6, 0.3, 0) }):Play()
	task.wait(0.4)
	if hrp then local t = TweenService:Create(fus, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(hrp.Position) }) t:Play() t.Completed:Wait() end
	fus:Destroy()
	api.marcar(p, "f1_fusivel")
	api.objetivo(p, "Instale o fusível no painel da porta")
end
local function painelLigado()
	local painel = GP.PainelEnergiaSaida
	painel.Indicador.Color = Color3.fromRGB(70, 230, 130)
	painel.Encaixe.Color = Color3.fromRGB(220, 170, 60)
	local gui = painel.Etiqueta:FindFirstChildOfClass("SurfaceGui")
	if gui then gui.TextLabel.Text = "ENERGIA OK" gui.TextLabel.TextColor3 = Color3.fromRGB(30, 140, 70) end
	desligarPrompt(painel)
end
function F.acoes.Painel(p, prompt, api)
	if not api.flag(p, "f1_fusivel") then api.aviso(p, "Falta um fusível. O painel está sem energia.") return end
	painelLigado()
	api.porta(1, "Porta_SaidaAla", false)
	api.marcar(p, "f1_painel")
	api.objetivo(p, "Vá até o elevador")
end

F.gatilhos = {}
function F.gatilhos.ala(p, api)
	api.radio(p, "f1_federais")
end
function F.gatilhos.saida(p, api)
	api.objetivo(p, "Use o painel do elevador (E)")
end

function F.aposPedra(p, api, n)
	api.radio(p, "f1_pedra")
	api.checkpoint(p, 1, "modulo")
	local leds = FASE.Props.ModuloSupressao:FindFirstChild("LedsPainel")
	if leds then leds.Color = Color3.fromRGB(255, 50, 50) leds:AddTag("LuzPiscando") end
	api.objetivo(p, "Volte pra Sala Arco-Íris")
end

F.arenaLimpa = {}
F.arenaLimpa.ArcoIris = function(p, api)
	if not api.flag(p, "f1_fusivel") then api.objetivo(p, "Use a mente (Pulso) no fusível atrás da grade — E") end
end

function F.podeSair(p, api)
	if not api.flag(p, "f1_painel") then return false, "O elevador está sem energia." end
	return true
end

-- restaura o estado do mundo a partir das flags (continuar / checkpoint)
function F.aoCarregar(p, api, cp)
	if api.flag(p, "f1_alavanca") then api.porta(1, "Porta_CamaraJane", false) desligarPrompt(GP.AlavancaEmergencia) end
	if api.flag(p, "f1_carrinho") and GP:FindFirstChild("CarrinhoTombado") then GP.CarrinhoTombado:PivotTo(CARRINHO_FIM) desligarPrompt(GP.CarrinhoTombado) end
	if api.flag(p, "pedra_1") and GP:FindFirstChild("Pedra_01") then GP.Pedra_01:Destroy() end
	if api.flag(p, "f1_fusivel") and GP:FindFirstChild("Fusivel") then GP.Fusivel:Destroy() end
	if api.flag(p, "f1_painel") then painelLigado() api.porta(1, "Porta_SaidaAla", false) end
	if cp == "inicio" and not api.flag(p, "f1_alavanca") then api.objetivo(p, "Encontre um jeito de abrir a porta") end
end

function F.prologo(p, api)
	task.wait(3.2)
	api.cutscene(p, {
		tomadas = {
			{ de = CFrame.lookAt(Vector3.new(15, 9, 2), Vector3.new(6, 2, 8)), ate = CFrame.lookAt(Vector3.new(12, 7, 4), Vector3.new(6, 2.5, 9)), dur = 4 },
			{ de = CFrame.lookAt(Vector3.new(9, 4, 16), Vector3.new(6, 2.6, 8)), ate = CFrame.lookAt(Vector3.new(8, 3.6, 14), Vector3.new(6, 2.8, 8)), dur = 4 },
		},
		falas = {
			{ "", "Horas depois do ataque.", 3 },
			{ "JANE", "...onde está todo mundo?", 3 },
			{ "JANE", "Por que a porta está trancada...?", 2 },
		},
	})
	api.objetivo(p, "Encontre um jeito de abrir a porta")
end

function F.objetivoPadrao(p, api)
	local f = function(k) return api.flag(p, k) end
	if not f("f1_alavanca") then return "Encontre um jeito de abrir a porta" end
	if not f("f1_carrinho") then return "Tire o que está bloqueando a passagem" end
	if not f("pedra_1") then return "Encontre a saída da Ala Infantil" end
	if not f("arena_ArcoIris") then return "Volte pra Sala Arco-Íris" end
	if not f("f1_fusivel") then return "Use a mente (Pulso) no fusível atrás da grade — E" end
	if not f("f1_painel") then return "Instale o fusível no painel da porta" end
	return "Vá até o elevador"
end

return F
