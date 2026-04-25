/*
    ============================================================================
    Painel Administrativo Staff - SA-MP
    ============================================================================
    Descricao: Painel completo de administracao para servidores SA-MP
    Funcionalidades:
        - Lista de jogadores conectados
        - Expulsar (Kick), Banir (Ban), Punir jogadores
        - Aguardar Banimento, Aceitar Jogador
        - Setar ao mundo, Limpar Logs
        - Acoes extras: Ir ao Player, Trazer Player, Verificar APK, Explodir
        - Limpar Punicao
        - Log do servidor em tempo real
        - Lista de jogadores banidos
    Comando: /painel
    ============================================================================
*/

#include <a_samp>
#include <a_players>

// ============================================================================
// DEFINES
// ============================================================================

// Versao
#define PAINEL_VERSAO "1.0"

// Maximo de jogadores
#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 1000
#endif

// Niveis de admin
#define ADMIN_LEVEL_MODERADOR  1
#define ADMIN_LEVEL_ADMIN      2
#define ADMIN_LEVEL_DONO       3

// Dialogs
#define DIALOG_PAINEL_ID        5000
#define DIALOG_MOTIVO           5001
#define DIALOG_MOTIVO_BAN       5002
#define DIALOG_MOTIVO_PUNIR     5003
#define DIALOG_SETAR_MUNDO      5004
#define DIALOG_CONFIRMAR_BAN    5005
#define DIALOG_SELECIONAR_PLAYER 5006
#define DIALOG_LOG_SERVIDOR     5007
#define DIALOG_BANIDOS_LISTA    5008
#define DIALOG_MOTIVO_AGUARDAR  5009
#define DIALOG_VERIFICAR_APK    5010

// Cores
#define COR_BRANCO      0xFFFFFFFF
#define COR_VERMELHO    0xFF0000FF
#define COR_VERDE       0x00FF00FF
#define COR_AZUL        0x0000FFFF
#define COR_AMARELO     0xFFFF00FF
#define COR_LARANJA     0xFF8C00FF
#define COR_CINZA       0xAFAFAFFF
#define COR_STAFF       0x00BFFFFF
#define COR_TITULO      0x4169E1FF
#define COR_SUCESSO     0x32CD32FF
#define COR_ERRO        0xFF4500FF

// Textdraw Colors (ARGB format para textdraws)
#define TD_COR_FUNDO        0xBB000814
#define TD_COR_PAINEL       0xBB0A1428
#define TD_COR_BOTAO        0xBB1E3250
#define TD_COR_BOTAO_HOVER  0xBB2A4A6E
#define TD_COR_TITULO_BG    0xBB0F2040
#define TD_COR_TEXTO        0xFFCCDDEE
#define TD_COR_TITULO_TXT   0xFF4499FF
#define TD_COR_DESTAQUE     0xFF00CCFF
#define TD_COR_SEPARADOR    0xBB334466

// Limites
#define MAX_BANS            500
#define MAX_LOG_ENTRIES     50
#define MAX_PUNICOES        100
#define MAX_MOTIVO_LEN      128

// Textdraw IDs por jogador
#define TD_FUNDO_PRINCIPAL  0
#define TD_TITULO           1
#define TD_SEPARADOR_TOP    2
// Abas
#define TD_ABA_GERAL        3
#define TD_ABA_LOGS         4
#define TD_ABA_BANIDOS      5
// Painel esquerdo - Lista de jogadores
#define TD_LISTA_TITULO     6
#define TD_LISTA_FUNDO      7
#define TD_LISTA_CONTEUDO   8
// Painel central - Campos
#define TD_CAMPO_ID_LABEL   9
#define TD_CAMPO_ID_FUNDO   10
#define TD_CAMPO_ID_TEXTO   11
#define TD_CAMPO_MOTIVO_LBL 12
#define TD_CAMPO_MOTIVO_FND 13
#define TD_CAMPO_MOTIVO_TXT 14
// Botoes de acao (direita)
#define TD_BTN_EXPULSAR     15
#define TD_BTN_BANIR        16
#define TD_BTN_PUNIR        17
#define TD_BTN_AGUARDAR     18
#define TD_BTN_ACEITAR      19
#define TD_BTN_SETAR_MUNDO  20
#define TD_BTN_LIMPAR_LOGS  21
#define TD_BTN_LIMPAR_PUN   22
// Acoes extras (centro-baixo)
#define TD_EXTRA_TITULO     23
#define TD_BTN_IR_PLAYER    24
#define TD_BTN_TRAZER       25
#define TD_BTN_VERIFICAR    26
#define TD_BTN_EXPLODIR     27
// Log do servidor (direita-baixo)
#define TD_LOG_TITULO       28
#define TD_LOG_FUNDO        29
#define TD_LOG_CONTEUDO     30
// Banidos (esquerda-baixo)
#define TD_BANIDOS_TITULO   31
#define TD_BANIDOS_FUNDO    32
#define TD_BANIDOS_CONTEUDO 33
// Info punicoes
#define TD_PUNICAO_INFO     34
// Botao fechar
#define TD_BTN_FECHAR       35
// Botao labels
#define TD_LBL_EXPULSAR     36
#define TD_LBL_BANIR        37
#define TD_LBL_PUNIR        38
#define TD_LBL_AGUARDAR     39
#define TD_LBL_ACEITAR      40
#define TD_LBL_SETAR_MUNDO  41
#define TD_LBL_LIMPAR_LOGS  42
#define TD_LBL_LIMPAR_PUN   43
#define TD_LBL_IR_PLAYER    44
#define TD_LBL_TRAZER       45
#define TD_LBL_VERIFICAR    46
#define TD_LBL_EXPLODIR     47
#define TD_LBL_FECHAR       48
#define TD_LBL_ABA_GERAL    49
#define TD_LBL_ABA_LOGS     50
#define TD_LBL_ABA_BANIDOS  51
// Separadores
#define TD_SEP_MEIO         52
#define TD_SEP_BAIXO        53
// Total de textdraws
#define MAX_PAINEL_TD       54

// ============================================================================
// VARIAVEIS
// ============================================================================

// Variavel de admin do jogador (setar via seu sistema de admin)
new pAdminLevel[MAX_PLAYERS];

// Painel aberto
new bool:pPainelAberto[MAX_PLAYERS];

// Jogador selecionado no painel
new pJogadorSelecionado[MAX_PLAYERS];

// Aba atual
new pAbaAtual[MAX_PLAYERS];

// Acao pendente (para dialogs de motivo)
// 0=nenhuma, 1=kick, 2=ban, 3=punir, 4=aguardar ban
new pAcaoPendente[MAX_PLAYERS];

// Textdraws do painel
new PlayerText:pTD[MAX_PLAYERS][MAX_PAINEL_TD];

// Sistema de bans
enum E_BAN_INFO {
    ban_Nome[MAX_PLAYER_NAME],
    ban_IP[16],
    ban_Motivo[MAX_MOTIVO_LEN],
    ban_Admin[MAX_PLAYER_NAME],
    ban_Data[32],
    bool:ban_Ativo
};
new gBanList[MAX_BANS][E_BAN_INFO];
new gTotalBans;

// Sistema de punicoes
enum E_PUNICAO_INFO {
    pun_Jogador[MAX_PLAYER_NAME],
    pun_Admin[MAX_PLAYER_NAME],
    pun_Motivo[MAX_MOTIVO_LEN],
    pun_Tipo[32],
    pun_Data[32]
};
new gPunicoes[MAX_PUNICOES][E_PUNICAO_INFO];
new gTotalPunicoes;

// Log do servidor
new gLogServidor[MAX_LOG_ENTRIES][256];
new gTotalLogs;

// ============================================================================
// FUNCOES AUXILIARES
// ============================================================================

stock GetPlayerNameEx(playerid)
{
    new nome[MAX_PLAYER_NAME];
    GetPlayerName(playerid, nome, sizeof(nome));
    return nome;
}

stock GetDataAtual()
{
    new ano, mes, dia, hora, minuto, segundo;
    getdate(ano, mes, dia);
    gettime(hora, minuto, segundo);
    new data[32];
    format(data, sizeof(data), "%02d/%02d/%04d %02d:%02d", dia, mes, ano, hora, minuto);
    return data;
}

stock AdicionarLog(const texto[])
{
    if(gTotalLogs >= MAX_LOG_ENTRIES)
    {
        // Shift logs para cima
        for(new i = 0; i < MAX_LOG_ENTRIES - 1; i++)
        {
            format(gLogServidor[i], 256, "%s", gLogServidor[i+1]);
        }
        gTotalLogs = MAX_LOG_ENTRIES - 1;
    }
    new data[32];
    data = GetDataAtual();
    format(gLogServidor[gTotalLogs], 256, "[%s] %s", data, texto);
    gTotalLogs++;

    // Atualizar painel de todos os admins que estao com o painel aberto
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && pPainelAberto[i])
        {
            AtualizarLogNoTextdraw(i);
        }
    }
}

