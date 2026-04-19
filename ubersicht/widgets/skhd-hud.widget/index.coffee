refreshFrequency: 100

# HUD para os modos leader do skhd. Lê /tmp/skhd-mode (escrito pelo skhd
# em `:: mode @ : echo ...`) no formato `mode|cheatsheet`. Fica invisível
# quando o ficheiro está vazio (modo default).

command: """
touch /tmp/skhd-mode
cat /tmp/skhd-mode
"""

render: -> """
  <div class="hud">
    <div class="mode"></div>
    <div class="hints"></div>
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
  top: 0
  left: 0
  right: 0
  bottom: 0
  pointer-events: none
  z-index: 9999

  .hud
    position: absolute
    top: 80px
    left: 50%
    transform: translate(-50%, -8px)
    opacity: 0
    transition: opacity 120ms ease-out, transform 120ms ease-out
    background: rgba(20, 22, 30, 0.92)
    color: #c0caf5
    padding: 16px 24px
    border-radius: 14px
    font-family: -apple-system, "SF Pro Display", sans-serif
    text-align: center
    backdrop-filter: blur(24px)
    -webkit-backdrop-filter: blur(24px)
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.45), 0 0 0 1px rgba(255, 255, 255, 0.06) inset
    white-space: nowrap

  .hud.visible
    opacity: 1
    transform: translate(-50%, 0)

  .mode
    font-size: 11px
    text-transform: uppercase
    letter-spacing: 3px
    color: #7aa2f7
    font-weight: 700
    margin-bottom: 6px

  .hints
    font-size: 17px
    font-weight: 500
    color: #c0caf5
    font-variant-numeric: tabular-nums
"""
