# Como usar e testar

Esta secção descreve os passos rápidos para usar os scripts no Windows (PowerShell) e no WSL (bash), como interpretar os logs e como executar os testes smoke que validam o pipeline.

1) Preparar o ambiente

- Recomendado: ter Node.js (para utilitários), `pwsh` (PowerShell Core) no Windows, e WSL/Ubuntu com `bash` para a versão Bash. Para renderização completa, instale `inkscape` e `ImageMagick` no WSL.

2) Executar os geradores (dry-run / real)

- PowerShell (Windows, via UNC path):

```powershell
Set-Location '\\wsl$\Ubuntu\home\truman\dev\sila-showcase\SILA-presentation'
.\scripts\generate_epic_svgs.ps1 -Compress -Keep 1 -Render -DryRun
```

- WSL / Bash (ou executar dentro do WSL):

```bash
cd /home/truman/dev/sila-showcase/SILA-presentation
./scripts/generate_epic_svgs.sh --compress --keep 1 --render --dry-run
```

3) Executar os smoke tests (validação rápida)

- PowerShell smoke (Windows pwsh):

```powershell
Set-Location '\\wsl$\Ubuntu\home\truman\dev\sila-showcase\SILA-presentation'
.\scripts\tests\smoke.ps1
```

- Bash smoke (via WSL):

```bash
wsl bash -lc "cd /home/truman/dev/sila-showcase/SILA-presentation && ./scripts/tests/smoke.sh"
```

4) Inspecionar logs

- O log principal é `logs/last-run.log` e contém timestamps, flags usadas, e mensagens de dry-run ou operações reais.

- Para ver as últimas linhas no PowerShell:

```powershell
Get-Content .\logs\last-run.log -Tail 200
```

- No WSL / bash:

```bash
tail -n 200 logs/last-run.log
```

5) Interpretação rápida das mensagens

- `[DRYRUN]` — ação simulada, nenhum ficheiro foi modificado.
- `[OK] Backup saved:` — destino do backup (em dry-run mostra o caminho pretendido).
- `[RETENTION] Removed` — arquivos de backup removidos pela política `--keep N`.
- `WARN: Command not found: inkscape` / `magick` — falta de dependências para render; instalação necessária apenas para `--render`.

6) Como fazer commit e push (seguro)

- Configure o autor localmente (opcional):

```powershell
git config user.name "silahbo-jpg"
git config user.email "silahbo@gmail.com"
```

- Criar commit e push:

```powershell
git add -A
git commit -m "chore: finalize epic SVG generators, add smoke tests, update README"
git push origin HEAD
```

- Preferível usar `gh auth login` (GitHub CLI) para autenticar com segurança antes do push.

7) CI (GitHub Actions)

- O repositório inclui um workflow em `.github/workflows/ci.yml` que roda os smoke tests em ubuntu (shell) e windows (PowerShell) e executa lints básicos (`shellcheck` / `PSScriptAnalyzer`). Após um push verifique a aba Actions no GitHub para o estado da execução.

8) Troubleshooting rápido

- Parser errors no PowerShell: verifique se não há restos de markdown ou caracteres estranhos no início do ficheiro `scripts/generate_epic_svgs.ps1`.
- `The property 'Count' cannot be found` — bug corrigido; caso apareça, envolva o `Get-ChildItem` com `@(...)` para garantir um array.

9) Contribuir

- Fork → branch feature → PR. Reviews automáticos pelo workflow CI.

---

Se quiser, eu posso também: (A) rodar o smoke.sh agora para validar a paridade, (B) adicionar artefatos no workflow para coletar `logs/last-run.log` como build artifacts, ou (C) criar um pequeno `CONTRIBUTING.md`. Diz o que preferes.