stock AdicionarPunicao(const jogador[], const admin[], const motivo[], const tipo[])
{
    if(gTotalPunicoes >= MAX_PUNICOES)
    {
        for(new i = 0; i < MAX_PUNICOES - 1; i++)
        {
            format(gPunicoes[i][pun_Jogador], MAX_PLAYER_NAME, "%s", gPunicoes[i+1][pun_Jogador]);
            format(gPunicoes[i][pun_Admin], MAX_PLAYER_NAME, "%s", gPunicoes[i+1][pun_Admin]);
            format(gPunicoes[i][pun_Motivo], MAX_MOTIVO_LEN, "%s", gPunicoes[i+1][pun_Motivo]);
            format(gPunicoes[i][pun_Tipo], 32, "%s", gPunicoes[i+1][pun_Tipo]);
            format(gPunicoes[i][pun_Data], 32, "%s", gPunicoes[i+1][pun_Data]);
        }
        gTotalPunicoes = MAX_PUNICOES - 1;
    }
    new data[32];
    data = GetDataAtual();
    format(gPunicoes[gTotalPunicoes][pun_Jogador], MAX_PLAYER_NAME, "%s", jogador);
    format(gPunicoes[gTotalPunicoes][pun_Admin], MAX_PLAYER_NAME, "%s", admin);
    format(gPunicoes[gTotalPunicoes][pun_Motivo], MAX_MOTIVO_LEN, "%s", motivo);
    format(gPunicoes[gTotalPunicoes][pun_Tipo], 32, "%s", tipo);
    format(gPunicoes[gTotalPunicoes][pun_Data], 32, "%s", data);
    gTotalPunicoes++;
}

stock SalvarBans()
{
    new File:arquivo = fopen("painel_bans.cfg", io_write);
    if(arquivo)
    {
        new linha[512];
        for(new i = 0; i < gTotalBans; i++)
        {
            if(gBanList[i][ban_Ativo])
            {
                format(linha, sizeof(linha), "%s|%s|%s|%s|%s\n",
                    gBanList[i][ban_Nome],
                    gBanList[i][ban_IP],
                    gBanList[i][ban_Motivo],
                    gBanList[i][ban_Admin],
                    gBanList[i][ban_Data]);
                fwrite(arquivo, linha);
            }
        }
        fclose(arquivo);
    }
}

stock CarregarBans()
{
    if(!fexist("painel_bans.cfg")) return 0;
    new File:arquivo = fopen("painel_bans.cfg", io_read);
    if(arquivo)
    {
        new linha[512];
        gTotalBans = 0;
        while(fread(arquivo, linha))
        {
            if(gTotalBans >= MAX_BANS) break;
            // Parse: Nome|IP|Motivo|Admin|Data
            new pos = 0, campo = 0;
            new temp[256];
            new len = strlen(linha);
            // Remove newline
            if(len > 0 && linha[len-1] == '\n') linha[len-1] = '\0';

            new tempPos = 0;
            for(new i = 0; i <= len; i++)
            {
                if(linha[i] == '|' || linha[i] == '\0')
                {
                    temp[tempPos] = '\0';
                    switch(campo)
                    {
                        case 0: format(gBanList[gTotalBans][ban_Nome], MAX_PLAYER_NAME, "%s", temp);
                        case 1: format(gBanList[gTotalBans][ban_IP], 16, "%s", temp);
                        case 2: format(gBanList[gTotalBans][ban_Motivo], MAX_MOTIVO_LEN, "%s", temp);
                        case 3: format(gBanList[gTotalBans][ban_Admin], MAX_PLAYER_NAME, "%s", temp);
                        case 4: format(gBanList[gTotalBans][ban_Data], 32, "%s", temp);
                    }
                    campo++;
                    tempPos = 0;
                }
                else
                {
                    temp[tempPos++] = linha[i];
                }
            }
            gBanList[gTotalBans][ban_Ativo] = true;
            gTotalBans++;
            #pragma unused pos
        }
        fclose(arquivo);
    }
    return 1;
}

stock SalvarLogs()
{
    new File:arquivo = fopen("painel_logs.cfg", io_write);
    if(arquivo)
    {
        for(new i = 0; i < gTotalLogs; i++)
        {
            new linha[260];
            format(linha, sizeof(linha), "%s\n", gLogServidor[i]);
            fwrite(arquivo, linha);
        }
        fclose(arquivo);
    }
}

stock CarregarLogs()
{
    if(!fexist("painel_logs.cfg")) return 0;
    new File:arquivo = fopen("painel_logs.cfg", io_read);
    if(arquivo)
    {
        new linha[260];
        gTotalLogs = 0;
        while(fread(arquivo, linha))
        {
            if(gTotalLogs >= MAX_LOG_ENTRIES) break;
            new len = strlen(linha);
            if(len > 0 && linha[len-1] == '\n') linha[len-1] = '\0';
            format(gLogServidor[gTotalLogs], 256, "%s", linha);
            gTotalLogs++;
        }
        fclose(arquivo);
    }
    return 1;
}

stock IsPlayerBanned(const nome[])
{
    for(new i = 0; i < gTotalBans; i++)
    {
        if(gBanList[i][ban_Ativo] && !strcmp(gBanList[i][ban_Nome], nome, true))
            return 1;
    }
    return 0;
}

stock RemoverBan(const nome[])
{
    for(new i = 0; i < gTotalBans; i++)
    {
        if(gBanList[i][ban_Ativo] && !strcmp(gBanList[i][ban_Nome], nome, true))
        {
            gBanList[i][ban_Ativo] = false;
            SalvarBans();
            return 1;
        }
    }
    return 0;
}

stock ContarJogadoresOnline()
{
    new count = 0;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i)) count++;
    }
    return count;
}

// ============================================================================
// CRIACAO DOS TEXTDRAWS DO PAINEL
// ============================================================================

