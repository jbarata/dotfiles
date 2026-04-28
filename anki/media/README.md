# anki/media — Imagens/áudio referenciados pelos decks Anki

Ficheiros aqui são referenciados em `../rectangle.txt` (e futuros decks
com `#html:true`) via `<img src="filename">`.

## Workflow de import

O Anki TSV não importa media — só texto. As imagens têm de estar na
pasta `collection.media/` do perfil Anki **antes** do import:

```bash
ANKI_MEDIA="$HOME/Library/Application Support/Anki2/User 1/collection.media"
cp ~/.dotfiles/anki/media/*.png "$ANKI_MEDIA/"
```

(ajustar o nome do perfil conforme aplicável; "User 1" é o default).

## Ficheiros esperados

- `rectangle-cheatsheet.png` — cheat sheet visual do Rectangle anexada
  aos 6 cartões `re*` do `../rectangle.txt`.
