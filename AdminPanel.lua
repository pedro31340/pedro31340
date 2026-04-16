local imgui = require 'imgui'
local key = require 'vkeys'
local inicfg = require 'inicfg'

-- ==========================================
-- HOT-RELOAD: Auto-atualizacao do script
-- Detecta mudancas no arquivo e recarrega
-- automaticamente sem precisar relogar.
-- ==========================================

-- ==========================================
-- CONFIGURACAO DE ARQUIVO
-- ==========================================
local configFile = "AdminPanelConfig.ini"
local defConfig = {
    settings = {
        posX = 200, posY = 100,
        tamanhoX = 1000, tamanhoY = 650,
        somID = 1057,
        confirmarPunicao = true,
        cooldownCmd = 2
    }
}
local config = inicfg.load(defConfig, configFile) or defConfig

-- ==========================================
-- CORES DO TEMA (estilo dashboard escuro)
-- ==========================================
local CORES = {
    -- Fundo principal
    fundoPrincipal = imgui.ImVec4(0.11, 0.11, 0.11, 0.97),
    -- Sidebar
    sidebar = imgui.ImVec4(0.13, 0.13, 0.15, 1.00),
    sidebarItem = imgui.ImVec4(0.13, 0.13, 0.15, 0.00),
    sidebarItemHover = imgui.ImVec4(0.20, 0.20, 0.22, 1.00),
    sidebarAtivo = imgui.ImVec4(0.85, 0.30, 0.22, 1.00),
    -- Acento (vermelho/laranja)
    acento = imgui.ImVec4(0.85, 0.30, 0.22, 1.00),
    acentoHover = imgui.ImVec4(0.95, 0.40, 0.30, 1.00),
    acentoEscuro = imgui.ImVec4(0.65, 0.20, 0.15, 1.00),
    -- Cards
    cardFundo = imgui.ImVec4(0.16, 0.16, 0.18, 1.00),
    -- Texto
    textoBranco = imgui.ImVec4(1.00, 1.00, 1.00, 1.00),
    textoClaro = imgui.ImVec4(0.80, 0.80, 0.80, 1.00),
    textoEscuro = imgui.ImVec4(0.50, 0.50, 0.50, 1.00),
    textoVermelho = imgui.ImVec4(0.85, 0.30, 0.22, 1.00),
    -- Cores para cards de estatistica
    azul = imgui.ImVec4(0.20, 0.45, 0.85, 1.00),
    roxo = imgui.ImVec4(0.55, 0.25, 0.75, 1.00),
    verde = imgui.ImVec4(0.20, 0.75, 0.55, 1.00),
    vermelho = imgui.ImVec4(0.85, 0.25, 0.25, 1.00),
    laranja = imgui.ImVec4(0.85, 0.55, 0.20, 1.00),
    -- Inputs
    inputFundo = imgui.ImVec4(0.10, 0.10, 0.12, 1.00),
    -- Botao verde
    btnVerde = imgui.ImVec4(0.15, 0.55, 0.30, 1.00),
    btnVerdeHover = imgui.ImVec4(0.20, 0.65, 0.38, 1.00),
    -- Botao cinza
    btnCinza = imgui.ImVec4(0.25, 0.25, 0.28, 1.00),
    btnCinzaHover = imgui.ImVec4(0.35, 0.35, 0.38, 1.00),
    -- Indicador online
    pontoVerde = imgui.ImVec4(0.30, 0.85, 0.45, 1.00),
}

-- ==========================================
-- VARIAVEIS DE CONTROLE
-- ==========================================
local janela = imgui.ImBool(false)
local estadoAnterior = false
local travaF2 = false
local startTime = os.time()
local paginaAtual = 1
local selectedPlayer = -1

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

-- Posicao/tamanho da janela principal (para salvar config corretamente)
local mainWinPos = nil
local mainWinSize = nil

-- Hot-Reload: variaveis de controle (sempre ativo, automatico)
local hotReloadIntervalo = 3
local hotReloadUltimaVerificacao = 0
local hotReloadHashAnterior = nil

-- ==========================================
-- BUFFERS
-- ==========================================
local somSelecionado = imgui.ImInt(config.settings.somID)
local tempo = imgui.ImBuffer(16)
local motivo = imgui.ImBuffer(128)
local avisos = imgui.ImBuffer(16)
local adv = imgui.ImBuffer(16)
local campoIP = imgui.ImBuffer(64)
local pesquisa = imgui.ImBuffer(64)
local campoNickIDF = imgui.ImBuffer(64)

-- ==========================================
-- HOT-RELOAD: Funcoes de auto-atualizacao
-- ==========================================
function calcularHashArquivo(caminho)
    local arquivo = io.open(caminho, "rb")
    if not arquivo then return nil end
    local conteudo = arquivo:read("*a")
    arquivo:close()
    if not conteudo then return nil end
    local hash = 5381
    for i = 1, #conteudo do
        hash = ((hash * 33) + string.byte(conteudo, i)) % 2^32
    end
    return hash
end

function verificarHotReload()
    local agora = os.clock()
    if agora - hotReloadUltimaVerificacao < hotReloadIntervalo then return end
    hotReloadUltimaVerificacao = agora
    local caminhoScript = thisScript().path
    if not caminhoScript then return end
    local hashAtual = calcularHashArquivo(caminhoScript)
    if not hashAtual then return end
    if hotReloadHashAnterior == nil then
        hotReloadHashAnterior = hashAtual
        return
    end
    if hashAtual ~= hotReloadHashAnterior then
        sampAddChatMessage(u8("{FFFF00}[Painel Admin] {FFFFFF}Mudanca detectada! Recarregando..."), -1)
        addOneOffSound(0, 0, 0, 1057)
        wait(500)
        thisScript():reload()
    end