stock CriarPainelTextdraws(playerid)
{
    // --- FUNDO PRINCIPAL ---
    pTD[playerid][TD_FUNDO_PRINCIPAL] = CreatePlayerTextDraw(playerid, 70.0, 60.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_FUNDO_PRINCIPAL], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_FUNDO_PRINCIPAL], 0.0, 0.0);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_FUNDO_PRINCIPAL], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_FUNDO_PRINCIPAL], 0xBB000A1E);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_FUNDO_PRINCIPAL], 570.0, 0.0);
    PlayerTextDrawSetProportional(playerid, pTD[playerid][TD_FUNDO_PRINCIPAL], 1);

    // Simular altura com um textdraw de fundo alto
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_FUNDO_PRINCIPAL], 0.0, 32.0);

    // --- TITULO ---
    pTD[playerid][TD_TITULO] = CreatePlayerTextDraw(playerid, 200.0, 63.0, "Painel Administrativo ~b~Staff");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_TITULO], 2);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_TITULO], 0.30, 1.5);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_TITULO], 0xFFCCDDEE);
    PlayerTextDrawSetOutline(playerid, pTD[playerid][TD_TITULO], 1);
    PlayerTextDrawSetShadow(playerid, pTD[playerid][TD_TITULO], 0);

    // --- SEPARADOR TOP ---
    pTD[playerid][TD_SEPARADOR_TOP] = CreatePlayerTextDraw(playerid, 75.0, 78.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_SEPARADOR_TOP], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_SEPARADOR_TOP], 0.0, -0.3);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_SEPARADOR_TOP], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_SEPARADOR_TOP], 0xFF2255AA);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_SEPARADOR_TOP], 565.0, 0.0);

    // === ABAS ===
    // Aba Geral
    pTD[playerid][TD_ABA_GERAL] = CreatePlayerTextDraw(playerid, 85.0, 83.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_ABA_GERAL], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_ABA_GERAL], 0.0, 1.2);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_ABA_GERAL], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_ABA_GERAL], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_ABA_GERAL], 195.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_ABA_GERAL], 1);

    pTD[playerid][TD_LBL_ABA_GERAL] = CreatePlayerTextDraw(playerid, 115.0, 84.0, "Geral");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_ABA_GERAL], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_ABA_GERAL], 0.22, 1.0);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_ABA_GERAL], 0xFF00CCFF);

    // Aba Logs
    pTD[playerid][TD_ABA_LOGS] = CreatePlayerTextDraw(playerid, 200.0, 83.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_ABA_LOGS], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_ABA_LOGS], 0.0, 1.2);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_ABA_LOGS], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_ABA_LOGS], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_ABA_LOGS], 310.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_ABA_LOGS], 1);

    pTD[playerid][TD_LBL_ABA_LOGS] = CreatePlayerTextDraw(playerid, 225.0, 84.0, "Copiar Log");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_ABA_LOGS], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_ABA_LOGS], 0.22, 1.0);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_ABA_LOGS], 0xFFCCDDEE);

    // Aba Banidos
    pTD[playerid][TD_ABA_BANIDOS] = CreatePlayerTextDraw(playerid, 315.0, 83.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_ABA_BANIDOS], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_ABA_BANIDOS], 0.0, 1.2);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_ABA_BANIDOS], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_ABA_BANIDOS], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_ABA_BANIDOS], 425.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_ABA_BANIDOS], 1);

    pTD[playerid][TD_LBL_ABA_BANIDOS] = CreatePlayerTextDraw(playerid, 335.0, 84.0, "Banidos");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_ABA_BANIDOS], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_ABA_BANIDOS], 0.22, 1.0);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_ABA_BANIDOS], 0xFFCCDDEE);

    // === PAINEL ESQUERDO - LISTA DE JOGADORES ===
    pTD[playerid][TD_LISTA_TITULO] = CreatePlayerTextDraw(playerid, 78.0, 100.0, "Jogadores Conectados: 0");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LISTA_TITULO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LISTA_TITULO], 0.20, 1.0);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LISTA_TITULO], 0xFF00CCFF);
    PlayerTextDrawSetOutline(playerid, pTD[playerid][TD_LISTA_TITULO], 0);
    PlayerTextDrawSetShadow(playerid, pTD[playerid][TD_LISTA_TITULO], 1);

    pTD[playerid][TD_LISTA_FUNDO] = CreatePlayerTextDraw(playerid, 75.0, 112.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LISTA_FUNDO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LISTA_FUNDO], 0.0, 14.5);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_LISTA_FUNDO], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_LISTA_FUNDO], 0xBB0A1428);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_LISTA_FUNDO], 220.0, 0.0);

    pTD[playerid][TD_LISTA_CONTEUDO] = CreatePlayerTextDraw(playerid, 80.0, 114.0, "Carregando...");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LISTA_CONTEUDO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LISTA_CONTEUDO], 0.17, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LISTA_CONTEUDO], 0xFFAABBCC);
    PlayerTextDrawSetOutline(playerid, pTD[playerid][TD_LISTA_CONTEUDO], 0);
    PlayerTextDrawSetShadow(playerid, pTD[playerid][TD_LISTA_CONTEUDO], 0);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_LISTA_CONTEUDO], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_LISTA_CONTEUDO], 0x00000000);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_LISTA_CONTEUDO], 215.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_LISTA_CONTEUDO], 1);

    // === PAINEL CENTRAL - CAMPOS DE ENTRADA ===
    // Label "ID do Jogador"
    pTD[playerid][TD_CAMPO_ID_LABEL] = CreatePlayerTextDraw(playerid, 230.0, 102.0, "ID do Jogador:");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_CAMPO_ID_LABEL], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_CAMPO_ID_LABEL], 0.19, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_CAMPO_ID_LABEL], 0xFFCCDDEE);

    // Campo ID fundo
    pTD[playerid][TD_CAMPO_ID_FUNDO] = CreatePlayerTextDraw(playerid, 230.0, 114.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_CAMPO_ID_FUNDO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_CAMPO_ID_FUNDO], 0.0, 1.2);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_CAMPO_ID_FUNDO], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_CAMPO_ID_FUNDO], 0xBB0A1428);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_CAMPO_ID_FUNDO], 400.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_CAMPO_ID_FUNDO], 1);

    // Texto ID
    pTD[playerid][TD_CAMPO_ID_TEXTO] = CreatePlayerTextDraw(playerid, 235.0, 114.5, "Nenhum selecionado");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_CAMPO_ID_TEXTO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_CAMPO_ID_TEXTO], 0.18, 1.0);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_CAMPO_ID_TEXTO], 0xFF88AACC);

    // Label "Motivo"
    pTD[playerid][TD_CAMPO_MOTIVO_LBL] = CreatePlayerTextDraw(playerid, 230.0, 132.0, "Motivo:");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_CAMPO_MOTIVO_LBL], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_CAMPO_MOTIVO_LBL], 0.19, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_CAMPO_MOTIVO_LBL], 0xFFCCDDEE);

    // Campo Motivo fundo
    pTD[playerid][TD_CAMPO_MOTIVO_FND] = CreatePlayerTextDraw(playerid, 230.0, 143.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_CAMPO_MOTIVO_FND], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_CAMPO_MOTIVO_FND], 0.0, 1.2);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_CAMPO_MOTIVO_FND], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_CAMPO_MOTIVO_FND], 0xBB0A1428);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_CAMPO_MOTIVO_FND], 400.0, 0.0);

    // Texto Motivo
    pTD[playerid][TD_CAMPO_MOTIVO_TXT] = CreatePlayerTextDraw(playerid, 235.0, 143.5, "Clique em uma acao...");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], 0.18, 1.0);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], 0xFF88AACC);

    // === SEPARADOR MEIO ===
    pTD[playerid][TD_SEP_MEIO] = CreatePlayerTextDraw(playerid, 75.0, 163.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_SEP_MEIO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_SEP_MEIO], 0.0, -0.3);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_SEP_MEIO], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_SEP_MEIO], 0xBB334466);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_SEP_MEIO], 565.0, 0.0);

    // === BOTOES DE ACAO (DIREITA) ===
    new Float:btnX = 410.0;
    new Float:btnY = 102.0;
    new Float:btnW = 560.0;
    new Float:btnH = 1.0;
    new Float:btnSpacing = 16.0;

    // Expulsar Player (Kick)
    pTD[playerid][TD_BTN_EXPULSAR] = CreatePlayerTextDraw(playerid, btnX, btnY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_EXPULSAR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_EXPULSAR], 0.0, btnH);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_EXPULSAR], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_EXPULSAR], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_EXPULSAR], btnW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_EXPULSAR], 1);

    pTD[playerid][TD_LBL_EXPULSAR] = CreatePlayerTextDraw(playerid, btnX + 15.0, btnY + 1.0, "Expulsar Player ~r~(Kick)");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_EXPULSAR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_EXPULSAR], 0.18, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_EXPULSAR], 0xFFCCDDEE);

    // Banir Jogador
    btnY += btnSpacing;
    pTD[playerid][TD_BTN_BANIR] = CreatePlayerTextDraw(playerid, btnX, btnY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_BANIR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_BANIR], 0.0, btnH);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_BANIR], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_BANIR], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_BANIR], btnW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_BANIR], 1);

    pTD[playerid][TD_LBL_BANIR] = CreatePlayerTextDraw(playerid, btnX + 15.0, btnY + 1.0, "Banir Jogador");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_BANIR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_BANIR], 0.18, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_BANIR], 0xFFCCDDEE);

    // Punir Jogador
    btnY += btnSpacing;
    pTD[playerid][TD_BTN_PUNIR] = CreatePlayerTextDraw(playerid, btnX, btnY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_PUNIR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_PUNIR], 0.0, btnH);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_PUNIR], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_PUNIR], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_PUNIR], btnW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_PUNIR], 1);

    pTD[playerid][TD_LBL_PUNIR] = CreatePlayerTextDraw(playerid, btnX + 15.0, btnY + 1.0, "Punir Jogador");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_PUNIR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_PUNIR], 0.18, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_PUNIR], 0xFFCCDDEE);

    // Aguardar Banimento
    btnY += btnSpacing;
    pTD[playerid][TD_BTN_AGUARDAR] = CreatePlayerTextDraw(playerid, btnX, btnY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_AGUARDAR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_AGUARDAR], 0.0, btnH);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_AGUARDAR], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_AGUARDAR], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_AGUARDAR], btnW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_AGUARDAR], 1);

    pTD[playerid][TD_LBL_AGUARDAR] = CreatePlayerTextDraw(playerid, btnX + 15.0, btnY + 1.0, "Aguardar Banimento");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_AGUARDAR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_AGUARDAR], 0.18, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_AGUARDAR], 0xFFCCDDEE);

    // Aceitar Jogador
    btnY += btnSpacing;
    pTD[playerid][TD_BTN_ACEITAR] = CreatePlayerTextDraw(playerid, btnX, btnY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_ACEITAR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_ACEITAR], 0.0, btnH);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_ACEITAR], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_ACEITAR], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_ACEITAR], btnW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_ACEITAR], 1);

    pTD[playerid][TD_LBL_ACEITAR] = CreatePlayerTextDraw(playerid, btnX + 15.0, btnY + 1.0, "Aceitar Jogador");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_ACEITAR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_ACEITAR], 0.18, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_ACEITAR], 0xFFCCDDEE);

    // Setar ao mundo
    btnY += btnSpacing;
    pTD[playerid][TD_BTN_SETAR_MUNDO] = CreatePlayerTextDraw(playerid, btnX, btnY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_SETAR_MUNDO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_SETAR_MUNDO], 0.0, btnH);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_SETAR_MUNDO], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_SETAR_MUNDO], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_SETAR_MUNDO], btnW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_SETAR_MUNDO], 1);

    pTD[playerid][TD_LBL_SETAR_MUNDO] = CreatePlayerTextDraw(playerid, btnX + 15.0, btnY + 1.0, "Setar ao Mundo");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_SETAR_MUNDO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_SETAR_MUNDO], 0.18, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_SETAR_MUNDO], 0xFFCCDDEE);

    // Limpar Logs
    btnY += btnSpacing;
    pTD[playerid][TD_BTN_LIMPAR_LOGS] = CreatePlayerTextDraw(playerid, btnX, btnY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_LIMPAR_LOGS], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_LIMPAR_LOGS], 0.0, btnH);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_LIMPAR_LOGS], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_LIMPAR_LOGS], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_LIMPAR_LOGS], btnW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_LIMPAR_LOGS], 1);

    pTD[playerid][TD_LBL_LIMPAR_LOGS] = CreatePlayerTextDraw(playerid, btnX + 15.0, btnY + 1.0, "Limpar Logs");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_LIMPAR_LOGS], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_LIMPAR_LOGS], 0.18, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_LIMPAR_LOGS], 0xFFCCDDEE);

    // Limpar Punicao
    btnY += btnSpacing;
    pTD[playerid][TD_BTN_LIMPAR_PUN] = CreatePlayerTextDraw(playerid, btnX, btnY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_LIMPAR_PUN], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_LIMPAR_PUN], 0.0, btnH);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_LIMPAR_PUN], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_LIMPAR_PUN], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_LIMPAR_PUN], btnW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_LIMPAR_PUN], 1);

    pTD[playerid][TD_LBL_LIMPAR_PUN] = CreatePlayerTextDraw(playerid, btnX + 15.0, btnY + 1.0, "Limpar Punicao");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_LIMPAR_PUN], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_LIMPAR_PUN], 0.18, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_LIMPAR_PUN], 0xFFCCDDEE);

    // === SEPARADOR BAIXO ===
    pTD[playerid][TD_SEP_BAIXO] = CreatePlayerTextDraw(playerid, 75.0, 240.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_SEP_BAIXO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_SEP_BAIXO], 0.0, -0.3);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_SEP_BAIXO], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_SEP_BAIXO], 0xBB334466);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_SEP_BAIXO], 565.0, 0.0);

    // === ACOES EXTRAS ===
    pTD[playerid][TD_EXTRA_TITULO] = CreatePlayerTextDraw(playerid, 78.0, 244.0, "~b~Acoes Extras:");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_EXTRA_TITULO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_EXTRA_TITULO], 0.19, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_EXTRA_TITULO], 0xFFCCDDEE);

    new Float:extraX = 78.0;
    new Float:extraY = 257.0;
    new Float:extraW = 153.0;

    // Ir ao Player
    pTD[playerid][TD_BTN_IR_PLAYER] = CreatePlayerTextDraw(playerid, extraX, extraY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_IR_PLAYER], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_IR_PLAYER], 0.0, 1.0);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_IR_PLAYER], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_IR_PLAYER], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_IR_PLAYER], extraW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_IR_PLAYER], 1);

    pTD[playerid][TD_LBL_IR_PLAYER] = CreatePlayerTextDraw(playerid, extraX + 10.0, extraY + 1.0, "Ir ao Player");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_IR_PLAYER], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_IR_PLAYER], 0.17, 0.8);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_IR_PLAYER], 0xFFCCDDEE);

    // Trazer Player
    pTD[playerid][TD_BTN_TRAZER] = CreatePlayerTextDraw(playerid, extraW + 8.0, extraY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_TRAZER], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_TRAZER], 0.0, 1.0);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_TRAZER], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_TRAZER], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_TRAZER], extraW + 83.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_TRAZER], 1);

    pTD[playerid][TD_LBL_TRAZER] = CreatePlayerTextDraw(playerid, extraW + 18.0, extraY + 1.0, "Trazer Player");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_TRAZER], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_TRAZER], 0.17, 0.8);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_TRAZER], 0xFFCCDDEE);

    // Verificar APK
    extraY += 16.0;
    pTD[playerid][TD_BTN_VERIFICAR] = CreatePlayerTextDraw(playerid, extraX, extraY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_VERIFICAR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_VERIFICAR], 0.0, 1.0);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_VERIFICAR], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_VERIFICAR], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_VERIFICAR], extraW, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_VERIFICAR], 1);

    pTD[playerid][TD_LBL_VERIFICAR] = CreatePlayerTextDraw(playerid, extraX + 10.0, extraY + 1.0, "Verificar APK");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_VERIFICAR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_VERIFICAR], 0.17, 0.8);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_VERIFICAR], 0xFFCCDDEE);

    // Explodir
    pTD[playerid][TD_BTN_EXPLODIR] = CreatePlayerTextDraw(playerid, extraW + 8.0, extraY, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_EXPLODIR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_EXPLODIR], 0.0, 1.0);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_EXPLODIR], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_EXPLODIR], 0xBB1E3250);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_EXPLODIR], extraW + 83.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_EXPLODIR], 1);

    pTD[playerid][TD_LBL_EXPLODIR] = CreatePlayerTextDraw(playerid, extraW + 18.0, extraY + 1.0, "Explodir");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_EXPLODIR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_EXPLODIR], 0.17, 0.8);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_EXPLODIR], 0xFFCCDDEE);

    // === INFO PUNICOES ===
    pTD[playerid][TD_PUNICAO_INFO] = CreatePlayerTextDraw(playerid, 230.0, 167.0, "Total de Punicoes: ~y~0");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_PUNICAO_INFO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_PUNICAO_INFO], 0.18, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_PUNICAO_INFO], 0xFFCCDDEE);

    // === LOG DO SERVIDOR ===
    pTD[playerid][TD_LOG_TITULO] = CreatePlayerTextDraw(playerid, 250.0, 182.0, "~b~Log do Servidor:");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LOG_TITULO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LOG_TITULO], 0.19, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LOG_TITULO], 0xFFCCDDEE);

    pTD[playerid][TD_LOG_FUNDO] = CreatePlayerTextDraw(playerid, 248.0, 194.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LOG_FUNDO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LOG_FUNDO], 0.0, 8.5);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_LOG_FUNDO], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_LOG_FUNDO], 0xBB0A1428);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_LOG_FUNDO], 565.0, 0.0);

    pTD[playerid][TD_LOG_CONTEUDO] = CreatePlayerTextDraw(playerid, 252.0, 196.0, "Nenhum log registrado.");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LOG_CONTEUDO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LOG_CONTEUDO], 0.15, 0.7);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LOG_CONTEUDO], 0xFF88AACC);
    PlayerTextDrawSetOutline(playerid, pTD[playerid][TD_LOG_CONTEUDO], 0);
    PlayerTextDrawSetShadow(playerid, pTD[playerid][TD_LOG_CONTEUDO], 0);

    // === BANIDOS ===
    pTD[playerid][TD_BANIDOS_TITULO] = CreatePlayerTextDraw(playerid, 78.0, 295.0, "~r~Jogadores Banidos (0):");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BANIDOS_TITULO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BANIDOS_TITULO], 0.19, 0.9);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_BANIDOS_TITULO], 0xFFCCDDEE);

    pTD[playerid][TD_BANIDOS_FUNDO] = CreatePlayerTextDraw(playerid, 75.0, 307.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BANIDOS_FUNDO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BANIDOS_FUNDO], 0.0, 4.5);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BANIDOS_FUNDO], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BANIDOS_FUNDO], 0xBB0A1428);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BANIDOS_FUNDO], 240.0, 0.0);

    pTD[playerid][TD_BANIDOS_CONTEUDO] = CreatePlayerTextDraw(playerid, 80.0, 309.0, "Nenhum banido.");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BANIDOS_CONTEUDO], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BANIDOS_CONTEUDO], 0.15, 0.7);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_BANIDOS_CONTEUDO], 0xFFCC4444);
    PlayerTextDrawSetOutline(playerid, pTD[playerid][TD_BANIDOS_CONTEUDO], 0);
    PlayerTextDrawSetShadow(playerid, pTD[playerid][TD_BANIDOS_CONTEUDO], 0);

    // === BOTAO FECHAR ===
    pTD[playerid][TD_BTN_FECHAR] = CreatePlayerTextDraw(playerid, 545.0, 63.0, "_");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_BTN_FECHAR], 1);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_BTN_FECHAR], 0.0, 1.2);
    PlayerTextDrawUseBox(playerid, pTD[playerid][TD_BTN_FECHAR], 1);
    PlayerTextDrawBoxColor(playerid, pTD[playerid][TD_BTN_FECHAR], 0xBBCC2222);
    PlayerTextDrawTextSize(playerid, pTD[playerid][TD_BTN_FECHAR], 565.0, 15.0);
    PlayerTextDrawSetSelectable(playerid, pTD[playerid][TD_BTN_FECHAR], 1);

    pTD[playerid][TD_LBL_FECHAR] = CreatePlayerTextDraw(playerid, 550.0, 64.0, "X");
    PlayerTextDrawFont(playerid, pTD[playerid][TD_LBL_FECHAR], 2);
    PlayerTextDrawLetterSize(playerid, pTD[playerid][TD_LBL_FECHAR], 0.25, 1.0);
    PlayerTextDrawColor(playerid, pTD[playerid][TD_LBL_FECHAR], 0xFFFFFFFF);
}

