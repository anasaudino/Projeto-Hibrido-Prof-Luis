-- Menu inicial, pausa, documentos, legendas, cutscenes, capitulos, creditos.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")

local T = require(RS:WaitForChild("Jogo"):WaitForChild("Textos"))
local RH = RS.Jogo.Remotes.Historia
local RMenu = RS.Jogo.Remotes.Menu
local VFX = require(RS:WaitForChild("Combate"):WaitForChild("VFX"))
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local gui = script.Parent
local rgb = Color3.fromRGB

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)

local function new(cls, props, parent) local o = Instance.new(cls) for k, v in pairs(props) do o[k] = v end o.Parent = parent return o end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o) end
local function stroke(o, c, t, tr) return new("UIStroke", { Color = c, Thickness = t or 1.5, Transparency = tr or 0, LineJoinMode = Enum.LineJoinMode.Miter }, o) end
local function tw(o, t, props, st) local x = TweenService:Create(o, TweenInfo.new(t, st or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props) x:Play() return x end

local config = { legendas = true, volume = 0.8 }

-- ================= fade / preto =================
local preto = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 1, ZIndex = 100 }, gui)
local pretoTxt = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.fromOffset(900, 40), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 22, TextColor3 = rgb(200, 195, 210), TextTransparency = 1, Text = "", ZIndex = 101 }, preto)
local pretoGrande = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromOffset(1000, 70), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 58, TextColor3 = rgb(240, 235, 250), TextTransparency = 1, Text = "", ZIndex = 101 }, preto)
local function fade(escuro, dur, texto, sub)
	dur = dur or 0.8
	tw(preto, dur, { BackgroundTransparency = escuro and 0 or 1 })
	if texto then pretoTxt.Text = texto tw(pretoTxt, dur, { TextTransparency = escuro and 0 or 1 }) elseif not escuro then tw(pretoTxt, dur, { TextTransparency = 1 }) end
	if sub then pretoGrande.Text = sub tw(pretoGrande, dur, { TextTransparency = escuro and 0 or 1 }) elseif not escuro then tw(pretoGrande, dur, { TextTransparency = 1 }) end
end

