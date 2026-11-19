-- Objetivo SEMPRE visivel no canto superior esquerdo. Pisca quando muda. Avisos curtos embaixo.
local TweenService = game:GetService("TweenService")
local player = game:GetService("Players").LocalPlayer
local gui = script.Parent
local obj, aviso = gui:WaitForChild("Objetivo"), gui:WaitForChild("Aviso")

-- caixa do objetivo
obj.Size = UDim2.new(0, 460, 0, 0)
obj.AutomaticSize = Enum.AutomaticSize.Y
obj.Position = UDim2.new(0, 24, 0, 70)
obj.TextWrapped = true
obj.TextSize = 18
obj.RichText = true
obj.BackgroundColor3 = Color3.fromRGB(10, 8, 18)
obj.BackgroundTransparency = 0.45
obj.TextTransparency = 0
obj.TextStrokeTransparency = 0.6
local pad = obj:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12) pad.PaddingRight = UDim.new(0, 12) pad.PaddingTop = UDim.new(0, 8) pad.PaddingBottom = UDim.new(0, 8) pad.Parent = obj
local canto = obj:FindFirstChildOfClass("UICorner") or Instance.new("UICorner") canto.CornerRadius = UDim.new(0, 6) canto.Parent = obj
local barra = obj:FindFirstChild("Barra") or Instance.new("Frame")
barra.Name = "Barra" barra.Size = UDim2.new(0, 3, 1, 0) barra.BackgroundColor3 = Color3.fromRGB(170, 110, 255) barra.BorderSizePixel = 0 barra.Parent = obj
local escala = obj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale") escala.Parent = obj

local function mostrarObjetivo(novo)
	local t = player:GetAttribute("Objetivo")
	if not t or t == "" or player:GetAttribute("NoMenu") then obj.Visible = false return end
	obj.Visible = true
	obj.Text = "<font color=\"#B78CFF\"><b>OBJETIVO</b></font>\n" .. t
	if novo then
		obj.BackgroundColor3 = Color3.fromRGB(90, 50, 150)
		TweenService:Create(obj, TweenInfo.new(1.2), { BackgroundColor3 = Color3.fromRGB(10, 8, 18) }):Play()
		escala.Scale = 1.12
		TweenService:Create(escala, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end
player:GetAttributeChangedSignal("Objetivo"):Connect(function() mostrarObjetivo(true) end)
player:GetAttributeChangedSignal("NoMenu"):Connect(function() mostrarObjetivo(false) end)

local function mostrarAviso(texto)
	aviso.Text = texto
	TweenService:Create(aviso, TweenInfo.new(0.4), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
	local token = {} aviso:SetAttribute("tok", tostring(token))
	task.delay(4, function()
		if aviso:GetAttribute("tok") == tostring(token) then
			TweenService:Create(aviso, TweenInfo.new(1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
game:GetService("ReplicatedStorage"):WaitForChild("AvisoJogador").OnClientEvent:Connect(mostrarAviso)
task.wait(1)
mostrarObjetivo(false)

-- ===== marcador do objetivo (losango + distancia) =====
local RunService = game:GetService("RunService")
local ancora = Instance.new("Part")
ancora.Name = "MarcadorObjetivo" ancora.Anchored = true ancora.CanCollide = false ancora.CanQuery = false ancora.CanTouch = false
ancora.Transparency = 1 ancora.Size = Vector3.new(0.2, 0.2, 0.2) ancora.Parent = workspace.CurrentCamera
local bb = Instance.new("BillboardGui")
bb.Size = UDim2.fromOffset(60, 60) bb.AlwaysOnTop = true bb.LightInfluence = 0 bb.Adornee = ancora bb.Enabled = false bb.Parent = gui
local los = Instance.new("Frame") los.AnchorPoint = Vector2.new(0.5, 0.5) los.Position = UDim2.fromScale(0.5, 0.35) los.Size = UDim2.fromOffset(18, 18)
los.Rotation = 45 los.BackgroundColor3 = Color3.fromRGB(190, 140, 255) los.BorderSizePixel = 0 los.Parent = bb
local st = Instance.new("UIStroke") st.Color = Color3.new(1, 1, 1) st.Thickness = 2 st.Parent = los
local dist = Instance.new("TextLabel") dist.AnchorPoint = Vector2.new(0.5, 0) dist.Position = UDim2.fromScale(0.5, 0.62) dist.Size = UDim2.fromOffset(60, 18)
dist.BackgroundTransparency = 1 dist.Font = Enum.Font.GothamBold dist.TextSize = 13 dist.TextColor3 = Color3.new(1, 1, 1) dist.TextStrokeTransparency = 0.3 dist.Parent = bb

RunService.RenderStepped:Connect(function()
	local alvo = player:GetAttribute("ObjetivoAlvo")
	local ch = player.Character
	local r = ch and ch:FindFirstChild("HumanoidRootPart")
	local escondido = player:GetAttribute("NoMenu") or player:GetAttribute("Congelado") or player:GetAttribute("EmUlt")
	if typeof(alvo) ~= "Vector3" or not r or escondido then bb.Enabled = false return end
	local d = (alvo - r.Position).Magnitude
	if d < 7 then bb.Enabled = false return end
	bb.Enabled = true
	local guia = player:GetAttribute("ObjetivoGuia")
	local naRota = typeof(guia) == "Vector3" and (guia - alvo).Magnitude > 3
	local destino = naRota and guia or alvo + Vector3.new(0, 2.5, 0)
	ancora.Position = ancora.Position:Lerp(destino, (ancora.Position - destino).Magnitude > 40 and 1 or 0.15)
	local total = player:GetAttribute("ObjetivoDist")
	if typeof(total) ~= "number" or not naRota then total = d end
	dist.Text = string.format("%dm", math.floor(total / 3.5 + 0.5))
	los.BackgroundColor3 = naRota and Color3.fromRGB(150, 110, 220) or Color3.fromRGB(190, 140, 255)
	local s = 1 + math.sin(os.clock() * 4) * 0.12
	los.Size = UDim2.fromOffset(18 * s, 18 * s)
end)