// ============================================================================
// MOSTRAR / ESCONDER PAINEL
// ============================================================================

stock MostrarPainel(playerid)
{
    if(pPainelAberto[playerid]) return 0;

    CriarPainelTextdraws(playerid);

    for(new i = 0; i < MAX_PAINEL_TD; i++)
    {
        PlayerTextDrawShow(playerid, pTD[playerid][i]);
    }

    SelectTextDraw(playerid, 0xFF4488CC);
    pPainelAberto[playerid] = true;
    pJogadorSelecionado[playerid] = INVALID_PLAYER_ID;
    pAbaAtual[playerid] = 0;
    pAcaoPendente[playerid] = 0;

    AtualizarListaJogadores(playerid);
    AtualizarLogNoTextdraw(playerid);
    AtualizarBanidosNoTextdraw(playerid);
    AtualizarInfoPunicoes(playerid);

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s abriu o painel administrativo", GetPlayerNameEx(playerid));
    AdicionarLog(logMsg);

    return 1;
}

stock EsconderPainel(playerid)
{
    if(!pPainelAberto[playerid]) return 0;

    for(new i = 0; i < MAX_PAINEL_TD; i++)
    {
        PlayerTextDrawHide(playerid, pTD[playerid][i]);
        PlayerTextDrawDestroy(playerid, pTD[playerid][i]);
    }

    CancelSelectTextDraw(playerid);
    pPainelAberto[playerid] = false;
    pAcaoPendente[playerid] = 0;
    return 1;
}

// ============================================================================
// ATUALIZACOES DE CONTEUDO
// ============================================================================

