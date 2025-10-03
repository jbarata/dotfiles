command: """
read -r running <<<"$(ps -ef | grep -e \"/System/Applications/Music.app/Contents/MacOS/Music\" | wc -l)" &&
test $running != 0 &&
IFS='|' read -r theArtist theName theId theApp <<<"$(osascript <<<'
    global aname, tname, alname, rate

    set musicapp to "Music"
    set playerstate to "Playing"

    try
    	if musicapp is not "" then
        tell application "Music"
          set {tname, aname, tid} to {name, artist, id} of current track
          set tpos to player position
        end tell
    		return aname & "|" & tname & "|" & tid & "|" & musicapp
    	else
    		return "NA" & "|" & "NA" & "|" & "NA" & "|" & "NA" & "| " & "NA" & "|" & "NA" & "|" & "NA"
    	end if
    on error e
    	return "erro a obter musica"
    end try

')" &&
echo '{ "artist":"'$theArtist'","song": "'$theName'", "id": "'$theId'", "app":"'$theApp'"}' || echo "Music.app Closed"
"""

refreshFrequency: 4000

style: """
  bottom: 0px
  left: 10px
  color: #fff

  .output
    font-family: Helvetica Neue
    font-weight: 100
    text-shadow: 0 1px 5px #000000;

  .artist
    font-size: 30px
    color:red
    font-weight: 200
    text-decoration: none

  .song
    font-size: 26px
    color:white
    text-decoration: none
    margin-left: 10px

  .link
    color:white
    font-size: 15px
    text-decoration: none
    margin-left: 5px

"""

render: (output) -> @getVisual output

update: (output, domEl) ->
  $domEl = $(domEl)
  $domEl.html @getVisual output

getVisual: (output) ->
  data = []
  try
    data = JSON.parse output
  catch ex
    return """
      <div class='github-notifications #{if @enterprise then "enterprise" else "public"}'>
        <span class="output song">#{output}</span>
      </div>
    """
  return """
      <div class="output">
        <a href="music://music.apple.com/pt/search?term=#{data.artist}" class="artist">#{data.artist}</a>
        <a href="music://music.apple.com/pt/search?term='#{data.song}' #{data.artist}" class="song">#{data.song}</a>
        <a href="music://" class="link">↩︎</a>
      </div>
  """
