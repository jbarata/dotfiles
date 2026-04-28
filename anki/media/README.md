# anki/media — Imagens/áudio referenciados pelo deck Anki

Ficheiros aqui são referenciados em `../cards.txt` via
`<img src="filename">` (o deck está em `#html:true`).

## Workflow de import

O Anki TSV não importa media — só texto. As imagens têm de estar na
pasta `collection.media/` do perfil Anki **antes** do import. Usar o
helper script (chamado pelo bootstrap; idempotente via `rsync --update`):

```bash
bash ~/.dotfiles/setup/anki-media.sh
# ou para um perfil diferente do "User 1":
ANKI_PROFILE="João" bash ~/.dotfiles/setup/anki-media.sh
```

O script copia `*.png/jpg/jpeg/gif/svg/webp/mp3/m4a/wav` (exclui o README
e ocultos) para `~/Library/Application Support/Anki2/<profile>/collection.media/`.

## Ficheiros esperados

- `rectangle-cheatsheet.png` — cheat sheet visual do Rectangle anexada
  aos 6 cartões `re*` em `../cards.txt`.