stock AtualizarListaJogadores(playerid)
{
    new lista[1024];
    new count = 0;
    new nome[MAX_PLAYER_NAME];

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            GetPlayerName(i, nome, sizeof(nome));
            new temp[64];
            if(count < 15)
            {
                format(temp, sizeof(temp), "~w~[%d] %s~n~", i, nome);
                strcat(lista, temp);
            }
            count++;
        }
    }

    if(count == 0)
    {
        format(lista, sizeof(lista), "~r~Nenhum jogador online");
    }

    new titulo[64];
    format(titulo, sizeof(titulo), "Jogadores Conectados: ~b~%d", count);

    PlayerTextDrawSetString(playerid, pTD[playerid][TD_LISTA_TITULO], titulo);
    PlayerTextDrawSetString(playerid, pTD[playerid][TD_LISTA_CONTEUDO], lista);
}

stock AtualizarLogNoTextdraw(playerid)
{
    new logText[1024];
    new startIdx = gTotalLogs > 8 ? gTotalLogs - 8 : 0;

    for(new i = startIdx; i < gTotalLogs; i++)
    {
        new temp[280];
        format(temp, sizeof(temp), "~w~%s~n~", gLogServidor[i]);
        strcat(logText, temp);
    }

    if(gTotalLogs == 0)
    {
        format(logText, sizeof(logText), "~w~Nenhum log registrado.");
    }

    PlayerTextDrawSetString(playerid, pTD[playerid][TD_LOG_CONTEUDO], logText);
}

stock AtualizarBanidosNoTextdraw(playerid)
{
    new banText[512];
    new count = 0;

    for(new i = 0; i < gTotalBans; i++)
    {
        if(gBanList[i][ban_Ativo] && count < 6)
        {
            new temp[128];
            format(temp, sizeof(temp), "~r~%s ~w~- %s~n~", gBanList[i][ban_Nome], gBanList[i][ban_Motivo]);
            strcat(banText, temp);
            count++;
        }
    }

    if(count == 0)
    {
        format(banText, sizeof(banText), "~w~Nenhum jogador banido.");
    }

    new titulo[64];
    format(titulo, sizeof(titulo), "~r~Jogadores Banidos (%d):", count);

    PlayerTextDrawSetString(playerid, pTD[playerid][TD_BANIDOS_TITULO], titulo);
    PlayerTextDrawSetString(playerid, pTD[playerid][TD_BANIDOS_CONTEUDO], banText);
}

stock AtualizarInfoPunicoes(playerid)
{
    new info[64];
    format(info, sizeof(info), "Total de Punicoes: ~y~%d", gTotalPunicoes);
    PlayerTextDrawSetString(playerid, pTD[playerid][TD_PUNICAO_INFO], info);
}

stock AtualizarCampoID(playerid)
{
    new texto[64];
    if(pJogadorSelecionado[playerid] != INVALID_PLAYER_ID && IsPlayerConnected(pJogadorSelecionado[playerid]))
    {
        new nome[MAX_PLAYER_NAME];
        GetPlayerName(pJogadorSelecionado[playerid], nome, sizeof(nome));
        format(texto, sizeof(texto), "~g~[%d] %s", pJogadorSelecionado[playerid], nome);
    }
    else
    {
        format(texto, sizeof(texto), "~r~Nenhum selecionado");
    }
    PlayerTextDrawSetString(playerid, pTD[playerid][TD_CAMPO_ID_TEXTO], texto);
}

// ============================================================================
// DIALOG PARA SELECIONAR JOGADOR
// ============================================================================

stock MostrarDialogSelecionarPlayer(playerid)
{
    new lista[2048];
    new nome[MAX_PLAYER_NAME];

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            GetPlayerName(i, nome, sizeof(nome));
            new temp[64];
            format(temp, sizeof(temp), "[ID: %d] %s\n", i, nome);
            strcat(lista, temp);
        }
    }

    if(strlen(lista) == 0)
    {
        format(lista, sizeof(lista), "Nenhum jogador conectado");
    }

    ShowPlayerDialog(playerid, DIALOG_SELECIONAR_PLAYER, DIALOG_STYLE_LIST,
        "{00BFFF}Selecionar Jogador", lista, "Selecionar", "Cancelar");
}

// ============================================================================
// ACOES DO PAINEL
// ============================================================================

stock AcaoExpulsar(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro! Clique na lista de jogadores.");
        return 0;
    }
    pAcaoPendente[playerid] = 1;
    ShowPlayerDialog(playerid, DIALOG_MOTIVO, DIALOG_STYLE_INPUT,
        "{FF0000}Expulsar Jogador - Motivo",
        "{FFFFFF}Digite o motivo para expulsar o jogador:",
        "Confirmar", "Cancelar");
    return 1;
}

stock AcaoBanir(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }
    if(pAdminLevel[playerid] < ADMIN_LEVEL_ADMIN)
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Voce precisa ser Admin nivel 2+ para banir!");
        return 0;
    }
    pAcaoPendente[playerid] = 2;
    ShowPlayerDialog(playerid, DIALOG_MOTIVO_BAN, DIALOG_STYLE_INPUT,
        "{FF0000}Banir Jogador - Motivo",
        "{FFFFFF}Digite o motivo para banir o jogador:",
        "Banir", "Cancelar");
    return 1;
}

stock AcaoPunir(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }
    pAcaoPendente[playerid] = 3;
    ShowPlayerDialog(playerid, DIALOG_MOTIVO_PUNIR, DIALOG_STYLE_INPUT,
        "{FFFF00}Punir Jogador - Motivo",
        "{FFFFFF}Digite o motivo da punicao:\n(O jogador sera congelado por 60 segundos)",
        "Punir", "Cancelar");
    return 1;
}

stock AcaoAguardarBanimento(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }
    pAcaoPendente[playerid] = 4;
    ShowPlayerDialog(playerid, DIALOG_MOTIVO_AGUARDAR, DIALOG_STYLE_INPUT,
        "{FF8C00}Aguardar Banimento - Motivo",
        "{FFFFFF}Digite o motivo para colocar o jogador em espera de banimento:",
        "Confirmar", "Cancelar");
    return 1;
}

stock AcaoAceitarJogador(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }

    new nomeTarget[MAX_PLAYER_NAME], nomeAdmin[MAX_PLAYER_NAME];
    GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
    GetPlayerName(playerid, nomeAdmin, sizeof(nomeAdmin));

    // Descongelar o jogador se estiver congelado
    TogglePlayerControllable(targetid, 1);

    new msg[256];
    format(msg, sizeof(msg), "[PAINEL] {00FF00}%s {FFFFFF}foi aceito pelo admin {00BFFF}%s", nomeTarget, nomeAdmin);
    SendClientMessageToAll(COR_STAFF, msg);

    SendClientMessage(targetid, COR_SUCESSO, "[PAINEL] {FFFFFF}Voce foi aceito por um administrador! Bem-vindo ao servidor.");

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s aceitou o jogador %s", nomeAdmin, nomeTarget);
    AdicionarLog(logMsg);

    // Atualizar motivo no painel
    PlayerTextDrawSetString(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], "~g~Jogador aceito com sucesso!");
    return 1;
}

stock AcaoSetarMundo(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }
    ShowPlayerDialog(playerid, DIALOG_SETAR_MUNDO, DIALOG_STYLE_INPUT,
        "{4169E1}Setar Mundo Virtual",
        "{FFFFFF}Digite o ID do mundo virtual para enviar o jogador:",
        "Setar", "Cancelar");
    return 1;
}

stock AcaoLimparLogs(playerid)
{
    if(pAdminLevel[playerid] < ADMIN_LEVEL_DONO)
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Apenas o dono pode limpar os logs!");
        return 0;
    }
    gTotalLogs = 0;
    if(fexist("painel_logs.cfg")) fremove("painel_logs.cfg");

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s limpou todos os logs do servidor", GetPlayerNameEx(playerid));
    AdicionarLog(logMsg);

    SendClientMessage(playerid, COR_SUCESSO, "[PAINEL] {FFFFFF}Logs limpos com sucesso!");
    AtualizarLogNoTextdraw(playerid);
    return 1;
}

stock AcaoLimparPunicao(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }

    new nomeTarget[MAX_PLAYER_NAME], nomeAdmin[MAX_PLAYER_NAME];
    GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
    GetPlayerName(playerid, nomeAdmin, sizeof(nomeAdmin));

    // Descongelar
    TogglePlayerControllable(targetid, 1);

    // Remover ban se existir
    RemoverBan(nomeTarget);

    new msg[256];
    format(msg, sizeof(msg), "[PAINEL] {FFFFFF}Punicoes de {00FF00}%s {FFFFFF}foram limpas por {00BFFF}%s", nomeTarget, nomeAdmin);
    SendClientMessageToAll(COR_STAFF, msg);

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s limpou as punicoes de %s", nomeAdmin, nomeTarget);
    AdicionarLog(logMsg);
    AdicionarPunicao(nomeTarget, nomeAdmin, "Punicao removida", "Limpeza");

    AtualizarBanidosNoTextdraw(playerid);
    AtualizarInfoPunicoes(playerid);

    PlayerTextDrawSetString(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], "~g~Punicao limpa com sucesso!");
    return 1;
}

stock AcaoIrAoPlayer(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);
    SetPlayerPos(playerid, x + 1.0, y + 1.0, z);
    SetPlayerInterior(playerid, GetPlayerInterior(targetid));
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));

    new nomeTarget[MAX_PLAYER_NAME];
    GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));

    new msg[128];
    format(msg, sizeof(msg), "[PAINEL] {FFFFFF}Voce foi ate o jogador {00BFFF}%s", nomeTarget);
    SendClientMessage(playerid, COR_STAFF, msg);

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s foi ate %s", GetPlayerNameEx(playerid), nomeTarget);
    AdicionarLog(logMsg);

    EsconderPainel(playerid);
    return 1;
}

