local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Config = require(RS:WaitForChild("Combate"):WaitForChild("Config"))
local Rem = RS.Combate:WaitForChild("Remotes")
local player = Players.LocalPlayer
local gui = script.Parent

local rgb = Color3.fromRGB
local PSI = Config.CorPsi

local function new(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o) end
local function stroke(o, c, t, tr) return new("UIStroke", { Color = c, Thickness = t or 1.5, Transparency = tr or 0, LineJoinMode = Enum.LineJoinMode.Miter }, o) end
local function tw(o, t, props, style) local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) x:Play() return x end

-- ================= barras (canto inferior esquerdo) =================
local painel = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 28, 1, -28), Size = UDim2.fromOffset(300, 64), BackgroundTransparency = 1 }, gui)
local function barra(y, cor, rotulo)
	local fundo = new("Frame", { Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = rgb(14, 16, 20), BackgroundTransparency = 0.15, BorderSizePixel = 0 }, painel)
	corner(fundo, 4) stroke(fundo, rgb(255, 255, 255), 1, 0.85)
	local rastro = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.3, BorderSizePixel = 0 }, fundo) corner(rastro, 4)
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = cor, BorderSizePixel = 0 }, fundo) corner(fill, 4)
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 255), rgb(170, 170, 170)) }, fill)
	local txt = new("TextLabel", { Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = rgb(245, 245, 245), TextXAlignment = Enum.TextXAlignment.Left, Text = rotulo, TextStrokeTransparency = 0.5 }, fundo)
	return { fundo = fundo, fill = fill, rastro = rastro, txt = txt, rotulo = rotulo, k = 1 }
end
local bVida = barra(0, rgb(220, 60, 70), "VIDA")
local bFoco = barra(28, PSI, "FOCO")
bFoco.fundo.Size = UDim2.new(0.8, 0, 0, 14) bFoco.txt.TextSize = 11
local function setBarra(b, v, max)
	local k = math.clamp(v / math.max(max, 1), 0, 1)
	b.fill.Size = UDim2.fromScale(k, 1)
	if k < b.k then tw(b.rastro, 0.45, { Size = UDim2.fromScale(k, 1) }) else b.rastro.Size = UDim2.fromScale(k, 1) end
	b.k = k
	b.txt.Text = ("%s  %d / %d"):format(b.rotulo, math.floor(v + 0.5), max)
end

-- ================= habilidades (centro inferior) =================
local slots = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -26), Size = UDim2.fromOffset(150, 64), BackgroundTransparency = 1, Visible = false }, gui)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 12) }, slots)
local function slot(tecla, nome)
	local f = new("Frame", { Size = UDim2.fromOffset(64, 64), BackgroundColor3 = rgb(16, 14, 24), BackgroundTransparency = 0.1 }, slots)
	corner(f, 10) local st = stroke(f, PSI, 2, 0.2)
	new("TextLabel", { Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.fromScale(0, 0.18), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = rgb(235, 225, 255), Text = nome }, f)
	local k = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromOffset(34, 18), BackgroundColor3 = PSI, Font = Enum.Font.GothamBlack, TextSize = 11, TextColor3 = rgb(20, 10, 30), Text = tecla }, f)
	corner(k, 4)
	local cd = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 2 }, f)
	corner(cd, 10)
	local cdt = new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = rgb(255, 255, 255), Text = "", ZIndex = 3 }, f)
	return { f = f, cd = cd, cdt = cdt, st = st }
end
local sPulso = slot("LMB", "PULSO")
local sOnda = slot("F", "ONDA")
local sDash = slot("Q", "DASH")
local sLev = slot("R", "LEVITAR")
local sEco = slot("G", "ECO")
local sUlt = slot("V", "ULT")
sUlt.f.Size = UDim2.fromOffset(76, 76)
slots.Size = UDim2.fromOffset(500, 76)
local ultPct = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -18), Size = UDim2.fromOffset(76, 16), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = rgb(255, 220, 120), Text = "0%", TextStrokeTransparency = 0.4, ZIndex = 4 }, sUlt.f)