end

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

-- Desenha um card de estatistica com borda colorida no topo
function desenharCardEstatistica(label, valor, corBorda, largura)
    local drawList = imgui.GetWindowDrawList()
    local pos = imgui.GetCursorScreenPos()

    imgui.PushStyleColor(imgui.Col.ChildWindowBg, CORES.cardFundo)
    imgui.BeginChild("card_" .. label, imgui.ImVec2(largura, 65), true)
        drawList:AddRectFilled(
            imgui.ImVec2(pos.x, pos.y),
            imgui.ImVec2(pos.x + largura, pos.y + 3),
            imgui.GetColorU32(corBorda)
        )
        imgui.Spacing()
        imgui.Spacing()
        local iconPos = imgui.GetCursorScreenPos()
        drawList:AddRectFilled(
            imgui.ImVec2(iconPos.x + 4, iconPos.y),
            imgui.ImVec2(iconPos.x + 28, iconPos.y + 24),
            imgui.GetColorU32(corBorda),
            4.0
        )
        imgui.Dummy(imgui.ImVec2(34, 0))
        imgui.SameLine()
        imgui.BeginGroup()
            imgui.TextColored(CORES.textoEscuro, label)
            imgui.SetWindowFontScale(1.3)
            imgui.TextColored(CORES.textoBranco, tostring(valor))
            imgui.SetWindowFontScale(1.0)
        imgui.EndGroup()
        imgui.SameLine()
        local dotX = pos.x + largura - 18
        local dotY = pos.y + 32
        drawList:AddCircleFilled(imgui.ImVec2(dotX, dotY), 4, imgui.GetColorU32(CORES.pontoVerde))
    imgui.EndChild()
    imgui.PopStyleColor()
end

-- Botao do sidebar
function botaoSidebar(icone, texto, indice)
    local ativo = (paginaAtual == indice)
    local altura = 32

    if ativo then
        imgui.PushStyleColor(imgui.Col.Button, CORES.sidebarAtivo)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CORES.sidebarAtivo)
        imgui.PushStyleColor(imgui.Col.ButtonActive, CORES.sidebarAtivo)
    else
        imgui.PushStyleColor(imgui.Col.Button, CORES.sidebarItem)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, CORES.sidebarItemHover)
        imgui.PushStyleColor(imgui.Col.ButtonActive, CORES.sidebarItemHover)
    end

    imgui.PushStyleVar(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.0, 0.5))
    local clicou = imgui.Button(icone .. "  " .. texto .. "##sidebar" .. indice, imgui.ImVec2(-1, altura))
    imgui.PopStyleVar()
    imgui.PopStyleColor(3)

    if clicou then
        paginaAtual = indice
    end
end

-- Botao estilizado (acento vermelho)
function botaoAcento(label, tamanho, callback)
    imgui.PushStyleColor(imgui.Col.Button, CORES.acento)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, CORES.acentoHover)
    imgui.PushStyleColor(imgui.Col.ButtonActive, CORES.acentoEscuro)
    if imgui.Button(label, tamanho) then
        callback()
    end
    imgui.PopStyleColor(3)
end

-- Botao estilizado (cinza)
function botaoCinza(label, tamanho, callback)
    imgui.PushStyleColor(imgui.Col.Button, CORES.btnCinza)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, CORES.btnCinzaHover)
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.40, 0.40, 0.44, 1.00))
    if imgui.Button(label, tamanho) then
        callback()
    end
    imgui.PopStyleColor(3)
end

-- Botao verde
function botaoVerde(label, tamanho, callback)
    imgui.PushStyleColor(imgui.Col.Button, CORES.btnVerde)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, CORES.btnVerdeHover)
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.10, 0.45, 0.25, 1.00))
    if imgui.Button(label, tamanho) then
        callback()
    end
    imgui.PopStyleColor(3)
end

-- Secao titulo simples
function tituloSecao(texto)
    imgui.Spacing()
    imgui.SetWindowFontScale(1.1)
    imgui.TextColored(CORES.textoBranco, texto)
    imgui.SetWindowFontScale(1.0)
    imgui.Spacing()
end

