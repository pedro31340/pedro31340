local imgui = require 'imgui'
local vkeys = require 'vkeys'
local inicfg = require 'inicfg'

-- ==========================================
-- MÓDULO DE VERIFICAÇÃO INTERNO (OFUSCADO)
-- Não altere esta seção.
-- ==========================================
local function _xb(a, b)
    local r, p = 0, 1
    for _ = 0, 7 do
        if math.floor(a / p) % 2 ~= math.floor(b / p) % 2 then r = r + p end
        p = p * 2
    end
    return r
end

local _mk = {163, 123, 93, 145}
local function _dv(e)
    local r = 0
    for i = 1, 4 do r = r * 256 + _xb(e[i], _mk[i]) end
    return r
end

local function _vf(s, t)
    local h = 0
    for i = 1, #s do h = (h * 31 + string.byte(s, i)) % 2^32 end
    return h == t
end

local _tg = _dv({165, 115, 243, 97})
local _td = _dv({165, 115, 243, 124})

-- ==========================================
-- CONFIGURAÇÃO E LISTAS
-- ==========================================
local configPath = "FreestyleMenu.ini"
local defaultConfig = { 
    config = { 
        tema = 0,
        posX = -1, 
        posY = -1,
        width = 760,
        height = 560,
        bloqueado = false,
        notificacoes = true,
        velPiscar = 3.0,
        velRGB = 2.0
    } 
}
local cfg = inicfg.load(defaultConfig, configPath)

local arrResultados = {"Em Analise", "Aprovado", "Reprovado"}
local arrCargos = {"Membro", "Vapor", "Sub-Gerente", "Gerente", "Sub-Lider"}

local arrTemas = {
    "Verde", "Azul", "Vermelho", "Roxo", "Laranja", "Rosa", "Amarelo", "Ciano", "Branco", "Cinza", "Marrom", "Verde Escuro",
    "Piscar Verde", "Piscar Azul", "Piscar Vermelho", "Piscar Roxo", "Piscar Laranja", "Piscar Rosa", "Piscar Amarelo", "Piscar Ciano", "Piscar Branco", "Piscar Cinza", "Piscar Marrom", "Piscar Verde Esc.",
    "Arco-Íris (RGB)"
}

local temasCores = {
    [0] = {imgui.ImVec4(0.12, 0.70, 0.12, 1.0), imgui.ImVec4(0.20, 0.85, 0.20, 1.0), imgui.ImVec4(0.4, 1.0, 0.4, 1.0)},
    [1] = {imgui.ImVec4(0.10, 0.40, 0.90, 1.0), imgui.ImVec4(0.20, 0.55, 1.00, 1.0), imgui.ImVec4(0.5, 0.8, 1.0, 1.0)},
    [2] = {imgui.ImVec4(0.80, 0.10, 0.10, 1.0), imgui.ImVec4(1.00, 0.25, 0.25, 1.0), imgui.ImVec4(1.0, 0.5, 0.5, 1.0)},
    [3] = {imgui.ImVec4(0.50, 0.10, 0.80, 1.0), imgui.ImVec4(0.70, 0.20, 1.00, 1.0), imgui.ImVec4(0.8, 0.6, 1.0, 1.0)},
    [4] = {imgui.ImVec4(0.90, 0.45, 0.00, 1.0), imgui.ImVec4(1.00, 0.60, 0.15, 1.0), imgui.ImVec4(1.0, 0.8, 0.4, 1.0)},
    [5] = {imgui.ImVec4(0.90, 0.20, 0.50, 1.0), imgui.ImVec4(1.00, 0.40, 0.70, 1.0), imgui.ImVec4(1.0, 0.6, 0.9, 1.0)},
    [6] = {imgui.ImVec4(0.90, 0.80, 0.10, 1.0), imgui.ImVec4(1.00, 0.95, 0.25, 1.0), imgui.ImVec4(1.0, 1.0, 0.5, 1.0)},
    [7] = {imgui.ImVec4(0.10, 0.70, 0.70, 1.0), imgui.ImVec4(0.20, 0.95, 0.95, 1.0), imgui.ImVec4(0.5, 1.0, 1.0, 1.0)},
    [8] = {imgui.ImVec4(0.90, 0.90, 0.90, 1.0), imgui.ImVec4(1.00, 1.00, 1.00, 1.0), imgui.ImVec4(1.0, 1.0, 1.0, 1.0)},
    [9] = {imgui.ImVec4(0.40, 0.40, 0.40, 1.0), imgui.ImVec4(0.55, 0.55, 0.55, 1.0), imgui.ImVec4(0.7, 0.7, 0.7, 1.0)},
    [10] = {imgui.ImVec4(0.45, 0.25, 0.10, 1.0), imgui.ImVec4(0.60, 0.35, 0.15, 1.0), imgui.ImVec4(0.8, 0.5, 0.3, 1.0)},
    [11] = {imgui.ImVec4(0.05, 0.30, 0.05, 1.0), imgui.ImVec4(0.10, 0.45, 0.10, 1.0), imgui.ImVec4(0.3, 0.8, 0.3, 1.0)}
}

