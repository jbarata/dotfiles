refreshFrequency: 500

style: """
  z-index: 1
  top: 0
  left: 0
  height: 100%
  width: 20px

  table
    position: absolute
    top: 10px
    left: 0
    transform: translateX(-100%)
    transition: transform 0.2s ease-in-out
    background-color: rgba(0,0,0,0.2)
    padding: 10px 5px
    border-radius: 0 10px 10px 0

  &:hover table
    transform: translateX(0)

  a
    text-decoration:none

  tr
    height: 50px

  .logoCoB
    margin-left: 8px;
    border-radius: 10px;
    background-color: #d5184b;
    text-align: center;
    vertical-align: middle;
    height: 32px;
    width:32px;

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

  .cgd
    border-radius: 10px;
    background-color: rgba(#fff, 0.7);
    padding: 2px

"""


render: -> """
  <div class="links">
    <table>
      <tr>
        <td>
          <a href="https://dogfooding.cultofbits.com">
            <div class="logoCoB">  <div class="symbolCoB">*</div>  </div>
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <a href="https://github.com/cob">
            <img style="width:35px;margin-left:6px;background-color:#ffffff40;padding:3px 0px 0px 0px;border-radius:7px;" src="links.widget/images/github.png">
          </a>
        </td>
      </tr>
      <tr>
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
          <a class="zoomLink" href="zoommtg://zoom.us/join?confno=668244305&zc=2&browser=chrome&uname=Miguel">
            <img style="width:32px;margin-left:7px" src="links.widget/images/zoom.us.png">
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
      <tr>
        <td>
          <a class="slackLink" href="slack://open?team=T02J1N4KH">
            <img style="width:24px;margin-left:10px;background-color:#fff;padding:2px;border-radius:7px;" src="links.widget/images/slack.png">
          </a>
        </td>
      </tr>
      <tr> <td> </td> </tr>
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
          <a href="https://web-new.budget-bakers.com/dashboard">
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
fi
"""

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
