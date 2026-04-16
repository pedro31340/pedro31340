local imgui = require 'imgui'
local key = require 'vkeys'
local inicfg = require 'inicfg'

-- ==========================================
-- CONFIGURACAO DE ARQUIVO
-- ==========================================
local configFile = "AdminPanelConfig.ini"
local defConfig = {
    settings = {
        corR = 0.07, corG = 0.08, corB = 0.07, corA = 1.00,
        btnR = 0.18, btnG = 0.65, btnB = 0.35, btnA = 1.00,
        textR = 1.00, textG = 1.00, textB = 1.00, textA = 1.00,
        titR = 0.18, titG = 0.65, titB = 0.35, titA = 1.00,
        posX = 400, posY = 300,
        tamanhoX = 860, tamanhoY = 700,
        somID = 1057,
        confirmarPunicao = true,
        logAcoes = true,
        cooldownCmd = 2
    }
}
local config = inicfg.load(defConfig, configFile) or defConfig

-- ==========================================
-- VARIAVEIS DE CONTROLE
-- ==========================================
local janela = imgui.ImBool(false)
local estadoAnterior = false
local exibirAjustes = imgui.ImBool(false)
local selectedPlayer = -1
local travaF2 = false
local cliques, timerClique = 0, 0
local startTime = os.time()
local abaAtual = 1

-- Log de acoes
local logAcoes = {}
local MAX_LOG = 50

-- Confirmacao de acoes perigosas
local confirmarAcao = imgui.ImBool(config.settings.confirmarPunicao)
local acaoPendente = nil
local acaoComando = nil
local mostrarConfirmacao = false

-- Cooldown entre comandos
local ultimoComando = 0
local cooldownSegundos = config.settings.cooldownCmd

-- ==========================================
-- BUFFERS
-- ==========================================
local corPainel = imgui.ImFloat4(config.settings.corR, config.settings.corG, config.settings.corB, config.settings.corA)
local corBotoes = imgui.ImFloat4(config.settings.btnR, config.settings.btnG, config.settings.btnB, config.settings.btnA)
local corTexto = imgui.ImFloat4(config.settings.textR, config.settings.textG, config.settings.textB, config.settings.textA)
local corTitulos = imgui.ImFloat4(config.settings.titR, config.settings.titG, config.settings.titB, config.settings.titA)
local somSelecionado = imgui.ImInt(config.settings.somID)

local tempo = imgui.ImBuffer(16)
local motivo = imgui.ImBuffer(128)
local avisos = imgui.ImBuffer(16)
local adv = imgui.ImBuffer(16)
local campoIP = imgui.ImBuffer(64)
local pesquisa = imgui.ImBuffer(64)
local campoNickIDF = imgui.ImBuffer(64)

-- ==========================================
-- FUNCOES UTILITARIAS
-- ==========================================
function u8(str)
    local p, result = {
        ["\195\167"] = "\231", ["\195\163"] = "\227", ["\195\181"] = "\245",
        ["\195\161"] = "\225", ["\195\169"] = "\233", ["\195\173"] = "\237",
        ["\195\179"] = "\243", ["\195\186"] = "\250", ["\195\129"] = "\193",
        ["\195\137"] = "\201", ["\195\147"] = "\211", ["\195\130"] = "\194",
        ["\195\170"] = "\234", ["\195\141"] = "\205"
    }, str
    for k, v in pairs(p) do result = result:gsub(k, v) end
    return result
end

function getSemana()
    local dias = {"Domingo", "Segunda-feira", "Terca-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sabado"}
    return dias[os.date("*t").wday]
end

-- ==========================================
-- SEGURANCA: Validacao de Entrada
-- ==========================================
function validarMotivo(m)
    if m == nil or m == "" then return false end
    if #m < 3 then return false end
    if #m > 100 then return false end
    return true
end

function sanitizarEntrada(str)
    if str == nil then return "" end
    -- Remove caracteres que poderiam ser usados para injecao de comandos
    str = str:gsub("[;|&`$%%]", "")
    return str
end

-- ==========================================
-- SEGURANCA: Cooldown de Comandos
-- ==========================================
function podeSendCmd()
    local agora = os.clock()
    if agora - ultimoComando < cooldownSegundos then
        return false
    end
    return true
end

function registrarComando()
    ultimoComando = os.clock()
end

-- ==========================================
-- SEGURANCA: Log de Acoes
-- ==========================================
function adicionarLog(acao)
    table.insert(logAcoes, 1, {
        hora = os.date("%H:%M:%S"),
        texto = acao
    })
    if #logAcoes > MAX_LOG then
        table.remove(logAcoes)
    end
end

-- ==========================================
-- ACAO COM SOM + VALIDACAO + LOG
-- ==========================================
function acaoSom(comando)
    if not podeSendCmd() then
        sampAddChatMessage(u8("{FF6600}[Painel] {FFFFFF}Aguarde antes de enviar outro comando."), -1)
        return false
    end
    if comando then
        sampSendChat(comando)
        registrarComando()
        adicionarLog(comando)
    end
    addOneOffSound(0, 0, 0, somSelecionado.v)
    return true
end

-- Executa com confirmacao para acoes perigosas
function acaoPerigosa(descricao, comando)
    if confirmarAcao.v then
        acaoPendente = descricao
        acaoComando = comando
        mostrarConfirmacao = true
    else
        acaoSom(comando)
    end
end

-- ==========================================
-- HELPERS DE UI
-- ==========================================
function contarPlayersOnline()
    local count = 0
    for i = 0, 1000 do
        if sampIsPlayerConnected(i) then count = count + 1 end
    end
    return count
end

function tituloSecao(texto)
    local cT = imgui.ImVec4(corTitulos.v[1], corTitulos.v[2], corTitulos.v[3], 1.0)
    imgui.Spacing()
    imgui.TextColored(cT, texto)
    -- Linha decorativa colorida abaixo do titulo
    local drawList = imgui.GetWindowDrawList()
    local cursorPos = imgui.GetCursorScreenPos()
    local availW = imgui.GetContentRegionAvailWidth()
    drawList:AddLine(
        imgui.ImVec2(cursorPos.x, cursorPos.y),
        imgui.ImVec2(cursorPos.x + availW, cursorPos.y),
        imgui.GetColorU32(imgui.ImVec4(corBotoes.v[1], corBotoes.v[2], corBotoes.v[3], 0.6)),
        2.0
    )
    imgui.Spacing()
    imgui.Spacing()