-- ==========================================
-- FUNCAO PRINCIPAL
-- ==========================================
function main()
    if not isSampLoaded() or not isSampAvailable() then repeat wait(100) until isSampAvailable() end
    sampRegisterChatCommand("admin", function() janela.v = not janela.v end)

    sampAddChatMessage(u8("{00FF00}[Painel Admin] {FFFFFF}Carregado! Auto-atualizacao ativa - salve o arquivo e ele recarrega sozinho."), -1)

    while true do
        wait(0)
        verificarHotReload()

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
-- ESTILO VISUAL - DASHBOARD ESCURO
-- ==========================================
function aplicarEstilo()
    local style = imgui.GetStyle()
    style.WindowRounding = 10.0
    style.FrameRounding = 6.0
    style.ChildWindowRounding = 8.0
    style.ScrollbarRounding = 6.0
    style.GrabRounding = 4.0
    style.ScrollbarSize = 6.0
    style.ItemSpacing = imgui.ImVec2(8, 6)
    style.ItemInnerSpacing = imgui.ImVec2(6, 4)
    style.WindowPadding = imgui.ImVec2(0, 0)
    style.FramePadding = imgui.ImVec2(8, 5)

    local col = style.Colors

    col[imgui.Col.WindowBg] = CORES.fundoPrincipal
    col[imgui.Col.ChildWindowBg] = imgui.ImVec4(0.12, 0.12, 0.14, 0.00)
    col[imgui.Col.PopupBg] = imgui.ImVec4(0.14, 0.14, 0.16, 0.98)
    col[imgui.Col.Text] = CORES.textoBranco
    col[imgui.Col.TextDisabled] = CORES.textoEscuro
    col[imgui.Col.TitleBg] = imgui.ImVec4(0.10, 0.10, 0.12, 1.00)
    col[imgui.Col.TitleBgActive] = imgui.ImVec4(0.10, 0.10, 0.12, 1.00)
    col[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.10, 0.10, 0.12, 0.75)
    col[imgui.Col.Button] = CORES.btnCinza
    col[imgui.Col.ButtonHovered] = CORES.btnCinzaHover
    col[imgui.Col.ButtonActive] = imgui.ImVec4(0.40, 0.40, 0.44, 1.00)
    col[imgui.Col.FrameBg] = CORES.inputFundo
    col[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.14, 0.14, 0.16, 1.00)
    col[imgui.Col.FrameBgActive] = imgui.ImVec4(0.18, 0.18, 0.20, 1.00)
    col[imgui.Col.CloseButton] = imgui.ImVec4(1.0, 1.0, 1.0, 0.10)
    col[imgui.Col.CloseButtonHovered] = imgui.ImVec4(0.85, 0.30, 0.22, 0.80)
    col[imgui.Col.CloseButtonActive] = imgui.ImVec4(1.0, 0.0, 0.0, 1.00)
    col[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.85, 0.30, 0.22, 0.50)
    col[imgui.Col.Header] = imgui.ImVec4(0.20, 0.20, 0.22, 0.60)
    col[imgui.Col.HeaderHovered] = imgui.ImVec4(0.25, 0.25, 0.28, 0.80)
    col[imgui.Col.HeaderActive] = CORES.acento
    col[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.05, 0.05, 0.06, 0.40)
    col[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.30, 0.30, 0.33, 0.60)
    col[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.40, 0.40, 0.44, 0.80)
    col[imgui.Col.ScrollbarGrabActive] = CORES.acento
    col[imgui.Col.Separator] = imgui.ImVec4(0.25, 0.25, 0.28, 0.50)
    col[imgui.Col.SeparatorHovered] = CORES.acento
    col[imgui.Col.SeparatorActive] = CORES.acento
    col[imgui.Col.CheckMark] = CORES.acento
    col[imgui.Col.SliderGrab] = imgui.ImVec4(0.50, 0.50, 0.55, 0.80)
    col[imgui.Col.SliderGrabActive] = CORES.acento
end

-- ==========================================
-- PAGINA: INICIO (Dashboard)
-- ==========================================
function desenharPaginaInicio()
    local availW = imgui.GetContentRegionAvailWidth()

    imgui.SetWindowFontScale(1.4)
    imgui.TextColored(CORES.textoBranco, u8("Pagina (Inicio)"))
    imgui.SetWindowFontScale(1.0)
    imgui.Spacing()

    imgui.SetWindowFontScale(1.1)
    imgui.Text("Bem-vindo, ")
    imgui.SameLine(0, 0)
    imgui.TextColored(CORES.textoVermelho, sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(playerPed)) or 0) or "Admin")
    imgui.SetWindowFontScale(1.0)
    imgui.TextColored(CORES.textoEscuro, u8("Este e o painel administrador. Voce tem acesso as informacoes do servidor."))
    imgui.Spacing()
    imgui.Spacing()

    -- Cards de estatisticas - Linha 1
    local cardW = (availW - 24) / 4
    desenharCardEstatistica("Players", contarPlayersOnline(), CORES.azul, cardW)
    imgui.SameLine(0, 8)
    desenharCardEstatistica("Staff", 0, CORES.roxo, cardW)
    imgui.SameLine(0, 8)
    desenharCardEstatistica("Presos", 0, CORES.verde, cardW)
    imgui.SameLine(0, 8)
    desenharCardEstatistica("Reportados", 0, CORES.vermelho, cardW)

    imgui.Spacing()

    -- Cards de estatisticas - Linha 2
    local uptime = os.time() - startTime
    local upH = math.floor(uptime / 3600)
    local upM = math.floor((uptime % 3600) / 60)
    desenharCardEstatistica("Sessao", string.format("%02d:%02d", upH, upM), CORES.laranja, cardW)
    imgui.SameLine(0, 8)
    desenharCardEstatistica("Hora", os.date("%H:%M"), CORES.roxo, cardW)

    imgui.Spacing()
    imgui.Spacing()

    -- Duas colunas: Logs e Info
    imgui.Columns(2, "logInfo", false)
    imgui.SetColumnWidth(0, availW * 0.65)

    tituloSecao("Logs Painel")
    imgui.PushStyleColor(imgui.Col.ChildWindowBg, CORES.cardFundo)
    imgui.BeginChild("LogsPanel", imgui.ImVec2(-8, 200), true)
        if #logAcoes == 0 then
            imgui.Spacing()
            imgui.TextColored(CORES.textoEscuro, "  Nenhuma acao registrada nesta sessao.")
        else
            for i, log in ipairs(logAcoes) do
                imgui.Spacing()
                local iconPos = imgui.GetCursorScreenPos()
                local dl = imgui.GetWindowDrawList()
                dl:AddRectFilled(
                    imgui.ImVec2(iconPos.x + 4, iconPos.y + 2),
                    imgui.ImVec2(iconPos.x + 22, iconPos.y + 18),
                    imgui.GetColorU32(CORES.azul),
                    3.0
                )
                imgui.Dummy(imgui.ImVec2(28, 0))
                imgui.SameLine()
                imgui.TextColored(CORES.textoBranco, log.texto)
                local horaW = imgui.CalcTextSize(log.hora).x
                imgui.SameLine(imgui.GetContentRegionAvailWidth() - horaW)
                imgui.TextColored(CORES.textoEscuro, log.hora)
                if i < #logAcoes then
                    imgui.Separator()
                end
            end
        end
    imgui.EndChild()
    imgui.PopStyleColor()

    imgui.NextColumn()

    tituloSecao("Info")
    imgui.PushStyleColor(imgui.Col.ChildWindowBg, CORES.cardFundo)
    imgui.BeginChild("InfoPanel", imgui.ImVec2(0, 200), true)
        imgui.Spacing()
        imgui.TextColored(CORES.textoEscuro, "  Data:")
        imgui.TextColored(CORES.textoBranco, "  " .. os.date("%d/%m/%Y") .. " (" .. getSemana() .. ")")
        imgui.Spacing()
        imgui.TextColored(CORES.textoEscuro, "  Hora:")
        imgui.TextColored(CORES.textoBranco, "  " .. os.date("%H:%M:%S"))
        imgui.Spacing()
        imgui.TextColored(CORES.textoEscuro, "  Uptime:")
        local upS = uptime % 60
        imgui.TextColored(CORES.textoBranco, string.format("  %02d:%02d:%02d", upH, upM, upS))
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        imgui.TextColored(CORES.textoEscuro, "  Hot-Reload:")
        imgui.TextColored(CORES.pontoVerde, "  Ativo")
    imgui.EndChild()
    imgui.PopStyleColor()

    imgui.Columns(1)
