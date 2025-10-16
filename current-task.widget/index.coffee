settings =
    lang: 'pt'
    militaryTime: true
    colors:
      default: 'rgba(0, 0, 0, .75)'
      accent: 'rgba(255, 255, 255, .75)'
      background: 'rgba(255, 255, 255, .3)'
    shadows:
      box: '0 0 1.25em rgba(0, 0, 0, .5)'
      text: '0 0 0.625em rgba(0, 0, 0, .25)'

command: """
IFS='~' read -r theArea theProject theTask theTags theNotes theId<<<"$(osascript current-task.widget/getTaskDetails.scpt)"
echo '{ "area":"'$theArea'","project": "'$theProject'", "task": "'$theTask'", "tags": "'$theTags'", "notes": "'$theNotes'", "id": "'$theId'"}'
"""

refreshFrequency: 3000


style: """
  bottom: 0px
  left: 50%
  transform: translateX(-50%)
  max-width: calc(100% - 540px)
  padding: 0 20px
  border-radius:10px

  text-align:center
  font-family: 'Ubuntu', sans-serif
  font-weight: 200
  text-decoration: none
  color:white

  .area, .project, .thing
    margin:0px
    color:white
    text-decoration: none

  #currentTaskContent
    padding:5px

  #timelapse
    margin:5px
    color:rgba(255,255,255,0.4)

  .thing
    font-size: 14px
    color:white
    border-radius: 1rem
    background: #{ settings.colors.background }
    box-shadow: #{ settings.shadows.box }
    text-shadow: #{ settings.shadows.text }
    overflow: hidden
    -webkit-backdrop-filter: blur(10px)
    background:rgba(255, 255, 255, .9)
    color: rgba(0, 0, 0, 0.9)
    padding:5px 20px 5px 15px

  .project
    font-size: 18px

  .area
    font-size: 12px

  .warning
    background:rgba(255,0,0,0.20)
    -webkit-transition: background-color 2000ms linear;

  .success
    background:rgba(0,255,0,0.15)
    -webkit-transition: background-color 2000ms linear;

"""

render: (output) ->
    return """
      <div id="currentTaskContent">
        <!-- p id="timelapse"/-->
        <!-- p id="timegoal"style="display:none"/-->
        <!-- p id="timelimit"style="display:none"/-->
        <div>
            <!--img id="toggl" style="vertical-align:3%" src="current-task.widget/images/Inactive-19.png"/-->
            <!--br/> <a class="area">area</a-->
            <br/> <a class="project">project</a>
            <br/> <a class="thing">thing</a>
        </div>
      </div>
    """

update: (output, domEl) ->
  data = []
  try
    data = JSON.parse output
  catch ex
    $(".area").text("Error Parsing JSON response: #{output}");

  $(".thing").text(data.task);
  $(".thing").attr("href","things:///show?id=today");
  $(".project").text(data.project);
  $(".project").attr("href","things:///show?query="+data.project);
  # $(".area").text(data.area);
  # $(".area").attr("href","things:///show?query="+data.area);

  tg = /\[TimeGoal:\s*([^\]]*)\]/.exec(data.notes);
  if(tg)
    tg = tg[1]
  else
    tg = "00:00"
  tl = /\[TimeLimit:\s*([^\]]*)\]/.exec(data.notes);
  if(tl)
    tl = tl[1]
  else
    tl = "00:00"

  $("#timegoal").text(tg);
  $("#timelimit").text(tl);
  if !$("#toggl").hasClass("reactDone")
    $("#toggl").addClass("reactDone")
    $("#toggl").click(@clickReact)
  $.ajax({url: "/Status", success: @updateStatus});


updateStatus: (resultArray) ->