stock AcaoTrazerPlayer(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    SetPlayerPos(targetid, x + 1.0, y + 1.0, z);
    SetPlayerInterior(targetid, GetPlayerInterior(playerid));
    SetPlayerVirtualWorld(targetid, GetPlayerVirtualWorld(playerid));

    new nomeTarget[MAX_PLAYER_NAME], nomeAdmin[MAX_PLAYER_NAME];
    GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
    GetPlayerName(playerid, nomeAdmin, sizeof(nomeAdmin));

    new msg[128];
    format(msg, sizeof(msg), "[PAINEL] {FFFFFF}Voce trouxe o jogador {00BFFF}%s {FFFFFF}ate voce", nomeTarget);
    SendClientMessage(playerid, COR_STAFF, msg);

    format(msg, sizeof(msg), "[PAINEL] {FFFFFF}Voce foi trazido por {00BFFF}%s", nomeAdmin);
    SendClientMessage(targetid, COR_STAFF, msg);

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s trouxe %s", nomeAdmin, nomeTarget);
    AdicionarLog(logMsg);
    return 1;
}

stock AcaoVerificarAPK(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }

    new nomeTarget[MAX_PLAYER_NAME];
    GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));

    new ip[16];
    GetPlayerIp(targetid, ip, sizeof(ip));

    new info[512];
    format(info, sizeof(info),
        "{00BFFF}=== Informacoes do Jogador ===\n\n"
        "{FFFFFF}Nome: {00FF00}%s\n"
        "{FFFFFF}ID: {00FF00}%d\n"
        "{FFFFFF}IP: {00FF00}%s\n"
        "{FFFFFF}Ping: {00FF00}%d ms\n"
        "{FFFFFF}Score: {00FF00}%d\n"
        "{FFFFFF}Vida: {00FF00}%.0f\n"
        "{FFFFFF}Colete: {00FF00}%.0f\n"
        "{FFFFFF}Interior: {00FF00}%d\n"
        "{FFFFFF}Mundo Virtual: {00FF00}%d\n"
        "{FFFFFF}Skin: {00FF00}%d",
        nomeTarget, targetid, ip, GetPlayerPing(targetid),
        GetPlayerScore(targetid), GetPlayerHealthEx(targetid),
        GetPlayerArmourEx(targetid), GetPlayerInterior(targetid),
        GetPlayerVirtualWorld(targetid), GetPlayerSkin(targetid));

    ShowPlayerDialog(playerid, DIALOG_VERIFICAR_APK, DIALOG_STYLE_MSGBOX,
        "{00BFFF}Verificar Jogador - Informacoes", info, "Fechar", "");

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s verificou informacoes de %s", GetPlayerNameEx(playerid), nomeTarget);
    AdicionarLog(logMsg);
    return 1;
}

stock Float:GetPlayerHealthEx(playerid)
{
    new Float:hp;
    GetPlayerHealth(playerid, hp);
    return hp;
}

stock Float:GetPlayerArmourEx(playerid)
{
    new Float:armour;
    GetPlayerArmour(playerid, armour);
    return armour;
}

stock AcaoExplodir(playerid)
{
    new targetid = pJogadorSelecionado[playerid];
    if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Selecione um jogador primeiro!");
        return 0;
    }

    if(pAdminLevel[playerid] < ADMIN_LEVEL_ADMIN)
    {
        SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Voce precisa ser Admin nivel 2+ para usar esta funcao!");
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);
    CreateExplosion(x, y, z, 7, 10.0);

    new nomeTarget[MAX_PLAYER_NAME], nomeAdmin[MAX_PLAYER_NAME];
    GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
    GetPlayerName(playerid, nomeAdmin, sizeof(nomeAdmin));

    new msg[128];
    format(msg, sizeof(msg), "[PAINEL] {FF0000}%s {FFFFFF}foi explodido por {00BFFF}%s", nomeTarget, nomeAdmin);
    SendClientMessageToAll(COR_STAFF, msg);

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s explodiu %s", nomeAdmin, nomeTarget);
    AdicionarLog(logMsg);
    AdicionarPunicao(nomeTarget, nomeAdmin, "Explodido pelo admin", "Explosao");
    AtualizarInfoPunicoes(playerid);
    return 1;
}

// ============================================================================
// CALLBACKS PRINCIPAIS
// ============================================================================

public OnFilterScriptInit()
{
    print("  ============================================");
    print("  |   Painel Administrativo Staff v"PAINEL_VERSAO"       |");
    print("  |   Carregado com sucesso!                 |");
    print("  |   Comando: /painel                       |");
    print("  ============================================");

    CarregarBans();
    CarregarLogs();
    AdicionarLog("Servidor iniciado - Painel Staff carregado");
    return 1;
}

public OnFilterScriptExit()
{
    SalvarBans();
    SalvarLogs();

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && pPainelAberto[i])
        {
            EsconderPainel(i);
        }
    }
    print("[Painel Staff] Descarregado com sucesso!");
    return 1;
}

public OnPlayerConnect(playerid)
{
    pAdminLevel[playerid] = 0;
    pPainelAberto[playerid] = false;
    pJogadorSelecionado[playerid] = INVALID_PLAYER_ID;
    pAbaAtual[playerid] = 0;
    pAcaoPendente[playerid] = 0;

    // Verificar se o jogador esta banido
    new nome[MAX_PLAYER_NAME];
    GetPlayerName(playerid, nome, sizeof(nome));
    if(IsPlayerBanned(nome))
    {
        new msg[128];
        format(msg, sizeof(msg), "{FF0000}Voce esta banido deste servidor!\n{FFFFFF}Contate um administrador para mais informacoes.");
        ShowPlayerDialog(playerid, 9999, DIALOG_STYLE_MSGBOX, "{FF0000}BANIDO", msg, "Fechar", "");
        SetTimerEx("KickTimer", 500, false, "i", playerid);
        return 1;
    }

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s [ID:%d] conectou ao servidor", nome, playerid);
    AdicionarLog(logMsg);

    // Atualizar painel de admins online
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && pPainelAberto[i])
        {
            AtualizarListaJogadores(i);
        }
    }
    return 1;
}

forward KickTimer(playerid);
public KickTimer(playerid)
{
    Kick(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(pPainelAberto[playerid])
    {
        EsconderPainel(playerid);
    }

    new nome[MAX_PLAYER_NAME];
    GetPlayerName(playerid, nome, sizeof(nome));

    new razao[32];
    switch(reason)
    {
        case 0: razao = "Timeout";
        case 1: razao = "Saiu";
        case 2: razao = "Kickado/Banido";
    }

    new logMsg[128];
    format(logMsg, sizeof(logMsg), "%s desconectou (%s)", nome, razao);
    AdicionarLog(logMsg);

    // Atualizar painel de admins online
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && pPainelAberto[i])
        {
            AtualizarListaJogadores(i);
            // Se o jogador desconectado era o selecionado, resetar
            if(pJogadorSelecionado[i] == playerid)
            {
                pJogadorSelecionado[i] = INVALID_PLAYER_ID;
                AtualizarCampoID(i);
            }
        }
    }
    return 1;
}

// ============================================================================
// COMANDO /painel
// ============================================================================

public OnPlayerCommandText(playerid, cmdtext[])
{
    if(!strcmp(cmdtext, "/painel", true))
    {
        if(pAdminLevel[playerid] < ADMIN_LEVEL_MODERADOR)
        {
            SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Voce nao tem permissao para usar o painel administrativo!");
            return 1;
        }

        if(pPainelAberto[playerid])
        {
            EsconderPainel(playerid);
            SendClientMessage(playerid, COR_STAFF, "[PAINEL] {FFFFFF}Painel fechado.");
        }
        else
        {
            MostrarPainel(playerid);
            SendClientMessage(playerid, COR_STAFF, "[PAINEL] {FFFFFF}Painel aberto! Clique nos botoes para usar.");
        }
        return 1;
    }

    // Comando para setar nivel admin (para testes - remover em producao)
    if(!strfind(cmdtext, "/setadmin", true))
    {
        // /setadmin [id] [nivel]
        new params[64];
        new targetid, level;
        format(params, sizeof(params), "%s", cmdtext[10]);

        if(sscanf_basic(params, targetid, level))
        {
            if(pAdminLevel[playerid] >= ADMIN_LEVEL_DONO || !IsPlayerAdmin(playerid))
            {
                if(IsPlayerConnected(targetid))
                {
                    pAdminLevel[targetid] = level;
                    new nomeTarget[MAX_PLAYER_NAME];
                    GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
                    new msg[128];
                    format(msg, sizeof(msg), "[PAINEL] {FFFFFF}Nivel admin de {00BFFF}%s {FFFFFF}definido para {FFFF00}%d", nomeTarget, level);
                    SendClientMessage(playerid, COR_STAFF, msg);

                    new logMsg[128];
                    format(logMsg, sizeof(logMsg), "%s definiu admin nivel %d para %s", GetPlayerNameEx(playerid), level, nomeTarget);
                    AdicionarLog(logMsg);
                }
            }
        }
        return 1;
    }

    return 0;
}