-- ================= legendas =================
local legCaixa = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(900, 80), BackgroundTransparency = 1, ZIndex = 60 }, gui)
local legQuem = new("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = rgb(190, 150, 255), Text = "", TextStrokeTransparency = 0.4, ZIndex = 61 }, legCaixa)
local legTxt = new("TextLabel", { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 22, TextColor3 = rgb(245, 242, 250), TextWrapped = true, Text = "", TextStrokeTransparency = 0.3, ZIndex = 61 }, legCaixa)
local CORES_FALANTE = { ["JANE"] = rgb(190, 150, 255), ["VAEL"] = rgb(255, 90, 90), ["CMD. REBECCA WARD"] = rgb(255, 180, 90), ["DRA. EVELYN CARTER"] = rgb(140, 210, 255), ["DR. MARCUS HALE"] = rgb(200, 200, 200), ["DR. SIMON REEVE"] = rgb(170, 230, 170) }
local filaLeg, tocandoLeg = {}, false
local function tocarLegendas()
	if tocandoLeg then return end
	tocandoLeg = true
	while #filaLeg > 0 do
		local f = table.remove(filaLeg, 1)
		local quem, texto, dur = f[1], f[2], f[3] or 3
		if config.legendas then
			legQuem.Text = quem or "" legQuem.TextColor3 = CORES_FALANTE[quem] or (quem and quem:find("RÁDIO") and rgb(255, 200, 120)) or rgb(220, 220, 230)
			legTxt.Text = texto legTxt.MaxVisibleGraphemes = 0
			legQuem.TextTransparency = 0 legTxt.TextTransparency = 0
			local n = utf8.len(texto) or #texto
			local t0 = os.clock()
			while os.clock() - t0 < dur do
				legTxt.MaxVisibleGraphemes = math.min(n, math.floor((os.clock() - t0) * 55))
				task.wait()
			end
			legTxt.MaxVisibleGraphemes = -1
		else
			task.wait(dur)
		end
	end
	tw(legQuem, 0.4, { TextTransparency = 1 }) tw(legTxt, 0.4, { TextTransparency = 1 })
	tocandoLeg = false
end
local function legendas(lista) for _, f in ipairs(lista) do table.insert(filaLeg, f) end task.spawn(tocarLegendas) end

-- ================= documento =================
local doc = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 620), BackgroundColor3 = rgb(232, 228, 214), Visible = false, ZIndex = 80, Active = true }, gui)
corner(doc, 4) stroke(doc, rgb(120, 110, 90), 2)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 250), rgb(220, 214, 196)) }, doc)
local dCab = new("TextLabel", { Position = UDim2.fromOffset(34, 26), Size = UDim2.new(1, -68, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = rgb(150, 40, 40), TextXAlignment = Enum.TextXAlignment.Left, Text = "CONFIDENCIAL — INSTALAÇÃO GOVERNAMENTAL", ZIndex = 81 }, doc)
local dTit = new("TextLabel", { Position = UDim2.fromOffset(34, 50), Size = UDim2.new(1, -68, 0, 60), BackgroundTransparency = 1, Font = Enum.Font.SpecialElite, TextSize = 26, TextColor3 = rgb(30, 28, 24), TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = "", ZIndex = 81 }, doc)
local dMeta = new("TextLabel", { Position = UDim2.fromOffset(34, 112), Size = UDim2.new(1, -68, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = rgb(90, 84, 70), TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 81 }, doc)
new("Frame", { Position = UDim2.fromOffset(34, 138), Size = UDim2.new(1, -68, 0, 2), BackgroundColor3 = rgb(120, 110, 90), BorderSizePixel = 0, ZIndex = 81 }, doc)
local dTxt = new("TextLabel", { Position = UDim2.fromOffset(34, 152), Size = UDim2.new(1, -68, 1, -230), BackgroundTransparency = 1, Font = Enum.Font.SpecialElite, TextSize = 19, TextColor3 = rgb(40, 36, 30), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Text = "", ZIndex = 81 }, doc)
local dEco = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -70), Size = UDim2.new(1, -68, 0, 60), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 48, TextColor3 = rgb(80, 150, 255), Text = "", ZIndex = 81 }, doc)
local dFechar = new("TextButton", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(200, 36), BackgroundColor3 = rgb(40, 36, 30), Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = rgb(240, 235, 220), Text = "FECHAR  [E]", ZIndex = 82 }, doc)
corner(dFechar, 4)
local docAberto
local function abrirDoc(id)
	local d = T.Docs[id] if not d then return end
	docAberto = id
	dTit.Text = d.titulo dMeta.Text = (d.data or "") .. "   ·   " .. (d.autor or "") dTxt.Text = d.texto
	if d.eco then dEco.Text = VFX.EcoAtivo() and d.eco or "▒ ▒" dEco.TextColor3 = VFX.EcoAtivo() and rgb(80, 150, 255) or rgb(160, 150, 130) else dEco.Text = "" end
	doc.Visible = true
	local us = doc:FindFirstChildOfClass("UIScale") or new("UIScale", {}, doc)
	us.Scale = 0.85 tw(us, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	VFX.Som("rbxassetid://9125646252", nil, 0.3, 2.5)
end
local function fecharDoc() doc.Visible = false docAberto = nil end
dFechar.Activated:Connect(fecharDoc)

-- ================= cartao de capitulo / pedra =================
local cartao = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 102 }, gui)
local cCap = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromOffset(900, 30), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 22, TextColor3 = rgb(190, 150, 255), Text = "", TextTransparency = 1, ZIndex = 103 }, cartao)
local cNome = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(1100, 80), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 64, TextColor3 = rgb(245, 240, 255), Text = "", TextTransparency = 1, ZIndex = 103 }, cartao)
local function mostrarCartao(a, b, cor, dur)
	cCap.Text = a cNome.Text = b cCap.TextColor3 = cor or rgb(190, 150, 255)
	local us = cNome:FindFirstChildOfClass("UIScale") or new("UIScale", {}, cNome)
	us.Scale = 1.15 tw(us, dur or 2.6, { Scale = 1 })
	tw(cCap, 0.6, { TextTransparency = 0 }) tw(cNome, 0.8, { TextTransparency = 0 })
	task.delay(dur or 2.4, function() tw(cCap, 0.8, { TextTransparency = 1 }) tw(cNome, 0.8, { TextTransparency = 1 }) end)
end
local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(200, 150, 255), BackgroundTransparency = 1, ZIndex = 99 }, gui)

