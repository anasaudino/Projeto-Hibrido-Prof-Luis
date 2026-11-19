-- Kit de construcao das fases (usado so no Studio, pra montar os mapas por script).
-- Convencao: sala de x0..x1 / z0..z1 = area INTERNA; paredes (1 stud) ficam do lado de FORA.
-- Duas salas vizinhas ficam separadas por 2 studs (parede de cada uma). A porta fica no meio.
local K = {}
local rgb = Color3.fromRGB
local SP = Enum.Material.SmoothPlastic
K.rgb = rgb

K.COR = {
	parede = rgb(182, 192, 189), piso = rgb(184, 190, 185), teto = rgb(170, 178, 176),
	paredeLab = rgb(200, 208, 206), pisoLab = rgb(170, 178, 176),
	metal = rgb(120, 126, 130), concreto = rgb(110, 114, 112), pisoConcreto = rgb(88, 92, 90),
	escuro = rgb(40, 42, 46), madeira = rgb(120, 90, 60),
}

function K.P(par, name, cf, sz, col, mat, ex)
	local p = Instance.new("Part")
	p.Anchored = true p.Name = name p.Size = sz p.CFrame = cf p.Color = col or K.COR.parede p.Material = mat or SP
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	if ex then for k, v in pairs(ex) do p[k] = v end end
	p.Parent = par
	return p
end
local P = K.P

function K.B(par, name, x0, y0, z0, x1, y1, z1, col, mat, ex)
	return P(par, name, CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), Vector3.new(math.abs(x1 - x0), math.abs(y1 - y0), math.abs(z1 - z0)), col, mat, ex)
end
local B = K.B

function K.M(par, name) local m = Instance.new("Model") m.Name = name m.Parent = par return m end
function K.F(par, name) local f = par:FindFirstChild(name) or Instance.new("Folder") f.Name = name f.Parent = par return f end

function K.cyl(par, name, a, b, d, col, mat)
	local mid = (a + b) / 2 local len = (b - a).Magnitude
	return P(par, name, CFrame.lookAt(mid, b) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(len, d, d), col, mat, { Shape = Enum.PartType.Cylinder })
end

-- parede ao longo de X (plano z fixo), com buracos {a, b, y0, y1}
function K.wallX(par, name, z, x0, x1, y0, y1, holes, col, mat, esp)
	esp = esp or 1
	holes = holes or {} table.sort(holes, function(a, b) return a[1] < b[1] end)
	local cur = x0
	for _, h in ipairs(holes) do
		if h[1] > cur then B(par, name, cur, y0, z - esp / 2, h[1], y1, z + esp / 2, col, mat) end
		if h[3] > y0 then B(par, name, h[1], y0, z - esp / 2, h[2], h[3], z + esp / 2, col, mat) end
		if h[4] < y1 then B(par, name, h[1], h[4], z - esp / 2, h[2], y1, z + esp / 2, col, mat) end
		cur = h[2]
	end
	if cur < x1 then B(par, name, cur, y0, z - esp / 2, x1, y1, z + esp / 2, col, mat) end
end
function K.wallZ(par, name, x, z0, z1, y0, y1, holes, col, mat, esp)
	esp = esp or 1
	holes = holes or {} table.sort(holes, function(a, b) return a[1] < b[1] end)
	local cur = z0
	for _, h in ipairs(holes) do
		if h[1] > cur then B(par, name, x - esp / 2, y0, cur, x + esp / 2, y1, h[1], col, mat) end
		if h[3] > y0 then B(par, name, x - esp / 2, y0, h[1], x + esp / 2, h[3], h[2], col, mat) end
		if h[4] < y1 then B(par, name, x - esp / 2, h[4], h[1], x + esp / 2, y1, h[2], col, mat) end
		cur = h[2]
	end
	if cur < z1 then B(par, name, x - esp / 2, y0, cur, x + esp / 2, y1, z1, col, mat) end
end