-- ================= abates + mutacoes (canto superior direito) =================
local topo = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 18), Size = UDim2.fromOffset(320, 90), BackgroundTransparency = 1, Visible = false }, gui)
local kills = new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(200, 28), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = rgb(240, 235, 255), TextXAlignment = Enum.TextXAlignment.Right, Text = "ABATES  0", TextStrokeTransparency = 0.4 }, topo)
local essLbl = new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -210, 0, 0), Size = UDim2.fromOffset(120, 28), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = rgb(110, 230, 255), TextXAlignment = Enum.TextXAlignment.Right, Text = "0", TextStrokeTransparency = 0.4 }, topo)
local icones = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 34), Size = UDim2.fromOffset(320, 40), BackgroundTransparency = 1 }, topo)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6) }, icones)
local tip = new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 80), Size = UDim2.fromOffset(320, 36), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = rgb(220, 215, 235), TextXAlignment = Enum.TextXAlignment.Right, TextWrapped = true, Text = "" }, topo)

local function atualizarIcones()
	for _, c in ipairs(icones:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local ok, buffs = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Buffs") or "{}")
	if not ok then return end
	for _, b in ipairs(Config.Buffs) do
		local n = buffs[b.id]
		if n and n > 0 then
			local cor = Config.Raridades[b.rar].Cor
			local f = new("Frame", { Size = UDim2.fromOffset(38, 38), BackgroundColor3 = rgb(16, 14, 24), BackgroundTransparency = 0.1 }, icones)
			corner(f, 8) stroke(f, cor, 2)
			new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = cor, Text = b.sigla }, f)
			if n > 1 then
				local q = new("TextLabel", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 4, 1, 4), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = cor, Font = Enum.Font.GothamBlack, TextSize = 11, TextColor3 = rgb(15, 10, 20), Text = tostring(n) }, f)
				corner(q, 8)
			end
			f.MouseEnter:Connect(function() tip.Text = b.nome .. " — " .. b.desc end)
			f.MouseLeave:Connect(function() tip.Text = "" end)
			local us = new("UIScale", { Scale = 0.2 }, f)
			tw(us, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
end
player:GetAttributeChangedSignal("Buffs"):Connect(atualizarIcones)
player:GetAttributeChangedSignal("Kills"):Connect(function()
	kills.Text = "ABATES  " .. tostring(player:GetAttribute("Kills") or 0)
	local us = kills:FindFirstChildOfClass("UIScale") or new("UIScale", {}, kills)
	us.Scale = 1.35 tw(us, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end)

-- ================= mira =================
local mira = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Visible = false, ZIndex = 20 }, gui)
corner(mira, 11) stroke(mira, rgb(235, 220, 255), 2, 0.1)
local ponto = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = rgb(255, 255, 255), ZIndex = 21 }, mira)
corner(ponto, 2)

-- ================= vinheta de dano =================
local vinheta = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 30 }, gui)
local bordas = {}
for i, d in ipairs({ { UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0), 90 }, { UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.78), 270 }, { UDim2.fromScale(0.16, 1), UDim2.fromScale(0, 0), 0 }, { UDim2.fromScale(0.16, 1), UDim2.fromScale(0.84, 0), 180 } }) do
	local f = new("Frame", { Size = d[1], Position = d[2], BackgroundColor3 = rgb(200, 0, 20), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 30 }, vinheta)
	new("UIGradient", { Rotation = d[3], Transparency = NumberSequence.new(0, 1) }, f)
	bordas[i] = f
end
local function flashDano(forca)
	for _, f in ipairs(bordas) do
		f.BackgroundTransparency = math.clamp(0.75 - forca, 0.1, 0.8)
		tw(f, 0.5, { BackgroundTransparency = 1 })
	end
end

