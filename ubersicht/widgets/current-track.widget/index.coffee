command: """
osascript -l JavaScript <<'JS'
function run() {
  var se = Application("System Events");
  if (se.processes.name().indexOf("Music") === -1) return "Music.app Closed";
  var music = Application("Music");
  try {
    if (music.playerState() === "stopped") return "Music Stopped";
    var t = music.currentTrack();
    return JSON.stringify({
      artist: t.artist(),
      song: t.name(),
      id: String(t.id()),
      app: "Music"
    });
  } catch (e) {
    return "No track";
  }
}
JS
"""

refreshFrequency: 4000

style: """
  bottom: 3px
  left: 6px
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

  @media (max-width: 1999px)
    .artist
      font-size: 18px
    .song
      font-size: 16px
    .link
      font-size: 11px

"""

render: (output) -> @getVisual output

afterRender: (domEl) ->
  $domEl = $(domEl)
  applyPlanningMode = ->
    if localStorage.getItem('planningMode') is 'on'
      $domEl.hide()
    else
      $domEl.show()
  applyPlanningMode()
  setInterval applyPlanningMode, 300

update: (output, domEl) ->
  $domEl = $(domEl)
  if localStorage.getItem('planningMode') is 'on'
    $domEl.hide()
    return
  $domEl.show()
  $domEl.html @getVisual output

encodeTerm: (s) -> encodeURIComponent(s ? '')

escapeHtml: (s) ->
  String(s ? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')

getVisual: (output) ->
  try
    data = JSON.parse output
  catch ex
    return """
      <div class="output">
        <span class="output song">#{@escapeHtml(output).trim() or 'Music.app Closed'}</span>
      </div>
    """
  artist = @escapeHtml(data.artist)
  song = @escapeHtml(data.song)
  artistQ = @encodeTerm(data.artist)
  songQ = @encodeTerm("#{data.song} #{data.artist}")
  return """
      <div class="output">
        <a href="music://music.apple.com/pt/search?term=#{artistQ}" class="artist">#{artist}</a>
        <a href="music://music.apple.com/pt/search?term=#{songQ}" class="song">#{song}</a>
        <a href="music://" class="link">↩︎</a>
      </div>
  """