-- ================= cutscene =================
local barraCima = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = rgb(0, 0, 0), BorderSizePixel = 0, ZIndex = 90 }, gui)
local barraBaixo = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = rgb(0, 0, 0), BorderSizePixel = 0, ZIndex = 90 }, gui)
local emCutscene = false
local function cutscene(tomadas, falas)
	emCutscene = true
	tw(barraCima, 0.6, { Size = UDim2.new(1, 0, 0.11, 0) }) tw(barraBaixo, 0.6, { Size = UDim2.new(1, 0, 0.11, 0) })
	camera.CameraType = Enum.CameraType.Scriptable
	if falas then legendas(falas) end
	for _, t in ipairs(tomadas) do
		camera.CFrame = t.de
		local x = TweenService:Create(camera, TweenInfo.new(t.dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { CFrame = t.ate })
		x:Play() x.Completed:Wait()
	end
	camera.CameraType = Enum.CameraType.Custom
	tw(barraCima, 0.6, { Size = UDim2.new(1, 0, 0, 0) }) tw(barraBaixo, 0.6, { Size = UDim2.new(1, 0, 0, 0) })
	emCutscene = false
end

-- ================= creditos =================
local cred = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(0, 0, 0), Visible = false, ZIndex = 110 }, gui)
local credLista = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromOffset(800, 900), BackgroundTransparency = 1, ZIndex = 111 }, cred)
new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8) }, credLista)
for i, l in ipairs(T.Creditos) do
	new("TextLabel", { Size = UDim2.new(1, 0, 0, i == 1 and 70 or 34), BackgroundTransparency = 1, Font = i == 1 and Enum.Font.GothamBlack or Enum.Font.GothamMedium, TextSize = i == 1 and 56 or 24, TextColor3 = rgb(235, 230, 245), Text = l, LayoutOrder = i, ZIndex = 111 }, credLista)
end
local function creditos(dur)
	cred.Visible = true cred.BackgroundTransparency = 1
	tw(cred, 1.5, { BackgroundTransparency = 0 })
	credLista.Position = UDim2.fromScale(0.5, 1)
	TweenService:Create(credLista, TweenInfo.new(dur or 22, Enum.EasingStyle.Linear), { Position = UDim2.new(0.5, 0, 0, -900) }):Play()
end

-- ================= menu inicial =================
-- fundo: corredor da Ala Infantil, desfocado e escurecido (GDD 11.3). Camera fixa com deriva minima, sem atravessar nada.
local MENU_CAM = CFrame.lookAt(Vector3.new(99, 18.4, 9.6), Vector3.new(150, 17.2, 7.4))
local menuBlur = new("BlurEffect", { Name = "MenuBlur", Size = 0, Enabled = false }, camera)
local menuGrade = new("ColorCorrectionEffect", { Name = "MenuGrade", Brightness = -0.07, Contrast = 0.14, Saturation = -0.45, TintColor = rgb(212, 220, 236), Enabled = false }, camera)

local menu = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 120 }, gui)
local sombraEsq = new("Frame", { Size = UDim2.fromScale(0.72, 1), BackgroundColor3 = rgb(3, 3, 6), BorderSizePixel = 0, ZIndex = 120 }, menu)
new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.04), NumberSequenceKeypoint.new(0.5, 0.38), NumberSequenceKeypoint.new(1, 1) }) }, sombraEsq)
local sombraBaixo = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.3), BackgroundColor3 = rgb(3, 3, 6), BorderSizePixel = 0, ZIndex = 120 }, menu)
new("UIGradient", { Rotation = -90, Transparency = NumberSequence.new(0.1, 1) }, sombraBaixo)
local sombraCima = new("Frame", { Size = UDim2.fromScale(1, 0.18), BackgroundColor3 = rgb(3, 3, 6), BorderSizePixel = 0, ZIndex = 120 }, menu)
new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.25, 1) }, sombraCima)

