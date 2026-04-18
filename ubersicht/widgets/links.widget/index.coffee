refreshFrequency: 500

style: """
  top: 0
  right: 0
  height: 100%
  width: 20px
  z-index: 10

  table
    position: absolute
    top: 50%
    right: 0
    transform: translate(100%, -50%)
    transition: transform 0.2s ease-in-out
    background-color: rgba(0,0,0,0.2)
    padding: 10px 5px
    border-radius: 10px 0 0 10px

  &:hover table
    transform: translate(0, -50%)

  a
    text-decoration:none

  tr
    height: 50px
    display: flex
    flex-direction: row-reverse

  tr.separator-row
    height: auto

  .logoCoB
    margin-left: 8px;
    border-radius: 10px;
    background-color: #d5184b;
    text-align: center;
    vertical-align: middle;
    height: 32px;
    width:32px;

  .logoCoB.qual
    background-color: #f39c12;

  .symbolCoB
    margin-left: 1px;
    padding-top: 2px;
    font-size: 29px;
    font-family: verdana;
    color: #fff;
    font-weight: bolder;

  .symbolMimes
    margin-left: 1px;
    padding-top: 2px;
    font-size: 22px;
    font-family: verdana;
    color: #fff;
    font-weight: bolder;

  .symbolText
    margin: auto;
    padding-top: 8px;
    font-size: 8px;
    font-family: Comic Sans MS, cursive, sans-serif;
    color: #fff;
    font-weight: bolder;

  .cgd
    border-radius: 10px;
    background-color: rgba(#fff, 0.7);
    padding: 2px

  .separator
    height: 1px
    width: 25px
    background-color: rgba(255,255,255,0.5)
    margin: 5px auto

  // ---------------------------------------------------------------
  //  MacBook (ecrã <= 1999px) — tipicamente temos apps abertas com
  //  uma margem de ~30px aos limites do ecrã. A última coluna deste
  //  widget (a rightmost, por causa do row-reverse) aparece nessa
  //  faixa exposta. As outras colunas ficam por trás da app.
  //
  //  Normalizamos todos os icones a 24x24 e asseguramos uma margem
  //  de 3px em cada lado para a coluna da direita ficar centrada na
  //  faixa de 30px expostos.
  // ---------------------------------------------------------------
  @media (max-width: 1999px)
    width: 30px

    // Padding vertical maior no table para criar margem em cima/em baixo
    // simétricas com o fundo (não ficar colado ao topo/fundo do ecrã).
    // NOTA: border-collapse: collapse faz o <table> ignorar o seu próprio padding,
    // portanto usa-se border-collapse: separate com border-spacing: 0.
    table
      padding: 10px 0 !important
      border-collapse: separate !important
      border-spacing: 0 !important

    td
      padding: 0

    tr
      height: 30px

    tr.separator-row
      height: auto

    // Uniformização: TODOS os icones com a mesma forma
    //  - 24x24 outer (box-sizing border-box)
    //  - padding interno 2px → área de imagem 20x20
    //  - fundo branco translúcido para visual consistente
    //  - border-radius 6px
    .logoCoB,
    img,
    a.calendarLink > div
      width: 24px !important
      height: 24px !important
      margin-left: 4px !important
      margin-right: 0 !important
      padding: 2px !important
      border-radius: 6px !important
      box-sizing: border-box !important
      display: flex !important
      align-items: center !important
      justify-content: center !important
      background-color: rgba(255, 255, 255, 0.35) !important

    // logoCoB mantém a cor de branding (sobrepõe o fundo translúcido)
    .logoCoB
      background-color: #d5184b !important
      padding: 0 !important

    .logoCoB.qual
      background-color: #f39c12 !important

    // Imagens: preservar aspect-ratio, centrar dentro do 24x24
    img
      object-fit: contain !important

    // Rightmost td (:first-child por causa de row-reverse)
    // margin-right cria o gap ao bordo direito do ecrã (3px)
    tr > td:first-child .logoCoB,
    tr > td:first-child img,
    tr > td:first-child a.calendarLink > div
      margin-right: 3px !important

    // Centrar texto/símbolo dentro dos logoCoB
    .symbolCoB,
    .symbolMimes,
    .symbolText
      margin: 0 !important
      padding: 0 !important
      line-height: 1 !important
      text-align: center !important

    // Asterisco em Verdana assenta no topo do line-box; compensa com translate
    .symbolCoB
      font-size: 20px !important
      transform: translateY(3px) !important

    .symbolMimes
      font-size: 16px !important

    .symbolText
      font-size: 8px !important

    // Calendário (emoji 📅 dentro de <div> sem classe dentro de <a.calendarLink>)
    a.calendarLink > div > div
      font-size: 16px !important
      margin: 0 !important
      padding: 0 !important
      line-height: 1 !important

"""


