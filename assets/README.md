# assets/

Ficheiros binários auxiliares (imagens, etc.) usados por scripts do repo.

## working-info-bg.png

Background da janela do Finder para `~/Documents/Working Info`, aplicado
por `bin/open-working-info.sh`. Se este ficheiro não existir, o script
salta silenciosamente (sem erro).

**Colocar imagem**:

```bash
cp <caminho-da-imagem>.png ~/.dotfiles/assets/working-info-bg.png
```

Dimensão recomendada: próxima do tamanho da janela (preset Rectangle),
PNG/JPEG. O Finder não faz scaling — usa o tamanho nativo da imagem.