end

-- ==========================================
-- PAGINA: JOGADORES
-- ==========================================
function desenharPaginaJogadores()
    imgui.SetWindowFontScale(1.4)
    imgui.TextColored(CORES.textoBranco, "Jogadores Online")
    imgui.SetWindowFontScale(1.0)
    imgui.Spacing()

    imgui.TextColored(CORES.textoEscuro, "Buscar:")
    imgui.SameLine()
    imgui.PushItemWidth(250)
    imgui.InputText("##searchJogadores", pesquisa)
    imgui.PopItemWidth()
    imgui.Spacing()

    imgui.PushStyleColor(imgui.Col.ChildWindowBg, CORES.cardFundo)
    imgui.BeginChild("ListaJogadores", imgui.ImVec2(0, -1), true)
        imgui.Columns(4, "jogadoresHeader", true)
        imgui.SetColumnWidth(0, 60)
        imgui.SetColumnWidth(1, 200)
        imgui.SetColumnWidth(2, 80)
        imgui.TextColored(CORES.textoEscuro, "ID")
        imgui.NextColumn()
        imgui.TextColored(CORES.textoEscuro, "Nome")
        imgui.NextColumn()
        imgui.TextColored(CORES.textoEscuro, "Score")
        imgui.NextColumn()
        imgui.TextColored(CORES.textoEscuro, "Ping")
        imgui.Columns(1)
        imgui.Separator()

        for i = 0, 1000 do
            if sampIsPlayerConnected(i) then
                local nick = sampGetPlayerNickname(i)
                local searchTerm = pesquisa.v:lower()
                if searchTerm == "" or nick:lower():find(searchTerm, 1, true) or tostring(i):find(searchTerm, 1, true) then
                    local isSelected = selectedPlayer == i
                    imgui.Columns(4, "jogadoresRow" .. i, true)
                    imgui.SetColumnWidth(0, 60)
                    imgui.SetColumnWidth(1, 200)
                    imgui.SetColumnWidth(2, 80)

                    if isSelected then
                        imgui.TextColored(CORES.acento, tostring(i))
                    else
                        imgui.Text(tostring(i))
                    end
                    imgui.NextColumn()

                    if imgui.Selectable(nick .. "##player" .. i, isSelected, imgui.SelectableFlags.SpanAllColumns) then
                        selectedPlayer = i
                        campoNickIDF.v = tostring(i)
                    end
                    imgui.NextColumn()
                    imgui.Text(tostring(sampGetPlayerScore(i)))
                    imgui.NextColumn()
                    imgui.Text(tostring(sampGetPlayerPing(i)) .. "ms")
                    imgui.Columns(1)
                end
            end
        end
    imgui.EndChild()
    imgui.PopStyleColor()
end