-- ==========================================
-- VARIÁVEIS
-- ==========================================
local janela = imgui.ImBool(false)
local wasOpen = false
local travaF3 = false
local aba = 1
local proximaAba = 1
local tempoInicial = os.clock()

local temaAtual = imgui.ImInt(cfg.config.tema)
local msgChat = imgui.ImBool(cfg.config.notificacoes) 
local velPiscar = imgui.ImFloat(cfg.config.velPiscar)
local velRGB = imgui.ImFloat(cfg.config.velRGB)

local idPlayer = imgui.ImInt(0)
local cargoID = imgui.ImInt(0)

local nomeRecruta = imgui.ImBuffer(128)
local pontosRecrutador = imgui.ImInt(0)
local pontosJogador = imgui.ImInt(0)
local recrutaStatus = imgui.ImInt(0)
local placarFF = imgui.ImInt(0)
local placarADV = imgui.ImInt(0)
local nomeADV = imgui.ImBuffer(128)
local nomeMeuTime = imgui.ImBuffer("Freestyle", 128)
local tipoMD = imgui.ImInt(10)
local salaQtd = imgui.ImInt(20)
local salaArma = imgui.ImInt(31)
local salaSenha = imgui.ImBuffer(16)
local nomeVencedor = imgui.ImBuffer(128)

-- VARIÁVEIS DE SEGURANÇA (tokens nunca são salvos no arquivo de configuração)
local _authRec = 0
local inputSenha = imgui.ImBuffer(16)
local senhaIncorreta = false
local _fcRec = 0
local _ltRec = 0

local _authGer = 0
local inputSenhaGer = imgui.ImBuffer(16)
local senhaIncorretaGer = false
local _fcGer = 0
local _ltGer = 0

local painelBloqueado = cfg.config.bloqueado 
local inputSenhaMaster = imgui.ImBuffer(16)
local senhaMasterIncorreta = false

local _maxFail = 5
local _cdThresh = 3
local _cdDur = 30

function main()
    while not isSampAvailable() do wait(100) end
    sampRegisterChatCommand("menu", function() janela.v = not janela.v end)

    while true do
        wait(0)
        if isKeyDown(vkeys.VK_F3) and not sampIsChatInputActive() and not sampIsDialogActive() then
            if not travaF3 then janela.v = not janela.v; travaF3 = true end
        elseif not isKeyDown(vkeys.VK_F3) then travaF3 = false end

        if janela.v and not wasOpen then
            if painelBloqueado then
                sampAddChatMessage("{FF0000}[Bloqueado] {FFFFFF}Acesso ao painel bloqueado.", -1)
            elseif cfg.config.notificacoes then 
                sampAddChatMessage("{00FF00}[Freestyle] {FFFFFF}Painel aberto com sucesso.", -1)
            end
            wasOpen = true
        elseif not janela.v and wasOpen then
            if not painelBloqueado and cfg.config.notificacoes then 
                sampAddChatMessage("{FF0000}[Freestyle] {FFFFFF}Painel fechado com sucesso.", -1)
            end
            wasOpen = false
        end

        imgui.Process = janela.v
        imgui.ShowCursor = janela.v
    end
end

