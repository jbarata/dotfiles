refreshFrequency: 200

# Painel de ajuda: mostra todos os atalhos skhd activos.
# IPC dedicado: skhd escreve "toggle" em /tmp/skhd-help-toggle quando o
# utilizador preme Shift+Ctrl+Alt+Cmd+?, o widget lê e alterna o estado.
# O estado persiste em localStorage para sobreviver a refreshes do
# Übersicht. Quando visível, ocupa o ecrã inteiro (backdrop) com um
# cartão central com a cheatsheet completa; esc não fecha (só a mesma
# combinação que abriu).

command: """
touch /tmp/skhd-help-toggle
content=$(tail -n 1 /tmp/skhd-help-toggle | tr -d '\\0')

if [ "$content" = "toggle" ]; then
  echo "" > /tmp/skhd-help-toggle
  echo "toggle"
fi
"""

render: -> """
  <div class="skhd-help">
    <div class="backdrop"></div>
    <div class="panel">
      <div class="title">skhd · atalhos</div>
      <div class="columns">
        <div class="column">
          <div class="section">
            <div class="section-title">Apps (tecla única)</div>
            <div class="item"><kbd>⌃⌥⌘ Z</kbd><span>Zoom</span></div>
            <div class="item"><kbd>⌃⌥⌘ S</kbd><span>Slack</span></div>
            <div class="item"><kbd>⌃⌥⌘ M</kbd><span>Mail</span></div>
            <div class="item"><kbd>⌃⌥⌘ C</kbd><span>Claude</span></div>
            <div class="item"><kbd>⇧⌃⌥⌘ C</kbd><span>ChatGPT</span></div>
            <div class="item"><kbd>⌃⌥⌘ V</kbd><span>VS Code</span></div>
            <div class="item"><kbd>⌃⌥⌘ G</kbd><span>Ghostty</span></div>
            <div class="item"><kbd>⌃⌥⌘ B</kbd><span>Safari</span></div>
            <div class="item"><kbd>⇧⌃⌥⌘ B</kbd><span>Google Chrome</span></div>
            <div class="item"><kbd>⌃⌥⌘ T</kbd><span>Calendário</span></div>
            <div class="item"><kbd>⇧⌃⌥⌘ N</kbd><span>Safari → Notes (reader)</span></div>
          </div>
          <div class="section">
            <div class="section-title">Leader <kbd>⌃⌥⌘ D</kbd> · cob</div>
            <div class="item"><kbd>P</kbd><span>Plan</span></div>
            <div class="item"><kbd>O</kbd><span>Do</span></div>
            <div class="item"><kbd>R</kbd><span>Review</span></div>
            <div class="item"><kbd>D</kbd><span>Dogfooding</span></div>
            <div class="item"><kbd>V</kbd><span>Vendas</span></div>
            <div class="item"><kbd>T</kbd><span>Tempo</span></div>
          </div>
          <div class="section">
            <div class="section-title">Leader <kbd>⌃⌥⌘ P</kbd> · personal</div>
            <div class="item"><kbd>M</kbd><span>Mimes</span></div>
            <div class="item"><kbd>B</kbd><span>BudgetBakers</span></div>
            <div class="item"><kbd>L</kbd><span>AnyList</span></div>
          </div>
        </div>
        <div class="column">
          <div class="section">
            <div class="section-title">Leader <kbd>⌃⌥⌘ K</kbd> · clients</div>
            <div class="item"><kbd>M → P / Q</kbd><span>Mello · Produção / Qualidade</span></div>
            <div class="item"><kbd>W → P / Q</kbd><span>Winestone · Produção / Qualidade</span></div>
            <div class="item"><kbd>L → E / I</kbd><span>Lidl · External / Internal</span></div>
            <div class="item"><kbd>R</kbd><span>Rentelecom</span></div>
          </div>
          <div class="section">
            <div class="section-title">Leader <kbd>⌃⌥⌘ R</kbd> · review</div>
            <div class="item"><kbd>T</kbd><span>Today plan</span></div>
            <div class="item"><kbd>D</kbd><span>Daily</span></div>
            <div class="item"><kbd>W</kbd><span>Weekly</span></div>
            <div class="item"><kbd>M</kbd><span>Monthly</span></div>
            <div class="item"><kbd>Q</kbd><span>Quarterly</span></div>
            <div class="item"><kbd>Y</kbd><span>Yearly</span></div>
            <div class="item"><kbd>O</kbd><span>Toggle painel</span></div>
          </div>
          <div class="section">
            <div class="section-title">Ajuda</div>
            <div class="item"><kbd>⌃⌥⌘ '</kbd><span>Alterna este painel</span></div>
            <div class="item"><kbd>Esc</kbd><span>Sai de qualquer leader (este painel fecha-se com ' )</span></div>
          </div>
        </div>
        <div class="column">
          <div class="section">
            <div class="section-title">Rectangle <kbd>⌃⌥</kbd> · janelas</div>
            <div class="item"><kbd>← / →</kbd><span>Half esq. / dir.</span></div>
            <div class="item"><kbd>↑ / ↓</kbd><span>Half topo / base</span></div>
            <div class="item"><kbd>U / I</kbd><span>Quarter topo · esq. / dir.</span></div>
            <div class="item"><kbd>J / K</kbd><span>Quarter base · esq. / dir.</span></div>
            <div class="item"><kbd>D / F / G</kbd><span>Thirds (1ª / centro / última)</span></div>
            <div class="item"><kbd>E / T</kbd><span>Two-thirds (esq. / dir.)</span></div>
            <div class="item"><kbd>C</kbd><span>Centrar</span></div>
            <div class="item"><kbd>↩ / ⌫</kbd><span>Maximizar / Restore</span></div>
            <div class="item"><kbd>⇧ ↑</kbd><span>Maximizar altura</span></div>
            <div class="item"><kbd>= / -</kbd><span>Larger / Smaller</span></div>
          </div>
          <div class="section">
            <div class="section-title">Rectangle <kbd>⌃⌥⌘</kbd> · extras</div>
            <div class="item"><kbd>1 / 2 / 3 / 4</kbd><span>Fourths (vertical)</span></div>
            <div class="item"><kbd>← / →</kbd><span>Display anterior / seguinte</span></div>
          </div>
        </div>
      </div>
    </div>
  </div>
"""

