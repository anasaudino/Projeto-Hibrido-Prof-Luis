-- Camera realista: inclina ao virar e ao andar de lado, balanco dos passos, respiracao parado e impacto ao cair.
-- O deslocamento e desfeito antes da camera padrao atualizar (prioridade First), entao nao acumula nem briga com ela.
-- Desliga em cutscene (Scriptable), no menu e com o personagem congelado. Atributo "MovCamera" = false desliga tudo.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local ROLL_VIRAR = 0.045       -- graus de inclinacao por grau/s de giro
local ROLL_VIRAR_MAX = 7
local ROLL_LADO = 2.4          -- graus ao andar de lado em velocidade cheia
local BOB_ALTURA = 0.11
local BOB_LADO = 0.07
local BOB_PITCH = 0.55         -- graus
local RESPIRA = 0.035

local aplicado = CFrame.identity
local roll, rollVel = 0, 0
local fase, intensidade = 0, 0
local queda, quedaVel = 0, 0
local yawAnterior
local tempo = 0

-- mola critica simples: aproxima x de alvo com velocidade v
local function mola(x, v, alvo, rigidez, dt)
	local amort = 2 * math.sqrt(rigidez)
	local a = (alvo - x) * rigidez - v * amort
	v += a * dt
	return x + v * dt, v
end

local function ativo()
	if player:GetAttribute("MovCamera") == false then return false end
	if player:GetAttribute("NoMenu") ~= false or player:GetAttribute("Congelado") or player:GetAttribute("EmUlt") then return false end
	return camera.CameraType == Enum.CameraType.Custom
end

local function ligarQueda(ch)
	local h = ch:WaitForChild("Humanoid", 10)
	if not h then return end
	h.StateChanged:Connect(function(_, novo)
		if novo == Enum.HumanoidStateType.Landed then
			local r = ch:FindFirstChild("HumanoidRootPart")
			local vy = r and math.abs(r.AssemblyLinearVelocity.Y) or 20
			quedaVel -= math.clamp(vy / 50, 0.15, 0.9) * 6
		end
	end)
end
if player.Character then task.spawn(ligarQueda, player.Character) end
player.CharacterAdded:Connect(ligarQueda)

-- antes da camera padrao: tira o que foi aplicado no frame anterior
RunService:BindToRenderStep("CameraRealistaDesfaz", Enum.RenderPriority.First.Value, function()
	if aplicado ~= CFrame.identity then
		camera.CFrame = camera.CFrame * aplicado:Inverse()
		aplicado = CFrame.identity
	end
end)

RunService:BindToRenderStep("CameraRealista", Enum.RenderPriority.Camera.Value + 2, function(dt)
	dt = math.min(dt, 1 / 20)
	local _, yaw = camera.CFrame:ToEulerAnglesYXZ()
	local giro = 0
	if yawAnterior then
		local d = yaw - yawAnterior
		if d > math.pi then d -= 2 * math.pi elseif d < -math.pi then d += 2 * math.pi end
		giro = math.deg(d) / dt
	end
	yawAnterior = yaw

	local ch = player.Character
	local h = ch and ch:FindFirstChildOfClass("Humanoid")
	local r = ch and ch:FindFirstChild("HumanoidRootPart")
	if not ativo() or not h or not r or h.Health <= 0 then
		roll, rollVel, intensidade, queda, quedaVel = 0, 0, 0, 0, 0
		return
	end
	tempo += dt

	local vel = r.AssemblyLinearVelocity
	local plano = Vector3.new(vel.X, 0, vel.Z)
	local noChao = h.FloorMaterial ~= Enum.Material.Air
	local velBase = math.max(h.WalkSpeed, 1)
	local ritmo = noChao and math.clamp(plano.Magnitude / velBase, 0, 1.4) or 0

	-- inclinacao: girar a camera + andar de lado
	local lado = camera.CFrame.RightVector:Dot(plano) / velBase
	local alvoRoll = math.clamp(-giro * ROLL_VIRAR, -ROLL_VIRAR_MAX, ROLL_VIRAR_MAX) - math.clamp(lado, -1, 1) * ROLL_LADO
	roll, rollVel = mola(roll, rollVel, alvoRoll, 60, dt)

	-- passos
	intensidade += (ritmo - intensidade) * math.min(1, dt * 8)
	fase += dt * (5.2 + 4.5 * intensidade) * (intensidade > 0.05 and 1 or 0)
	local bobY = math.abs(math.sin(fase)) * BOB_ALTURA * intensidade - BOB_ALTURA * 0.5 * intensidade
	local bobX = math.sin(fase) * BOB_LADO * intensidade
	local bobPitch = math.sin(fase * 2) * BOB_PITCH * intensidade

	-- respiracao quando parado
	local parado = 1 - math.clamp(intensidade * 3, 0, 1)
	local resp = math.sin(tempo * 1.6) * RESPIRA * parado

	-- impacto ao cair (mola volta pro zero)
	queda, quedaVel = mola(queda, quedaVel, 0, 90, dt)

	aplicado = CFrame.new(bobX, bobY + resp + queda * 0.25, 0)
		* CFrame.Angles(math.rad(bobPitch + queda * 2.5), 0, math.rad(roll))
	camera.CFrame = camera.CFrame * aplicado
end)