local coluna = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 96, 0.5, 0), Size = UDim2.fromOffset(640, 760), BackgroundTransparency = 1, ZIndex = 121 }, menu)
local escalaColuna = new("UIScale", {}, coluna)
local ponto = new("Frame", { Position = UDim2.fromOffset(0, 6), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = rgb(230, 60, 60), BorderSizePixel = 0, ZIndex = 122 }, coluna)
corner(ponto, 4)
new("TextLabel", { Position = UDim2.fromOffset(18, 0), Size = UDim2.fromOffset(600, 20), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 15, TextColor3 = rgb(215, 95, 95), TextXAlignment = Enum.TextXAlignment.Left, Text = "SUJEITO JANE-01  ·  SUBNÍVEL B2  ·  ACESSO RESTRITO", ZIndex = 122 }, coluna)
local palavras = string.split(T.Titulo, " ")
local tit1 = new("TextLabel", { Position = UDim2.fromOffset(-4, 30), Size = UDim2.fromOffset(640, 92), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 96, TextColor3 = rgb(244, 240, 252), TextXAlignment = Enum.TextXAlignment.Left, Text = palavras[1] or T.Titulo, ZIndex = 122 }, coluna)
local tit2 = new("TextLabel", { Position = UDim2.fromOffset(-4, 116), Size = UDim2.fromOffset(640, 92), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 96, TextColor3 = rgb(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Text = table.concat(palavras, " ", 2), ZIndex = 122 }, coluna)
new("UIGradient", { Rotation = 0, Color = ColorSequence.new(rgb(200, 160, 255), rgb(120, 80, 210)) }, tit2)
new("TextLabel", { Position = UDim2.fromOffset(0, 216), Size = UDim2.fromOffset(640, 24), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 19, TextColor3 = rgb(178, 168, 204), TextXAlignment = Enum.TextXAlignment.Left, Text = "Um jogo de terror psicológico, ficção científica e sobrevivência", ZIndex = 122 }, coluna)
new("Frame", { Position = UDim2.fromOffset(0, 262), Size = UDim2.fromOffset(80, 2), BackgroundColor3 = rgb(160, 110, 240), BorderSizePixel = 0, ZIndex = 122 }, coluna)
local opcoes = new("Frame", { Position = UDim2.fromOffset(-16, 292), Size = UDim2.fromOffset(500, 400), BackgroundTransparency = 1, ZIndex = 121 }, coluna)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, opcoes)
new("TextLabel", { Position = UDim2.fromOffset(0, 724), Size = UDim2.fromOffset(640, 18), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = rgb(128, 122, 148), TextXAlignment = Enum.TextXAlignment.Left, Text = "Use fones de ouvido. Contém sustos e tensão psicológica.", ZIndex = 122 }, coluna)

local rodape = new("TextLabel", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -32, 1, -24), Size = UDim2.fromOffset(700, 18), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 14, TextColor3 = rgb(140, 132, 160), TextXAlignment = Enum.TextXAlignment.Right, Text = "", ZIndex = 121 }, menu)

-- painel lateral (controles, configuracoes, creditos, confirmacao)
local painelMenu = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -96, 0.5, 0), Size = UDim2.fromOffset(500, 540), BackgroundColor3 = rgb(10, 9, 16), BackgroundTransparency = 0.08, Visible = false, ZIndex = 121, Active = true }, menu)
local escalaPainel = new("UIScale", {}, painelMenu)
corner(painelMenu, 6) stroke(painelMenu, rgb(150, 110, 230), 1.2, 0.5)
local painelTit = new("TextLabel", { Position = UDim2.fromOffset(28, 22), Size = UDim2.new(1, -90, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 24, TextColor3 = rgb(245, 240, 255), TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 122 }, painelMenu)
local painelX = new("TextButton", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 18), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = rgb(30, 26, 44), Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = rgb(210, 200, 230), Text = "X", AutoButtonColor = true, ZIndex = 123 }, painelMenu)
corner(painelX, 4)
new("Frame", { Position = UDim2.fromOffset(28, 66), Size = UDim2.new(1, -56, 0, 1), BackgroundColor3 = rgb(90, 75, 130), BorderSizePixel = 0, ZIndex = 122 }, painelMenu)
local painelTxt = new("TextLabel", { Position = UDim2.fromOffset(28, 84), Size = UDim2.new(1, -56, 1, -108), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 18, LineHeight = 1.25, RichText = true, TextColor3 = rgb(222, 216, 234), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 122 }, painelMenu)
local painelLinhas = new("Frame", { Position = UDim2.fromOffset(28, 84), Size = UDim2.new(1, -56, 1, -108), BackgroundTransparency = 1, Visible = false, ZIndex = 122 }, painelMenu)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, painelLinhas)