render: -> """
  <div class="links">
    <table>
      <tr>
        <td>
          <a class="dogfoodingLink" href="https://dogfooding.cultofbits.com">
            <div class="logoCoB">  <div class="symbolCoB">*</div>  </div>
          </a>
        </td>
        <td>
          <a href="https://dogfooding.cultofbits.com/recordm/index.html#/cob.custom-resource/Plan:{%22switchView%22:%22yes%22,%22concurrentFilterToggle%22:%22yes%22,%22showFilters%22:%22yes%22}/dash">
            <div class="logoCoB">  <div class="symbolText">Plan</div>  </div>
          </a>
        </td>
        <td>
          <a href="https://dogfooding.cultofbits.com/recordm/index.html#/cob.custom-resource/Do/dash?">
            <div class="logoCoB">  <div class="symbolText">Do</div>  </div>
          </a>
        </td>
        <td>
          <a href="https://dogfooding.cultofbits.com/recordm/index.html#/cob.custom-resource/Review/dash?">
            <div class="logoCoB">  <div class="symbolText">Review</div>  </div>
          </a>
        </td>
        <td>
          <a href="https://dogfooding.cultofbits.com/recordm/index.html#/cob.custom-resource/Visão Geral/dash">
            <div class="logoCoB">  <div class="symbolText">Sales</div>  </div>
          </a>
        </td>
        <td>
          <a href="https://dogfooding.cultofbits.com/recordm/index.html#/cob.custom-resource/Resultados/dash">
            <div class="logoCoB">  <div class="symbolText">€€€</div>  </div>
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a href="https://github.com/cob">
            <img style="width:35px;margin-left:6px;background-color:#ffffff40;padding:3px 0px 0px 0px;border-radius:7px;" src="links.widget/images/github.png">
          </a>
        </td>
        <td>
          <a href="https://gitlab.com/cob">
            <img style="width:25px;margin-left:7px;background-color:#ffffff40;padding:4px;border-radius:7px;" src="links.widget/images/gitlab.svg">
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a href="https://www.cgd.pt/Pages/Default.aspx">
            <img class="cgd" style="width:28px;margin-left:7px" src="links.widget/images/cgd.png">
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a class="slackLink" href="slack://open?team=T02J1N4KH">
            <img style="width:24px;margin-left:10px;background-color:#fff;padding:2px;border-radius:7px;" src="links.widget/images/slack.png">
          </a>
        </td>
        <td>
          <a class="zoomLink" href="zoommtg://zoom.us/join?confno=668244305&zc=2&browser=chrome&uname=Miguel">
            <img style="width:32px;margin-left:7px" src="links.widget/images/zoom.us.png">
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a href="https://mdados.cultofbits.com">
            <div class="logoCoB">  <div class="symbolText">Mello</div>  </div>
          </a>
        </td>
        <td>
          <a href="https://winestone.cultofbits.com">
            <div class="logoCoB">  <div class="symbolText">WS</div>  </div>
          </a>
        </td>
        <td>
          <a href="https://servinform-sam.cultofbits.com">
            <div class="logoCoB">  <div class="symbolText">SAM</div>  </div>
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a href="https://mdados-qual.cultofbits.com">
            <div class="logoCoB qual">  <div class="symbolText">Mello</div>  </div>
          </a>
        </td>
        <td>
          <a href="https://winestone-qual.cultofbits.com">
            <div class="logoCoB qual">  <div class="symbolText">WS</div>  </div>
          </a>
        </td>
      </tr>

      <tr>
        <td>
          <a class="claudeLink"  href="claude://">
            <img style="width:32px;margin-left:7px;border-radius:7px;" src="links.widget/images/claude.svg">
          </a>
        </td>
        <td>
          <a class="chatgptLink"  href="https://chatgpt.com/pt-PT">
            <img style="width:26px;margin-left:10px;background-color:#fff;padding:2px;border-radius:7px;" src="links.widget/images/chat.png">
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a class="visualcodeLink"  href="vscode://">
            <img style="width:26px;margin-left:10px;background-color:#fff;padding:2px;border-radius:7px;" src="links.widget/images/vc.png">
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a class="calendarLink"  href="#">
            <div >  <div style="font-size: 30px; margin-right: 1px">📅</div>  </div>
          </a>
        </td>
      </tr>
      <tr class="separator-row"><td><div class="separator"></div></td></tr>
      <tr>
        <td>
          <a href="https://my.shelly.cloud/#dashboard">
            <img style="width:32px;margin-left:7px" src="links.widget/images/shelly.png">
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a href="shortcuts://run-shortcut?name=Abrir%20AnyList">
            <img style="width:39px;margin-left:4px" src="links.widget/images/anylist.png">
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a href="https://web.budgetbakers.com/dashboard">
            <img style="width:32px;margin-left:7px" src="links.widget/images/budgetbakers.svg">
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a href="https://mimes.cultofbits.com/recordm/index.html#/cob.custom-resource/Dia a Dia/dash">
            <div class="logoCoB">  <div class="symbolMimes">M</div>  </div>
          </a>
        </td>
      </tr>
    </table>
"""