-- ==========================================
-- PAGINA: GERENCIAR
-- ==========================================
function desenharPaginaGerenciar()
    local availW = imgui.GetContentRegionAvailWidth()
    local bW = (availW - 24) / 3
    local bH = 34

    imgui.SetWindowFontScale(1.4)
    imgui.TextColored(CORES.textoBranco, "Gerenciamento")
    imgui.SetWindowFontScale(1.0)
    imgui.Spacing()
    imgui.TextColored(CORES.textoEscuro, "Comandos administrativos do servidor.")
    imgui.Spacing()
    imgui.Spacing()

    tituloSecao("Administracao")
    botaoAcento("Modo Admin##g1", imgui.ImVec2(bW, bH), function() acaoSom("/tra") end)
    imgui.SameLine(0, 8)
    botaoAcento("Fila##g2", imgui.ImVec2(bW, bH), function() acaoSom("/fila") end)
    imgui.SameLine(0, 8)
    botaoAcento("Reports##g3", imgui.ImVec2(bW, bH), function() acaoSom("/reportados") end)
    imgui.Spacing()
    botaoCinza("Voar##g4", imgui.ImVec2(bW, bH), function() acaoSom("/voaron") end)
    imgui.SameLine(0, 8)
    botaoCinza("Staffs Online##g5", imgui.ImVec2(bW, bH), function() acaoSom("/admins") end)
    imgui.SameLine(0, 8)
    botaoCinza("Finalizar Att##g6", imgui.ImVec2(bW, bH), function() acaoSom("/fimatt") end)
    imgui.Spacing()
    botaoCinza("Ver Presos##g7", imgui.ImVec2(bW, bH), function() acaoSom("/presos") end)
    imgui.SameLine(0, 8)
    botaoCinza("Trocar Modo##g8", imgui.ImVec2(bW, bH), function() acaoSom("/trocarmodo") end)
    imgui.SameLine(0, 8)
    botaoCinza("Reconectar##g9", imgui.ImVec2(bW, bH), function() acaoSom("/connect") end)
    imgui.Spacing()
    imgui.Spacing()

    tituloSecao("Servidor")
    botaoCinza("Fix Caixas##s1", imgui.ImVec2(bW, bH), function() acaoSom("/consertarcaixas") end)
    imgui.SameLine(0, 8)
    botaoCinza("Att Ranking##s2", imgui.ImVec2(bW, bH), function() acaoSom("/atualizarrank") end)
    imgui.SameLine(0, 8)
    botaoCinza("Iniciar Guerra##s3", imgui.ImVec2(bW, bH), function() acaoSom("/guerramorro") end)
    imgui.Spacing()
    botaoCinza("Reset Veiculos##s4", imgui.ImVec2(bW, bH), function() acaoSom("/dc") end)
    imgui.SameLine(0, 8)
    botaoCinza("Limpar Chat##s5", imgui.ImVec2(bW, bH), function()
        if validarMotivo(motivo.v) then
            acaoSom("/lc " .. sanitizarEntrada(motivo.v))
        else
            sampAddChatMessage(u8("{FF0000}[Painel] {FFFFFF}Informe um motivo valido (min 3 chars)."), -1)
        end
    end)
    imgui.Spacing()
    imgui.Spacing()

    tituloSecao("Interacao com Player")
    if campoNickIDF.v == "" then
        imgui.TextColored(CORES.laranja, "Selecione um jogador na aba Jogadores primeiro.")
        imgui.Spacing()
    else
        imgui.TextColored(CORES.textoEscuro, "Alvo: ")
        imgui.SameLine()
        imgui.TextColored(CORES.acento, campoNickIDF.v)
        imgui.Spacing()
    end

    local iW = (availW - 32) / 4
    botaoCinza("Ir##i1", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/ir " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.SameLine(0, 8)
    botaoCinza("Trazer##i2", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/tr " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.SameLine(0, 8)
    botaoCinza("Espiar##i3", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/tv " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.SameLine(0, 8)
    botaoCinza("Parar Espiar##i4", imgui.ImVec2(iW, bH), function() acaoSom("/tvoff") end)
    imgui.Spacing()
    botaoCinza("Segurar##i5", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/segurar " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.SameLine(0, 8)
    botaoCinza("Largar##i6", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/largar " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.SameLine(0, 8)
    botaoCinza("Congelar##i7", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/congelar " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.SameLine(0, 8)
    botaoCinza("Descongelar##i8", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/descongelar " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.Spacing()
    botaoAcento("Matar##i9", imgui.ImVec2(iW, bH), function()
        acaoPerigosa("Matar jogador " .. campoNickIDF.v, "/killplayer " .. sanitizarEntrada(campoNickIDF.v))
    end)
    imgui.SameLine(0, 8)
    botaoAcento("Explodir##i10", imgui.ImVec2(iW, bH), function()
        acaoPerigosa("Explodir jogador " .. campoNickIDF.v, "/explodir " .. sanitizarEntrada(campoNickIDF.v))
    end)
    imgui.SameLine(0, 8)
    botaoCinza("Tapa##i11", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/tapa " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.SameLine(0, 8)
    botaoCinza("Forcar Spawn##i12", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/spawnarplayer " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.Spacing()
    botaoCinza("Soltar##i13", imgui.ImVec2(iW, bH), function()
        verificarPlayerEExecutar("/soltar " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(motivo.v),
            {{nome = "Motivo", valor = motivo.v}})
    end)
    imgui.SameLine(0, 8)
    botaoCinza("Ret. Arma##i14", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/rarma " .. sanitizarEntrada(campoNickIDF.v)) end)
    imgui.SameLine(0, 8)
    botaoCinza("Ret. Armas Todos##i15", imgui.ImVec2(iW, bH), function() acaoSom("/rarmast") end)
    imgui.SameLine(0, 8)
    botaoVerde("Reviver##i16", imgui.ImVec2(iW, bH), function() verificarPlayerEExecutar("/god " .. sanitizarEntrada(campoNickIDF.v)) end)
end

-- ==========================================
-- PAGINA: PUNICOES
-- ==========================================
function desenharPaginaPunicoes()
    local availW = imgui.GetContentRegionAvailWidth()

    imgui.SetWindowFontScale(1.4)
    imgui.TextColored(CORES.textoBranco, u8("Punicoes"))
    imgui.SetWindowFontScale(1.0)
    imgui.Spacing()
    imgui.TextColored(CORES.textoEscuro, u8("Gerencie punicoes e acessos dos jogadores."))
    imgui.Spacing()
    imgui.Spacing()

    imgui.Columns(2, "punicoesLayout", false)
    imgui.SetColumnWidth(0, 300)

    -- Campos de entrada
    imgui.PushStyleColor(imgui.Col.ChildWindowBg, CORES.cardFundo)
    imgui.BeginChild("CamposPunicao", imgui.ImVec2(-8, 280), true)
        imgui.Spacing()
        tituloSecao("Dados da Punicao")

        imgui.Text("  ID/Nick:")
        imgui.SameLine(100)
        imgui.PushItemWidth(-12)
        imgui.InputText("##pn", campoNickIDF)
        imgui.PopItemWidth()

        imgui.Spacing()
        imgui.Text("  Motivo:")
        imgui.SameLine(100)
        imgui.PushItemWidth(-12)
        imgui.InputText("##pm", motivo)
        imgui.PopItemWidth()

        imgui.Spacing()
        imgui.Text("  Tempo:")
        imgui.SameLine(100)
        imgui.PushItemWidth(-12)
        imgui.InputText("##pt", tempo)
        imgui.PopItemWidth()

        imgui.Spacing()
        imgui.Text("  Avisos:")
        imgui.SameLine(100)
        imgui.PushItemWidth(-12)
        imgui.InputText("##pav", avisos)
        imgui.PopItemWidth()

        imgui.Spacing()
        imgui.Text("  ADV:")
        imgui.SameLine(100)
        imgui.PushItemWidth(-12)
        imgui.InputText("##padv", adv)
        imgui.PopItemWidth()

        imgui.Spacing()
        imgui.Text("  IP:")
        imgui.SameLine(100)
        imgui.PushItemWidth(-12)
        imgui.InputText("##pip", campoIP)
        imgui.PopItemWidth()

        imgui.Spacing()
        if campoNickIDF.v ~= "" then
            imgui.TextColored(CORES.pontoVerde, "  [OK] ID/Nick preenchido")
        else
            imgui.TextColored(CORES.vermelho, "  [--] ID/Nick vazio")
        end
    imgui.EndChild()
    imgui.PopStyleColor()

    imgui.NextColumn()

    local pW = (imgui.GetColumnWidth() - 16) / 2
    local pH = 32

    -- Punicoes Graves (vermelho)
    tituloSecao("Graves")
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.55, 0.12, 0.12, 1.00))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.70, 0.18, 0.18, 1.00))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.85, 0.10, 0.10, 1.00))
    if imgui.Button("Ban##p1", imgui.ImVec2(pW, pH)) then
        acaoPerigosa("BAN: " .. campoNickIDF.v, "/ban " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(tempo.v) .. " " .. sanitizarEntrada(motivo.v))
    end
    imgui.SameLine(0, 8)
    if imgui.Button("Kick##p2", imgui.ImVec2(pW, pH)) then
        acaoPerigosa("KICK: " .. campoNickIDF.v, "/kick " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(motivo.v))
    end
    imgui.Spacing()
    if imgui.Button("Ag. Ban##p3", imgui.ImVec2(pW, pH)) then
        acaoPerigosa("AG.BAN: " .. campoNickIDF.v, "/agendarban " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(motivo.v))
    end
    imgui.SameLine(0, 8)
    if imgui.Button("Telagem##p4", imgui.ImVec2(pW, pH)) then
        acaoPerigosa("TELAGEM: " .. campoNickIDF.v, "/telagem " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(motivo.v))
    end
    imgui.PopStyleColor(3)
    imgui.Spacing()

    -- Punicoes Medias (laranja)
    tituloSecao("Moderadas")
    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.50, 0.30, 0.08, 1.00))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.65, 0.38, 0.12, 1.00))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.80, 0.45, 0.10, 1.00))
    if imgui.Button("Cadeia##p5", imgui.ImVec2(pW, pH)) then
        acaoSom("/cadeia " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(tempo.v) .. " " .. sanitizarEntrada(motivo.v))
    end
    imgui.SameLine(0, 8)
    if imgui.Button("Ag. Cad##p6", imgui.ImVec2(pW, pH)) then
        acaoSom("/agendarcadeia " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(tempo.v) .. " " .. sanitizarEntrada(avisos.v) .. " " .. sanitizarEntrada(motivo.v))
    end
    imgui.Spacing()
    if imgui.Button("ADV##p7", imgui.ImVec2(pW, pH)) then
        acaoSom("/adv " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(adv.v))
    end
    imgui.SameLine(0, 8)
    if imgui.Button("Rem. Tela##p8", imgui.ImVec2(pW, pH)) then
        acaoSom("/removertelagem " .. sanitizarEntrada(campoNickIDF.v))
    end
    imgui.PopStyleColor(3)
    imgui.Spacing()

    -- Remocoes (verde)
    tituloSecao("Remocoes")
    imgui.PushStyleColor(imgui.Col.Button, CORES.btnVerde)
    imgui.PushStyleColor(imgui.Col.ButtonHovered, CORES.btnVerdeHover)
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.10, 0.45, 0.25, 1.00))
    if imgui.Button("Desban##p9", imgui.ImVec2(pW, pH)) then
        acaoSom("/desbanconta " .. sanitizarEntrada(campoNickIDF.v))
    end
    imgui.SameLine(0, 8)
    if imgui.Button("Limp. Ban##p10", imgui.ImVec2(pW, pH)) then
        acaoSom("/limparban " .. sanitizarEntrada(campoNickIDF.v))
    end
    imgui.Spacing()
    if imgui.Button("Limp. Cad##p11", imgui.ImVec2(pW, pH)) then
        acaoSom("/limparcadeia " .. sanitizarEntrada(campoNickIDF.v))
    end
    imgui.SameLine(0, 8)
    if imgui.Button("Rem. ADV##p12", imgui.ImVec2(pW, pH)) then
        acaoSom("/retiraradv " .. sanitizarEntrada(campoNickIDF.v) .. " " .. sanitizarEntrada(adv.v))
    end
    imgui.Spacing()
    if imgui.Button("Desb. IP##p13", imgui.ImVec2(pW, pH)) then
        acaoSom("/desbanip " .. sanitizarEntrada(campoIP.v))
    end
    imgui.SameLine(0, 8)
    if imgui.Button("Liberar IP##p14", imgui.ImVec2(pW, pH)) then
        acaoSom("/liberarip " .. sanitizarEntrada(campoIP.v))
    end
    imgui.PopStyleColor(3)

    imgui.Columns(1)