-- sala: x0,z0,x1,z1 internos; y = piso; h = pe-direito
-- o.furos = { N = {{centro, largura, altura}}, S = ..., L = ..., O = ... }  (N = z0, S = z1, O = x0, L = x1)
-- o.parede/piso/teto = cor; o.matParede/matPiso/matTeto; o.semTeto; o.semPiso
function K.sala(par, nome, x0, z0, x1, z1, y, h, o)
	o = o or {}
	local f = K.F(par, nome)
	local cp, cpi, ct = o.parede or K.COR.parede, o.piso or K.COR.piso, o.teto or K.COR.teto
	if not o.semPiso then B(f, "Piso", x0 - 1, y - 1, z0 - 1, x1 + 1, y, z1 + 1, cpi, o.matPiso or SP, { Reflectance = o.refl or 0.05 }) end
	if not o.semTeto then B(f, "Teto", x0 - 1, y + h, z0 - 1, x1 + 1, y + h + 1, z1 + 1, ct, o.matTeto or SP) end
	local fu = o.furos or {}
	local function conv(lista, base)
		local t = {}
		for _, fu in ipairs(lista or {}) do table.insert(t, { fu[1] - fu[2] / 2, fu[1] + fu[2] / 2, y + (fu[4] or 0), y + (fu[3] or 9) }) end
		return t
	end
	K.wallX(f, "Parede", z0 - 0.5, x0 - 1, x1 + 1, y, y + h, conv(fu.N), cp, o.matParede)
	K.wallX(f, "Parede", z1 + 0.5, x0 - 1, x1 + 1, y, y + h, conv(fu.S), cp, o.matParede)
	K.wallZ(f, "Parede", x0 - 0.5, z0, z1, y, y + h, conv(fu.O), cp, o.matParede)
	K.wallZ(f, "Parede", x1 + 0.5, z0, z1, y, y + h, conv(fu.L), cp, o.matParede)
	if o.rodape ~= false then
		local rc = o.corRodape or rgb(140, 146, 146)
		B(f, "Rodape", x0, y, z0, x1, y + 0.45, z0 + 0.08, rc) B(f, "Rodape", x0, y, z1 - 0.08, x1, y + 0.45, z1, rc)
		B(f, "Rodape", x0, y, z0, x0 + 0.08, y + 0.45, z1, rc) B(f, "Rodape", x1 - 0.08, y, z0, x1, y + 0.45, z1, rc)
	end
	return f
end

-- luminarias no teto (grade). o.off = {[i]=true} por indice sequencial; o.pisca = {[i]=true}; o.cor; o.brilho; o.cada (luz real a cada N)
function K.luzes(par, x0, z0, x1, z1, yTeto, passo, o)
	o = o or {}
	local f = K.F(par, "Luzes")
	local i = 0
	local nx = math.max(1, math.floor((x1 - x0) / passo + 0.5))
	local nz = math.max(1, math.floor((z1 - z0) / passo + 0.5))
	for a = 1, nx do for b = 1, nz do
		i += 1
		local cx = x0 + (a - 0.5) * (x1 - x0) / nx
		local cz = z0 + (b - 0.5) * (z1 - z0) / nz
		local off = o.off and o.off[i]
		local cor = o.cor or rgb(214, 232, 234)
		local p = P(f, off and "LuminariaApagada" or "Luminaria", CFrame.new(cx, yTeto - 0.15, cz), Vector3.new(o.w or 5, 0.2, o.d or 2.4), off and rgb(105, 110, 112) or cor, off and SP or Enum.Material.Neon)
		P(f, "Moldura", CFrame.new(cx, yTeto - 0.1, cz), Vector3.new((o.w or 5) + 0.6, 0.16, (o.d or 2.4) + 0.6), rgb(150, 158, 158))
		if not off and (i % (o.cada or 1) == 0) then
			local l = Instance.new("SurfaceLight") l.Face = Enum.NormalId.Bottom l.Range = o.alcance or 18 l.Brightness = o.brilho or 0.8
			l.Angle = 120 l.Color = o.corLuz or cor l.Shadows = true l.Parent = p
		end
		if o.pisca and o.pisca[i] then p:AddTag("LuzPiscando") end
	end end
	return f
end

function K.luzPonto(par, nome, pos, cor, alcance, brilho, visivel)
	local p = P(par, nome, CFrame.new(pos), Vector3.new(0.6, 0.3, 0.6), cor, Enum.Material.Neon, { CanCollide = false, Transparency = visivel == false and 1 or 0 })
	local l = Instance.new("PointLight") l.Color = cor l.Range = alcance or 14 l.Brightness = brilho or 0.8 l.Shadows = true l.Parent = p
	return p
end