end

function botaoComTooltip(label, tamanho, tooltip, callback)
    if imgui.Button(label, tamanho) then
        callback()
    end
    if tooltip and imgui.IsItemHovered() then
        imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 6.0)
        imgui.PushStyleColor(imgui.Col.PopupBg, imgui.ImVec4(0.12, 0.12, 0.12, 0.95))
        imgui.BeginTooltip()
        imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.8, 1.0), tooltip)
        imgui.EndTooltip()
        imgui.PopStyleColor()
        imgui.PopStyleVar()
    end
end

-- Verifica se o campo de ID/Nick esta preenchido antes de executar
function verificarPlayerEExecutar(comando, campos)
    local id = sanitizarEntrada(campoNickIDF.v)
    if id == "" then
        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Selecione um player ou preencha o ID/Nick."), -1)
        return
    end
    if campos then
        for _, campo in ipairs(campos) do
            if campo.valor == nil or campo.valor == "" then
                sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Campo obrigatorio: " .. campo.nome), -1)
                return
            end
        end
    end
    acaoSom(comando)
end

-- ==========================================
-- FUNCAO PRINCIPAL
-- ==========================================
function main()
    if not isSampLoaded() or not isSampAvailable() then repeat wait(100) until isSampAvailable() end
    sampRegisterChatCommand("admin", function() janela.v = not janela.v end)

    while true do
        wait(0)
        if isKeyDown(key.VK_F2) and not sampIsChatInputActive() and not sampIsDialogActive() then
            if not travaF2 then janela.v = not janela.v; travaF2 = true end
        else travaF2 = false end

        if janela.v ~= estadoAnterior then
            if janela.v then
                sampAddChatMessage(u8("{00FF00}[Painel Admin] {FFFFFF}Aberto com sucesso."), -1)
            else
                sampAddChatMessage(u8("{FF0000}[Painel Admin] {FFFFFF}Fechado com sucesso."), -1)
            end
            estadoAnterior = janela.v
        end
        imgui.Process = janela.v
    end
end