stock sscanf_basic(const str[], &val1, &val2)
{
    new pos = 0;
    new len = strlen(str);

    // Skip spaces
    while(pos < len && str[pos] == ' ') pos++;

    // Parse first number
    new num1[12], idx1 = 0;
    while(pos < len && str[pos] != ' ' && idx1 < 11)
    {
        num1[idx1++] = str[pos++];
    }
    num1[idx1] = '\0';

    // Skip spaces
    while(pos < len && str[pos] == ' ') pos++;

    // Parse second number
    new num2[12], idx2 = 0;
    while(pos < len && str[pos] != ' ' && idx2 < 11)
    {
        num2[idx2++] = str[pos++];
    }
    num2[idx2] = '\0';

    if(idx1 == 0 || idx2 == 0) return 0;

    val1 = strval(num1);
    val2 = strval(num2);
    return 1;
}

// ============================================================================
// CLICK EM TEXTDRAWS
// ============================================================================

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(!pPainelAberto[playerid]) return 0;

    // Botao Fechar
    if(playertextid == pTD[playerid][TD_BTN_FECHAR])
    {
        EsconderPainel(playerid);
        SendClientMessage(playerid, COR_STAFF, "[PAINEL] {FFFFFF}Painel fechado.");
        return 1;
    }

    // Selecionar jogador (clique na lista)
    if(playertextid == pTD[playerid][TD_LISTA_CONTEUDO] || playertextid == pTD[playerid][TD_CAMPO_ID_FUNDO])
    {
        MostrarDialogSelecionarPlayer(playerid);
        return 1;
    }

    // === ABAS ===
    if(playertextid == pTD[playerid][TD_ABA_GERAL])
    {
        pAbaAtual[playerid] = 0;
        SendClientMessage(playerid, COR_STAFF, "[PAINEL] {FFFFFF}Aba: Geral");
        AtualizarListaJogadores(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_ABA_LOGS])
    {
        pAbaAtual[playerid] = 1;
        // Mostrar dialog com logs completos
        new logDialog[4096];
        for(new i = 0; i < gTotalLogs; i++)
        {
            new temp[280];
            format(temp, sizeof(temp), "%s\n", gLogServidor[i]);
            strcat(logDialog, temp);
        }
        if(gTotalLogs == 0) format(logDialog, sizeof(logDialog), "Nenhum log registrado.");
        ShowPlayerDialog(playerid, DIALOG_LOG_SERVIDOR, DIALOG_STYLE_MSGBOX,
            "{00BFFF}Log Completo do Servidor", logDialog, "Fechar", "Copiar");
        return 1;
    }
    if(playertextid == pTD[playerid][TD_ABA_BANIDOS])
    {
        pAbaAtual[playerid] = 2;
        // Mostrar dialog com lista de banidos
        new banDialog[4096];
        new count = 0;
        for(new i = 0; i < gTotalBans; i++)
        {
            if(gBanList[i][ban_Ativo])
            {
                new temp[256];
                format(temp, sizeof(temp), "%s | IP: %s | Motivo: %s | Admin: %s | Data: %s\n",
                    gBanList[i][ban_Nome], gBanList[i][ban_IP],
                    gBanList[i][ban_Motivo], gBanList[i][ban_Admin],
                    gBanList[i][ban_Data]);
                strcat(banDialog, temp);
                count++;
            }
        }
        if(count == 0) format(banDialog, sizeof(banDialog), "Nenhum jogador banido.");
        new titulo[64];
        format(titulo, sizeof(titulo), "{FF0000}Jogadores Banidos (%d)", count);
        ShowPlayerDialog(playerid, DIALOG_BANIDOS_LISTA, DIALOG_STYLE_MSGBOX,
            titulo, banDialog, "Fechar", "");
        return 1;
    }

    // === BOTOES DE ACAO ===
    if(playertextid == pTD[playerid][TD_BTN_EXPULSAR])
    {
        AcaoExpulsar(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_BANIR])
    {
        AcaoBanir(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_PUNIR])
    {
        AcaoPunir(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_AGUARDAR])
    {
        AcaoAguardarBanimento(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_ACEITAR])
    {
        AcaoAceitarJogador(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_SETAR_MUNDO])
    {
        AcaoSetarMundo(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_LIMPAR_LOGS])
    {
        AcaoLimparLogs(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_LIMPAR_PUN])
    {
        AcaoLimparPunicao(playerid);
        return 1;
    }

    // === ACOES EXTRAS ===
    if(playertextid == pTD[playerid][TD_BTN_IR_PLAYER])
    {
        AcaoIrAoPlayer(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_TRAZER])
    {
        AcaoTrazerPlayer(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_VERIFICAR])
    {
        AcaoVerificarAPK(playerid);
        return 1;
    }
    if(playertextid == pTD[playerid][TD_BTN_EXPLODIR])
    {
        AcaoExplodir(playerid);
        return 1;
    }

    return 0;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    // Quando o jogador pressiona ESC com o painel aberto
    if(clickedid == Text:INVALID_TEXT_DRAW)
    {
        if(pPainelAberto[playerid])
        {
            EsconderPainel(playerid);
            SendClientMessage(playerid, COR_STAFF, "[PAINEL] {FFFFFF}Painel fechado.");
        }
    }
    return 0;
}

