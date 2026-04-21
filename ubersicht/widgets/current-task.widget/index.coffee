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
IFS='~' read -r theArea theProject theTask theId <<<"$(osascript <<'APPLESCRIPT_EOF'
tell application "System Events" to (name of processes) contains "Things3"

if result is true then
	tell application "Things3"
		set OList to to dos of list "Today"
		set theTodo to missing value
		repeat with aTodo in OList
			if status of aTodo is open then
				set theTodo to aTodo
				exit repeat
			end if
		end repeat

		if theTodo is missing value then
			return ""
		end if

		set theAreaName to ""
		set theNotesText to ""

		set theTaskName to name of the theTodo
		set theId to id of the theTodo

		try
			set theProject to the project of the theTodo
			set theProjectName to the name of theProject
			set theArea to the area of theProject
			set theAreaName to the name of theArea
		on error errStr number errorNumber
			set theProjectName to name of theTodo
			try
				set projectTodos to to dos of the theTodo
				set theTaskName to ""
			on error errStr number errorNumber
				set theProjectName to ""
			end try
			try
				set theArea to the area of the theTodo
				set theAreaName to the name of theArea
			end try
		end try

		set theTagsList to the tag names of the theTodo

		if notes of theTodo is not "" then
			set theNotesText to notes of theTodo
			set AppleScript's text item delimiters to {return & linefeed, return, linefeed, character id 8233, character id 8232}
			set newText to text items of theNotesText
			set AppleScript's text item delimiters to {"§"}
			set newText to newText as text
			set theNotesText to newText
		end if

		set message to theAreaName & "~" & theProjectName & "~" & theTaskName & "~" & "~" & theId

		set AppleScript's text item delimiters to {"\\""}
		set message to text items of message
		set AppleScript's text item delimiters to {"'"}
		set message to message as text
	end tell
else
	return "No focus (Things closed)!"
end if
APPLESCRIPT_EOF
)"
echo '{ "area":"'$theArea'","project": "'$theProject'", "task": "'$theTask'", "id": "'$theId'"}'
"""

refreshFrequency: 3000


style: """
  z-index: 0
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

  .taskDetails
    position: relative
    display:flex
    flex-direction: row
    justify-content: center
    align-items: center
    gap:2px
    min-width: 260px
    border-radius: 1rem
    background: #{ settings.colors.background }
    box-shadow: #{ settings.shadows.box }
    overflow: hidden
    -webkit-backdrop-filter: blur(10px)
    background:rgba(255, 255, 255, .8)
    padding:3px 38px 4px 15px

  .review-trigger
    position: absolute
    right: 6px
    top: 50%
    transform: translateY(-50%)
    width: 22px
    height: 15px
    line-height: 13px
    border-radius: 8px
    background-color: #fff
    color: #d5184b
    border: 1px solid #d5184b
    font-family: verdana
    font-weight: bolder
    font-size: 10px
    text-align: center
    cursor: pointer
    text-decoration: none
    box-sizing: border-box

  .thing
    font-size: 12px
    font-weight: 600
    color: rgba(0, 0, 0, 0.7)
    
  .project
    font-size: 18px
    color: rgba(0, 0, 0, 0.7)
    
  .area
    font-size: 12px

  .warning
    background:rgba(255,0,0,0.20)
    -webkit-transition: background-color 2000ms linear;

  .success
    background:rgba(0,255,0,0.15)
    -webkit-transition: background-color 2000ms linear;

  @media (max-width: 1999px)
    .taskDetails
      padding: 1px 28px 2px 10px
      min-width: 180px
    .project
      font-size: 12px
    .thing
      font-size: 10px
    .review-trigger
      right: 4px
      width: 18px
      height: 12px
      line-height: 10px
      font-size: 8px
      border-radius: 6px

"""

render: (output) ->
    return """
      <div id="currentTaskContent">
        <!-- p id="timelapse"/-->
        <!-- p id="timegoal"style="display:none"/-->
        <!-- p id="timelimit"style="display:none"/-->
        <div class="taskDetails">
            <!--img id="toggl" style="vertical-align:3%" src="current-task.widget/images/Inactive-19.png"/-->
            <!--br/> <a class="area">area</a-->
            <a class="project">project</a> <a class="thing">thing</a>
            <a href="#" class="review-trigger">R</a>
        </div>
      </div>
    """

afterRender: (domEl) ->
  $(domEl).find('.review-trigger').on 'click', (e) =>
    e.preventDefault()
    @run "echo toggle > /tmp/focus-review-cmd"

update: (output, domEl) ->
  data = []
  try
    data = JSON.parse output
  catch ex
    $(".area").text("Error Parsing JSON response: #{output}");

  $(".thing").text(data.task);
  $(".thing").attr("href","things:///show?id=today");
  $(".project").text(data.project);
  $(".project").attr("href","things:///show?id="+data.id);
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