function K.placa(par, cf, w, h, texto, corTexto, corFundo, face)
	local p = P(par, "Placa", cf, Vector3.new(w, h, 0.1), corFundo or rgb(40, 60, 110))
	local g = Instance.new("SurfaceGui") g.Face = face or Enum.NormalId.Front g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud g.PixelsPerStud = 40 g.LightInfluence = 1 g.Parent = p
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1, 1) t.BackgroundTransparency = 1
	t.TextColor3 = corTexto or rgb(240, 240, 236) t.Font = Enum.Font.Arimo t.Text = texto t.TextWrapped = true t.TextScaled = true t.Parent = g
	local pad = Instance.new("UIPadding") pad.PaddingLeft = UDim.new(0.05, 0) pad.PaddingRight = UDim.new(0.05, 0) pad.PaddingTop = UDim.new(0.12, 0) pad.PaddingBottom = UDim.new(0.12, 0) pad.Parent = t
	return p
end

-- ===== portas (mesmo formato do sistema PortasFase) =====
local function weldTo(leaf, p) p.Anchored = false p.CanCollide = false p.Massless = true local w = Instance.new("WeldConstraint") w.Part0 = leaf w.Part1 = p w.Parent = p end
-- base = centro do vao no chao; eixo "X" = parede corre ao longo de X; "Z" idem
function K.porta(par, name, base, eixo, largura, altura, o)
	o = o or {}
	local m = Instance.new("Model") m.Name = name m.Parent = par
	local rot = eixo == "Z" and CFrame.Angles(0, math.pi / 2, 0) or CFrame.new()
	local center = CFrame.new(base + Vector3.new(0, altura / 2, 0)) * rot
	local col = o.cor or rgb(196, 200, 198)
	local folhas = o.dupla and 2 or 1
	local lw = largura / folhas
	for i = 1, folhas do
		local sinal = folhas == 1 and 1 or (i == 1 and -1 or 1)
		local off = folhas == 1 and 0 or sinal * lw / 2
		local leaf = P(m, "Folha", center * CFrame.new(off, 0, 0), Vector3.new(lw - 0.05, altura - 0.05, 0.5), col, o.mat or SP)
		leaf:SetAttribute("Folha", true)
		local dir = (center * CFrame.new(off, 0, 0)).Position - center.Position
		local along = (center.RightVector)
		local slide
		if o.sobe then slide = Vector3.new(0, altura - 0.4, 0)
		elseif folhas == 2 then slide = Vector3.new(dir.X, 0, dir.Z).Unit * (lw - 0.3)
		else slide = along * (lw - 0.3) end
		leaf:SetAttribute("Abrir", slide)
		if o.janela ~= false then
			local g = P(m, "Visor", center * CFrame.new(off, altura * 0.22, 0), Vector3.new(math.min(lw * 0.35, 2.2), altura * 0.22, 0.56), rgb(30, 38, 42), Enum.Material.Glass, { Transparency = 0.2, Reflectance = 0.2 })
			weldTo(leaf, g)
		end
		if o.faixa then
			local fx = P(m, "Faixa", center * CFrame.new(off, -altura * 0.1, 0), Vector3.new(lw - 0.2, 0.5, 0.56), o.faixa, SP)
			weldTo(leaf, fx)
		end
	end
	local FC = o.batente or rgb(132, 138, 140)
	for _, s in ipairs({ -1, 1 }) do P(m, "Batente", center * CFrame.new(s * (largura / 2 + 0.3), 0, 0), Vector3.new(0.68, altura + 0.68, (o.prof or 2.2) + 0.04), FC, Enum.Material.Metal) end
	P(m, "Batente", center * CFrame.new(0, altura / 2 + 0.3, 0), Vector3.new(largura + 1.28, 0.68, (o.prof or 2.2) + 0.04), FC, Enum.Material.Metal)
	for _, s in ipairs({ -1, 1 }) do
		local st = P(m, "Status", center * CFrame.new(largura / 2 + 0.3, altura / 2 + 1, s * 1.15), Vector3.new(0.4, 0.4, 0.1), rgb(255, 60, 60), Enum.Material.Neon)
		st:SetAttribute("StatusLuz", true)
	end
	m:AddTag("PortaFase")
	m:SetAttribute("Trancada", o.trancada or false)
	m:SetAttribute("Motivo", o.motivo or "")
	m:SetAttribute("Distancia", o.dist or 9)
	m:SetAttribute("Tempo", o.tempo or 0.6)
	m.PrimaryPart = m:FindFirstChild("Folha")
	return m
end

-- ===== props =====
function K.mesa(par, cf, w, d, h, col)
	local m = K.M(par, "Mesa")
	h = h or 3.2
	P(m, "Tampo", cf * CFrame.new(0, h, 0), Vector3.new(w, 0.3, d), col or rgb(170, 174, 172))
	for _, o in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do P(m, "Pe", cf * CFrame.new(o[1] * (w / 2 - 0.3), h / 2, o[2] * (d / 2 - 0.3)), Vector3.new(0.3, h, 0.3), rgb(120, 124, 128), Enum.Material.Metal) end
	return m
