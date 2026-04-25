# Painel Administrativo Staff - SA-MP

Painel completo de administracao para servidores SA-MP com interface grafica baseada em TextDraws.

## Funcionalidades

### Painel Principal (Comando: `/painel`)
- **Lista de jogadores conectados** com atualizacao em tempo real
- **Selecao de jogador** clicando na lista ou no campo de ID
- **Abas**: Geral, Copiar Log, Banidos

### Botoes de Acao
| Botao | Descricao | Nivel Minimo |
|-------|-----------|-------------|
| Expulsar Player (Kick) | Expulsa o jogador do servidor | Moderador (1) |
| Banir Jogador | Bane permanentemente o jogador | Admin (2) |
| Punir Jogador | Congela o jogador por 60 segundos | Moderador (1) |
| Aguardar Banimento | Coloca jogador em espera de ban | Moderador (1) |
| Aceitar Jogador | Aceita/descongela jogador | Moderador (1) |
| Setar ao Mundo | Envia jogador para mundo virtual | Moderador (1) |
| Limpar Logs | Limpa todos os logs do servidor | Dono (3) |
| Limpar Punicao | Remove punicoes do jogador | Moderador (1) |

### Acoes Extras
| Acao | Descricao |
|------|-----------|
| Ir ao Player | Teleporta ate o jogador selecionado |
| Trazer Player | Traz o jogador ate voce |
| Verificar APK | Mostra informacoes detalhadas do jogador |
| Explodir | Cria explosao na posicao do jogador |

### Sistemas Integrados
- **Sistema de Bans** com persistencia em arquivo (`painel_bans.cfg`)
- **Sistema de Logs** com registro automatico de todas as acoes
- **Sistema de Punicoes** com historico completo
- **Verificacao de ban** automatica no connect do jogador

## Niveis de Administracao

| Nivel | Nome | Permissoes |
|-------|------|-----------|
| 1 | Moderador | Acesso basico ao painel |
| 2 | Admin | Banir, Explodir |
| 3 | Dono | Limpar logs, Setar admin |

## Instalacao

1. Copie o arquivo `PainelStaff.pwn` para a pasta `filterscripts/` do seu servidor
2. Compile com o compilador PAWN:
   ```
   pawncc PainelStaff.pwn -i<caminho_dos_includes>
   ```
3. Adicione ao `server.cfg`:
   ```
   filterscripts PainelStaff
   ```
4. Reinicie o servidor

## Comandos

| Comando | Descricao | Permissao |
|---------|-----------|-----------|
| `/painel` | Abre/fecha o painel staff | Admin nivel 1+ |
| `/setadmin [id] [nivel]` | Define nivel admin (teste) | Dono/RCON |

## Cores do Painel

O painel usa uma paleta de cores escura/azul inspirada no estilo moderno:
- Fundo principal: azul escuro
- Botoes: azul medio
- Destaques: azul claro / ciano
- Alertas: vermelho / amarelo / laranja

## Arquivos de Dados

| Arquivo | Descricao |
|---------|-----------|
| `painel_bans.cfg` | Lista de jogadores banidos |
| `painel_logs.cfg` | Logs do servidor |

## Notas

- O sistema de admin (`pAdminLevel`) deve ser integrado com o seu sistema existente
- O comando `/setadmin` eh para testes - remova ou proteja em producao
- O painel atualiza automaticamente quando jogadores conectam/desconectam
- Todas as acoes sao registradas no log do servidor
