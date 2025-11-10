Exportar apresentação para MP4

1) Instalar dependências (PowerShell):

```powershell
cd SILA-presentation
npm install
```

2) Executar exportador (usa puppeteer headless):

```powershell
npm run export-frames
```

3) Montar MP4 com ffmpeg (instale ffmpeg localmente):

```powershell
# dentro de SILA-presentation
ffmpeg -framerate 30 -i frames_out/slide_%03d.png -c:v libx264 -pix_fmt yuv420p SILA_presentation.mp4
```

Notas:
- O script captura um screenshot por slide. Se precisares de animações contínuas, podemos aumentar o número de frames por slide e interpolar com timestamps.
- Para gravação de vídeo com áudio, precisamos de criar uma pipeline que combine frames com uma trilha sonora (ffmpeg permite).