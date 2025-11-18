refreshFrequency: 500

style: """
  top: 0
  left: 0
  height: 100%
  width: 20px

  table
    position: absolute
    top: 50%
    left: 0
    transform: translate(-100%, -50%)
    transition: transform 0.2s ease-in-out
    background-color: rgba(0,0,0,0.2)
    padding: 10px 5px
    border-radius: 0 10px 10px 0

  &:hover table
    transform: translate(0, -50%)

  a
    text-decoration:none

  tr
    height: 50px

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

  .confirm-dialog-overlay
    position: fixed
    top: 0
    left: 0
    width: 100%
    height: 100%
    background-color: rgba(0,0,0,0.7)
    display: none
    z-index: 1000

  .confirm-dialog
    position: fixed
    top: 4px
    left: 50%
    transform: translateX(-50%)
    background-color: #2c3e50
    padding: 0 20px
    border-radius: 10px
    color: white
    font-family: sans-serif
    height: 55px
    display: flex
    align-items: center
    justify-content: center

  .confirm-dialog p
    margin: 0 15px 0 0

  .confirm-dialog button
    border: none
    padding: 8px 15px
    margin: 0 5px
    border-radius: 5px
    cursor: pointer
    font-weight: bold

  .confirm-yes
    background-color: #27ae60
    color: white

  .confirm-no
    background-color: #c0392b
    color: white
"""


render: -> """
  <div class="links">
    <div class="confirm-dialog-overlay">
      <div class="confirm-dialog">
        <p>Deseja executar o comando de unlock?</p>
        <button class="confirm-yes">Sim</button>
        <button class="confirm-no">Não</button>
      </div>
    </div>
    <table>
      <tr>
        <td>
          <a class="unlockLink" href="#">
            <div class="logoCoB qual">  <div class="symbolText">Unlock</div>  </div>          
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a href="https://dogfooding.cultofbits.com">
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
# Lança o servidor nc só uma vez (se ainda não estiver a correr)
if ! pgrep -f "nc -lk 5555" > /dev/null; then
  nohup nc -lk 5555 > /tmp/uber-listener.log 2>/dev/null &
fi

# Lê a última linha do log
content=$(tail -n 1 /tmp/uber-listener.log | tr -d '\0')

# Se o comando for relevante, limpa o log e devolve o comando
if [ "$content" = "zoom" ] || [ "$content" = "chatgpt" ] || [ "$content" = "visualcode" ] || [ "$content" = "slack" ]; then
  echo "" > /tmp/uber-listener.log
  echo "$content"
elif [ "$content" = "unlock" ]; then
  echo "" > /tmp/uber-listener.log
  export SSHPASS=$(/usr/local/bin/op item get "unlockNuki" --fields password --account CW5IDM3OZRCEBMCSQFLHA3UBLQ)
  /usr/local/bin/sshpass -e ssh -p 443 cob@demo.cultofbits.com "source unlock.sh"
  echo "unlocked at $(date)"
fi
"""

afterRender: (domEl) ->
  widget = $(domEl)
  overlay = widget.find('.confirm-dialog-overlay')

  hideDialog = -> overlay.css('display', 'none')
  showDialog = -> overlay.css('display', 'block')

  widget.find('.unlockLink').on 'click', (e) ->
    e.preventDefault()
    showDialog()

  widget.find('.confirm-no').on 'click', (e) ->
    e.preventDefault()
    hideDialog()

  widget.find('.confirm-yes').on 'click', (e) =>
    e.preventDefault()
    @run 'echo unlock > /tmp/uber-listener.log'
    hideDialog()

update: (output, domEl) ->
  command = output.trim()
  
  if command == "zoom"
    link = domEl.querySelector('.zoomLink')
    link?.click()
  else if command == "chatgpt"
    link = domEl.querySelector('.chatgptLink')
    link?.click()
  else if command == "visualcode"
    link = domEl.querySelector('.visualcodeLink')
    link?.click()
  else if command == "slack"
    link = domEl.querySelector('.slackLink')
    link?.click()

