refreshFrequency: 100

# HUD para os modos leader do skhd. Lê /tmp/skhd-mode (escrito pelo skhd
# em `:: mode @ : echo ...`) no formato `mode|cheatsheet`. Fica invisível
# quando o ficheiro está vazio (modo default).
#
# Posição: barra inferior do ecrã, contida na faixa visível
# (iMac: 60px, MacBook ≤1999px: 30px). Layout single-row para caber.

command: """
touch /tmp/skhd-mode
cat /tmp/skhd-mode
"""

render: -> """
  <div class="hud">
    <span class="mode"></span>
    <span class="sep">·</span>
    <span class="hints"></span>
  </div>
"""

update: (output, domEl) ->
  content = output.replace(/\n$/, '')
  hud = domEl.querySelector('.hud')

  if not content or content is 'default'
    hud.classList.remove('visible')
    return

  [mode, hints] = content.split('|')
  domEl.querySelector('.mode').textContent = mode or ''
  domEl.querySelector('.hints').textContent = hints or ''
  hud.classList.add('visible')

style: """
  left: 0
  right: 0
  bottom: 0
  pointer-events: none
  z-index: 9999

  .hud
    position: absolute
    bottom: 0
    left: 50%
    height: 60px
    transform: translate(-50%, 8px)
    opacity: 0
    transition: opacity 120ms ease-out, transform 120ms ease-out
    background: rgba(20, 22, 30, 0.92)
    color: #c0caf5
    padding: 0 24px
    border-radius: 14px 14px 0 0
    font-family: -apple-system, "SF Pro Display", sans-serif
    text-align: center
    backdrop-filter: blur(24px)
    -webkit-backdrop-filter: blur(24px)
    box-shadow: 0 -8px 28px rgba(0, 0, 0, 0.4), 0 0 0 1px rgba(255, 255, 255, 0.06) inset
    white-space: nowrap
    display: flex
    align-items: center
    gap: 12px

  .hud.visible
    opacity: 1
    transform: translate(-50%, 0)

  .mode
    font-size: 11px
    text-transform: uppercase
    letter-spacing: 3px
    color: #7aa2f7
    font-weight: 700

  .sep
    color: rgba(192, 202, 245, 0.35)
    font-size: 14px

  .hints
    font-size: 15px
    font-weight: 500
    color: #c0caf5
    font-variant-numeric: tabular-nums

  @media (max-width: 1999px)
    .hud
      height: 30px
      padding: 0 14px
      gap: 8px
      border-radius: 8px 8px 0 0

    .mode
      font-size: 9px
      letter-spacing: 2px

    .sep
      font-size: 11px

    .hints
      font-size: 12px
"""