end

-- ==========================================
-- PAGINA: COMANDOS (Setagem + Extras)
-- ==========================================
function desenharPaginaComandos()
    local availW = imgui.GetContentRegionAvailWidth()
    local bW = (availW - 24) / 3
    local bH = 34

    imgui.SetWindowFontScale(1.4)
    imgui.TextColored(CORES.textoBranco, "Comandos")
    imgui.SetWindowFontScale(1.0)
    imgui.Spacing()
    imgui.TextColored(CORES.textoEscuro, "Setagem e comandos extras.")
    imgui.Spacing()
    imgui.Spacing()

    if campoNickIDF.v == "" then
        imgui.TextColored(CORES.laranja, "Selecione um jogador na aba Jogadores primeiro.")
        imgui.Spacing()
    else
        imgui.TextColored(CORES.textoEscuro, "Alvo: ")
        imgui.SameLine()
        imgui.TextColored(CORES.acento, campoNickIDF.v)
        imgui.Spacing()
    end

    tituloSecao("Setagem")
    botaoVerde("Set. Booster##c1", imgui.ImVec2(bW, bH), function() acaoSom("/setbooster " .. sanitizarEntrada(campoNickIDF.v) .. " 1") end)
    imgui.SameLine(0, 8)
    botaoAcento("Ret. Booster##c2", imgui.ImVec2(bW, bH), function() acaoSom("/setbooster " .. sanitizarEntrada(campoNickIDF.v) .. " 0") end)
    imgui.SameLine(0, 8)
    botaoVerde("Set. YT##c3", imgui.ImVec2(bW, bH), function() acaoSom("/setyt " .. sanitizarEntrada(campoNickIDF.v) .. " 1") end)
    imgui.Spacing()
    botaoAcento("Ret. YT##c4", imgui.ImVec2(bW, bH), function() acaoSom("/setyt " .. sanitizarEntrada(campoNickIDF.v) .. " 0") end)
    imgui.Spacing()
    imgui.Spacing()

    tituloSecao("Utilitarios")
    botaoCinza("Limpar Todos os Campos##util1", imgui.ImVec2(availW * 0.5, bH), function()
        tempo.v = ""; motivo.v = ""; avisos.v = ""; adv.v = ""
        campoIP.v = ""; campoNickIDF.v = ""; pesquisa.v = ""
        selectedPlayer = -1
    end)
