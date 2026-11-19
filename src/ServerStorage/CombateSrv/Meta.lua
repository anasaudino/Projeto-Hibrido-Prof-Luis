-- Progresso PERMANENTE: Essencia + nos da arvore. Salvo no DataStore (1 chave por jogador).
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Config = require(game:GetService("ReplicatedStorage").Combate.Config)

local Meta = {}
local dados = {}        -- [player] = { essencia, nos = {id=true} }
local sujo = {}
local okStore, store = pcall(function() return DataStoreService:GetDataStore("JaneMeta_v1") end)
if not okStore then store = nil end

local function chave(p) return "u" .. p.UserId end

local function publicar(p)
	local d = dados[p] if not d then return end
	p:SetAttribute("Essencia", math.floor(d.essencia))
	p:SetAttribute("Arvore", HttpService:JSONEncode(d.nos))
end

function Meta.carregar(p)
	local d = { essencia = 0, nos = {}, camp = Meta.campNova() }
	if store then
		for tentativa = 1, 3 do
			local ok, v = pcall(function() return store:GetAsync(chave(p)) end)
			if ok then
				if type(v) == "table" then
					d.essencia = tonumber(v.essencia) or 0
					-- nos salvos como LISTA de ids (chave string numa tabela mista vira problema no DataStore)
					if type(v.nos) == "table" then for _, id in ipairs(v.nos) do if Config.NoPorId[id] then d.nos[id] = true end end end
					if type(v.camp) == "table" then
						local c = d.camp
						c.fase = tonumber(v.camp.fase) or 1
						c.cp = type(v.camp.cp) == "string" and v.camp.cp or "inicio"
						c.pedras = tonumber(v.camp.pedras) or 0
						c.iniciado = v.camp.iniciado == true
						c.zerado = v.camp.zerado == true
						c.obj = type(v.camp.obj) == "string" and v.camp.obj or nil
						for _, id in ipairs(v.camp.docs or {}) do c.docs[id] = true end
						for _, id in ipairs(v.camp.flags or {}) do c.flags[id] = true end
					end
				end
				break
			end
			task.wait(tentativa)
		end
	end
	dados[p] = d
	publicar(p)
	return d
end

local ultimoSave, agendado = {}, {}
function Meta.salvar(p, forcar)
	local d = dados[p]
	if not d or not store then return end
	local agora = os.clock()
	if not forcar and ultimoSave[p] and agora - ultimoSave[p] < 7 then
		sujo[p] = true
		if not agendado[p] then
			agendado[p] = true
			task.delay(7 - (agora - ultimoSave[p]) + 0.1, function() agendado[p] = nil if dados[p] and sujo[p] then Meta.salvar(p) end end)
		end
		return
	end
	ultimoSave[p] = agora
	local lista = {}
	for id in pairs(d.nos) do table.insert(lista, id) end
	local c = d.camp
	local docs, flags = {}, {}
	for id in pairs(c.docs) do table.insert(docs, id) end
	for id in pairs(c.flags) do table.insert(flags, id) end
	pcall(function() store:SetAsync(chave(p), { essencia = math.floor(d.essencia), nos = lista,
		camp = { fase = c.fase, cp = c.cp, pedras = c.pedras, iniciado = c.iniciado, zerado = c.zerado, obj = c.obj, docs = docs, flags = flags } }) end)
	sujo[p] = nil
end

function Meta.campNova() return { fase = 1, cp = "inicio", pedras = 0, docs = {}, flags = {}, iniciado = false, zerado = false } end
function Meta.camp(p) local d = dados[p] return d and d.camp end
function Meta.resetCamp(p) local d = dados[p] if d then local z = d.camp.zerado d.camp = Meta.campNova() d.camp.zerado = z sujo[p] = true end end
function Meta.sujar(p) sujo[p] = true end

function Meta.tem(p, id) local d = dados[p] return d and d.nos[id] == true end
function Meta.essencia(p) local d = dados[p] return d and d.essencia or 0 end

function Meta.ganhar(p, qtd)
	local d = dados[p] if not d then return 0 end
	if d.nos.f5 then qtd *= 1.5 end
	d.essencia += qtd
	sujo[p] = true
	publicar(p)
	return qtd
end

function Meta.gastar(p, qtd)
	local d = dados[p]
	if not d or d.essencia < qtd then return false end
	d.essencia -= qtd
	sujo[p] = true
	publicar(p)
	return true
end

function Meta.comprar(p, id)
	local d = dados[p]
	local no = Config.NoPorId[id]
	if not d or not no or d.nos[id] then return false, "invalido" end
	if no.req and not d.nos[no.req] then return false, "Desbloqueie o anterior primeiro" end
	if d.essencia < no.custo then return false, "Essência insuficiente" end
	d.essencia -= no.custo
	d.nos[id] = true
	publicar(p)
	Meta.salvar(p)
	return true
end

-- aplica os bonus da arvore nos stats base da run
function Meta.aplicar(p, s)
	local t = function(id) return Meta.tem(p, id) end
	if t("m1") then s.danoMult += 0.10 end
	if t("m2") then s.critico += 0.06 end
	if t("m3") then s.critMult = 2.5 end
	if t("m4") then s.projeteis += 1 end
	if t("m5") then s.cartas = 4 end
	if t("c1") then s.dash = true end
	if t("c2") then s.vidaMax += 20 end
	if t("c3") then s.dashInvuln = 0.45 s.dashRecarga -= 1 end
	if t("c4") then s.veloc += 0.10 end
	if t("c5") then s.segundaChance = true end
	if t("f1") then s.focoMax += 20 end
	if t("f2") then s.focoRegen *= 1.25 end
	if t("f3") then s.ondaRecarga -= 1.5 end
	if t("f4") then s.ima = 2 s.orbeCura = 3 end
end

function Meta.soltar(p)
	Meta.salvar(p, true)
	dados[p] = nil
end

-- autosave a cada 60s se mudou
task.spawn(function()
	while true do
		task.wait(60)
		for p in pairs(sujo) do if p.Parent then Meta.salvar(p) end end
	end
end)

game:BindToClose(function()
	for p in pairs(dados) do Meta.salvar(p, true) end
end)

return Meta