end
function K.cadeira(par, cf)
	local m = K.M(par, "Cadeira")
	P(m, "Assento", cf * CFrame.new(0, 1.9, 0), Vector3.new(2.2, 0.3, 2.2), rgb(60, 64, 70), Enum.Material.Fabric)
	P(m, "Encosto", cf * CFrame.new(0, 3.2, 1), Vector3.new(2.2, 2.4, 0.3), rgb(60, 64, 70), Enum.Material.Fabric)
	P(m, "Coluna", cf * CFrame.new(0, 0.95, 0), Vector3.new(0.3, 1.9, 0.3), rgb(120, 124, 128), Enum.Material.Metal)
	return m
end
function K.monitor(par, cf, ligado, corTela)
	local m = K.M(par, "Monitor")
	P(m, "Carcaca", cf, Vector3.new(3, 2.6, 2.6), rgb(190, 186, 172))
	local t = P(m, "Tela", cf * CFrame.new(0, 0.05, -1.32), Vector3.new(2.4, 1.9, 0.05), ligado and (corTela or rgb(40, 120, 110)) or rgb(10, 12, 14), ligado and Enum.Material.Neon or SP)
	return m, t
end
function K.console(par, cf, w, n, corTela)
	local m = K.M(par, "Console")
	P(m, "Base", cf * CFrame.new(0, 1.6, 0), Vector3.new(w, 3.2, 2.6), rgb(150, 154, 152))
	P(m, "Painel", cf * CFrame.new(0, 3.35, -0.2) * CFrame.Angles(math.rad(-20), 0, 0), Vector3.new(w, 0.3, 2.4), rgb(90, 94, 98), Enum.Material.Metal)
	for i = 1, n or 3 do
		local x = -w / 2 + (i - 0.5) * w / (n or 3)
		K.monitor(m, cf * CFrame.new(x, 4.9, 0.4), math.random() < 0.8, corTela)
	end
	for i = 1, math.floor(w * 1.5) do
		P(m, "Botao", cf * CFrame.new(-w / 2 + 0.4 + (i - 1) * 0.66, 3.55, -0.5) * CFrame.Angles(math.rad(-20), 0, 0), Vector3.new(0.3, 0.1, 0.3), ({ rgb(255, 60, 60), rgb(60, 220, 120), rgb(255, 200, 60) })[math.random(1, 3)], Enum.Material.Neon)
	end
	return m
end
function K.estante(par, cf, w, h, d, cheio)
	local m = K.M(par, "Estante")
	local col = rgb(120, 126, 130)
	P(m, "Lateral", cf * CFrame.new(-w / 2, h / 2, 0), Vector3.new(0.2, h, d), col, Enum.Material.Metal)
	P(m, "Lateral", cf * CFrame.new(w / 2, h / 2, 0), Vector3.new(0.2, h, d), col, Enum.Material.Metal)
	for i = 0, 3 do
		local y = 0.3 + i * (h - 0.4) / 3
		P(m, "Prateleira", cf * CFrame.new(0, y, 0), Vector3.new(w, 0.15, d), col, Enum.Material.Metal)
		if cheio ~= false and i < 3 then
			local x = -w / 2 + 0.6
			while x < w / 2 - 0.8 do
				local bw = 0.8 + math.random() * 1.2
				if math.random() < 0.8 then
					P(m, "Caixa", cf * CFrame.new(x + bw / 2, y + 0.6, 0), Vector3.new(bw, 1.0 + math.random() * 0.3, d - 0.4), ({ rgb(178, 146, 104), rgb(200, 196, 180), rgb(90, 110, 140) })[math.random(1, 3)], Enum.Material.Cardboard)
				end
				x += bw + 0.15
			end
		end
	end
	return m
end
function K.caixa(par, cf, s, col)
	return P(par, "Caixote", cf * CFrame.new(0, s.Y / 2, 0), s, col or rgb(120, 100, 70), Enum.Material.WoodPlanks)
end
function K.arquivo(par, cf)
	local m = K.M(par, "Arquivo")
	P(m, "Corpo", cf * CFrame.new(0, 2.6, 0), Vector3.new(2, 5.2, 2.4), rgb(120, 128, 120), Enum.Material.Metal)
	for i = 0, 3 do P(m, "Gaveta", cf * CFrame.new(0, 0.7 + i * 1.25, -1.22), Vector3.new(1.7, 1, 0.05), rgb(140, 148, 140), Enum.Material.Metal) end
	return m
