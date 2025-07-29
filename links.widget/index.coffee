command: ""

refreshFrequency: 6000000

style: """
  top: 0px
  left: 0px
  color: #fff
  font-family: Helvetica Neue
  border-radius: 10px;

  a
    text-decoration:none

  p
    margin:3px
    padding-left: 5px
    font-size: 13px;
    font-weight: 400
    text-shadow: 0 1px 5px #000000;

  .task
    font-weight: 200
    padding-left: 15px
    text-shadow:none

  table
    padding-top:10px

  tr
    height: 50px

  .tickets
    border-bottom-style: solid;
    border-bottom-width: 1px;
    border-top-style: solid;
    border-top-width: 1px;
    border-bottom-color: rgba(#fff, 0.3)
    //background-color:rgba(0,0,0,0.3);
    border-radius: 4px;

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

  .cgd
    border-radius: 10px;
    background-color: rgba(#fff, 0.7);
    padding: 2px

"""


render: -> """
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
        <a href="https://github.com">
          <img style="width:47px;" src="links.widget/images/github.png">
        </a>
      </td>
    </tr>
    <tr>
      <td>
        <a href="http://gitlab.com/">
          <img style="width:32px;margin-left:7px" src="links.widget/images/gitlab.svg">
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
        <a href="https://my.shelly.cloud/#dashboard">
          <img style="width:32px;margin-left:7px" src="links.widget/images/shelly.png">
        </a>
      </td>
    </tr>
    <tr>
      <td>
        <a href="zoommtg://zoom.us/join?confno=668244305&zc=2&browser=chrome&uname=Miguel">
          <img style="width:32px;margin-left:7px" src="links.widget/images/zoom.us.png">
        </a>
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://web-new.budgetbakers.com/dashboard">
          <img style="width:32px;margin-left:7px" src="links.widget/images/budgetbakers.svg">
        </a>
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://mimes.cultofbits.com/recordm/index.html#/cob.custom-resource/Dia a Dia/dash">
          <div class="logoCoB">  <div class="symbolCoB">*</div>  </div>
        </a>
      </td>
    </tr>
  </table>
"""