local posColuna = coluna.Position
local function ajustarEscala()
	local s = math.clamp(camera.ViewportSize.Y / 1080, 0.55, 1.3)
	escalaColuna.Scale = s escalaPainel.Scale = s
	posColuna = UDim2.new(0, math.floor(96 * s), 0.5, 0)
	coluna.Position = posColuna
	painelMenu.Position = UDim2.new(1, -math.floor(96 * s), 0.5, 0)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(ajustarEscala)
ajustarEscala()

-- botao simples (usado na pausa)
local function botao(parent, texto, ordem, fn)
	local b = new("TextButton", { Size = UDim2.fromOffset(360, 44), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 24, TextColor3 = rgb(220, 215, 235), TextXAlignment = Enum.TextXAlignment.Left, Text = texto, LayoutOrder = ordem, ZIndex = 122 }, parent)
	local barra = new("Frame", { Position = UDim2.new(0, -18, 0.5, -10), Size = UDim2.fromOffset(4, 20), BackgroundColor3 = rgb(170, 110, 255), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 122 }, b)
	b.MouseEnter:Connect(function() tw(b, 0.12, { TextColor3 = rgb(255, 255, 255), Position = UDim2.fromOffset(10, 0) }) tw(barra, 0.12, { BackgroundTransparency = 0 }) end)
	b.MouseLeave:Connect(function() tw(b, 0.12, { TextColor3 = rgb(220, 215, 235), Position = UDim2.fromOffset(0, 0) }) tw(barra, 0.12, { BackgroundTransparency = 1 }) end)
	b.Activated:Connect(fn)
	return b
end

