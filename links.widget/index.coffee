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



  .confirm-dialog
    display: none

  .confirm-dialog .logoCoB 
    background-color: green;


"""


render: -> """
  <div class="links">
    <table>
      <tr>
        <td style="position: relative">
          <a class="unlockLink" href="#">
            <div class="logoCoB qual">  <div class="symbolText">Unlock</div>  </div>          
          </a>
        </td>
        <td>
          <span class="confirm-dialog">
            <div class="logoCoB">  <div class="symbolText confirm-yes">Open</div>  </div>
          </span>
        </td>
      </tr>
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
elif [ "$content" = "unlock" ]; then
  echo "" > /tmp/uber-listener.log
  BREW_PREFIX=$([[ -d /opt/homebrew ]] && echo /opt/homebrew || echo /usr/local)
  export SSHPASS=$($BREW_PREFIX/bin/op item get "unlockNuki" --fields password --account CW5IDM3OZRCEBMCSQFLHA3UBLQ)
  $BREW_PREFIX/bin/sshpass -e ssh -p 443 cob@demo.cultofbits.com "source unlock.sh"
  echo "unlocked at $(date)"
fi
"""

afterRender: (domEl) ->
  widget = $(domEl)
  overlay = widget.find('.confirm-dialog-overlay')
  dialog = widget.find('.confirm-dialog')

  hideDialog = -> 
    overlay.css('display', 'none')
    dialog.css('display', 'none')

  showDialog = -> 
    overlay.css('display', 'block')
    dialog.css('display', 'flex')

  widget.find('.unlockLink').on 'click', (e) ->
    e.preventDefault()
    if dialog.css('display') is 'none'
      showDialog()
    else
      hideDialog()

  widget.find('.confirm-yes').on 'click', (e) =>
    e.preventDefault()
    @run 'echo unlock > /tmp/uber-listener.log'
    hideDialog()

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