-- ================= banner =================
local banner = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.16, 0), Size = UDim2.fromOffset(700, 90), BackgroundTransparency = 1, ZIndex = 40 }, gui)
local bTitulo = new("TextLabel", { Size = UDim2.new(1, 0, 0, 56), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 46, TextColor3 = rgb(255, 245, 250), TextTransparency = 1, TextStrokeTransparency = 1, TextStrokeColor3 = rgb(60, 0, 20), Text = "", ZIndex = 40 }, banner)
local bSub = new("TextLabel", { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 20, TextColor3 = rgb(230, 210, 230), TextTransparency = 1, Text = "", ZIndex = 40 }, banner)
local bLinha = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 54), Size = UDim2.fromOffset(0, 2), BackgroundColor3 = rgb(255, 70, 80), BorderSizePixel = 0, ZIndex = 40 }, banner)
local tokenBanner = 0
local function mostrarBanner(t, sub)
	tokenBanner += 1 local meu = tokenBanner
	bTitulo.Text = t bSub.Text = sub or ""
	local us = bTitulo:FindFirstChildOfClass("UIScale") or new("UIScale", {}, bTitulo)
	us.Scale = 1.4
	bTitulo.TextTransparency = 0 bTitulo.TextStrokeTransparency = 0.3
	tw(us, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	bLinha.Size = UDim2.fromOffset(0, 2) bLinha.BackgroundTransparency = 0
	tw(bLinha, 0.4, { Size = UDim2.fromOffset(420, 2) })
	tw(bSub, 0.4, { TextTransparency = 0 })
	task.delay(2.2, function()
		if meu ~= tokenBanner then return end
		tw(bTitulo, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 }) tw(bSub, 0.5, { TextTransparency = 1 }) tw(bLinha, 0.5, { BackgroundTransparency = 1 })
	end)
end

-- ================= tela de morte =================
local morte = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 1, ZIndex = 60, Visible = false }, gui)
local mT = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(800, 70), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 64, TextColor3 = rgb(230, 40, 50), Text = "CAPTURADO", TextTransparency = 1, ZIndex = 61 }, morte)
local mS = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromOffset(800, 30), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 20, TextColor3 = rgb(220, 210, 220), Text = "As mutações se perderam. O laboratório te arrasta de volta...", TextTransparency = 1, ZIndex = 61 }, morte)
local mR = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromOffset(800, 60), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = rgb(110, 230, 255), Text = "", TextTransparency = 1, ZIndex = 61 }, morte)
local function telaMorte(kills, ess)
	mR.Text = ("Abates nesta run: %d     ·     Essência ganha: %d\nGaste Essência na ÁRVORE (tecla T) pra voltar mais forte"):format(kills or 0, ess or 0)
	tw(mR, 1.6, { TextTransparency = 0 })
	morte.Visible = true
	tw(morte, 1, { BackgroundTransparency = 0.15 }) tw(mT, 1, { TextTransparency = 0 }) tw(mS, 1.4, { TextTransparency = 0 })
end
player.CharacterAdded:Connect(function()
	if morte.Visible then
		tw(morte, 1, { BackgroundTransparency = 1 }) tw(mT, 0.6, { TextTransparency = 1 }) tw(mS, 0.6, { TextTransparency = 1 }) tw(mR, 0.6, { TextTransparency = 1 })
		task.delay(1, function() morte.Visible = false end)
	end
end)

-- ================= escolha de mutacao =================
local modal = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(6, 4, 12), BackgroundTransparency = 1, Visible = false, ZIndex = 50, Active = true }, gui)
local mTitulo = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.14), Size = UDim2.fromOffset(800, 50), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 40, TextColor3 = rgb(240, 225, 255), Text = "", ZIndex = 51 }, modal)
local mDica = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.14, 50), Size = UDim2.fromOffset(800, 24), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = rgb(190, 180, 210), Text = "Clique numa carta ou aperte 1, 2 ou 3", ZIndex = 51 }, modal)
local linhaCartas = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromOffset(880, 340), BackgroundTransparency = 1, ZIndex = 51 }, modal)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 26) }, linhaCartas)
local rerolar = new("TextButton", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.56, 190), Size = UDim2.fromOffset(220, 40), BackgroundColor3 = rgb(20, 40, 55), Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = rgb(110, 230, 255), Text = "REROLAR   10", ZIndex = 52, AutoButtonColor = true }, modal)
corner(rerolar, 8) stroke(rerolar, rgb(110, 230, 255), 1.5, 0.2)
rerolar.Activated:Connect(function() Rem.Rerolar:FireServer() end)
local ofertaAtual
local NOMES_RAR = { Comum = "COMUM", Raro = "RARO", Epico = "ÉPICO" }