end

-- ==========================================
-- PAGINA: APARENCIA (Configuracoes)
-- ==========================================
function desenharPaginaAparencia()
    imgui.SetWindowFontScale(1.4)
    imgui.TextColored(CORES.textoBranco, u8("Aparencia"))
    imgui.SetWindowFontScale(1.0)
    imgui.Spacing()
    imgui.TextColored(CORES.textoEscuro, u8("Personalize o painel."))
    imgui.Spacing()
    imgui.Spacing()

    imgui.PushStyleColor(imgui.Col.ChildWindowBg, CORES.cardFundo)
    imgui.BeginChild("ConfigPanel", imgui.ImVec2(0, 200), true)
        imgui.Spacing()
        imgui.Text("  Som de Notificacao:")
        imgui.SameLine(200)
        imgui.PushItemWidth(120)
        if imgui.InputInt("##idSom", somSelecionado) then addOneOffSound(0, 0, 0, somSelecionado.v) end
        imgui.PopItemWidth()
        imgui.Spacing()
        imgui.Spacing()
        imgui.Text("  ")
        imgui.SameLine()
        imgui.Checkbox("Confirmar acoes perigosas (Ban/Kick/Matar)", confirmarAcao)
        imgui.Spacing()
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()
        botaoAcento("  Salvar Configuracoes  ##save", imgui.ImVec2(-1, 36), function()
            config.settings = {
                posX = mainWinPos and mainWinPos.x or config.settings.posX,
                posY = mainWinPos and mainWinPos.y or config.settings.posY,
                tamanhoX = mainWinSize and mainWinSize.x or config.settings.tamanhoX,
                tamanhoY = mainWinSize and mainWinSize.y or config.settings.tamanhoY,
                somID = somSelecionado.v,
                confirmarPunicao = confirmarAcao.v,
                cooldownCmd = cooldownSegundos
            }
            inicfg.save(config, configFile)
            sampAddChatMessage(u8("{FFFF00}[Painel Admin] {FFFFFF}Configuracoes salvas com sucesso!"), -1)
            acaoSom()
        end)
    imgui.EndChild()
    imgui.PopStyleColor()

    imgui.Spacing()
    imgui.Spacing()

    imgui.PushStyleColor(imgui.Col.ChildWindowBg, CORES.cardFundo)
    imgui.BeginChild("InfoPainel", imgui.ImVec2(0, 80), true)
        imgui.Spacing()
        imgui.TextColored(CORES.textoEscuro, "  Painel Admin - Arcade PVP")
        imgui.TextColored(CORES.textoEscuro, "  Auto-atualizacao: Ativa (salve o arquivo .lua e ele recarrega)")
        imgui.TextColored(CORES.textoEscuro, "  Teclas: F2 ou /admin para abrir")
    imgui.EndChild()
    imgui.PopStyleColor()
end

