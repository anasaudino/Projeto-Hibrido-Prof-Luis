-- FASE 4 — Administracao e Arquivos (Capitulo 4: A Diretora)
local F = {}
local FASE = workspace:WaitForChild("Fases"):WaitForChild("Fase4")
local GP = FASE:WaitForChild("Gameplay")
local OZ = 1500
local function V(x, y, z) return Vector3.new(x, y, z + OZ) end

local function checarPorta(p, api)
	if api.flag(p, "f4_codigo") and api.flag(p, "f4_trava") then
		api.porta(4, "Porta_Genetico", false)
		return true
	end
end

local function tecladoVerde()
	local led = GP:FindFirstChild("TecladoLed") if led then led.Color = Color3.fromRGB(60, 230, 120) end
end

F.acoes = {}
function F.acoes.Teclado(p, prompt, api)
	if api.flag(p, "f4_codigo") then
		if not api.flag(p, "f4_trava") then api.aviso(p, "Tem uma TRAVA do lado de dentro. Olhe pela janela e use a Levitação (R).") end
		return
	end
	if api.flag(p, "eco_f4_codigo_a") and api.flag(p, "eco_f4_codigo_b") then
		api.marcar(p, "f4_codigo")
		tecladoVerde()
		api.aviso(p, "Código 7 3 1 9 aceito.")
		if checarPorta(p, api) then api.objetivo(p, "Entre no Arquivo Genético")
		else api.objetivo(p, "A porta está travada por dentro. Levite a trava (R) pra fora e solte no chão marcado.") end
	else
		api.aviso(p, "Você não sabe o código.")
		api.objetivo(p, "O código está em duas folhas com números apagados (Diretoria e Arquivo Geral). Leia-as com o ECO (G).")
	end
end

function F.acoes.Genetico(p, prompt, api)
	prompt.Enabled = false
	api.doc(p, "f4_genetico")
	task.wait(1.5)
	api.historia(p, "flash", 1, Color3.fromRGB(255, 255, 255))
	api.cutscene(p, {
		tomadas = {
			{ de = CFrame.lookAt(V(44, 6, 15), V(48, 4, 13)), ate = CFrame.lookAt(V(46, 5, 15.5), V(48, 4, 13)), dur = 7 },
			{ de = CFrame.lookAt(V(38, 8, 24), V(44, 3, 14)), ate = CFrame.lookAt(V(40, 7, 22), V(44, 3, 14)), dur = 7 },
		},
		falas = "f4_revelacao",
	})
	api.marcar(p, "f4_revelacao")
	local ic = GP:FindFirstChild("Intercom")
	local q = ic and ic:FindFirstChildWhichIsA("ProximityPrompt") if q then q.Enabled = true end
	api.objetivo(p, "Use o intercomunicador. Ela precisa saber.")
end

function F.acoes.Intercom(p, prompt, api)
	prompt.Enabled = false
	api.gravacao(p, "f4_evelyn", true)
	api.marcar(p, "f4_evelyn")
	api.checkpoint(p, 4, "salao")
	api.radio(p, "f5_bloqueio")
	api.objetivo(p, "Saia pelo Salão da Diretoria (leste do corredor)")
end

function F.aposDocumento(p, id, api)
	if api.flag(p, "f4_codigo") then return end
	if api.flag(p, "eco_f4_codigo_a") and api.flag(p, "eco_f4_codigo_b") then
		api.objetivo(p, "Use o código no teclado do Arquivo Genético")
	elseif id == "f4_codigo_a" or id == "f4_codigo_b" then
		api.objetivo(p, "O código está em duas folhas com números apagados (Diretoria e Arquivo Geral). Leia-as com o ECO (G).")
	end
end

function F.encaixe(p, nome, obj, api)
	if nome ~= "SocketTrava" then return end
	api.marcar(p, "f4_trava")
	if checarPorta(p, api) then api.objetivo(p, "Entre no Arquivo Genético")
	else api.objetivo(p, "A trava saiu. Falta o código do teclado (leia as folhas com o ECO).") end
end

function F.aposPedra(p, api, n)
	api.checkpoint(p, 4, "genetico")
	api.objetivo(p, "Abra o arquivo de procedência genética (terminal azul)")
end

F.arenaLimpa = {}
F.arenaLimpa.Salao = function(p, api)
	api.objetivo(p, "Pegue o elevador até a Sala do Portal")
end

function F.podeSair(p, api)
	if not api.flag(p, "arena_Salao") then return false, "Não há energia no elevador." end
	return true
end

function F.aoCarregar(p, api, cp)
	if api.flag(p, "pedra_6") and GP:FindFirstChild("Pedra_06") then GP.Pedra_06:Destroy() end
	if api.flag(p, "f4_codigo") then tecladoVerde() end
	if api.flag(p, "f4_trava") then
		local t = GP:FindFirstChild("TravaPorta") local s = GP:FindFirstChild("SocketTrava")
		if t and s then t.CFrame = s.CFrame t:SetAttribute("Levitavel", nil) end
	end
	checarPorta(p, api)
	if api.flag(p, "f4_revelacao") then
		local tg = GP:FindFirstChild("TerminalGenetico") local q = tg and tg:FindFirstChildWhichIsA("ProximityPrompt") if q then q.Enabled = false end
		local ic = GP:FindFirstChild("Intercom") local qi = ic and ic:FindFirstChildWhichIsA("ProximityPrompt") if qi then qi.Enabled = not api.flag(p, "f4_evelyn") end
	end
	if api.flag(p, "arena_Salao") then api.porta(4, "Porta_ElevF4", false) end
	if cp == "inicio" then
		api.falas(p, { { "JANE", "A Administração. A sala dela.", 2.5 }, { "JANE", "Por que meu prontuário está acima dos diretores?", 3.5 } })
		api.objetivo(p, "Descubra por que seu prontuário é secreto. Comece pela Diretoria.")
	end
end

function F.objetivoPadrao(p, api)
	local f = function(k) return api.flag(p, k) end
	if not f("f4_codigo") then
		if f("eco_f4_codigo_a") and f("eco_f4_codigo_b") then return "Use o código no teclado do Arquivo Genético" end
		return "O código está em duas folhas com números apagados (Diretoria e Arquivo Geral). Leia-as com o ECO (G)."
	end
	if not f("f4_trava") then return "A porta está travada por dentro. Levite a trava (R) pra fora e solte no chão marcado." end
	if not f("pedra_6") then return "Entre no Arquivo Genético" end
	if not f("f4_revelacao") then return "Abra o arquivo de procedência genética (terminal azul)" end
	if not f("f4_evelyn") then return "Use o intercomunicador. Ela precisa saber." end
	if not f("arena_Salao") then return "Saia pelo Salão da Diretoria (leste do corredor)" end
	return "Pegue o elevador até a Sala do Portal"
end

return F