local function fecharModal()
	tw(modal, 0.3, { BackgroundTransparency = 1 })
	for _, c in ipairs(linhaCartas:GetChildren()) do
		if c:IsA("TextButton") then local us = c:FindFirstChildOfClass("UIScale") if us then tw(us, 0.2, { Scale = 0 }) end end
	end
	task.delay(0.3, function() if not ofertaAtual then modal.Visible = false end end)
end

local function escolher(id)
	if not ofertaAtual then return end
	ofertaAtual = nil
	Rem.EscolherBuff:FireServer(id)
	fecharModal()
end

local function abrirModal(titulo, ids, atuais, custo)
	ofertaAtual = ids
	rerolar.Text = "REROLAR   ·   Essência " .. tostring(custo or 10)
	rerolar.TextTransparency = (player:GetAttribute("Essencia") or 0) >= (custo or 10) and 0 or 0.6
	local largura = #ids * 250 + (#ids - 1) * 26
	linhaCartas.Size = UDim2.fromOffset(largura, 340)
	for _, c in ipairs(linhaCartas:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	mTitulo.Text = titulo
	modal.Visible = true modal.BackgroundTransparency = 1
	tw(modal, 0.35, { BackgroundTransparency = 0.35 })
	for i, id in ipairs(ids) do
		local b = Config.BuffPorId[id]
		local cor = Config.Raridades[b.rar].Cor
		local nivel = (atuais and atuais[id]) or 0
		local card = new("TextButton", { Size = UDim2.fromOffset(250, 330), BackgroundColor3 = rgb(18, 14, 28), AutoButtonColor = false, Text = "", ZIndex = 52, LayoutOrder = i }, linhaCartas)
		corner(card, 14)
		local st = stroke(card, cor, 2.5, 0.1)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 255), rgb(150, 140, 170)) }, card)
		local faixa = new("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = cor, BorderSizePixel = 0, ZIndex = 53 }, card) corner(faixa, 14)
		new("Frame", { Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = cor, BorderSizePixel = 0, ZIndex = 53 }, faixa)
		new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 14, TextColor3 = rgb(15, 10, 20), Text = NOMES_RAR[b.rar] .. "   ·   " .. tostring(i), ZIndex = 54 }, faixa)
		local selo = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 56), Size = UDim2.fromOffset(92, 92), BackgroundColor3 = rgb(10, 8, 16), ZIndex = 53 }, card)
		corner(selo, 46) stroke(selo, cor, 3)
		new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 34, TextColor3 = cor, Text = b.sigla, ZIndex = 54 }, selo)
		new("TextLabel", { Position = UDim2.fromOffset(12, 162), Size = UDim2.new(1, -24, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 21, TextColor3 = rgb(250, 245, 255), Text = b.nome, TextWrapped = true, ZIndex = 53 }, card)
		new("TextLabel", { Position = UDim2.fromOffset(18, 198), Size = UDim2.new(1, -36, 0, 80), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = rgb(210, 200, 225), Text = b.desc, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 53 }, card)
		new("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -24, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = cor, Text = nivel > 0 and ("NÍVEL %d → %d"):format(nivel, nivel + 1) or "NOVA", ZIndex = 53 }, card)
		local us = new("UIScale", { Scale = 0 }, card)
		task.delay(0.08 * i, function() tw(us, 0.35, { Scale = 1 }, Enum.EasingStyle.Back) end)
		card.MouseEnter:Connect(function() tw(us, 0.15, { Scale = 1.06 }) st.Thickness = 4 end)
		card.MouseLeave:Connect(function() tw(us, 0.15, { Scale = 1 }) st.Thickness = 2.5 end)
		card.Activated:Connect(function() escolher(id) end)
	end
end
Rem.OferecerBuffs.OnClientEvent:Connect(abrirModal)
UIS.InputBegan:Connect(function(input)
	if not ofertaAtual then return end
	local map = { [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3 }
	local i = map[input.KeyCode]
	if i and ofertaAtual[i] then escolher(ofertaAtual[i]) end
end)

-- ================= eventos =================
Rem.VFX.OnClientEvent:Connect(function(tipo, a, b)
	if tipo == "banner" then mostrarBanner(a, b)
	elseif tipo == "danoJogador" then flashDano(math.min(0.6, (a or 5) / 25))
	elseif tipo == "morte" then telaMorte(a, b)
	end
end)

-- ================= loop =================
RunService.RenderStepped:Connect(function()
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if h then
		setBarra(bVida, h.Health, h.MaxHealth)
		local k = h.Health / math.max(h.MaxHealth, 1)
		if k < 0.3 and h.Health > 0 then
			local pulso = 0.55 + 0.25 * math.sin(os.clock() * 6)
			for _, f in ipairs(bordas) do if f.BackgroundTransparency > pulso then f.BackgroundTransparency = pulso end end
		end
	end
	local poder = player:GetAttribute("PoderAtracao") == true
	bFoco.fundo.Visible = poder
	slots.Visible = poder
	topo.Visible = poder
	mira.Visible = poder and not ofertaAtual and not morte.Visible
	if poder then
		setBarra(bFoco, player:GetAttribute("Foco") or 0, player:GetAttribute("FocoMax") or 100)
		local m = UIS:GetMouseLocation()
		mira.Position = UDim2.fromOffset(m.X, m.Y)
		-- recarga da onda
		local pronta = player:GetAttribute("OndaPronta") or 0
		local total = player:GetAttribute("OndaRecarga") or Config.Onda.Recarga
		local resto = pronta - workspace:GetServerTimeNow()
		if resto > 0 then
			sOnda.cd.Size = UDim2.fromScale(1, resto / total)
			sOnda.cdt.Text = string.format("%.1f", resto)
		else
			sOnda.cd.Size = UDim2.fromScale(1, 0) sOnda.cdt.Text = ""
		end
		local focoOk = (player:GetAttribute("Foco") or 0) >= Config.Onda.Custo
		sOnda.st.Transparency = focoOk and 0.2 or 0.8
		sPulso.st.Transparency = (player:GetAttribute("Foco") or 0) >= Config.Pulso.Custo and 0.2 or 0.8
	end
end)
atualizarIcones()



-- ================= Essencia =================
local function atualizarEss()
	essLbl.Text = "Essência " .. tostring(player:GetAttribute("Essencia") or 0)
	local us = essLbl:FindFirstChildOfClass("UIScale") or new("UIScale", {}, essLbl)
	us.Scale = 1.3 tw(us, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end
player:GetAttributeChangedSignal("Essencia"):Connect(atualizarEss)
atualizarEss()

-- ================= barra do chefe =================
local bossF = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.fromOffset(620, 46), BackgroundTransparency = 1, Visible = false, ZIndex = 35 }, gui)
local bossNome = new("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = rgb(255, 225, 225), Text = "", TextStrokeTransparency = 0.3, ZIndex = 35 }, bossF)
local bossFundo = new("Frame", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = rgb(20, 10, 12), BorderSizePixel = 0, ZIndex = 35 }, bossF)
corner(bossFundo, 3) stroke(bossFundo, rgb(255, 80, 80), 1.5, 0.3)
local bossRastro = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(255, 240, 220), BorderSizePixel = 0, ZIndex = 35 }, bossFundo) corner(bossRastro, 3)
local bossBar = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(220, 40, 45), BorderSizePixel = 0, ZIndex = 36 }, bossFundo) corner(bossBar, 3)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 255), rgb(150, 150, 150)) }, bossBar)
for _, k in ipairs(Config.Boss.Fases) do
	new("Frame", { Position = UDim2.fromScale(k, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = rgb(255, 255, 255), BorderSizePixel = 0, ZIndex = 37 }, bossFundo)
end
local ultimoK = 1
RunService.RenderStepped:Connect(function()
	local chefe
	local pasta = workspace:FindFirstChild("Inimigos")
	if pasta then for _, m in ipairs(pasta:GetChildren()) do if m:GetAttribute("Boss") then chefe = m break end end end
	local hm = chefe and chefe:FindFirstChildOfClass("Humanoid")
	if hm and hm.Health > 0 then
		if not bossF.Visible then bossF.Visible = true ultimoK = 1 bossRastro.Size = UDim2.fromScale(1, 1) end
		local k = math.clamp(hm.Health / hm.MaxHealth, 0, 1)
		local fase = k > Config.Boss.Fases[1] and 1 or (k > Config.Boss.Fases[2] and 2 or 3)
		bossNome.Text = chefe:GetAttribute("Boss") .. "   ·   FASE " .. fase
		bossBar.Size = UDim2.fromScale(k, 1)
		if k < ultimoK then tw(bossRastro, 0.6, { Size = UDim2.fromScale(k, 1) }) end
		ultimoK = k
	else
		bossF.Visible = false
	end
	local np = player:GetAttribute("Pedras") or 0
	local u = player:GetAttribute("Ult") or 0
	sUlt.f.Visible = np >= 1
	sUlt.cd.Size = UDim2.fromScale(1, 1 - u / 100)
	sUlt.cdt.Text = ""
	if u >= 100 then
		ultPct.Text = player:GetAttribute("EmUlt") and "..." or "PRONTA [V]"
		sUlt.st.Color = rgb(255, 210, 90)
		sUlt.st.Thickness = 3 + math.sin(os.clock() * 8) * 1.5
		sUlt.st.Transparency = 0
	else
		ultPct.Text = math.floor(u) .. "%"
		sUlt.st.Color = PSI sUlt.st.Thickness = 2 sUlt.st.Transparency = 0.2
	end
	sOnda.f.Visible = np >= 2
	sLev.f.Visible = np >= 4
	sEco.f.Visible = np >= 5
	if sEco.f.Visible then
		local resto = (player:GetAttribute("EcoPronto") or 0) - workspace:GetServerTimeNow()
		if resto > 0 then sEco.cd.Size = UDim2.fromScale(1, resto / 10) sEco.cdt.Text = string.format("%.0f", resto) else sEco.cd.Size = UDim2.fromScale(1, 0) sEco.cdt.Text = "" end
	end
	sLev.st.Transparency = player:GetAttribute("Segurando") and 0 or 0.2
	sLev.st.Thickness = player:GetAttribute("Segurando") and 3.5 or 2
	-- dash
	sDash.f.Visible = player:GetAttribute("TemDash") == true
	if sDash.f.Visible then
		local resto = (player:GetAttribute("DashPronto") or 0) - workspace:GetServerTimeNow()
		local total = player:GetAttribute("DashRecarga") or Config.Dash.Recarga
		if resto > 0 then sDash.cd.Size = UDim2.fromScale(1, resto / total) sDash.cdt.Text = string.format("%.1f", resto)
		else sDash.cd.Size = UDim2.fromScale(1, 0) sDash.cdt.Text = "" end
	end
end)

-- ================= ARVORE DE HABILIDADES (tecla T) =================
local arv = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(6, 5, 12), BackgroundTransparency = 0.08, Visible = false, ZIndex = 70, Active = true }, gui)
new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.fromOffset(700, 44), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 36, TextColor3 = rgb(240, 230, 255), Text = "ÁRVORE DA MENTE", ZIndex = 71 }, arv)
new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 74), Size = UDim2.fromOffset(700, 22), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 15, TextColor3 = rgb(170, 160, 195), Text = "Evoluções permanentes — valem pra todas as runs. Pressione T pra fechar.", ZIndex = 71 }, arv)
local arvEss = new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -40, 0, 36), Size = UDim2.fromOffset(240, 36), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 28, TextColor3 = rgb(110, 230, 255), TextXAlignment = Enum.TextXAlignment.Right, Text = "0", ZIndex = 71 }, arv)
local area = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, -150, 0, 120), Size = UDim2.fromOffset(720, 520), BackgroundTransparency = 1, ZIndex = 71 }, arv)
local det = new("Frame", { AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.5, 240, 0, 140), Size = UDim2.fromOffset(300, 300), BackgroundColor3 = rgb(16, 13, 26), ZIndex = 71 }, arv)
corner(det, 12) local detSt = stroke(det, rgb(120, 110, 150), 2, 0.2)
local dNome = new("TextLabel", { Position = UDim2.fromOffset(18, 16), Size = UDim2.new(1, -36, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = rgb(250, 245, 255), TextXAlignment = Enum.TextXAlignment.Left, Text = "Escolha um nó", ZIndex = 72 }, det)
local dRamo = new("TextLabel", { Position = UDim2.fromOffset(18, 46), Size = UDim2.new(1, -36, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = rgb(170, 160, 195), TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 72 }, det)
local dDesc = new("TextLabel", { Position = UDim2.fromOffset(18, 76), Size = UDim2.new(1, -36, 0, 110), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 17, TextColor3 = rgb(215, 205, 230), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Text = "Clique num círculo pra ver o que ele faz.", ZIndex = 72 }, det)
local dBtn = new("TextButton", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(1, -36, 0, 48), BackgroundColor3 = rgb(40, 34, 60), Font = Enum.Font.GothamBlack, TextSize = 17, TextColor3 = rgb(240, 240, 250), Text = "", Visible = false, ZIndex = 72 }, det)
corner(dBtn, 8)

-- voltar pro menu fecha as telas de combate (precisa vir depois do arv existir)
-- o HUD inteiro some no menu inicial (NoMenu ainda nil = servidor nao respondeu, tambem e menu)
local function hudNoMenu()
	local noMenu = player:GetAttribute("NoMenu") ~= false
	gui.Enabled = not noMenu
	if noMenu then modal.Visible = false arv.Visible = false morte.Visible = false end
end
player:GetAttributeChangedSignal("NoMenu"):Connect(hudNoMenu)
hudNoMenu()

local nosUI = {}
local selecionado
local function comprados()
	local ok, t = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Arvore") or "{}")
	return ok and t or {}
end
local function corRamo(r) for _, x in ipairs(Config.Ramos) do if x.id == r then return x.cor end end return rgb(200, 200, 200) end

local function mostrarDetalhe(no)
	selecionado = no
	local tem = comprados()
	local cor = corRamo(no.ramo)
	dNome.Text = no.nome dRamo.Text = string.upper(no.ramo) .. "  ·  NÍVEL " .. no.tier dRamo.TextColor3 = cor
	dDesc.Text = no.desc .. (no.req and ("\n\nRequer: " .. Config.NoPorId[no.req].nome) or "")
	detSt.Color = cor
	dBtn.Visible = true
	if tem[no.id] then
		dBtn.Text = "DESBLOQUEADO ✓" dBtn.BackgroundColor3 = rgb(30, 70, 50) dBtn.AutoButtonColor = false
	elseif no.req and not tem[no.req] then
		dBtn.Text = "BLOQUEADO" dBtn.BackgroundColor3 = rgb(40, 36, 46) dBtn.AutoButtonColor = false
	else
		local pode = (player:GetAttribute("Essencia") or 0) >= no.custo
		dBtn.Text = ("DESBLOQUEAR   ·   %d Essência"):format(no.custo)
		dBtn.BackgroundColor3 = pode and cor:Lerp(rgb(0, 0, 0), 0.35) or rgb(50, 40, 50)
		dBtn.AutoButtonColor = pode
	end
end
dBtn.Activated:Connect(function()
	if selecionado and not comprados()[selecionado.id] then Rem.ComprarNo:FireServer(selecionado.id) end
end)

local linhasUI = {}
local function linha(a, b, cor)
	local d = b - a
	local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2), Size = UDim2.fromOffset(d.Magnitude, 4), Rotation = math.deg(math.atan2(d.Y, d.X)), BackgroundColor3 = cor, BorderSizePixel = 0, ZIndex = 71 }, area)
	return f
