-- Portas das fases (SERVIDOR): decide abrir/fechar e cuida da colisao.
-- A animacao roda no cliente (PortasClient) pra ficar lisa. Atributo "Aberta" sincroniza.
-- Pra destrancar por puzzle: porta:SetAttribute("Trancada", false)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local TAG = "PortaFase"
local COR_TRANCADA = Color3.fromRGB(255, 60, 60)
local COR_LIVRE = Color3.fromRGB(70, 230, 130)
local FECHAR_APOS = 1.4
local portas = {}

local function registrar(m)
	if portas[m] then return end
	local r = { model = m, folhas = {}, luzes = {}, aberta = false, ultimoPerto = 0, token = 0 }
	for _, c in ipairs(m:GetChildren()) do
		if c:IsA("BasePart") and c:GetAttribute("Folha") then
			table.insert(r.folhas, { part = c, fechado = c.CFrame })
		elseif c:IsA("BasePart") and c:GetAttribute("StatusLuz") then
			table.insert(r.luzes, c)
		end
	end
	local soma = Vector3.zero
	for _, f in ipairs(r.folhas) do soma += f.fechado.Position end
	r.centro = #r.folhas > 0 and soma / #r.folhas or m:GetPivot().Position
	m:SetAttribute("Aberta", false)
	portas[m] = r
end

local function mover(r, abrir)
	r.aberta = abrir
	r.token += 1
	local meu = r.token
	r.model:SetAttribute("Aberta", abrir)
	if abrir then
		task.delay(0.18, function() if r.token == meu then for _, f in ipairs(r.folhas) do f.part.CanCollide = false end end end)
	else
		task.delay(0.55, function() if r.token == meu then for _, f in ipairs(r.folhas) do f.part.CanCollide = true end end end)
	end
end

local function jogadorPerto(r)
	local dist = r.model:GetAttribute("Distancia") or 9
	for _, p in ipairs(Players:GetPlayers()) do
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = hrp.Position - r.centro
			if Vector3.new(d.X, 0, d.Z).Magnitude < dist and math.abs(d.Y) < 10 then return true end
		end
	end
	return false
end

for _, m in ipairs(CollectionService:GetTagged(TAG)) do registrar(m) end
CollectionService:GetInstanceAddedSignal(TAG):Connect(registrar)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(m) portas[m] = nil end)

while task.wait(0.1) do
	local dev = workspace:GetAttribute("DEV_DestravarPortas") == true
	local agora = os.clock()
	for m, r in pairs(portas) do
		if not m.Parent then portas[m] = nil continue end
		local livre = dev or not m:GetAttribute("Trancada")
		for _, l in ipairs(r.luzes) do
			local cor = livre and COR_LIVRE or COR_TRANCADA
			if l.Color ~= cor then l.Color = cor end
		end
		local perto = livre and jogadorPerto(r)
		if perto then
			r.ultimoPerto = agora
			if not r.aberta then mover(r, true) end
		elseif r.aberta and agora - r.ultimoPerto > FECHAR_APOS then
			mover(r, false)
		end
	end
end