function imgui.OnDrawFrame()
    if not janela.v then return end

    local style = imgui.GetStyle()
    local colors = style.Colors
    
    local cMain, cHover, cTextH

    if painelBloqueado then
        cMain = imgui.ImVec4(0.80, 0.10, 0.10, 1.0)
        cHover = imgui.ImVec4(1.00, 0.25, 0.25, 1.0)
        cTextH = imgui.ImVec4(1.0, 0.1, 0.1, 1.0) 
    else
        local time = os.clock()
        local tIndex = temaAtual.v

        if tIndex <= 11 then
            -- Temas Padrões
            local t = temasCores[tIndex] or temasCores[0]
            cMain, cHover, cTextH = t[1], t[2], t[3]

        elseif tIndex >= 12 and tIndex <= 23 then
            -- Temas Pisca-Pisca Sincronizado
            local baseTheme = tIndex - 12
            local t = temasCores[baseTheme]
            
            -- Calculo da pulsação e aplicação a TODAS as camadas
            local pulso = (math.sin(time * velPiscar.v * 3) + 1) / 2
            local brilho = 0.3 + (0.7 * pulso)
            
            cMain = imgui.ImVec4(t[1].x * brilho, t[1].y * brilho, t[1].z * brilho, 1.0)
            cHover = imgui.ImVec4(t[2].x * brilho, t[2].y * brilho, t[2].z * brilho, 1.0)
            cTextH = imgui.ImVec4(t[3].x * brilho, t[3].y * brilho, t[3].z * brilho, 1.0)

        elseif tIndex == 24 then
            -- Tema Arco-Íris (RGB) Sincronizado
            local r = (math.sin(time * velRGB.v) + 1) / 2
            local g = (math.sin(time * velRGB.v + 2.09) + 1) / 2
            local b = (math.sin(time * velRGB.v + 4.18) + 1) / 2
            
            cMain = imgui.ImVec4(r, g, b, 1.0)
            -- Adiciona um aumento leve para hover e texto, mantendo a escala de cor correta
            cHover = imgui.ImVec4(math.min(1.0, r + 0.2), math.min(1.0, g + 0.2), math.min(1.0, b + 0.2), 1.0)
            cTextH = imgui.ImVec4(math.min(1.0, r + 0.4), math.min(1.0, g + 0.4), math.min(1.0, b + 0.4), 1.0)
        end
    end

    style.WindowRounding = 8.0
    style.ScrollbarSize = 10.0
    
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.06, 0.06, 0.06, 0.98)
    colors[imgui.Col.ChildWindowBg] = imgui.ImVec4(0.08, 0.08, 0.08, 0.00)
    
    colors[imgui.Col.TitleBg]          = imgui.ImVec4(0.07, 0.07, 0.07, 1.0)
    colors[imgui.Col.TitleBgActive]    = imgui.ImVec4(0.07, 0.07, 0.07, 1.0)
    colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.07, 0.07, 0.07, 1.0)
    
    colors[imgui.Col.Button] = imgui.ImVec4(0.12, 0.12, 0.12, 1.0) 
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(cHover.x, cHover.y, cHover.z, 0.6)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(cHover.x, cHover.y, cHover.z, 0.9) 
    
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.10, 0.10, 0.10, 1.0)
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.15, 0.15, 0.15, 1.0)
    colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.20, 0.20, 0.20, 1.0)
    
    colors[imgui.Col.Header] = imgui.ImVec4(0.15, 0.15, 0.15, 1.0)
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.20, 0.20, 0.20, 1.0)
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.25, 0.25, 0.25, 1.0)

    colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.0)
    colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(cMain.x, cMain.y, cMain.z, 0.5)
    colors[imgui.Col.ScrollbarGrabHovered] = cHover
    colors[imgui.Col.ScrollbarGrabActive] = cTextH

    -- Sincronizando a barrinha do Slider Float (Scroll sem cor)
    colors[imgui.Col.SliderGrab] = imgui.ImVec4(cMain.x, cMain.y, cMain.z, 0.8)
    colors[imgui.Col.SliderGrabActive] = cTextH

    colors[imgui.Col.CloseButton] = imgui.ImVec4(cMain.x, cMain.y, cMain.z, 0.7)
    colors[imgui.Col.CloseButtonHovered] = imgui.ImVec4(cHover.x, cHover.y, cHover.z, 0.9)
    colors[imgui.Col.CloseButtonActive] = cTextH
    
    colors[imgui.Col.Text] = cTextH
    colors[imgui.Col.CheckMark] = cMain

    imgui.SetNextWindowPos(imgui.ImVec2(cfg.config.posX, cfg.config.posY), imgui.Cond.FirstUseEver)
    imgui.SetNextWindowSize(imgui.ImVec2(cfg.config.width, cfg.config.height), imgui.Cond.FirstUseEver)

    local window_flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar
    if painelBloqueado then
        window_flags = window_flags + imgui.WindowFlags.NoResize
    end

    if painelBloqueado then
        imgui.Begin("CENTRAL FREESTYLE", nil, window_flags)
    else
        imgui.Begin("CENTRAL FREESTYLE", janela, window_flags)
    end
        
        colors[imgui.Col.Text] = imgui.ImVec4(0.9, 0.9, 0.9, 1.0)

        local parentPos = imgui.GetWindowPos()
        local parentSize = imgui.GetWindowSize()

        if painelBloqueado then
            local size = imgui.GetWindowSize()
            local childWidth = size.x - 60
            local childHeight = size.y - 100
            imgui.SetCursorPos(imgui.ImVec2(30, 60))
            
            imgui.BeginChild("LockScreen", imgui.ImVec2(childWidth, childHeight), false)
                local totalGroupHeight = 220 
                imgui.SetCursorPosY((childHeight / 2) - (totalGroupHeight / 2))

                local textoTitulo = "ACESSO SUSPENSO"
                local textoAviso1 = "Por questões de segurança, este painel foi bloqueado"
                local textoAviso2 = "após sucessivas tentativas incorretas."
                local textoAviso3 = "Favor contatar o suporte da liderança para solicitar a liberação."
                
                imgui.SetCursorPosX((childWidth - imgui.CalcTextSize(textoTitulo).x) / 2)
                imgui.TextColored(cTextH, textoTitulo) -- Vai pegar o vermelho base do bloqueio
                imgui.Spacing(); imgui.Spacing()
                
                imgui.SetCursorPosX((childWidth - imgui.CalcTextSize(textoAviso1).x) / 2)
                imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.8, 1.0), textoAviso1)
                
                imgui.SetCursorPosX((childWidth - imgui.CalcTextSize(textoAviso2).x) / 2)
                imgui.TextColored(imgui.ImVec4(0.8, 0.8, 0.8, 1.0), textoAviso2)
                
                imgui.Spacing()
                imgui.SetCursorPosX((childWidth - imgui.CalcTextSize(textoAviso3).x) / 2)
                imgui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), textoAviso3)
                
                imgui.Spacing(); imgui.Spacing(); imgui.Spacing()
                
                local inputWidth = 220
                local labelSenha = "Insira o código de autenticação para desbloqueio:"
                local labelSize = imgui.CalcTextSize(labelSenha)
                
                imgui.SetCursorPosX((childWidth - labelSize.x) / 2)
                imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), labelSenha)
                
                imgui.SetCursorPosX((childWidth - inputWidth) / 2)
                imgui.PushItemWidth(inputWidth)
                imgui.InputText("##senhaMaster", inputSenhaMaster, imgui.InputTextFlags.Password)
                imgui.PopItemWidth()
                
                if senhaMasterIncorreta then
                    local erroMsg = "Senha incorreta!"
                    local erroSize = imgui.CalcTextSize(erroMsg)
                    imgui.SetCursorPosX((childWidth - erroSize.x) / 2)
                    imgui.TextColored(cTextH, erroMsg)
                end
                
                imgui.Spacing(); imgui.Spacing()
                
                imgui.SetCursorPosX((childWidth - 140) / 2)
                
                -- Mudando a cor EXCLUSIVA desse botão (Fundo preto, Hover/Active vermelho do título)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.06, 0.06, 0.06, 1.0))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.80, 0.10, 0.10, 0.8))
                imgui.PushStyleColor(imgui.Col.ButtonActive, cTextH)

                if imgui.Button("DESBLOQUEAR", imgui.ImVec2(140, 30)) then
                    if _vf(tostring(inputSenhaMaster.v), _td) then
                        painelBloqueado = false
                        cfg.config.bloqueado = false
                        inicfg.save(cfg, configPath) 
                        senhaMasterIncorreta = false
                        senhaIncorreta = false
                        senhaIncorretaGer = false
                        _fcRec = 0
                        _fcGer = 0
                        inputSenhaMaster.v = ""
                        inputSenha.v = ""
                        inputSenhaGer.v = ""
                    else
                        senhaMasterIncorreta = true
                    end
                end
                -- Restaurando as cores normais dos botões para o resto do script
                imgui.PopStyleColor(3)

            imgui.EndChild()
        else
            imgui.BeginChild("Side", imgui.ImVec2(170, 0), true, imgui.WindowFlags.NoScrollbar)
                local menus = {"ARENAS", "ANUNCIAR FF", "RECRUTAMENTO", "GERENCIAR", "CRIAR SALA", "REGRAS", "STATUS", "INFO", "CONFIG"}
                for i, n in ipairs(menus) do 
                    if aba == i then 
                        imgui.PushStyleColor(imgui.Col.Text, cTextH)
                    else
                        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.6, 0.6, 0.6, 1.0))
                    end
                    
                    if imgui.Button(n, imgui.ImVec2(-1, 38)) then proximaAba = i end 
                    
                    imgui.PopStyleColor()
                end
                
                imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.6, 0.6, 0.6, 1.0))
                if imgui.Button("SPAWNAR", imgui.ImVec2(-1, 38)) then sampSendChat("/hqf") end
                imgui.PopStyleColor()
            imgui.EndChild()

            imgui.SameLine()

            imgui.BeginChild("Main", imgui.ImVec2(0, 0), true, imgui.WindowFlags.AlwaysVerticalScrollbar)
                
                if aba == 1 then -- ARENAS
                    imgui.TextColored(cTextH, "CATÁLOGO DE ARENAS"); 
                    imgui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "Selecione um local para treinar.")
                    imgui.Separator(); imgui.Spacing()

                    imgui.Columns(2, "grid", false) 
                    local arenas = {
                        {"[M4] Campo", "/m4", "Combate em área aberta."}, 
                        {"[M4-2] Padrão", "/m42", "Treino de precisão fixa."}, 
                        {"[AK] Pesada", "/ak", "Dano alto e recuo médio."}, 
                        {"[SNIPER] Longa", "/snp", "Treino de longa distância."}, 
                        {"[PT-1] Damínio", "/pt", "Combate em área aberta."}, 
                        {"[PT-2] Prédio", "/predio", "Verticalidade e altura."},
                        {"[PT-3] Ammu", "/ammu", "Espaço aberto / fechado."}, 
                        {"[SHOT] Rústica", "/shot", "Combate de curto alcance."}
                    }
                    
                    for i, v in ipairs(arenas) do
                        imgui.TextColored(cTextH, v[1]) 
                        imgui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), v[3]) 
                        if imgui.Button("ENTRAR##"..i, imgui.ImVec2(-1, 32)) then sampSendChat(v[2]) end
                        imgui.Spacing()
                        imgui.NextColumn()
                    end
                    imgui.Columns(1); imgui.Spacing(); imgui.Separator();
                    imgui.Spacing(); imgui.Spacing()
                                        
                    imgui.Spacing()
                    if imgui.Button("SAIR DA ARENA ATUAL", imgui.ImVec2(-1, 30)) then sampSendChat("/sair") end

                elseif aba == 2 then -- ANUNCIAR FF
                    imgui.TextColored(cTextH, "CONFIGURAÇÃO DO CONFRONTO"); imgui.Separator(); imgui.Spacing()
                    
                    imgui.Columns(2, "times_ff", false)
                    imgui.Text("Seu Time:")
                    imgui.PushItemWidth(-1); imgui.InputText("##meutime", nomeMeuTime); imgui.PopItemWidth()
                    imgui.NextColumn()
                    imgui.Text("Time Adversário:")
                    imgui.PushItemWidth(-1); imgui.InputText("##adv", nomeADV); imgui.PopItemWidth()
                    imgui.Columns(1)
                    
                    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

                    imgui.TextColored(cTextH, "PLACAR E RESULTADO FINAL")
                    imgui.Spacing()
                    
                    imgui.Columns(3, "placar_ff_new", false)
                    imgui.SetColumnWidth(0, 110); imgui.SetColumnWidth(1, 40)
                    
                    imgui.Text("Nosso Placar:")
                    imgui.PushItemWidth(90); imgui.InputInt("##p1", placarFF); imgui.PopItemWidth()
                    
                    imgui.NextColumn()
                    imgui.SetCursorPosY(imgui.GetCursorPosY() + 20); imgui.TextColored(cTextH, "  X")
                    
                    imgui.NextColumn()
                    imgui.Text("Placar Deles:")
                    imgui.PushItemWidth(90); imgui.InputInt("##p2", placarADV); imgui.PopItemWidth()
                    imgui.Columns(1)
                    
                    imgui.Spacing()
                    imgui.Text("Vencedor da Partida:")
                    imgui.SameLine()
                    imgui.PushItemWidth(200); imgui.InputText("##venced", nomeVencedor); imgui.PopItemWidth()
                    imgui.SameLine(); imgui.TextDisabled("(Opcional)")

                    imgui.Spacing(); imgui.Separator(); imgui.Spacing()

                    imgui.Text("Tipo de MD:")
                    imgui.SameLine()
                    imgui.PushItemWidth(100); imgui.InputInt("##md", tipoMD); imgui.PopItemWidth()
                    
                    imgui.Spacing(); imgui.Spacing()
                    
                    if imgui.Button("ANUNCIAR CONFRONTO", imgui.ImVec2(-1, 35)) then 
                        local txtGG = ""
                        if nomeVencedor.v and nomeVencedor.v ~= "" then
                            txtGG = " GG " .. nomeVencedor.v
                        end

                        sampSendChat(string.format("/g FF %s [%d] X [%d] %s MD%d%s", nomeMeuTime.v, placarFF.v, placarADV.v, nomeADV.v, tipoMD.v, txtGG)) 
                        nomeVencedor.v = "" 
                        janela.v = false
                    end

                elseif aba == 3 then -- RECRUTAMENTO
                    if _authRec ~= _tg then
                        imgui.TextColored(cTextH, "ACESSO RESTRITO"); imgui.Separator(); imgui.Spacing()
                        imgui.Text("Digite a senha:")
                        imgui.PushItemWidth(150); imgui.InputText("##senha", inputSenha, imgui.InputTextFlags.Password); imgui.PopItemWidth()
                        
                        if senhaIncorreta then
                            imgui.TextColored(imgui.ImVec4(1.0, 0.0, 0.0, 1.0), "Senha incorreta!")
                        end

                        -- Cooldown após múltiplas tentativas
                        if _fcRec >= _cdThresh and (os.clock() - _ltRec) < _cdDur then
                            local restante = math.ceil(_cdDur - (os.clock() - _ltRec))
                            imgui.Spacing()
                            imgui.TextColored(imgui.ImVec4(1.0, 0.5, 0.0, 1.0), 
                                string.format("Aguarde %d segundos para tentar novamente.", restante))
                        else
                            imgui.Spacing()
                            imgui.SetCursorPosX(20)
                            if imgui.Button("DESBLOQUEAR", imgui.ImVec2(120, 28)) then
                                if _vf(tostring(inputSenha.v), _tg) then
                                    _authRec = _tg
                                    senhaIncorreta = false
                                    _fcRec = 0
                                    inputSenha.v = ""
                                else
                                    senhaIncorreta = true
                                    _fcRec = _fcRec + 1
                                    _ltRec = os.clock()
                                    if _fcRec >= _maxFail then
                                        painelBloqueado = true 
                                        cfg.config.bloqueado = true
                                        inicfg.save(cfg, configPath)
                                    end
                                end
                            end
                        end
                    else
                        imgui.TextColored(cTextH, "RECRUTAMENTO"); imgui.Separator(); imgui.Spacing()
                        imgui.Text("Candidato:"); imgui.PushItemWidth(160); imgui.InputText("##rn", nomeRecruta); imgui.PopItemWidth()
                        imgui.Text("Meus Pontos:"); imgui.PushItemWidth(160); imgui.InputInt("##rp1", pontosRecrutador); imgui.PopItemWidth()
                        imgui.Text("Pontos Cantidado:"); imgui.PushItemWidth(160); imgui.InputInt("##rp2", pontosJogador); imgui.PopItemWidth()
                        imgui.Text("Resultado:"); imgui.PushItemWidth(160); imgui.Combo("##rst", recrutaStatus, arrResultados); imgui.PopItemWidth()
                        
                        if imgui.Button("ANUNCIAR RECRUTAMENTO", imgui.ImVec2(-1, 30)) then
                            local s = {"EM ANALISE", "APROVADO", "REPROVADO"}
                            sampSendChat(string.format("/g FF RECRUTAMENTO Freestyle [%d] x [%d] %s %s", pontosRecrutador.v, pontosJogador.v, nomeRecruta.v, s[recrutaStatus.v+1]))
                            janela.v = false
                        end
                        imgui.Spacing()

                        imgui.Separator(); imgui.Spacing()
                        local rRec = {
                            {"1. Atenção ao canal de formulários", "Fique atento ao canal de formulários e aguarde o candidato abrir um ticket para que você possa atendê-lo e informar se foi aprovado ou reprovado no formulário."},
                            {"2. Verificação do RG", "Solicite a foto do RG do candidato. Caso ele tenha informado que não possui advertências, mas conste alguma no RG, o candidato deverá ser dispensado."},
                            {"3. Requisitos mínimos (Opcional)", "O candidato deve possuir no mínimo 200+ leveis e 700 kills em sua conta."},
                            {"4. Avaliação em x1", "Realize um x1 com o candidato para avaliar suas habilidades."},
                            {"5. Aprovação final", "Caso o candidato seja aprovado no x1, envie a mensagem de aprovação no ticket e atribua os cargos a ele, retirando o cargo atual de Visitante."}
                        }
                        for _, v in ipairs(rRec) do
                            imgui.TextColored(cTextH, v[1]); imgui.TextWrapped(v[2]); imgui.Spacing()
                        end
                        
                        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

                        if imgui.Button("BLOQUEAR ABA", imgui.ImVec2(-1, 30)) then _authRec = 0 end
                    end

                elseif aba == 4 then -- GERENCIAR
                    if _authGer ~= _tg then
                        imgui.TextColored(cTextH, "ACESSO RESTRITO"); imgui.Separator(); imgui.Spacing()
                        imgui.Text("Digite a senha:")
                        imgui.PushItemWidth(150); imgui.InputText("##senhaGer", inputSenhaGer, imgui.InputTextFlags.Password); imgui.PopItemWidth()
                        
                        if senhaIncorretaGer then 
                            imgui.TextColored(imgui.ImVec4(1.0, 0.0, 0.0, 1.0), "Senha incorreta!") 
                        end

                        -- Cooldown após múltiplas tentativas
                        if _fcGer >= _cdThresh and (os.clock() - _ltGer) < _cdDur then
                            local restante = math.ceil(_cdDur - (os.clock() - _ltGer))
                            imgui.Spacing()
                            imgui.TextColored(imgui.ImVec4(1.0, 0.5, 0.0, 1.0), 
                                string.format("Aguarde %d segundos para tentar novamente.", restante))
                        else
                            imgui.Spacing()
                            imgui.SetCursorPosX(20)
                            if imgui.Button("DESBLOQUEAR", imgui.ImVec2(120, 28)) then
                                if _vf(tostring(inputSenhaGer.v), _tg) then
                                    _authGer = _tg
                                    senhaIncorretaGer = false
                                    _fcGer = 0
                                    inputSenhaGer.v = ""
                                else
                                    senhaIncorretaGer = true
                                    _fcGer = _fcGer + 1
                                    _ltGer = os.clock()
                                    if _fcGer >= _maxFail then
                                        painelBloqueado = true 
                                        cfg.config.bloqueado = true
                                        inicfg.save(cfg, configPath)
                                    end
                                end
                            end
                        end
                    else
                        imgui.TextColored(cTextH, "GERENCIAR MEMBROS"); imgui.Separator(); imgui.Spacing()
                        imgui.Text("ID:"); imgui.PushItemWidth(120); imgui.InputInt("##idp", idPlayer); imgui.PopItemWidth()
                        imgui.Text("Cargo:"); imgui.PushItemWidth(120); imgui.Combo("##crg", cargoID, arrCargos); imgui.PopItemWidth()
                        imgui.Spacing()
                        if imgui.Button("CONVIDAR", imgui.ImVec2(-1, 30)) then sampSendChat("/convidar "..idPlayer.v) end
                        if imgui.Button("PROMOVER", imgui.ImVec2(-1, 30)) then sampSendChat("/promover "..idPlayer.v.." "..(cargoID.v+1)) end
                        if imgui.Button("DEMITIR", imgui.ImVec2(-1, 30)) then sampSendChat("/demitir "..idPlayer.v) end
                         
                        if imgui.Button("BLOQUEAR ABA", imgui.ImVec2(-1, 30)) then _authGer = 0 end
                    end

                elseif aba == 5 then -- CRIAR SALA
                    imgui.TextColored(cTextH, "SALA DE TREINO"); imgui.Separator(); imgui.Spacing()
                    imgui.Text("Vagas:"); imgui.PushItemWidth(120); imgui.InputInt("##v", salaQtd); imgui.PopItemWidth()
                    imgui.Text("Arma ID:"); imgui.PushItemWidth(120); imgui.InputInt("##a", salaArma); imgui.PopItemWidth()
                    imgui.Text("Senha:"); imgui.PushItemWidth(120); imgui.InputText("##s", salaSenha); imgui.PopItemWidth()
                    imgui.Spacing()
                    if imgui.Button("CRIAR SALA", imgui.ImVec2(-1, 30)) then sampSendChat(string.format("/criarsala %d %d %s", salaQtd.v, salaArma.v, salaSenha.v)) end
                    if imgui.Button("SAIR DA SALA", imgui.ImVec2(-1, 30)) then sampSendChat("/sairsala") end
                    if imgui.Button("DELETAR SALA", imgui.ImVec2(-1, 30)) then sampSendChat("/deletarsala") end

                elseif aba == 6 then -- REGRAS
                    imgui.TextColored(cTextH, "REGRAS"); imgui.Separator(); imgui.Spacing()
                    local rFam = {
                        {"1. Respeito à hierarquia", "Respeite sempre a hierarquia e todos os membros que ocupam cargos superiores."},
                        {"2. Spawn da família", "É estritamente proibido colocar malas, grafites e portões no spawn da família."},
                        {"3. Pedidos de cargo", "Não peça cargos. Promoções são conquistadas com dedicação e lealdade."},
                        {"4. Convivência entre membros", "Evite discussões ou ofensas dentro da família."},
                        {"5. Obediência às ordens", "Siga todas as ordens dos superiores."},
                        {"6. Atividade na família", "Seja ativo e participe de eventos e reuniões."},
                        {"7. Imagem da família", "Representar bem a família dentro e fora do servidor é essencial."},
                        {"8. Fofocas e conflitos", "É proibido gerar conflitos internos ou externos."},
                        {"9. Uso de cheaters", "Uso de cheaters resulta em banimento permanente."},
                        {"10. Respeito aos jogadores", "Respeite todos os jogadores do servidor."},
                        {"11. Punições", "O não cumprimento poderá resultar em expulsão."},
                        {"12. Comprometimento", "Todos os membros devem demonstrar compromisso com a união da família."}
                    }
                    for _, v in ipairs(rFam) do
                        imgui.TextColored(cTextH, v[1]); imgui.TextWrapped(v[2]); imgui.Spacing()
                    end

                elseif aba == 7 then -- STATUS
                    imgui.TextColored(cTextH, "STATUS DO JOGADOR"); imgui.Separator(); imgui.Spacing()
                    local myId = "N/A"; local myPing = 0; local myScore = 0
                    if sampIsLocalPlayerSpawned() then
                        local res, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                        if res then myId = id; myPing = sampGetPlayerPing(id); myScore = sampGetPlayerScore(id) end
                    end
                    local sOn = os.clock() - tempoInicial
                    local currentFPS = math.floor(imgui.GetIO().Framerate)
                    imgui.Columns(2, "status_cols", false)
                    imgui.SetColumnWidth(0, 100)
                    imgui.TextColored(cTextH, "ID:"); imgui.NextColumn(); imgui.Text(tostring(myId)); imgui.NextColumn()
                    imgui.TextColored(cTextH, "FPS:"); imgui.NextColumn(); imgui.Text(tostring(currentFPS)); imgui.NextColumn()
                    imgui.TextColored(cTextH, "PING:"); imgui.NextColumn(); imgui.Text(tostring(myPing) .. "ms"); imgui.NextColumn()
                    imgui.TextColored(cTextH, "LEVEL:"); imgui.NextColumn(); imgui.Text(tostring(myScore)); imgui.NextColumn()
                    imgui.TextColored(cTextH, "SESSÃO:"); imgui.NextColumn(); imgui.Text(string.format("%02d:%02d:%02d", math.floor(sOn/3600), math.floor(sOn/60)%60, sOn%60)); imgui.NextColumn()
                    imgui.TextColored(cTextH, "SKIN FAMÍLIA:"); imgui.NextColumn();imgui.Text("   45"); 
                    imgui.Columns(1)

                elseif aba == 8 then -- INFO
                    imgui.TextColored(cTextH, "LIDERANÇA SUPREMA"); imgui.Separator(); imgui.Spacing()
                    local lideres = {"Falcon", "Jamaica171", "Venom_Arcade"}
                    for _, lider in ipairs(lideres) do
                        imgui.TextColored(cTextH, "•"); imgui.SameLine(); imgui.Text(lider)
                    end

                elseif aba == 9 then -- CONFIG
                    imgui.TextColored(cTextH, "AJUSTES"); imgui.Separator(); imgui.Spacing()
                    
                    imgui.Text("Tema:"); imgui.PushItemWidth(200); imgui.Combo("##t", temaAtual, arrTemas); imgui.PopItemWidth()
                    
                    -- Se for um tema animado, mostra os controles de velocidade
                    if temaAtual.v >= 12 and temaAtual.v <= 23 then
                        imgui.Spacing()
                        imgui.Text("Velocidade do Piscar:")
                        imgui.SliderFloat("##velP", velPiscar, 0.5, 10.0, "%.1f")
                    elseif temaAtual.v == 24 then
                        imgui.Spacing()
                        imgui.Text("Velocidade do RGB:")
                        imgui.SliderFloat("##velRGB", velRGB, 0.5, 10.0, "%.1f")
                    end

                    imgui.Spacing()
                    imgui.Checkbox("Mostrar aviso de menu aberto / fechado no chat", msgChat)
                    
                    imgui.Spacing(); imgui.Spacing()
                    
                    if imgui.Button("SALVAR CONFIGURAÇÕES", imgui.ImVec2(-1, 30)) then
                        cfg.config.tema = temaAtual.v
                        cfg.config.notificacoes = msgChat.v 
                        cfg.config.velPiscar = velPiscar.v
                        cfg.config.velRGB = velRGB.v

                        cfg.config.posX, cfg.config.posY = parentPos.x, parentPos.y
                        cfg.config.width, cfg.config.height = parentSize.x, parentSize.y
                        inicfg.save(cfg, configPath)
                        
                        sampAddChatMessage("{FFFF00}[Freestyle] {FFFFFF}Salvo com sucesso.", -1)
                        janela.v = false; wasOpen = false
                    end
                end
            imgui.EndChild()
        end
    imgui.End()
    aba = proximaAba 
end
