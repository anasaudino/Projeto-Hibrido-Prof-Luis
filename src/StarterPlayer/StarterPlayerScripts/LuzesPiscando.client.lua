-- Pisca (no cliente) toda peca com a tag "LuzPiscando": luminarias com defeito, monitores etc.
local CollectionService = game:GetService("CollectionService")

local function piscar(part)
	local neonOriginal = part.Material
	local corOriginal = part.Color
	local luzes = {}
	for _, l in ipairs(part:GetChildren()) do
		if l:IsA("Light") then table.insert(luzes, l) end
	end
	local apagada = corOriginal:Lerp(Color3.new(0.25, 0.27, 0.28), 0.75)
	local function set(on)
		part.Material = on and neonOriginal or Enum.Material.SmoothPlastic
		part.Color = on and corOriginal or apagada
		for _, l in ipairs(luzes) do l.Enabled = on end
	end
	task.spawn(function()
		local rng = Random.new()
		while part.Parent do
			set(true)
			task.wait(rng:NextNumber(0.4, 3.5))
			-- rajada de 1 a 4 piscadas
			for _ = 1, rng:NextInteger(1, 4) do
				set(false) task.wait(rng:NextNumber(0.03, 0.12))
				set(true) task.wait(rng:NextNumber(0.03, 0.1))
			end
			if rng:NextNumber() < 0.25 then
				set(false) task.wait(rng:NextNumber(0.3, 1.2))
			end
		end
	end)
end

for _, p in ipairs(CollectionService:GetTagged("LuzPiscando")) do piscar(p) end
CollectionService:GetInstanceAddedSignal("LuzPiscando"):Connect(piscar)
