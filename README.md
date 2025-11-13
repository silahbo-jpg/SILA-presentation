# 🎬 SILA Presentation Engine

**Sistema institucional para geração automatizada de vídeos e auditoria confiável de estrutura de projeto.**

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Instalação](#instalação)
- [Scripts Disponíveis](#scripts-disponíveis)
- [Auditoria e Proteção](#auditoria-e-proteção)
- [GitHub Actions](#github-actions)
- [Distribuição](#distribuição)
- [Manutenção](#manutenção)
- [Suporte](#suporte)

---

## 🎯 Visão Geral

O **SILA Presentation Engine** é um sistema automatizado que:

✅ Gera vídeos institucionais (formato EPIC e resumido)  
✅ Realiza auditoria estrutural completa do projeto  
✅ Valida integridade de arquivos críticos  
✅ Protege `package.json` contra corrupção/deleção  
✅ Executa testes de fumaça e integração automaticamente  
✅ Mantém histórico de auditorias via GitHub Actions  

---

## 📦 Estrutura do Projeto

```
SILA-presentation/
├── 📄 package.json                    # Metadados e scripts npm
├── 📄 package.json.backup             # Backup automático
├── 📄 generate_video.js               # Motor de geração de vídeos
├── 📄 README.md                       # Esta documentação
├── 📄 CHANGELOG.md                    # Histórico de mudanças
│
├── 📁 configs/
│   └── epic.json                      # Configuração padrão EPIC
│
├── 📁 frames/
│   └── epic/                          # Frames para geração
│
├── 📁 output/
│   └── epic/                          # Vídeos gerados (output)
│
├── 📁 i18n/
│   ├── index.js                       # Internacionalização
│   └── strings.json
│
├── 📁 audio/
│   └── (narração gerada ou importada)
│
├── 📁 scripts/
│   ├── tree_clean.sh                  # ✅ Árvore simples
│   ├── audit_structure.sh             # ✅ Auditoria estrutural
│   ├── validate_structure.sh          # ✅ Validação de integridade
│   ├── protect_package.sh             # 🔐 Proteção de package.json
│   ├── audit/                         # Verificações de qualidade
│   ├── tests/                         # Suite de testes
│   └── ...
│
└── 📁 .github/
    └── workflows/
        └── audit-structure.yml        # 🤖 Automação CI/CD
```

---

## 🚀 Instalação

### Pré-requisitos

- Node.js 18+ instalado
- npm 8+
- `tree` utility (opcional, mas recomendado): `apt-get install tree`

### Passos

```bash
# 1. Clonar ou extrair o projeto
cd ~/dev/sila-showcase/SILA-presentation

# 2. Instalar dependências
npm install

# 3. Validar ambiente
npm run validate

# 4. Verificar estrutura
npm run validate:structure

# 5. Proteger package.json
npm run protect:package
```

---

## 🔧 Scripts Disponíveis

### 🎥 Geração de Conteúdo

```bash
# Gera vídeo padrão
npm run generate

# Gera vídeo completo (EPIC) - recomendado
npm run generate:epic

# Teste rápido (modo curto)
npm run generate:short

# Teste rápido EPIC
npm run generate:epic:short

# Gerar com configuração customizada
npm run generate:custom
```

### 📊 Auditoria e Validação

```bash
# Árvore limpa do projeto (rápida, foco em código)
npm run audit:tree

# Auditoria estrutural completa (5 níveis de profundidade)
npm run audit:structure

# Validar diretórios e arquivos críticos
npm run validate:structure

# Proteger e restaurar package.json
npm run protect:package
```

### 🏥 Diagnóstico

```bash
# Validação básica do ambiente
npm run validate

# Diagnóstico verboso
npm run doctor

# Diagnóstico completo
npm run diagnostics

# Auditoria de scripts npm
npm run audit:scripts
```

### 🧪 Testes

```bash
# Teste de fumaça (verificação rápida)
npm run test:smoke

# Teste de integração (gera vídeo teste)
npm run test:integration

# Todos os testes
npm run test:all
```

### 🛠️ Utilitários

```bash
# Limpar outputs
npm run clean

# Limpar tudo (outputs + logs)
npm run clean:all

# Reset completo (reinstala node_modules)
npm run reset

# Benchmark de performance
npm run benchmark

# Listar presets disponíveis
npm run preset:list

# Validar presets JSON
npm run preset:validate
```

---

## 🔐 Auditoria e Proteção

### Sistema de Proteção

O projeto inclui um sistema automático de proteção do `package.json`:

```bash
npm run protect:package
```

**O que faz:**
- ✅ Valida sintaxe JSON
- ✅ Verifica campos obrigatórios (name, version, scripts, etc.)
- ✅ Cria backup automático: `package.json.backup`
- ✅ Detecta corrupção ou deleção
- ✅ Restaura automaticamente do backup se necessário

**Backup sincronizado:**
- Sempre atualizado após cada execução de `protect:package`
- Recuperação rápida em caso de emergência

### Auditoria Estrutural

```bash
npm run audit:structure
```

**Gera relatório com:**
- Árvore limpa do projeto (5 níveis)
- Apenas arquivos de código (`.js`, `.json`, `.sh`, `.md`)
- Exclusões automáticas (node_modules, .git, output, logs, etc.)
- Timestamp da auditoria

---

## 🤖 GitHub Actions

### Workflow: `audit-structure.yml`

Executa automaticamente em:
- **Push** para `main` ou `develop`
- **Pull Requests** contra `main` ou `develop`
- Mudanças em: `.js`, `.json`, `.sh`, `.md`, `package.json`

**Etapas do workflow:**

1. 📥 Checkout do código
2. 📦 Setup Node.js 18
3. 📋 Instalar `tree` utility
4. 🔍 Executar `npm run audit:structure`
5. ✅ Executar `npm run validate:structure`
6. 📊 Gerar relatório em Markdown
7. 💾 Upload de artefato (30 dias de retenção)

**Para visualizar:**
- Acesse GitHub → Actions → "📁 Audit Structure"
- Baixe o artefato `structure-report.md`

---

## 📦 Distribuição

### Empacotamento

```bash
# Criar pacote final (opcional)
tar --exclude='node_modules' \
    --exclude='.git' \
    --exclude='output' \
    --exclude='logs' \
    -czf sila-presentation-final_$(date +%Y%m%d_%H%M%S).tar.gz \
    .
```

### Instalação do Pacote

```bash
# 1. Extrair
tar -xzf sila-presentation-final_YYYYMMDD_HHMMSS.tar.gz

# 2. Entrar no diretório
cd SILA-presentation

# 3. Instalar dependências
npm install

# 4. Validar estrutura
npm run validate:structure

# 5. Começar a usar
npm run generate:epic
```

---

## 🧭 Manutenção

### Verificações Regulares

```bash
# Semanal: validar estrutura
npm run validate:structure

# Antes de cada release: proteger package.json
npm run protect:package

# Antes de commits: auditoria rápida
npm run audit:tree
```

### Resolução de Problemas

#### ❌ "package.json não encontrado"
```bash
npm run protect:package
# Restaura automaticamente do backup
```

#### ❌ "JSON inválido"
```bash
npm run protect:package --restore
# Força restauração do backup
```

#### ❌ Script não encontrado
```bash
npm run validate:structure
# Valida se todos os scripts estão presentes
```

---

## 📚 Documentação Adicional

- `CHANGELOG.md` — Histórico de todas as mudanças
- `RELEASE_NOTES.md` — Notas para stakeholders
- `package.json` — Metadados e scripts completos
- `.github/workflows/audit-structure.yml` — Configuração do CI/CD

---

## 👥 Suporte

**Desenvolvido por:** Janeiro  
**Institucionalizado para:** Rochete Consultoria  
**Última atualização:** 2025-11-13  
**Versão:** 1.0.0

---

### 📞 Contato e Feedback

Para bugs, sugestões ou melhorias, abra uma issue no repositório.

---

## 📜 Licença

MIT License — Veja `package.json` para detalhes.

---

**🚀 SILA Presentation Engine — Pronto para Produção!**

## ⚡ Exemplos

### Exemplo Básico
```bash
./scripts/generate_epic_svgs.sh
```

### Exemplo Avançado
```bash
# Usa 8 workers paralelos, mantém 5 backups e renderiza o vídeo
./scripts/generate_epic_svgs.sh --concurrent 8 --keep 5 --render
```

### Desativar cache (útil para desenvolvimento)
```bash
./scripts/generate_epic_svgs.sh --no-cache
```

## 🛠️ Otimizações de Performance

### Processamento Paralelo
O script agora suporta processamento paralelo de frames, acelerando significativamente a geração de vídeos. O número padrão de workers é 4, mas pode ser ajustado conforme necessário.

### Cache de SVGs
Os SVGs são armazenados em cache para evitar reprocessamento desnecessário. Use `--no-cache` para forçar a atualização.

### Monitoramento em Tempo Real
Acompanhe o progresso com:
- Contador de frames processados
- Porcentagem concluída
- FPS (quadros por segundo)

---

## ✅ Teste Automatizado (CI/CD)

```bash

```

---

## Estrutura

```
frames/epic/         -> SVGs gerados
backup/epic/         -> Backups com timestamp
scripts/             -> Automação
scripts/tests/       -> Testes automatizados
```

---

Feito com 🚀 e 🇦🇴 Angola First.
SILA-presentation — Automação e assets

Conteúdo criado:
- index.html — apresentação interativa
- video_prompt.json — prompt para gerar vídeo em Runway/Pika
- frames/*.svg — 4 frames de referência (Angola, circuitos, HUD, foco em Luanda)
- generate_video.js — script template para enviar `video_prompt.json` a uma API (ex: Runway)
- puppeteer_export.js — (será criado) script para abrir `index.html`, avançar slides e capturar screenshots
- package.json — scripts utilitários

Como usar (rápido):

1) Instalar dependências (Node.js >=18 recomendado). No Powershell (na raiz `SILA-presentation`):

```powershell
cd SILA-presentation
npm install
```

2) Gerar vídeo via API (exemplo Runway):
- Exporte sua API key como variável de ambiente `RUNWAY_API_KEY`.
- Opcionalmente ajuste `RUNWAY_API_URL` se o provider usar outra rota.

```powershell
$env:RUNWAY_API_KEY = "YOUR_KEY_HERE"
npm run generate-video
```

O script `generate_video.js` é um template: providers podem exigir autenticação diferente ou endpoints distintos. O script salva a resposta do job em `video_job_response.json`.

3) Exportar slides como frames (requer `puppeteer` e `ffmpeg`):

```powershell
npm run export-frames
# depois usar ffmpeg para montar o mp4, exemplo:
ffmpeg -framerate 30 -i frames_out/slide_%03d.png -c:v libx264 -pix_fmt yuv420p out.mp4
```

Se precisares, eu adapto `generate_video.js` para um provider específico (Runway, Pika, Kaiber) e adiciono polling automático para baixar o vídeo quando pronto.