// ============================================================================
// RESPOSTAS DOS DIALOGS
// ============================================================================

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    // --- Selecionar jogador da lista ---
    if(dialogid == DIALOG_SELECIONAR_PLAYER)
    {
        if(!response) return 1;

        // Encontrar o jogador pelo index na lista
        new count = 0;
        for(new i = 0; i < MAX_PLAYERS; i++)
        {
            if(IsPlayerConnected(i))
            {
                if(count == listitem)
                {
                    pJogadorSelecionado[playerid] = i;
                    AtualizarCampoID(playerid);

                    new nome[MAX_PLAYER_NAME];
                    GetPlayerName(i, nome, sizeof(nome));
                    new msg[128];
                    format(msg, sizeof(msg), "[PAINEL] {FFFFFF}Jogador selecionado: {00BFFF}[%d] %s", i, nome);
                    SendClientMessage(playerid, COR_STAFF, msg);
                    break;
                }
                count++;
            }
        }
        // Reabrir selecao de textdraw
        if(pPainelAberto[playerid]) SelectTextDraw(playerid, 0xFF4488CC);
        return 1;
    }

    // --- Motivo para Expulsar (Kick) ---
    if(dialogid == DIALOG_MOTIVO)
    {
        if(pPainelAberto[playerid]) SelectTextDraw(playerid, 0xFF4488CC);
        if(!response) { pAcaoPendente[playerid] = 0; return 1; }

        new targetid = pJogadorSelecionado[playerid];
        if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
        {
            SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Jogador nao encontrado!");
            pAcaoPendente[playerid] = 0;
            return 1;
        }

        new motivo[MAX_MOTIVO_LEN];
        if(strlen(inputtext) < 3)
        {
            format(motivo, sizeof(motivo), "Sem motivo especificado");
        }
        else
        {
            format(motivo, sizeof(motivo), "%s", inputtext);
        }

        new nomeTarget[MAX_PLAYER_NAME], nomeAdmin[MAX_PLAYER_NAME];
        GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
        GetPlayerName(playerid, nomeAdmin, sizeof(nomeAdmin));

        new msg[256];
        format(msg, sizeof(msg), "[PAINEL] {FF0000}%s {FFFFFF}foi expulso por {00BFFF}%s {FFFFFF}| Motivo: {FFFF00}%s", nomeTarget, nomeAdmin, motivo);
        SendClientMessageToAll(COR_STAFF, msg);

        format(msg, sizeof(msg), "{FF0000}Voce foi expulso!\n{FFFFFF}Admin: %s\nMotivo: %s", nomeAdmin, motivo);
        ShowPlayerDialog(targetid, 9998, DIALOG_STYLE_MSGBOX, "{FF0000}EXPULSO", msg, "Fechar", "");

        new logMsg[256];
        format(logMsg, sizeof(logMsg), "%s expulsou %s - Motivo: %s", nomeAdmin, nomeTarget, motivo);
        AdicionarLog(logMsg);
        AdicionarPunicao(nomeTarget, nomeAdmin, motivo, "Kick");

        SetTimerEx("KickTimer", 500, false, "i", targetid);

        if(pPainelAberto[playerid])
        {
            PlayerTextDrawSetString(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], "~r~Jogador expulso!");
            AtualizarInfoPunicoes(playerid);
        }
        pAcaoPendente[playerid] = 0;
        pJogadorSelecionado[playerid] = INVALID_PLAYER_ID;
        return 1;
    }

    // --- Motivo para Banir ---
    if(dialogid == DIALOG_MOTIVO_BAN)
    {
        if(pPainelAberto[playerid]) SelectTextDraw(playerid, 0xFF4488CC);
        if(!response) { pAcaoPendente[playerid] = 0; return 1; }

        new targetid = pJogadorSelecionado[playerid];
        if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
        {
            SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Jogador nao encontrado!");
            pAcaoPendente[playerid] = 0;
            return 1;
        }

        new motivo[MAX_MOTIVO_LEN];
        if(strlen(inputtext) < 3)
            format(motivo, sizeof(motivo), "Sem motivo especificado");
        else
            format(motivo, sizeof(motivo), "%s", inputtext);

        new nomeTarget[MAX_PLAYER_NAME], nomeAdmin[MAX_PLAYER_NAME];
        GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
        GetPlayerName(playerid, nomeAdmin, sizeof(nomeAdmin));

        new ip[16];
        GetPlayerIp(targetid, ip, sizeof(ip));

        // Adicionar ao sistema de bans
        if(gTotalBans < MAX_BANS)
        {
            format(gBanList[gTotalBans][ban_Nome], MAX_PLAYER_NAME, "%s", nomeTarget);
            format(gBanList[gTotalBans][ban_IP], 16, "%s", ip);
            format(gBanList[gTotalBans][ban_Motivo], MAX_MOTIVO_LEN, "%s", motivo);
            format(gBanList[gTotalBans][ban_Admin], MAX_PLAYER_NAME, "%s", nomeAdmin);
            new data[32];
            data = GetDataAtual();
            format(gBanList[gTotalBans][ban_Data], 32, "%s", data);
            gBanList[gTotalBans][ban_Ativo] = true;
            gTotalBans++;
            SalvarBans();
        }

        new msg[256];
        format(msg, sizeof(msg), "[PAINEL] {FF0000}%s {FFFFFF}foi BANIDO por {00BFFF}%s {FFFFFF}| Motivo: {FFFF00}%s", nomeTarget, nomeAdmin, motivo);
        SendClientMessageToAll(COR_STAFF, msg);

        format(msg, sizeof(msg), "{FF0000}Voce foi BANIDO!\n{FFFFFF}Admin: %s\nMotivo: %s\n\nContate um administrador se achar que foi injusto.", nomeAdmin, motivo);
        ShowPlayerDialog(targetid, 9998, DIALOG_STYLE_MSGBOX, "{FF0000}BANIDO", msg, "Fechar", "");

        new logMsg[256];
        format(logMsg, sizeof(logMsg), "%s BANIU %s (IP: %s) - Motivo: %s", nomeAdmin, nomeTarget, ip, motivo);
        AdicionarLog(logMsg);
        AdicionarPunicao(nomeTarget, nomeAdmin, motivo, "Ban");

        SetTimerEx("KickTimer", 500, false, "i", targetid);

        if(pPainelAberto[playerid])
        {
            PlayerTextDrawSetString(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], "~r~Jogador BANIDO!");
            AtualizarBanidosNoTextdraw(playerid);
            AtualizarInfoPunicoes(playerid);
        }
        pAcaoPendente[playerid] = 0;
        pJogadorSelecionado[playerid] = INVALID_PLAYER_ID;
        return 1;
    }

    // --- Motivo para Punir ---
    if(dialogid == DIALOG_MOTIVO_PUNIR)
    {
        if(pPainelAberto[playerid]) SelectTextDraw(playerid, 0xFF4488CC);
        if(!response) { pAcaoPendente[playerid] = 0; return 1; }

        new targetid = pJogadorSelecionado[playerid];
        if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
        {
            SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Jogador nao encontrado!");
            pAcaoPendente[playerid] = 0;
            return 1;
        }

        new motivo[MAX_MOTIVO_LEN];
        if(strlen(inputtext) < 3)
            format(motivo, sizeof(motivo), "Sem motivo especificado");
        else
            format(motivo, sizeof(motivo), "%s", inputtext);

        new nomeTarget[MAX_PLAYER_NAME], nomeAdmin[MAX_PLAYER_NAME];
        GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
        GetPlayerName(playerid, nomeAdmin, sizeof(nomeAdmin));

        // Congelar o jogador
        TogglePlayerControllable(targetid, 0);
        SetTimerEx("DescongelarTimer", 60000, false, "i", targetid);

        new msg[256];
        format(msg, sizeof(msg), "[PAINEL] {FFFF00}%s {FFFFFF}foi punido por {00BFFF}%s {FFFFFF}| Motivo: {FFFF00}%s {FFFFFF}(60s congelado)", nomeTarget, nomeAdmin, motivo);
        SendClientMessageToAll(COR_STAFF, msg);

        SendClientMessage(targetid, COR_AMARELO, "[PAINEL] {FFFFFF}Voce foi punido e congelado por 60 segundos!");
        format(msg, sizeof(msg), "[PAINEL] {FFFFFF}Motivo: {FFFF00}%s", motivo);
        SendClientMessage(targetid, COR_AMARELO, msg);

        new logMsg[256];
        format(logMsg, sizeof(logMsg), "%s puniu %s - Motivo: %s (congelado 60s)", nomeAdmin, nomeTarget, motivo);
        AdicionarLog(logMsg);
        AdicionarPunicao(nomeTarget, nomeAdmin, motivo, "Punicao");

        if(pPainelAberto[playerid])
        {
            PlayerTextDrawSetString(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], "~y~Jogador punido (60s)!");
            AtualizarInfoPunicoes(playerid);
        }
        pAcaoPendente[playerid] = 0;
        return 1;
    }

    // --- Motivo para Aguardar Banimento ---
    if(dialogid == DIALOG_MOTIVO_AGUARDAR)
    {
        if(pPainelAberto[playerid]) SelectTextDraw(playerid, 0xFF4488CC);
        if(!response) { pAcaoPendente[playerid] = 0; return 1; }

        new targetid = pJogadorSelecionado[playerid];
        if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
        {
            SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Jogador nao encontrado!");
            pAcaoPendente[playerid] = 0;
            return 1;
        }

        new motivo[MAX_MOTIVO_LEN];
        if(strlen(inputtext) < 3)
            format(motivo, sizeof(motivo), "Sem motivo especificado");
        else
            format(motivo, sizeof(motivo), "%s", inputtext);

        new nomeTarget[MAX_PLAYER_NAME], nomeAdmin[MAX_PLAYER_NAME];
        GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
        GetPlayerName(playerid, nomeAdmin, sizeof(nomeAdmin));

        // Congelar jogador enquanto aguarda
        TogglePlayerControllable(targetid, 0);

        new msg[256];
        format(msg, sizeof(msg), "[PAINEL] {FF8C00}%s {FFFFFF}esta aguardando banimento por {00BFFF}%s {FFFFFF}| Motivo: {FFFF00}%s", nomeTarget, nomeAdmin, motivo);
        SendClientMessageToAll(COR_STAFF, msg);

        SendClientMessage(targetid, COR_LARANJA, "[PAINEL] {FFFFFF}Voce esta em espera de banimento. Aguarde a decisao do administrador.");

        new logMsg[256];
        format(logMsg, sizeof(logMsg), "%s colocou %s em espera de banimento - Motivo: %s", nomeAdmin, nomeTarget, motivo);
        AdicionarLog(logMsg);
        AdicionarPunicao(nomeTarget, nomeAdmin, motivo, "Aguardando Ban");

        if(pPainelAberto[playerid])
        {
            PlayerTextDrawSetString(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], "~o~Aguardando banimento...");
            AtualizarInfoPunicoes(playerid);
        }
        pAcaoPendente[playerid] = 0;
        return 1;
    }

    // --- Setar mundo virtual ---
    if(dialogid == DIALOG_SETAR_MUNDO)
    {
        if(pPainelAberto[playerid]) SelectTextDraw(playerid, 0xFF4488CC);
        if(!response) return 1;

        new targetid = pJogadorSelecionado[playerid];
        if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid))
        {
            SendClientMessage(playerid, COR_ERRO, "[PAINEL] {FFFFFF}Jogador nao encontrado!");
            return 1;
        }

        new worldid = strval(inputtext);
        SetPlayerVirtualWorld(targetid, worldid);

        new nomeTarget[MAX_PLAYER_NAME], nomeAdmin[MAX_PLAYER_NAME];
        GetPlayerName(targetid, nomeTarget, sizeof(nomeTarget));
        GetPlayerName(playerid, nomeAdmin, sizeof(nomeAdmin));

        new msg[128];
        format(msg, sizeof(msg), "[PAINEL] {FFFFFF}%s {FFFFFF}foi enviado para o mundo virtual {00BFFF}%d {FFFFFF}por {00BFFF}%s", nomeTarget, worldid, nomeAdmin);
        SendClientMessageToAll(COR_STAFF, msg);

        new logMsg[128];
        format(logMsg, sizeof(logMsg), "%s setou %s para o mundo %d", nomeAdmin, nomeTarget, worldid);
        AdicionarLog(logMsg);

        if(pPainelAberto[playerid])
        {
            new tdMsg[64];
            format(tdMsg, sizeof(tdMsg), "~b~Mundo setado: %d", worldid);
            PlayerTextDrawSetString(playerid, pTD[playerid][TD_CAMPO_MOTIVO_TXT], tdMsg);
        }
        return 1;
    }

    // --- Dialogs informativos (fechar) ---
    if(dialogid == DIALOG_LOG_SERVIDOR || dialogid == DIALOG_BANIDOS_LISTA || dialogid == DIALOG_VERIFICAR_APK)
    {
        if(pPainelAberto[playerid]) SelectTextDraw(playerid, 0xFF4488CC);
        return 1;
    }

    return 0;
}

// ============================================================================
// TIMER PARA DESCONGELAR
// ============================================================================

forward DescongelarTimer(playerid);
public DescongelarTimer(playerid)
{
    if(IsPlayerConnected(playerid))
    {
        TogglePlayerControllable(playerid, 1);
        SendClientMessage(playerid, COR_SUCESSO, "[PAINEL] {FFFFFF}Voce foi descongelado. Sua punicao terminou.");
    }
    return 1;
}

// ============================================================================
// TIMER PARA ATUALIZAR PAINEL AUTOMATICAMENTE
// ============================================================================

forward AtualizarPainelTimer();
public AtualizarPainelTimer()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && pPainelAberto[i])
        {
            AtualizarListaJogadores(i);
        }
    }
    return 1;
}