-- botao do menu inicial: numero + rotulo + nota, com barra no hover
local COR_ITEM, COR_ITEM_OFF = rgb(218, 212, 232), rgb(105, 100, 122)
local function botaoMenu(texto, ordem, fn)
	local b = new("TextButton", { Size = UDim2.fromOffset(500, 54), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = ordem, ZIndex = 122 }, opcoes)
	local barra = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 0), BackgroundColor3 = rgb(170, 110, 255), BorderSizePixel = 0, ZIndex = 122 }, b)
	local num = new("TextLabel", { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(0, 34, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 15, TextColor3 = rgb(150, 115, 220), TextXAlignment = Enum.TextXAlignment.Left, Text = ("%02d"):format(ordem), ZIndex = 122 }, b)
	local rot = new("TextLabel", { Position = UDim2.fromOffset(54, -4), Size = UDim2.new(1, -54, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = COR_ITEM, TextXAlignment = Enum.TextXAlignment.Left, Text = texto, ZIndex = 122 }, b)
	local nota = new("TextLabel", { Position = UDim2.new(0, 55, 1, -14), Size = UDim2.new(1, -55, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = rgb(120, 112, 140), TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 122 }, b)
	local item = { ativo = true, nota = nota }
	b.MouseEnter:Connect(function()
		if not item.ativo then return end
		tw(rot, 0.16, { Position = UDim2.fromOffset(64, -4), TextColor3 = rgb(255, 255, 255) }) tw(barra, 0.16, { Size = UDim2.fromOffset(3, 32) }) tw(num, 0.16, { TextColor3 = rgb(205, 165, 255) })
	end)
	b.MouseLeave:Connect(function()
		tw(rot, 0.16, { Position = UDim2.fromOffset(54, -4), TextColor3 = item.ativo and COR_ITEM or COR_ITEM_OFF }) tw(barra, 0.16, { Size = UDim2.fromOffset(3, 0) }) tw(num, 0.16, { TextColor3 = rgb(150, 115, 220) })
	end)
	b.Activated:Connect(function() if item.ativo then fn() end end)
	function item.setAtivo(sim)
		item.ativo = sim
		rot.TextColor3 = sim and COR_ITEM or COR_ITEM_OFF
		num.TextTransparency = sim and 0 or 0.55
	end
	return item
end

local camMenuCon
local function cameraMenu(on)
	if camMenuCon then camMenuCon:Disconnect() camMenuCon = nil end
	menuBlur.Enabled = on menuGrade.Enabled = on
	if on then
		camera.CameraType = Enum.CameraType.Scriptable
		local t0 = os.clock()
		menuBlur.Size = 18 tw(menuBlur, 2.5, { Size = 7 })
		camMenuCon = RunService.RenderStepped:Connect(function()
			local t = os.clock() - t0
			local deriva = Vector3.new(math.sin(t * 0.07) * 0.5, math.sin(t * 0.11) * 0.12, math.sin(t * 0.05) * 0.3)
			camera.CFrame = (MENU_CAM + deriva) * CFrame.Angles(math.sin(t * 0.09) * 0.006, math.sin(t * 0.06) * 0.018, math.sin(t * 0.13) * 0.004)
		end)
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end
task.spawn(function() while true do task.wait(0.8) if menu.Visible then ponto.BackgroundTransparency = ponto.BackgroundTransparency == 0 and 0.8 or 0 end end end)

local confirmando = false
local bNovo, bContinuar
local function fecharMenu()
	menu.Visible = false
	painelMenu.Visible = false
	cameraMenu(false)
end
local function mostrarPainel(titulo, t)
	painelMenu.Visible = true
	painelTit.Text = titulo
	painelTxt.Text = t painelTxt.Visible = true painelLinhas.Visible = false
end
painelX.Activated:Connect(function() painelMenu.Visible = false confirmando = false bNovo.nota.Text = "" end)

-- configuracoes (compartilhadas com a pausa)
local atualizarPausa = function() end
local function aplicarVolume()
	local sg = SoundService:FindFirstChild("Efeitos") if sg then sg.Volume = config.volume end
end
local OPCOES_CONFIG = {
	{ "LEGENDAS", function() return config.legendas and "LIGADAS" or "DESLIGADAS" end, function() config.legendas = not config.legendas end },
	{ "MOVIMENTO DA CÂMERA", function() return player:GetAttribute("MovCamera") == false and "DESLIGADO" or "LIGADO" end, function() player:SetAttribute("MovCamera", player:GetAttribute("MovCamera") == false) end },
	{ "VOLUME DOS EFEITOS", function() return ("%d%%"):format(config.volume * 100) end, function() config.volume = config.volume >= 1 and 0 or math.floor((config.volume + 0.2) * 10 + 0.5) / 10 aplicarVolume() end },
}
local function mostrarConfig()
	painelMenu.Visible = true
	painelTit.Text = "CONFIGURAÇÕES"
	painelTxt.Visible = false painelLinhas.Visible = true
	for _, c in ipairs(painelLinhas:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
	for i, op in ipairs(OPCOES_CONFIG) do
		local linha = new("TextButton", { Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = rgb(22, 19, 34), Text = "", AutoButtonColor = true, LayoutOrder = i, ZIndex = 123 }, painelLinhas)
		corner(linha, 4)
		new("TextLabel", { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = rgb(225, 218, 240), TextXAlignment = Enum.TextXAlignment.Left, Text = op[1], ZIndex = 124 }, linha)
		local valor = new("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 16, TextColor3 = rgb(190, 150, 255), TextXAlignment = Enum.TextXAlignment.Right, Text = op[2](), ZIndex = 124 }, linha)
		linha.Activated:Connect(function() op[3]() valor.Text = op[2]() atualizarPausa() end)
	end
	new("TextLabel", { Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = rgb(130, 122, 150), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "Clique numa linha pra alternar. Desligue o movimento da câmera se sentir enjoo.", LayoutOrder = 99, ZIndex = 123 }, painelLinhas)
end

bNovo = botaoMenu("NOVO JOGO", 1, function()
	if player:GetAttribute("TemSave") and not confirmando then
		confirmando = true
		bNovo.nota.Text = "clique de novo pra confirmar"
		mostrarPainel("COMEÇAR DO ZERO?", "O progresso da <b>campanha</b> será apagado.\n\nA Árvore da Mente e sua Essência continuam.\n\n<font color=\"#b48cff\">Clique em NOVO JOGO de novo pra confirmar.</font>")
		return
	end
	confirmando = false
	fade(true, 0.6)
	task.wait(0.7)
	fecharMenu()
	RMenu:FireServer("novo")
end)
bContinuar = botaoMenu("CONTINUAR", 2, function()
	if not player:GetAttribute("TemSave") then return end
	fade(true, 0.6)
	task.wait(0.7)
	fecharMenu()
	RMenu:FireServer("continuar")
end)
botaoMenu("ÁRVORE DA MENTE", 3, function()
	mostrarPainel("ÁRVORE DA MENTE", "Aperte <b>T</b> dentro do jogo pra abrir a Árvore da Mente.\n\nEssência é ganha derrotando inimigos e chefes, e fica salva mesmo quando você morre.\n\nEssência atual: <font color=\"#6ee6ff\"><b>" .. tostring(player:GetAttribute("Essencia") or 0) .. "</b></font>")
end)
botaoMenu("CONTROLES", 4, function()
	local function l(tecla, acao) return ("<font face=\"RobotoMono\" color=\"#b48cff\">%s</font>  %s"):format(tecla .. string.rep(" ", 10 - utf8.len(tecla)), acao) end
	mostrarPainel("CONTROLES", table.concat({
		l("W A S D", "andar"), l("ESPAÇO", "pular"), l("MOUSE", "olhar em volta"), l("E", "interagir / ler"),
		l("CLIQUE", "Pulso telecinético"), l("F", "Onda"), l("R", "Levitar"), l("G", "Eco"),
		l("Q", "Dash (Árvore)"), l("V", "Ultimate"), l("T", "Árvore da Mente"), l("P", "pausa / arquivos"), l("1 2 3", "escolher mutação"),
	}, "\n"))
end)
botaoMenu("CONFIGURAÇÕES", 5, mostrarConfig)
botaoMenu("CRÉDITOS", 6, function()
	local linhas = {}
	for i, l in ipairs(T.Creditos) do linhas[i] = i == 1 and ("<b>" .. l .. "</b>") or l end
	mostrarPainel("CRÉDITOS", table.concat(linhas, "\n"))
end)

local function abrirMenu()
	fecharDoc()
	cred.Visible = false
	painelMenu.Visible = false
	confirmando = false bNovo.nota.Text = ""
	menu.Visible = true
	local temSave = player:GetAttribute("TemSave") == true
	bContinuar.setAtivo(temSave)
	bContinuar.nota.Text = temSave and "" or "nenhum progresso salvo"
	rodape.Text = T.Disciplina .. "   ·   ESSÊNCIA " .. tostring(player:GetAttribute("Essencia") or 0)
	cameraMenu(true)
	coluna.Position = posColuna - UDim2.fromOffset(30, 0)
	tw(coluna, 1.4, { Position = posColuna }, Enum.EasingStyle.Quart)
	fade(false, 1.4)
end
player:GetAttributeChangedSignal("TemSave"):Connect(function()
	if menu.Visible then
		local temSave = player:GetAttribute("TemSave") == true
		bContinuar.setAtivo(temSave) bContinuar.nota.Text = temSave and "" or "nenhum progresso salvo"
	end
end)

-- ================= pausa =================
local pausa = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = rgb(4, 3, 8), BackgroundTransparency = 0.25, Visible = false, ZIndex = 95, Active = true }, gui)
new("TextLabel", { Position = UDim2.new(0, 90, 0.18, 0), Size = UDim2.fromOffset(600, 60), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 52, TextColor3 = rgb(240, 235, 255), TextXAlignment = Enum.TextXAlignment.Left, Text = "PAUSA", ZIndex = 96 }, pausa)
local pObj = new("TextLabel", { Position = UDim2.new(0, 94, 0.18, 62), Size = UDim2.fromOffset(700, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 17, TextColor3 = rgb(190, 170, 230), TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 96 }, pausa)
local pOp = new("Frame", { Position = UDim2.new(0, 90, 0.36, 0), Size = UDim2.fromOffset(400, 300), BackgroundTransparency = 1, ZIndex = 96 }, pausa)
new("UIListLayout", { Padding = UDim.new(0, 6) }, pOp)
local pLista = new("ScrollingFrame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -90, 0.2, 0), Size = UDim2.fromOffset(480, 460), BackgroundColor3 = rgb(12, 10, 20), BackgroundTransparency = 0.15, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, Visible = false, ZIndex = 96 }, pausa)
corner(pLista, 8)
new("UIListLayout", { Padding = UDim.new(0, 6) }, pLista)
new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, pLista)
local function fecharPausa() pausa.Visible = false pLista.Visible = false end
local function botaoP(t, o, fn)
	local b = botao(pOp, t, o, fn) b.ZIndex = 97 b.TextSize = 22 return b
end
botaoP("CONTINUAR", 1, fecharPausa)
botaoP("ARQUIVOS", 2, function()
	pLista.Visible = not pLista.Visible
	for _, c in ipairs(pLista:GetChildren()) do if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end end
	local ok, lidos = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("Docs") or "[]")
	lidos = ok and lidos or {}
	if #lidos == 0 then new("TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 16, TextColor3 = rgb(180, 170, 200), Text = "Nenhum documento encontrado ainda.", ZIndex = 97 }, pLista) end
	for i, id in ipairs(lidos) do
		local d = T.Docs[id]
		if d then
			local b = new("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = rgb(28, 24, 40), Font = Enum.Font.GothamMedium, TextSize = 16, TextColor3 = rgb(230, 225, 240), TextXAlignment = Enum.TextXAlignment.Left, Text = "   " .. d.titulo, LayoutOrder = i, ZIndex = 97 }, pLista)
			corner(b, 6)
			b.Activated:Connect(function() abrirDoc(id) end)
		end
	end
end)
local bVol, bLeg, bCam
function atualizarPausa()
	bVol.Text = ("VOLUME: %d%%"):format(config.volume * 100)
	bLeg.Text = "LEGENDAS: " .. (config.legendas and "LIGADAS" or "DESLIGADAS")
	bCam.Text = "CÂMERA: " .. (player:GetAttribute("MovCamera") == false and "PARADA" or "COM MOVIMENTO")
end
bVol = botaoP("VOLUME: 80%", 3, function() OPCOES_CONFIG[3][3]() atualizarPausa() end)
bLeg = botaoP("LEGENDAS: LIGADAS", 4, function() OPCOES_CONFIG[1][3]() atualizarPausa() end)
bCam = botaoP("CÂMERA: COM MOVIMENTO", 5, function() OPCOES_CONFIG[2][3]() atualizarPausa() end)
atualizarPausa()
botaoP("SAIR PRO MENU", 6, function()
	fecharPausa()
	fade(true, 0.6)
	task.wait(0.7)
	RMenu:FireServer("sair")
	abrirMenu()
end)

UIS.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.E and docAberto then fecharDoc() return end
	if gp then return end
	if input.KeyCode == Enum.KeyCode.P and not menu.Visible and not emCutscene then
		pausa.Visible = not pausa.Visible
		pObj.Text = "Objetivo: " .. tostring(player:GetAttribute("Objetivo") or "—")
		if not pausa.Visible then pLista.Visible = false end
	end
end)

-- ================= eventos do servidor =================
RH.OnClientEvent:Connect(function(tipo, a, b, c, d)
	if tipo == "legendas" then legendas(a)
	elseif tipo == "documento" then
		-- pos-creditos: o documento fica atras da tela dos creditos se ela continuar aberta
		if cred.Visible then tw(cred, 1, { BackgroundTransparency = 1 }) credLista.Position = UDim2.new(0.5, 0, 0, -900) task.delay(1, function() cred.Visible = false end) end
		abrirDoc(a)
	elseif tipo == "fade" then fade(a, b, c, d)
	elseif tipo == "capitulo" then mostrarCartao(a, b, rgb(190, 150, 255), 2.2)
	elseif tipo == "cutscene" then task.spawn(cutscene, a, b)
	elseif tipo == "pedra" then
		flash.BackgroundTransparency = 0.2 tw(flash, 1.2, { BackgroundTransparency = 1 })
		VFX.Tremer(3) VFX.SocoFOV(-12)
		mostrarCartao(("PEDRA %d / 7 REMOVIDA"):format(a), b or "", rgb(200, 150, 255), 3)
	elseif tipo == "creditos" then creditos(a)
	elseif tipo == "flash" then flash.BackgroundColor3 = b or rgb(255, 255, 255) flash.BackgroundTransparency = 0 tw(flash, a or 1, { BackgroundTransparency = 1 })
	elseif tipo == "menu" then abrirMenu()
	end
end)

-- som dos efeitos passa pelo grupo de volume
local sg = SoundService:FindFirstChild("Efeitos")
workspace.DescendantAdded:Connect(function(x) if x:IsA("Sound") and sg and not x.SoundGroup then x.SoundGroup = sg end end)

-- entrada: menu
preto.BackgroundTransparency = 0
task.wait(0.5)
if player:GetAttribute("NoMenu") ~= false then abrirMenu() else fade(false, 1) end