afterRender: (domEl) ->
  # Reaplica estado ao inicializar / refrescar widget.
  @applyState(domEl)

applyState: (domEl) ->
  isOpen = localStorage.getItem('skhdHelpOpen') is 'yes'
  domEl.querySelector('.skhd-help').classList.toggle('visible', isOpen)

update: (output, domEl) ->
  command = output.trim()
  if command is 'toggle'
    current = localStorage.getItem('skhdHelpOpen') is 'yes'
    localStorage.setItem('skhdHelpOpen', if current then 'no' else 'yes')
  @applyState(domEl)

style: """
  top: 0
  left: 0
  right: 0
  bottom: 0
  pointer-events: none
  z-index: 99999

  .skhd-help
    position: fixed
    inset: 0
    opacity: 0
    transition: opacity 140ms ease-out
    pointer-events: none

  .skhd-help.visible
    opacity: 1

  .backdrop
    position: absolute
    inset: 0
    background: rgba(10, 12, 18, 0.55)
    backdrop-filter: blur(12px)
    -webkit-backdrop-filter: blur(12px)

  .panel
    position: absolute
    top: 50%
    left: 50%
    transform: translate(-50%, -50%)
    background: rgba(20, 22, 30, 0.94)
    color: #c0caf5
    padding: 28px 36px 24px
    border-radius: 18px
    font-family: -apple-system, "SF Pro Display", sans-serif
    box-shadow: 0 24px 72px rgba(0, 0, 0, 0.55), 0 0 0 1px rgba(255, 255, 255, 0.08) inset
    max-width: 90vw
    max-height: 90vh
    overflow: auto

  .title
    font-size: 13px
    text-transform: uppercase
    letter-spacing: 3px
    color: #7aa2f7
    font-weight: 700
    text-align: center
    margin-bottom: 22px

  .columns
    display: flex
    gap: 48px
    align-items: flex-start

  .column
    display: flex
    flex-direction: column
    gap: 22px
    min-width: 280px

  .section-title
    font-size: 11px
    text-transform: uppercase
    letter-spacing: 2px
    color: rgba(192, 202, 245, 0.55)
    margin-bottom: 8px
    font-weight: 600

  .section-title kbd
    margin: 0 4px
    font-size: 10px

  .item
    display: flex
    align-items: center
    gap: 14px
    padding: 4px 0
    font-size: 13px

  .item kbd
    flex-shrink: 0
    min-width: 86px
    text-align: center
    font-family: "SF Mono", ui-monospace, monospace
    font-size: 12px
    color: #e0af68
    background: rgba(224, 175, 104, 0.08)
    border: 1px solid rgba(224, 175, 104, 0.25)
    border-radius: 6px
    padding: 3px 8px

  .item span
    color: #c0caf5

  @media (max-width: 1999px)
    .panel
      padding: 18px 22px 16px
      border-radius: 12px

    .title
      font-size: 11px
      letter-spacing: 2px
      margin-bottom: 14px

    .columns
      flex-direction: column
      gap: 14px

    .column
      gap: 14px
      min-width: auto

    .section-title
      font-size: 10px
      margin-bottom: 4px

    .item
      font-size: 11px
      gap: 10px
      padding: 2px 0

    .item kbd
      min-width: 72px
      font-size: 10px
      padding: 2px 6px
"""