-- ==========================================
-- PAINEL PRINCIPAL - DRAW FRAME
-- ==========================================
function imgui.OnDrawFrame()
    if not janela.v then return end
    aplicarEstilo()

    imgui.SetNextWindowPos(imgui.ImVec2(config.settings.posX, config.settings.posY), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(config.settings.tamanhoX, config.settings.tamanhoY), imgui.Cond.FirstUseEver)

    imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
    if imgui.Begin("##PainelAdmin", janela, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoScrollbar) then
        imgui.PopStyleVar()
        local mainWindowPos = imgui.GetWindowPos()
        local mainWindowSize = imgui.GetWindowSize()
        mainWinPos = mainWindowPos
        mainWinSize = mainWindowSize
        local sidebarWidth = 200

        -- ==========================================
        -- SIDEBAR ESQUERDA
        -- ==========================================
        imgui.PushStyleColor(imgui.Col.ChildWindowBg, CORES.sidebar)
        imgui.BeginChild("Sidebar", imgui.ImVec2(sidebarWidth, -1), false)
            imgui.Spacing()
            imgui.Spacing()
            imgui.SetCursorPosX(15)
            imgui.SetWindowFontScale(1.2)
            imgui.TextColored(CORES.acento, ">>")
            imgui.SameLine(0, 8)
            imgui.TextColored(CORES.textoBranco, "Painel Admin")
            imgui.SetWindowFontScale(1.0)

            imgui.SetCursorPosX(15)
            imgui.TextColored(CORES.textoEscuro, "Controle do servidor")
            imgui.Spacing()
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            imgui.Spacing()

            imgui.SetCursorPosX(8)
            imgui.BeginGroup()
                botaoSidebar(">>", u8("Pagina Inicial"), 1)
                imgui.Spacing()
                botaoSidebar(">>", "Jogadores", 2)
                imgui.Spacing()
                botaoSidebar(">>", "Gerenciar", 3)
                imgui.Spacing()
                botaoSidebar(">>", u8("Punicoes"), 4)
                imgui.Spacing()
                botaoSidebar(">>", "Comandos", 5)
                imgui.Spacing()
                botaoSidebar(">>", u8("Aparencia"), 6)
            imgui.EndGroup()

            imgui.Spacing()
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            imgui.SetCursorPosX(8)
            imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0, 0, 0))
            imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.55, 0.12, 0.12, 0.50))
            imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.55, 0.12, 0.12, 0.80))
            imgui.PushStyleVar(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.0, 0.5))
            if imgui.Button(">>  Sair##fechar", imgui.ImVec2(-1, 30)) then
                janela.v = false
            end
            imgui.PopStyleVar()
            imgui.PopStyleColor(3)

        imgui.EndChild()
        imgui.PopStyleColor()

        imgui.SameLine()

        -- ==========================================
        -- AREA PRINCIPAL (direita)
        -- ==========================================
        imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(16, 12))
        imgui.BeginChild("MainContent", imgui.ImVec2(0, -1), false)

            -- Top bar com hora
            local topAvailW = imgui.GetContentRegionAvailWidth()
            local horaStr = os.date("%H:%M")
            local horaW = imgui.CalcTextSize(horaStr).x
            imgui.SetCursorPosX(topAvailW - horaW - 10)
            imgui.TextColored(CORES.textoEscuro, horaStr)
            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            imgui.Spacing()

            -- Conteudo da pagina
            if paginaAtual == 1 then
                desenharPaginaInicio()
            elseif paginaAtual == 2 then
                desenharPaginaJogadores()
            elseif paginaAtual == 3 then
                desenharPaginaGerenciar()
            elseif paginaAtual == 4 then
                desenharPaginaPunicoes()
            elseif paginaAtual == 5 then
                desenharPaginaComandos()
            elseif paginaAtual == 6 then
                desenharPaginaAparencia()
            end

        imgui.EndChild()
        imgui.PopStyleVar()

        -- ==========================================
        -- MODAL DE CONFIRMACAO
        -- ==========================================
        if mostrarConfirmacao and acaoPendente then
            local modalW, modalH = 400, 170
            local mX = mainWindowPos.x + (mainWindowSize.x - modalW) / 2
            local mY = mainWindowPos.y + (mainWindowSize.y - modalH) / 2
            imgui.SetNextWindowPos(imgui.ImVec2(mX, mY), imgui.Cond.Always)
            imgui.SetNextWindowSize(imgui.ImVec2(modalW, modalH), imgui.Cond.Always)
            imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.10, 0.06, 0.06, 0.98))
            imgui.PushStyleColor(imgui.Col.TitleBgActive, imgui.ImVec4(0.55, 0.08, 0.08, 1.00))
            imgui.PushStyleVar(imgui.StyleVar.WindowPadding, imgui.ImVec2(12, 10))

            if imgui.Begin("CONFIRMAR ACAO##modal", nil, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
                imgui.Spacing()
                imgui.TextColored(CORES.laranja, "Tem certeza que deseja executar esta acao?")
                imgui.Spacing()
                imgui.TextColored(CORES.vermelho, acaoPendente)
                imgui.Spacing()
                imgui.Spacing()
                imgui.Separator()
                imgui.Spacing()

                local btnW = (imgui.GetContentRegionAvailWidth() - 12) / 2
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.55, 0.12, 0.12, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.70, 0.18, 0.18, 1.00))
                imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(0.85, 0.10, 0.10, 1.00))
                if imgui.Button("CONFIRMAR##modalSim", imgui.ImVec2(btnW, 32)) then
                    acaoSom(acaoComando)
                    mostrarConfirmacao = false
                    acaoPendente = nil
                    acaoComando = nil
                end
                imgui.PopStyleColor(3)
                imgui.SameLine(0, 12)
                if imgui.Button("Cancelar##modalNao", imgui.ImVec2(btnW, 32)) then
                    mostrarConfirmacao = false
                    acaoPendente = nil
                    acaoComando = nil
                end
                imgui.End()
            end
            imgui.PopStyleVar()
            imgui.PopStyleColor(2)
        end

        imgui.End()
    else
        imgui.PopStyleVar()
    end
end