-- ==========================================
-- ESTILO VISUAL MODERNO
-- ==========================================
function aplicarEstilo()
    local style = imgui.GetStyle()
    style.WindowRounding = 8.0
    style.FrameRounding = 4.0
    style.ChildWindowRounding = 6.0
    style.ScrollbarRounding = 6.0
    style.GrabRounding = 3.0
    style.ScrollbarSize = 8.0
    style.ItemSpacing = imgui.ImVec2(8, 6)
    style.ItemInnerSpacing = imgui.ImVec2(6, 4)
    style.WindowPadding = imgui.ImVec2(12, 10)
    style.FramePadding = imgui.ImVec2(6, 4)

    local col = style.Colors
    local p, b, t = corPainel.v, corBotoes.v, corTexto.v

    -- Fundo principal com profundidade
    col[imgui.Col.WindowBg] = imgui.ImVec4(p[1], p[2], p[3], p[4])
    col[imgui.Col.ChildWindowBg] = imgui.ImVec4(p[1] + 0.03, p[2] + 0.03, p[3] + 0.03, 0.95)
    col[imgui.Col.PopupBg] = imgui.ImVec4(p[1] + 0.02, p[2] + 0.02, p[3] + 0.02, 0.98)

    -- Texto
    col[imgui.Col.Text] = imgui.ImVec4(t[1], t[2], t[3], t[4])
    col[imgui.Col.TextDisabled] = imgui.ImVec4(t[1] * 0.5, t[2] * 0.5, t[3] * 0.5, 0.6)

    -- Titulo da janela
    col[imgui.Col.TitleBg] = imgui.ImVec4(p[1] - 0.02, p[2] - 0.02, p[3] - 0.02, 1.00)
    col[imgui.Col.TitleBgActive] = imgui.ImVec4(b[1] * 0.5, b[2] * 0.5, b[3] * 0.5, 1.00)
    col[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(p[1], p[2], p[3], 0.75)

    -- Botoes com visual moderno
    col[imgui.Col.Button] = imgui.ImVec4(b[1] * 0.6, b[2] * 0.6, b[3] * 0.6, b[4])
    col[imgui.Col.ButtonHovered] = imgui.ImVec4(b[1], b[2], b[3], 1.00)
    col[imgui.Col.ButtonActive] = imgui.ImVec4(math.min(1.0, b[1] * 1.3), math.min(1.0, b[2] * 1.3), math.min(1.0, b[3] * 1.3), 1.00)

    -- Frames (inputs)
    col[imgui.Col.FrameBg] = imgui.ImVec4(0.10, 0.10, 0.10, 1.00)
    col[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.16, 0.16, 0.16, 1.00)
    col[imgui.Col.FrameBgActive] = imgui.ImVec4(b[1] * 0.3, b[2] * 0.3, b[3] * 0.3, 0.80)

    -- Close button
    col[imgui.Col.CloseButton] = imgui.ImVec4(1.0, 1.0, 1.0, 0.15)
    col[imgui.Col.CloseButtonHovered] = imgui.ImVec4(1.0, 0.3, 0.3, 0.80)
    col[imgui.Col.CloseButtonActive] = imgui.ImVec4(1.0, 0.0, 0.0, 1.00)

    -- Selecao
    col[imgui.Col.TextSelectedBg] = imgui.ImVec4(b[1], b[2], b[3], 0.50)

    -- Headers
    col[imgui.Col.Header] = imgui.ImVec4(b[1] * 0.4, b[2] * 0.4, b[3] * 0.4, 0.60)
    col[imgui.Col.HeaderHovered] = imgui.ImVec4(b[1] * 0.6, b[2] * 0.6, b[3] * 0.6, 0.80)
    col[imgui.Col.HeaderActive] = imgui.ImVec4(b[1], b[2], b[3], 1.00)

    -- Scrollbar estilizada
    col[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.04, 0.04, 0.04, 0.40)
    col[imgui.Col.ScrollbarGrab] = imgui.ImVec4(b[1] * 0.4, b[2] * 0.4, b[3] * 0.4, 0.60)
    col[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(b[1] * 0.7, b[2] * 0.7, b[3] * 0.7, 0.80)
    col[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(b[1], b[2], b[3], 1.00)

    -- Separator colorido
    col[imgui.Col.Separator] = imgui.ImVec4(b[1] * 0.3, b[2] * 0.3, b[3] * 0.3, 0.50)
    col[imgui.Col.SeparatorHovered] = imgui.ImVec4(b[1], b[2], b[3], 0.80)
    col[imgui.Col.SeparatorActive] = imgui.ImVec4(b[1], b[2], b[3], 1.00)

    -- CheckMark
    col[imgui.Col.CheckMark] = imgui.ImVec4(b[1], b[2], b[3], 1.00)

    -- SliderGrab
    col[imgui.Col.SliderGrab] = imgui.ImVec4(b[1] * 0.7, b[2] * 0.7, b[3] * 0.7, 0.80)
    col[imgui.Col.SliderGrabActive] = imgui.ImVec4(b[1], b[2], b[3], 1.00)
end

-- ==========================================
-- PAINEL PRINCIPAL - DRAW FRAME
-- ==========================================
function imgui.OnDrawFrame()
    if not janela.v then return end
    aplicarEstilo()

    imgui.SetNextWindowPos(imgui.ImVec2(config.settings.posX, config.settings.posY), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(config.settings.tamanhoX, config.settings.tamanhoY), imgui.Cond.FirstUseEver)

    if imgui.Begin("PAINEL ADMINISTRACAO  -  ARCADE PVP", janela, imgui.WindowFlags.NoCollapse) then
        local mainWindowPos = imgui.GetWindowPos()
        local mainWindowSize = imgui.GetWindowSize()
        local cT = imgui.ImVec4(corTitulos.v[1], corTitulos.v[2], corTitulos.v[3], 1.0)
        local availW = imgui.GetContentRegionAvailWidth()

        -- Triple click para abrir ajustes ocultos
        if imgui.IsWindowHovered() and imgui.IsMouseClicked(0) then
            local t = os.clock()
            if t - timerClique < 0.5 then cliques = cliques + 1 else cliques = 1 end
            timerClique = t
            if cliques >= 3 then exibirAjustes.v = not exibirAjustes.v; cliques = 0 end
        end

        -- ==========================================
        -- PAINEL DE AJUSTES (triple click para abrir)
        -- ==========================================
        if exibirAjustes.v then
            imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.98))
            imgui.BeginChild("AjustesOcultos", imgui.ImVec2(0, 220), true)
                tituloSecao("PERSONALIZACAO DO PAINEL")

                imgui.Columns(2, "coresCol", false)
                imgui.ColorEdit4("Fundo", corPainel, 32)
                imgui.ColorEdit4("Botoes", corBotoes, 32)
                imgui.NextColumn()
                imgui.ColorEdit4("Textos", corTexto, 32)
                imgui.ColorEdit4("Categorias", corTitulos, 32)
                imgui.Columns(1)

                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()

                imgui.PushItemWidth(120)
                if imgui.InputInt("##idSom", somSelecionado) then addOneOffSound(0, 0, 0, somSelecionado.v) end
                imgui.PopItemWidth()
                imgui.SameLine(); imgui.TextDisabled("ID do som de notificacao")

                imgui.Spacing()
                imgui.Checkbox("Confirmar acoes perigosas (Ban/Kick/Matar)", confirmarAcao)

                imgui.Spacing()
                if imgui.Button("Salvar Configuracoes", imgui.ImVec2(-1, 32)) then
                    config.settings = {
                        corR = corPainel.v[1], corG = corPainel.v[2], corB = corPainel.v[3], corA = corPainel.v[4],
                        btnR = corBotoes.v[1], btnG = corBotoes.v[2], btnB = corBotoes.v[3], btnA = corBotoes.v[4],
                        textR = corTexto.v[1], textG = corTexto.v[2], textB = corTexto.v[3], textA = corTexto.v[4],
                        titR = corTitulos.v[1], titG = corTitulos.v[2], titB = corTitulos.v[3], titA = corTitulos.v[4],
                        posX = mainWindowPos.x, posY = mainWindowPos.y,
                        tamanhoX = mainWindowSize.x, tamanhoY = mainWindowSize.y,
                        somID = somSelecionado.v,
                        confirmarPunicao = confirmarAcao.v,
                        logAcoes = true,
                        cooldownCmd = cooldownSegundos
                    }
                    inicfg.save(config, configFile)
                    sampAddChatMessage(u8("{FFFF00}[Painel Admin] {FFFFFF}Configuracoes salvas com sucesso!"), -1)
                    acaoSom()
                    exibirAjustes.v = false
                end
            imgui.EndChild()
            imgui.PopStyleColor()
            imgui.Spacing()
        end

        -- ==========================================
        -- BARRA DE STATUS SUPERIOR
        -- ==========================================
        imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.05, 0.05, 0.05, 0.95))
        imgui.BeginChild("StatusBar", imgui.ImVec2(0, 45), true)
            local uptime = os.time() - startTime
            local upH = math.floor(uptime / 3600)
            local upM = math.floor((uptime % 3600) / 60)
            local upS = uptime % 60
            local playersOnline = contarPlayersOnline()

            imgui.Columns(4, "statusCols", false)

            -- Data
            imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "DATA")
            imgui.TextColored(imgui.ImVec4(1, 1, 1, 1), os.date("%d/%m/%Y") .. " (" .. getSemana() .. ")")
            imgui.NextColumn()

            -- Hora
            imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "HORA")
            imgui.TextColored(imgui.ImVec4(1, 1, 1, 1), os.date("%H:%M:%S"))
            imgui.NextColumn()

            -- Tempo Online
            imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "SESSAO")
            imgui.TextColored(cT, string.format("%02d:%02d:%02d", upH, upM, upS))
            imgui.NextColumn()

            -- Players online
            imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "PLAYERS")
            imgui.TextColored(cT, tostring(playersOnline))

            imgui.Columns(1)
        imgui.EndChild()
        imgui.PopStyleColor()

        imgui.Spacing()

        -- ==========================================
        -- PAINEL ESQUERDO - LISTA DE PLAYERS
        -- ==========================================
        imgui.BeginChild("PlayersList", imgui.ImVec2(200, -1), true)
            imgui.TextColored(cT, "PLAYERS ONLINE")
            imgui.Separator()
            imgui.Spacing()

            -- Campo de busca
            imgui.PushItemWidth(-1)
            imgui.InputText("##search", pesquisa)
            imgui.PopItemWidth()
            if imgui.IsItemHovered() then
                imgui.BeginTooltip()
                imgui.Text("Busque por nome ou ID")
                imgui.EndTooltip()
            end
            imgui.Spacing()
            imgui.Separator()

            -- Lista de players com scroll
            imgui.BeginChild("ScrollPlayers", imgui.ImVec2(0, -80), false)
            for i = 0, 1000 do
                if sampIsPlayerConnected(i) then
                    local nick = sampGetPlayerNickname(i)
                    local searchTerm = pesquisa.v:lower()
                    if searchTerm == "" or nick:lower():find(searchTerm, 1, true) or tostring(i):find(searchTerm) then
                        local isSelected = selectedPlayer == i
                        if isSelected then
                            imgui.PushStyleColor(imgui.Col.Text, cT)
                        end
                        if imgui.Selectable(string.format("[%d] %s", i, nick), isSelected) then
                            selectedPlayer = i
                            campoNickIDF.v = tostring(i)
                        end
                        if isSelected then
                            imgui.PopStyleColor()
                        end
                    end
                end
            end
            imgui.EndChild()

            imgui.Separator()
            imgui.Spacing()

            -- Info do player selecionado
            if selectedPlayer >= 0 and sampIsPlayerConnected(selectedPlayer) then
                local nick = sampGetPlayerNickname(selectedPlayer)
                local score = sampGetPlayerScore(selectedPlayer)
                local ping = sampGetPlayerPing(selectedPlayer)
                imgui.TextColored(cT, nick)
                imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), string.format("ID: %d", selectedPlayer))
                imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1), string.format("Score: %d | Ping: %dms", score, ping))
            else
                imgui.TextColored(imgui.ImVec4(0.35, 0.35, 0.35, 1), "Nenhum player")
                imgui.TextColored(imgui.ImVec4(0.35, 0.35, 0.35, 1), "selecionado")
            end
        imgui.EndChild()

        imgui.SameLine()

        -- ==========================================
        -- PAINEL DIREITO - AREA PRINCIPAL COM ABAS
        -- ==========================================
        imgui.BeginChild("MainArea", imgui.ImVec2(0, -1), false)

            -- Abas de navegacao
            local abaW = (imgui.GetContentRegionAvailWidth() - 25) / 5
            local abas = {"Gerenciamento", "Interacao", "Punicoes", "Setagem", "Log"}
            for i, nome in ipairs(abas) do
                if i > 1 then imgui.SameLine() end
                if abaAtual == i then
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(corBotoes.v[1], corBotoes.v[2], corBotoes.v[3], 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(corBotoes.v[1], corBotoes.v[2], corBotoes.v[3], 1.0))
                    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0, 0, 0, 1))
                end
                local pushed = (abaAtual == i)
                if imgui.Button(nome .. "##aba" .. i, imgui.ImVec2(abaW, 30)) then
                    abaAtual = i
                end
                if pushed then
                    imgui.PopStyleColor(3)
                end
            end

            -- Linha decorativa abaixo das abas
            local drawList = imgui.GetWindowDrawList()
            local cursorPos = imgui.GetCursorScreenPos()
            local tabLineW = imgui.GetContentRegionAvailWidth()
            drawList:AddLine(
                imgui.ImVec2(cursorPos.x, cursorPos.y + 2),
                imgui.ImVec2(cursorPos.x + tabLineW, cursorPos.y + 2),
                imgui.GetColorU32(imgui.ImVec4(corBotoes.v[1], corBotoes.v[2], corBotoes.v[3], 0.5)),
                2.0
            )
            imgui.Spacing()
            imgui.Spacing()

            local bW = (imgui.GetContentRegionAvailWidth() - 30) / 5
            local bH = 28

            -- ==========================================
            -- ABA 1: GERENCIAMENTO
            -- ==========================================
            if abaAtual == 1 then
                tituloSecao("COMANDOS ADMINISTRATIVOS")

                -- Linha 1
                botaoComTooltip("Modo Admin", imgui.ImVec2(bW, bH), "Ativar/Desativar modo admin (/tra)", function() acaoSom("/tra") end)
                imgui.SameLine()
                botaoComTooltip("Fila", imgui.ImVec2(bW, bH), "Ver fila de atendimento (/fila)", function() acaoSom("/fila") end)
                imgui.SameLine()
                botaoComTooltip("Reports", imgui.ImVec2(bW, bH), "Ver jogadores reportados (/reportados)", function() acaoSom("/reportados") end)
                imgui.SameLine()
                botaoComTooltip("Voar", imgui.ImVec2(bW, bH), "Ativar modo voo (/voaron)", function() acaoSom("/voaron") end)
                imgui.SameLine()
                botaoComTooltip("Limpar Campos", imgui.ImVec2(bW, bH), "Limpar todos os campos de entrada", function()
                    tempo.v = ""; motivo.v = ""; avisos.v = ""; adv.v = ""
                    campoIP.v = ""; campoNickIDF.v = ""; pesquisa.v = ""
                    selectedPlayer = -1
                end)

                imgui.Spacing()

                -- Linha 2
                botaoComTooltip("Alterar Modo", imgui.ImVec2(bW, bH), "Trocar modo de jogo (/trocarmodo)", function() acaoSom("/trocarmodo") end)
                imgui.SameLine()
                botaoComTooltip("Staffs Online", imgui.ImVec2(bW, bH), "Ver admins online (/admins)", function() acaoSom("/admins") end)
                imgui.SameLine()
                botaoComTooltip("Finalizar Att", imgui.ImVec2(bW, bH), "Finalizar atendimento (/fimatt)", function() acaoSom("/fimatt") end)
                imgui.SameLine()
                botaoComTooltip("Reset Veiculos", imgui.ImVec2(bW, bH), "Resetar veiculos do servidor (/dc)", function() acaoSom("/dc") end)
                imgui.SameLine()
                botaoComTooltip("Ver Presos", imgui.ImVec2(bW, bH), "Ver jogadores presos (/presos)", function() acaoSom("/presos") end)

                imgui.Spacing()

                -- Linha 3
                botaoComTooltip("Fix Caixas", imgui.ImVec2(bW, bH), "Consertar caixas do servidor", function() acaoSom("/consertarcaixas") end)
                imgui.SameLine()
                botaoComTooltip("Att Ranking", imgui.ImVec2(bW, bH), "Atualizar ranking do servidor", function() acaoSom("/atualizarrank") end)
                imgui.SameLine()
                botaoComTooltip("Iniciar Guerra", imgui.ImVec2(bW, bH), "Iniciar guerra de morro (/guerramorro)", function() acaoSom("/guerramorro") end)
                imgui.SameLine()
                botaoComTooltip("Limpar Chat", imgui.ImVec2(bW, bH), "Limpar chat do servidor (/lc)", function()
                    if validarMotivo(motivo.v) then
                        acaoSom("/lc " .. sanitizarEntrada(motivo.v))
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Informe um motivo valido (min 3 chars)."), -1)
                    end
                end)
                imgui.SameLine()
                botaoComTooltip("Reconectar", imgui.ImVec2(bW, bH), "Reconectar ao servidor (/connect)", function() acaoSom("/connect") end)

            -- ==========================================
            -- ABA 2: INTERACAO
            -- ==========================================
            elseif abaAtual == 2 then
                -- Aviso visual se nenhum player selecionado
                if campoNickIDF.v == "" then
                    imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.15, 0.10, 0.02, 0.90))
                    imgui.BeginChild("AvisoPlayer", imgui.ImVec2(0, 28), true)
                        imgui.TextColored(imgui.ImVec4(1, 0.7, 0.2, 1), "  Selecione um player na lista ou digite o ID/Nick na aba Punicoes.")
                    imgui.EndChild()
                    imgui.PopStyleColor()
                    imgui.Spacing()
                end

                local iW = (imgui.GetContentRegionAvailWidth() - 20) / 4

                -- Sub-secao: Observacao
                tituloSecao("OBSERVACAO")
                botaoComTooltip("Espiar", imgui.ImVec2(iW, bH), "Espiar jogador (/tv)", function()
                    verificarPlayerEExecutar("/tv " .. sanitizarEntrada(campoNickIDF.v))
                end)
                imgui.SameLine()
                botaoComTooltip("Parar Espiar", imgui.ImVec2(iW, bH), "Parar de espiar (/tvoff)", function() acaoSom("/tvoff") end)
                imgui.SameLine()
                botaoComTooltip("Ir ao Player", imgui.ImVec2(iW, bH), "Ir ate o jogador (/ir)", function()
                    verificarPlayerEExecutar("/ir " .. sanitizarEntrada(campoNickIDF.v))
                end)
                imgui.SameLine()
                botaoComTooltip("Trazer Player", imgui.ImVec2(iW, bH), "Trazer jogador ate voce (/tr)", function()
                    verificarPlayerEExecutar("/tr " .. sanitizarEntrada(campoNickIDF.v))
                end)

                -- Sub-secao: Controle
                tituloSecao("CONTROLE DE PLAYER")
                botaoComTooltip("Segurar", imgui.ImVec2(iW, bH), "Segurar jogador (/segurar)", function()
                    verificarPlayerEExecutar("/segurar " .. sanitizarEntrada(campoNickIDF.v))
                end)
                imgui.SameLine()
                botaoComTooltip("Largar", imgui.ImVec2(iW, bH), "Largar jogador (/largar)", function()
                    verificarPlayerEExecutar("/largar " .. sanitizarEntrada(campoNickIDF.v))
                end)
                imgui.SameLine()
                botaoComTooltip("Forcar Spawn", imgui.ImVec2(iW, bH), "Forcar spawn do jogador (/spawnarplayer)", function()
                    verificarPlayerEExecutar("/spawnarplayer " .. sanitizarEntrada(campoNickIDF.v))
                end)
                imgui.SameLine()
                botaoComTooltip("Congelar", imgui.ImVec2(iW, bH), "Congelar jogador (/congelar)", function()
                    verificarPlayerEExecutar("/congelar " .. sanitizarEntrada(campoNickIDF.v))
                end)

                imgui.Spacing()

                botaoComTooltip("Descongelar", imgui.ImVec2(iW, bH), "Descongelar jogador (/descongelar)", function()
                    verificarPlayerEExecutar("/descongelar " .. sanitizarEntrada(campoNickIDF.v))
                end)
                imgui.SameLine()
                botaoComTooltip("Reviver", imgui.ImVec2(iW, bH), "Reviver jogador (/god)", function()
                    verificarPlayerEExecutar("/god " .. sanitizarEntrada(campoNickIDF.v))
                end)
                imgui.SameLine()
                botaoComTooltip("Ret. Arma", imgui.ImVec2(iW, bH), "Retirar arma do jogador (/rarma)", function()
                    verificarPlayerEExecutar("/rarma " .. sanitizarEntrada(campoNickIDF.v))
                end)
                imgui.SameLine()
                botaoComTooltip("R. Armas Todos", imgui.ImVec2(iW, bH), "Retirar armas de todos (/rarmast)", function() acaoSom("/rarmast") end)

                -- Sub-secao: Acoes Severas (visual vermelho)
                tituloSecao("ACOES SEVERAS")
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45, 0.10, 0.10, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65, 0.15, 0.15, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.85, 0.10, 0.10, 1.0))

                botaoComTooltip("Matar", imgui.ImVec2(iW, bH), "Matar jogador (/killplayer) - Requer confirmacao", function()
                    if campoNickIDF.v ~= "" then
                        acaoPerigosa("MATAR jogador ID " .. campoNickIDF.v, "/killplayer " .. sanitizarEntrada(campoNickIDF.v))
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Selecione um player primeiro."), -1)
                    end
                end)
                imgui.SameLine()
                botaoComTooltip("Explodir", imgui.ImVec2(iW, bH), "Explodir jogador (/explodir) - Requer confirmacao", function()
                    if campoNickIDF.v ~= "" then
                        acaoPerigosa("EXPLODIR jogador ID " .. campoNickIDF.v, "/explodir " .. sanitizarEntrada(campoNickIDF.v))
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Selecione um player primeiro."), -1)
                    end
                end)
                imgui.SameLine()
                botaoComTooltip("Tapa", imgui.ImVec2(iW, bH), "Dar tapa no jogador (/tapa)", function()
                    verificarPlayerEExecutar("/tapa " .. sanitizarEntrada(campoNickIDF.v))
                end)
                imgui.SameLine()
                botaoComTooltip("Soltar Preso", imgui.ImVec2(iW, bH), "Soltar jogador da cadeia (/soltar) - Precisa de motivo", function()
                    if campoNickIDF.v ~= "" and validarMotivo(motivo.v) then
                        acaoSom("/soltar " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(motivo.v))
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha o ID e o motivo para soltar."), -1)
                    end
                end)

                imgui.PopStyleColor(3)

            -- ==========================================
            -- ABA 3: PUNICOES & ACESSOS
            -- ==========================================
            elseif abaAtual == 3 then
                tituloSecao("PUNICOES E ACESSOS")

                -- Campos de entrada com validacao visual
                imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.98))
                imgui.BeginChild("CamposPunicao", imgui.ImVec2(0, 195), true)
                    imgui.Columns(2, "inputCols", false)
                    imgui.SetColumnWidth(0, 290)

                    imgui.Spacing()
                    imgui.AlignTextToFramePadding()
                    imgui.TextColored(cT, "ID/Nick:"); imgui.SameLine(105)
                    imgui.PushItemWidth(165); imgui.InputText("##n", campoNickIDF); imgui.PopItemWidth()

                    imgui.AlignTextToFramePadding()
                    imgui.TextColored(cT, "Tempo:"); imgui.SameLine(105)
                    imgui.PushItemWidth(165); imgui.InputText("##t", tempo); imgui.PopItemWidth()

                    imgui.AlignTextToFramePadding()
                    imgui.TextColored(cT, "Motivo:"); imgui.SameLine(105)
                    imgui.PushItemWidth(165); imgui.InputText("##m", motivo); imgui.PopItemWidth()

                    imgui.AlignTextToFramePadding()
                    imgui.TextColored(cT, "Avisos Cadeia:"); imgui.SameLine(105)
                    imgui.PushItemWidth(165); imgui.InputText("##avi", avisos); imgui.PopItemWidth()

                    imgui.AlignTextToFramePadding()
                    imgui.TextColored(cT, "Motivo ADV:"); imgui.SameLine(105)
                    imgui.PushItemWidth(165); imgui.InputText("##adv", adv); imgui.PopItemWidth()

                    imgui.AlignTextToFramePadding()
                    imgui.TextColored(cT, "IP:"); imgui.SameLine(105)
                    imgui.PushItemWidth(165); imgui.InputText("##ip", campoIP); imgui.PopItemWidth()

                    imgui.NextColumn()

                    -- Painel de validacao em tempo real
                    imgui.Spacing()
                    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "Status dos Campos:")
                    imgui.Spacing()

                    -- Indicador ID/Nick
                    if campoNickIDF.v ~= "" then
                        imgui.TextColored(imgui.ImVec4(0.2, 0.85, 0.3, 1), "[OK] ID/Nick preenchido")
                    else
                        imgui.TextColored(imgui.ImVec4(0.85, 0.25, 0.25, 1), "[--] ID/Nick vazio")
                    end

                    -- Indicador Motivo
                    if motivo.v ~= "" and #motivo.v >= 3 then
                        imgui.TextColored(imgui.ImVec4(0.2, 0.85, 0.3, 1), "[OK] Motivo valido")
                    elseif motivo.v ~= "" and #motivo.v < 3 then
                        imgui.TextColored(imgui.ImVec4(0.9, 0.6, 0.1, 1), "[!!] Motivo muito curto (min 3)")
                    else
                        imgui.TextColored(imgui.ImVec4(0.85, 0.25, 0.25, 1), "[--] Motivo vazio")
                    end

                    -- Indicador Tempo
                    if tempo.v ~= "" then
                        imgui.TextColored(imgui.ImVec4(0.2, 0.85, 0.3, 1), "[OK] Tempo preenchido")
                    else
                        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "[  ] Tempo (quando necessario)")
                    end

                    -- Indicador IP
                    if campoIP.v ~= "" then
                        imgui.TextColored(imgui.ImVec4(0.2, 0.85, 0.3, 1), "[OK] IP preenchido")
                    else
                        imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), "[  ] IP (quando necessario)")
                    end

                    imgui.Columns(1)
                imgui.EndChild()
                imgui.PopStyleColor()

                imgui.Spacing()

                -- Botoes de punicao organizados por gravidade
                local pW = (imgui.GetContentRegionAvailWidth() - 10) / 2

                -- PUNICOES GRAVES (vermelho)
                imgui.TextColored(imgui.ImVec4(0.9, 0.2, 0.2, 1), "Punicoes Graves")
                imgui.Spacing()
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45, 0.08, 0.08, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65, 0.12, 0.12, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.85, 0.08, 0.08, 1.0))

                botaoComTooltip("Ban", imgui.ImVec2(pW, 26), "Banir: /ban [ID] [Tempo] [Motivo]", function()
                    local id = sanitizarEntrada(campoNickIDF.v)
                    local t = sanitizarEntrada(tempo.v)
                    local m = sanitizarEntrada(motivo.v)
                    if id ~= "" and t ~= "" and validarMotivo(m) then
                        acaoPerigosa("BANIR jogador " .. id .. " por " .. t .. " - " .. m, "/ban " .. id .. " " .. t .. " " .. m)
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha ID, Tempo e Motivo para banir."), -1)
                    end
                end)
                imgui.SameLine()
                botaoComTooltip("Kick", imgui.ImVec2(pW, 26), "Kickar: /kick [ID] [Motivo]", function()
                    local id = sanitizarEntrada(campoNickIDF.v)
                    local m = sanitizarEntrada(motivo.v)
                    if id ~= "" and validarMotivo(m) then
                        acaoPerigosa("KICKAR jogador " .. id .. " - " .. m, "/kick " .. id .. " " .. m)
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha ID e Motivo para kickar."), -1)
                    end
                end)

                botaoComTooltip("Ag. Ban", imgui.ImVec2(pW, 26), "Agendar ban: /agendarban [ID] [Motivo]", function()
                    local id = sanitizarEntrada(campoNickIDF.v)
                    local m = sanitizarEntrada(motivo.v)
                    if id ~= "" and validarMotivo(m) then
                        acaoPerigosa("AGENDAR BAN para " .. id, "/agendarban " .. id .. " " .. m)
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha ID e Motivo."), -1)
                    end
                end)
                imgui.SameLine()
                botaoComTooltip("Telagem", imgui.ImVec2(pW, 26), "Aplicar telagem: /telagem [ID] [Motivo]", function()
                    local id = sanitizarEntrada(campoNickIDF.v)
                    local m = sanitizarEntrada(motivo.v)
                    if id ~= "" and validarMotivo(m) then
                        acaoPerigosa("TELAR jogador " .. id, "/telagem " .. id .. " " .. m)
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha ID e Motivo."), -1)
                    end
                end)

                imgui.PopStyleColor(3)

                imgui.Spacing()

                -- PUNICOES MEDIAS (laranja)
                imgui.TextColored(imgui.ImVec4(0.9, 0.6, 0.1, 1), "Punicoes Moderadas")
                imgui.Spacing()
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45, 0.25, 0.05, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65, 0.35, 0.10, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.85, 0.45, 0.05, 1.0))

                botaoComTooltip("Cadeia", imgui.ImVec2(pW, 26), "Prender: /cadeia [ID] [Tempo] [Motivo]", function()
                    local id = sanitizarEntrada(campoNickIDF.v)
                    local t = sanitizarEntrada(tempo.v)
                    local m = sanitizarEntrada(motivo.v)
                    if id ~= "" and t ~= "" and validarMotivo(m) then
                        acaoPerigosa("PRENDER jogador " .. id, "/cadeia " .. id .. " " .. t .. " " .. m)
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha ID, Tempo e Motivo."), -1)
                    end
                end)
                imgui.SameLine()
                botaoComTooltip("Ag. Cadeia", imgui.ImVec2(pW, 26), "Agendar cadeia: /agendarcadeia [ID] [Tempo] [Avisos] [Motivo]", function()
                    local id = sanitizarEntrada(campoNickIDF.v)
                    local t = sanitizarEntrada(tempo.v)
                    local a = sanitizarEntrada(avisos.v)
                    local m = sanitizarEntrada(motivo.v)
                    if id ~= "" and t ~= "" and validarMotivo(m) then
                        acaoSom("/agendarcadeia " .. id .. " " .. t .. " " .. a .. " " .. m)
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha todos os campos obrigatorios."), -1)
                    end
                end)

                botaoComTooltip("Advertencia", imgui.ImVec2(pW, 26), "Dar advertencia: /adv [ID] [Motivo ADV]", function()
                    local id = sanitizarEntrada(campoNickIDF.v)
                    local a = sanitizarEntrada(adv.v)
                    if id ~= "" and a ~= "" then
                        acaoSom("/adv " .. id .. " " .. a)
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha ID e Motivo ADV."), -1)
                    end
                end)
                imgui.SameLine()
                botaoComTooltip("Rem. Advertencia", imgui.ImVec2(pW, 26), "Retirar advertencia: /retiraradv [ID] [Motivo ADV]", function()
                    local id = sanitizarEntrada(campoNickIDF.v)
                    local a = sanitizarEntrada(adv.v)
                    if id ~= "" and a ~= "" then
                        acaoSom("/retiraradv " .. id .. " " .. a)
                    else
                        sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha ID e Motivo ADV."), -1)
                    end
                end)

                imgui.PopStyleColor(3)

                imgui.Spacing()

                -- REMOCOES / DESBLOQUEIOS (verde)
                imgui.TextColored(imgui.ImVec4(0.2, 0.85, 0.3, 1), "Remocoes e Desbloqueios")
                imgui.Spacing()
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.08, 0.32, 0.12, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12, 0.48, 0.18, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.18, 0.65, 0.25, 1.0))

                botaoComTooltip("Desbanir Conta", imgui.ImVec2(pW, 26), "Desbanir conta: /desbanconta [ID]", function()
                    if campoNickIDF.v ~= "" then acaoSom("/desbanconta " .. sanitizarEntrada(campoNickIDF.v))
                    else sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha o ID/Nick."), -1) end
                end)
                imgui.SameLine()
                botaoComTooltip("Limpar Ban", imgui.ImVec2(pW, 26), "Limpar historico de ban: /limparban [ID]", function()
                    if campoNickIDF.v ~= "" then acaoSom("/limparban " .. sanitizarEntrada(campoNickIDF.v))
                    else sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha o ID/Nick."), -1) end
                end)

                botaoComTooltip("Limpar Cadeia", imgui.ImVec2(pW, 26), "Limpar historico de cadeia: /limparcadeia [ID]", function()
                    if campoNickIDF.v ~= "" then acaoSom("/limparcadeia " .. sanitizarEntrada(campoNickIDF.v))
                    else sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha o ID/Nick."), -1) end
                end)
                imgui.SameLine()
                botaoComTooltip("Rem. Telagem", imgui.ImVec2(pW, 26), "Remover telagem: /removertelagem [ID]", function()
                    if campoNickIDF.v ~= "" then acaoSom("/removertelagem " .. sanitizarEntrada(campoNickIDF.v))
                    else sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha o ID/Nick."), -1) end
                end)

                botaoComTooltip("Desbanir IP", imgui.ImVec2(pW, 26), "Desbanir IP: /desbanip [IP]", function()
                    local ip = sanitizarEntrada(campoIP.v)
                    if ip ~= "" then acaoSom("/desbanip " .. ip)
                    else sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha o campo IP."), -1) end
                end)
                imgui.SameLine()
                botaoComTooltip("Liberar IP", imgui.ImVec2(pW, 26), "Liberar IP: /liberarip [IP]", function()
                    local ip = sanitizarEntrada(campoIP.v)
                    if ip ~= "" then acaoSom("/liberarip " .. ip)
                    else sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Preencha o campo IP."), -1) end
                end)

                imgui.PopStyleColor(3)

            -- ==========================================
            -- ABA 4: SETAGEM
            -- ==========================================
            elseif abaAtual == 4 then
                tituloSecao("SETAGEM DE PRIVILEGIOS")

                -- Aviso se nenhum player selecionado
                if campoNickIDF.v == "" then
                    imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.15, 0.10, 0.02, 0.90))
                    imgui.BeginChild("AvisoSetagem", imgui.ImVec2(0, 28), true)
                        imgui.TextColored(imgui.ImVec4(1, 0.7, 0.2, 1), "  Selecione um player para aplicar setagens.")
                    imgui.EndChild()
                    imgui.PopStyleColor()
                    imgui.Spacing()
                end

                local sW = (imgui.GetContentRegionAvailWidth() - 10) / 2

                -- BOOSTER
                imgui.BeginChild("BoosterSection", imgui.ImVec2(0, 75), true)
                    imgui.TextColored(cT, "BOOSTER")
                    imgui.Separator()
                    imgui.Spacing()
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.08, 0.32, 0.12, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12, 0.48, 0.18, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.18, 0.65, 0.25, 1.0))
                    botaoComTooltip("Ativar Booster", imgui.ImVec2(sW, 30), "Conceder booster ao jogador", function()
                        verificarPlayerEExecutar("/setbooster " .. sanitizarEntrada(campoNickIDF.v) .. " 1")
                    end)
                    imgui.PopStyleColor(3)
                    imgui.SameLine()
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45, 0.10, 0.10, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65, 0.15, 0.15, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.85, 0.10, 0.10, 1.0))
                    botaoComTooltip("Remover Booster", imgui.ImVec2(sW, 30), "Retirar booster do jogador", function()
                        verificarPlayerEExecutar("/setbooster " .. sanitizarEntrada(campoNickIDF.v) .. " 0")
                    end)
                    imgui.PopStyleColor(3)
                imgui.EndChild()

                imgui.Spacing()

                -- YOUTUBER
                imgui.BeginChild("YTSection", imgui.ImVec2(0, 75), true)
                    imgui.TextColored(cT, "YOUTUBER")
                    imgui.Separator()
                    imgui.Spacing()
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.08, 0.32, 0.12, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.12, 0.48, 0.18, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.18, 0.65, 0.25, 1.0))
                    botaoComTooltip("Ativar YT", imgui.ImVec2(sW, 30), "Conceder cargo YouTuber", function()
                        verificarPlayerEExecutar("/setyt " .. sanitizarEntrada(campoNickIDF.v) .. " 1")
                    end)
                    imgui.PopStyleColor(3)
                    imgui.SameLine()
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.45, 0.10, 0.10, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65, 0.15, 0.15, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.85, 0.10, 0.10, 1.0))
                    botaoComTooltip("Remover YT", imgui.ImVec2(sW, 30), "Retirar cargo YouTuber", function()
                        verificarPlayerEExecutar("/setyt " .. sanitizarEntrada(campoNickIDF.v) .. " 0")
                    end)
                    imgui.PopStyleColor(3)
                imgui.EndChild()

            -- ==========================================
            -- ABA 5: LOG DE ACOES
            -- ==========================================
            elseif abaAtual == 5 then
                tituloSecao("HISTORICO DE ACOES DA SESSAO")

                if #logAcoes == 0 then
                    imgui.Spacing()
                    imgui.TextColored(imgui.ImVec4(0.4, 0.4, 0.4, 1), "Nenhuma acao registrada nesta sessao.")
                    imgui.Spacing()
                    imgui.TextColored(imgui.ImVec4(0.35, 0.35, 0.35, 1), "Todas as acoes executadas pelo painel serao registradas aqui")
                    imgui.TextColored(imgui.ImVec4(0.35, 0.35, 0.35, 1), "para controle e auditoria durante a sessao atual.")
                else
                    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1), string.format("Total: %d acoes registradas (max %d)", #logAcoes, MAX_LOG))
                    imgui.Spacing()

                    imgui.PushStyleColor(imgui.Col.ChildWindowBg, imgui.ImVec4(0.05, 0.05, 0.05, 0.95))
                    imgui.BeginChild("LogScroll", imgui.ImVec2(0, -35), true)
                    for _, entry in ipairs(logAcoes) do
                        imgui.TextColored(cT, "[" .. entry.hora .. "]")
                        imgui.SameLine()
                        imgui.Text(entry.texto)
                        imgui.Separator()
                    end
                    imgui.EndChild()
                    imgui.PopStyleColor()

                    imgui.Spacing()
                    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.35, 0.15, 0.15, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.5, 0.2, 0.2, 1.0))
                    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.7, 0.1, 0.1, 1.0))
                    if imgui.Button("Limpar Historico", imgui.ImVec2(-1, 26)) then
                        logAcoes = {}
                    end
                    imgui.PopStyleColor(3)
                end
            end

        imgui.EndChild()

        -- ==========================================
        -- MODAL DE CONFIRMACAO DE ACAO PERIGOSA
        -- ==========================================
        if mostrarConfirmacao and acaoPendente then
            imgui.SetNextWindowPos(
                imgui.ImVec2(mainWindowPos.x + mainWindowSize.x / 2 - 190, mainWindowPos.y + mainWindowSize.y / 2 - 80),
                imgui.Cond.Always
            )
            imgui.SetNextWindowSize(imgui.ImVec2(380, 160), imgui.Cond.Always)
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.08, 0.04, 0.04, 0.98))
            imgui.PushStyleColor(imgui.Col.TitleBgActive, imgui.ImVec4(0.55, 0.08, 0.08, 1.0))
            imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 8.0)

            if imgui.Begin("CONFIRMAR ACAO##modal", nil,
                imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then

                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(1, 0.8, 0.15, 1), "Tem certeza que deseja executar esta acao?")
                imgui.Spacing()
                imgui.TextColored(imgui.ImVec4(1, 0.4, 0.4, 1), acaoPendente)
                imgui.Spacing(); imgui.Spacing()

                local modalBtnW = (imgui.GetContentRegionAvailWidth() - 10) / 2

                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.55, 0.08, 0.08, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.75, 0.12, 0.12, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.9, 0.05, 0.05, 1.0))
                if imgui.Button("CONFIRMAR", imgui.ImVec2(modalBtnW, 30)) then
                    acaoSom(acaoComando)
                    mostrarConfirmacao = false
                    acaoPendente = nil
                    acaoComando = nil
                end
                imgui.PopStyleColor(3)

                imgui.SameLine()

                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.25, 0.25, 0.25, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.35, 0.35, 0.35, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.45, 0.45, 0.45, 1.0))
                if imgui.Button("CANCELAR", imgui.ImVec2(modalBtnW, 30)) then
                    mostrarConfirmacao = false
                    acaoPendente = nil
                    acaoComando = nil
                    sampAddChatMessage(u8("{FFFF00}[Painel] {FFFFFF}Acao cancelada pelo administrador."), -1)
                end
                imgui.PopStyleColor(3)

                imgui.End()
            end
            imgui.PopStyleVar()
            imgui.PopStyleColor(2)
        end

        imgui.End()
    end
end