end
function K.tanque(par, cf, h, corLiq)
	local m = K.M(par, "Tanque")
	P(m, "Base", cf * CFrame.new(0, 0.6, 0), Vector3.new(1.2, 4.4, 4.4), rgb(80, 86, 90), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder, CFrame = cf * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2) })
	P(m, "Vidro", cf * CFrame.new(0, 1.2 + h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(h, 3.8, 3.8), rgb(180, 220, 230), Enum.Material.Glass, { Shape = Enum.PartType.Cylinder, Transparency = 0.6 })
	local liq = P(m, "Liquido", cf * CFrame.new(0, 1.2 + h * 0.4, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(h * 0.8, 3.5, 3.5), corLiq or rgb(80, 200, 170), Enum.Material.Neon, { Shape = Enum.PartType.Cylinder, Transparency = 0.55 })
	P(m, "Topo", cf * CFrame.new(0, 1.2 + h + 0.4, 0) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.8, 4.4, 4.4), rgb(80, 86, 90), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	local l = Instance.new("PointLight") l.Color = corLiq or rgb(80, 200, 170) l.Range = 10 l.Brightness = 0.6 l.Parent = liq
	return m
end
function K.gerador(par, cf, ligado)
	local m = K.M(par, "Gerador")
	P(m, "Corpo", cf * CFrame.new(0, 2.5, 0), Vector3.new(6, 5, 4), rgb(90, 100, 96), Enum.Material.Metal)
	P(m, "Tampa", cf * CFrame.new(0, 5.2, 0), Vector3.new(6.4, 0.4, 4.4), rgb(70, 76, 74), Enum.Material.Metal)
	for i = -1, 1 do P(m, "Aleta", cf * CFrame.new(i * 1.6, 2.5, -2.05), Vector3.new(0.4, 3.6, 0.2), rgb(60, 66, 64), Enum.Material.Metal) end
	local led = P(m, "Led", cf * CFrame.new(2.4, 4.2, -2.05), Vector3.new(0.4, 0.4, 0.1), ligado and rgb(60, 230, 120) or rgb(255, 50, 50), Enum.Material.Neon)
	return m, led
end
function K.canos(par, a, b, n, d, col)
	for i = 0, (n or 2) - 1 do
		local off = Vector3.new(0, -i * (d + 0.3), 0)
		K.cyl(par, "Cano", a + off, b + off, d or 0.6, col or rgb(96, 104, 108), Enum.Material.Metal)
	end
end
function K.entulho(par, centro, raio, n, col)
	local r = Random.new(math.floor(centro.X + centro.Z))
	for i = 1, n do
		local s = r:NextNumber(0.5, 1.8)
		P(par, "Entulho", CFrame.new(centro + Vector3.new(r:NextNumber(-raio, raio), s * 0.35, r:NextNumber(-raio, raio))) * CFrame.Angles(r:NextNumber(0, 3), r:NextNumber(0, 3), r:NextNumber(0, 3)), Vector3.new(s, s * 0.7, s * 0.9), col or rgb(150, 156, 154), Enum.Material.Concrete)
	end
end
function K.papeis(par, x0, z0, x1, z1, y, n)
	local r = Random.new(math.floor(x0 * 3 + z1))
	for i = 1, n do
		P(par, "Papel", CFrame.new(r:NextNumber(x0, x1), y + 0.03, r:NextNumber(z0, z1)) * CFrame.Angles(0, r:NextNumber(0, 6), 0), Vector3.new(1.1, 0.02, 1.5), rgb(232, 230, 220), SP, { CanCollide = false })
	end
end

-- ponto de interacao com ProximityPrompt (Acao = id tratado pelo modulo da fase)
function K.prompt(part, acao, texto, objeto, hold, dist)
	for _, c in ipairs(part:GetChildren()) do if c:IsA("ProximityPrompt") then c:Destroy() end end
	local p = Instance.new("ProximityPrompt") p.Name = "Prompt" p.ActionText = texto p.ObjectText = objeto or "" p.HoldDuration = hold or 0
	p.MaxActivationDistance = dist or 7 p.RequiresLineOfSight = false p:SetAttribute("Acao", acao) p.Parent = part
	return p
end

function K.contar(inst) local n = 0 for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BasePart") then n += 1 end end return n end

return K