end

local function montarArvore()
	for _, c in ipairs(area:GetChildren()) do c:Destroy() end
	nosUI = {}
	local tem = comprados()
	local pos = {}
	for ci, ramo in ipairs(Config.Ramos) do
		local x = (ci - 1) * 240 + 120
		new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(220, 26), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = ramo.cor, Text = string.upper(ramo.id), ZIndex = 72 }, area)
		new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(x, 26), Size = UDim2.fromOffset(220, 18), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = rgb(160, 150, 185), Text = ramo.desc, ZIndex = 72 }, area)
		local porTier = {}
		for _, no in ipairs(Config.Arvore) do if no.ramo == ramo.id then porTier[no.tier] = porTier[no.tier] or {} table.insert(porTier[no.tier], no) end end
		for tier, lista in pairs(porTier) do
			for i, no in ipairs(lista) do
				local dx = (#lista == 1) and 0 or ((i - 1.5) * 110)
				pos[no.id] = Vector2.new(x + dx, 60 + tier * 100)
			end
		end
	end
	for _, no in ipairs(Config.Arvore) do
		if no.req then
			local ativa = tem[no.req] and tem[no.id]
			linha(pos[no.req], pos[no.id], ativa and corRamo(no.ramo) or rgb(55, 50, 70))
		end
	end
	for _, no in ipairs(Config.Arvore) do
		local p = pos[no.id]
		local cor = corRamo(no.ramo)
		local comprado = tem[no.id]
		local disponivel = not comprado and (not no.req or tem[no.req])
		local b = new("TextButton", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(p.X, p.Y), Size = UDim2.fromOffset(78, 78), BackgroundColor3 = comprado and cor or rgb(18, 15, 28), Text = "", AutoButtonColor = false, ZIndex = 73 }, area)
		corner(b, 39)
		local st = stroke(b, disponivel and cor or (comprado and rgb(255, 255, 255) or rgb(70, 64, 86)), disponivel and 3 or 2, 0)
		new("TextLabel", { Size = UDim2.new(1, -8, 1, 0), Position = UDim2.fromOffset(4, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 11, TextWrapped = true, TextColor3 = comprado and rgb(15, 10, 20) or (disponivel and rgb(240, 235, 255) or rgb(110, 104, 128)), Text = no.nome, ZIndex = 74 }, b)
		if not comprado then
			local c = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(70, 16), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = rgb(110, 230, 255), Text = "" .. no.custo, TextTransparency = disponivel and 0 or 0.5, ZIndex = 74 }, b)
		end
		local us = new("UIScale", {}, b)
		b.MouseEnter:Connect(function() tw(us, 0.12, { Scale = 1.1 }) end)
		b.MouseLeave:Connect(function() tw(us, 0.12, { Scale = 1 }) end)
		b.Activated:Connect(function() mostrarDetalhe(no) end)
		if disponivel then
			task.spawn(function()
				while b.Parent do
					tw(st, 0.8, { Transparency = 0.6 }) task.wait(0.8)
					if not b.Parent then break end
					tw(st, 0.8, { Transparency = 0 }) task.wait(0.8)
				end
			end)
		end
		nosUI[no.id] = b
	end
end

local function atualizarArvore()
	arvEss.Text = "Essência: " .. tostring(player:GetAttribute("Essencia") or 0)
	if arv.Visible then montarArvore() if selecionado then mostrarDetalhe(selecionado) end end
end
player:GetAttributeChangedSignal("Arvore"):Connect(atualizarArvore)
player:GetAttributeChangedSignal("Essencia"):Connect(atualizarArvore)

local function alternarArvore()
	arv.Visible = not arv.Visible
	if arv.Visible then
		montarArvore() atualizarArvore()
		local us = area:FindFirstChildOfClass("UIScale")
		arv.BackgroundTransparency = 1 tw(arv, 0.25, { BackgroundTransparency = 0.08 })
	end
end
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.T then alternarArvore() end
end)
local btnArv = new("TextButton", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 28, 1, -100), Size = UDim2.fromOffset(150, 30), BackgroundColor3 = rgb(22, 18, 34), Font = Enum.Font.GothamBlack, TextSize = 13, TextColor3 = rgb(220, 205, 255), Text = "ÁRVORE  [T]", ZIndex = 5 }, gui)
corner(btnArv, 6) stroke(btnArv, PSI, 1.5, 0.3)
btnArv.Activated:Connect(alternarArvore)