command: """
# Lê a última linha do log do uber-listener, o ficheiro de comunicação entre o widget e o script de escuta de comandos
touch /tmp/uber-listener.log
content=$(tail -n 1 /tmp/uber-listener.log | tr -d '\0')

# Se o comando for relevante, limpa o log e devolve o comando
if [ "$content" = "zoom" ] || [ "$content" = "chatgpt" ] || [ "$content" = "claude" ] || [ "$content" = "visualcode" ] || [ "$content" = "slack" ] || [ "$content" = "calendar" ] || [ "$content" = "dogfooding" ]; then
  echo "" > /tmp/uber-listener.log
  echo "$content"
fi
"""

afterRender: (domEl) ->
  widget = $(domEl)

  widget.find('.claudeLink').on 'click', (e) =>
    e.preventDefault()
    @run "osascript -e 'tell application \"Claude\" to activate'"

  widget.find('.calendarLink').on 'click', (e) =>
    e.preventDefault()
    @run "osascript focus.widget/open_calendar.scpt"

update: (output, domEl) ->
  command = output.trim()
  
  if command == "zoom"
    link = domEl.querySelector('.zoomLink')
    link?.click()
  else if command == "chatgpt"
    link = domEl.querySelector('.chatgptLink')
    link?.click()
  else if command == "claude"
    link = domEl.querySelector('.claudeLink')
    link?.click()
  else if command == "visualcode"
    link = domEl.querySelector('.visualcodeLink')
    link?.click()
  else if command == "slack"
    link = domEl.querySelector('.slackLink')
    link?.click()
  else if command == "calendar"
    link = domEl.querySelector('.calendarLink')
    link?.click()
  else if command == "dogfooding"
    link = domEl.querySelector('.dogfoodingLink')
    link?.click()
