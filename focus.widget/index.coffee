refreshFrequency: 500

afterRender: (domEl) ->
  widget = $(domEl)
  overlays =
    today: widget.find('.today-plan-overlay')
    daily: widget.find('.daily-review-overlay')
    weekly: widget.find('.weekly-review-overlay')
    monthly: widget.find('.monthly-review-overlay')
    trimester: widget.find('.trimester-review-overlay')
    year: widget.find('.year-review-overlay')

  hideAllOverlays = ->
    for key, overlay of overlays
      overlay.addClass 'hidden'
  
  showOverlay = (type) ->
    hideAllOverlays()
    overlays[type]?.removeClass 'hidden'

  togglePlanningMode = (state) ->
    container = widget.find('.container')
    links = widget.find('.links')
    reviewOptions = widget.find('.review-options')
    reviewOpen = widget.find('.review-open')

    if state
      localStorage.setItem('planningMode', 'on')
      container.addClass 'planning'
      links.addClass 'hidden'
      reviewOpen.addClass 'hidden'
      reviewOptions.removeClass 'hidden'
    else
      localStorage.removeItem('planningMode')
      container.removeClass 'planning'
      links.removeClass 'hidden'
      reviewOpen.removeClass 'hidden'
      reviewOptions.addClass 'hidden'
      hideAllOverlays()

  # Set initial state from localStorage
  if localStorage.getItem('planningMode') is 'on'
    togglePlanningMode(true)
  else
    togglePlanningMode(false)

  # Add click handlers
  widget.find('.calendar-trigger').on 'click', (e) =>
    e.preventDefault()
    @run "open -a Calendar"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.mail-trigger').on 'click', (e) =>
    e.preventDefault()
    @run "open -a Mail"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.safari-trigger').on 'click', (e) =>
    e.preventDefault()
    @run "open -a Safari 'https://dogfooding.cultofbits.com/recordm/index.html#/cob.custom-resource/458932:{%22todayVar%22:%221759846813737%22,%22switchView%22:%22yes%22}/dash'"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.review-open').on 'click', (e) =>
    togglePlanningMode(true)
    showOverlay('today')
    e.preventDefault()
    @run "osascript focus.widget/review_open.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.review-close').on 'click', (e) =>
    togglePlanningMode(false)
    e.preventDefault()
    @run "osascript focus.widget/review_close.scpt"

  widget.find('.today-plan-trigger').on 'click', (e) =>
    e.preventDefault()
    showOverlay('today')
    @run "osascript focus.widget/review_open.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.daily-review-trigger').on 'click', (e) =>
    e.preventDefault()
    showOverlay('daily')
    @run "osascript focus.widget/review_daily.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.weekly-review-trigger').on 'click', (e) =>
    e.preventDefault()
    showOverlay('weekly')
    @run "osascript focus.widget/review_weekly.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.monthly-review-trigger').on 'click', (e) =>
    e.preventDefault()
    showOverlay('monthly')
    @run "osascript focus.widget/review_monthly.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.trimester-review-trigger').on 'click', (e) =>
    e.preventDefault()
    showOverlay('trimester')
    @run "osascript focus.widget/review_trimester.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.year-review-trigger').on 'click', (e) =>
    e.preventDefault()
    showOverlay('year')
    @run "osascript focus.widget/review_year.scpt"
    @run "osascript focus.widget/large_center.scpt"
    
style: """
  top: 0px
  left: 0px
  width: -webkit-fill-content
  height: 100%
  color: #fff
  font-family: Helvetica Neue

  .container
    display: none
    z-index:998

  .container.planning
    display: block
    width: 100vw
    background-image: url('links.widget/images/calm.png')
    background-size: cover
    background-position: center

  .links.hidden
    display: none

  .review-selector
    z-index:999
    position: absolute
    bottom: 15px
    left: 15px
    text-align: center

  .review-options
    display: flex
    justify-content: center
    gap: 10px

  .review-options.hidden
    display: none

  .review-open.hidden
    display: none

  .review-btn
    display: inline-block
    width: 15px
    height: 15px
    line-height:15px
    border-radius: 4px
    background-color: #d5184b
    color: #fff
    font-family: verdana
    font-weight: bolder
    font-size: 10px
    text-align: center
    cursor: pointer

  a
    text-decoration:none

  .review-overlay
    position: absolute
    top: 0
    left: 0
    width: 100vw
    height: 100%
    z-index: 999
    color: #fff
    font-family: "Helvetica Neue"
    font-weight: 200
    box-sizing: border-box
    pointer-events: none

  .review-overlay.hidden
    display: none

  .today-plan-overlay
    background-color: rgba(121, 255, 121, 0.42) // Lightest Green
  .daily-review-overlay
    background-color: rgba(31, 136, 194, 0.32) // Green-Blue
  .weekly-review-overlay
    background-color: rgba(170, 128, 0, 0.5) // Yellow-Orange
  .monthly-review-overlay
    background-color: rgba(200, 80, 0, 0.5) // Orange-Red
  .trimester-review-overlay
    background-color: rgba(225, 40, 0, 0.5) // Red
  .year-review-overlay
    background-color: rgba(255, 0, 0, 0.6) // Darkest Red
  .review-title
    position: absolute
    top: 5px
    left: 0
    width: 100%
    text-align: center
    height: auto

  .review-title span
    display: inline-block
    padding: 4px 18px
    border-radius: 15px
    font-size: 22px
    font-weight: 300
    color: #fff
    text-shadow: 0 1px 2px rgba(0,0,0,0.4)

  .today-plan-overlay .review-title span
    background-color: rgb(0, 128, 0)
  .daily-review-overlay .review-title span
    background-color: rgb(100, 128, 0)
  .weekly-review-overlay .review-title span
    background-color: rgb(170, 128, 0)
  .monthly-review-overlay .review-title span
    background-color: rgb(200, 80, 0)
  .trimester-review-overlay .review-title span
    background-color: rgb(225, 40, 0)
  .year-review-overlay .review-title span
    background-color: rgb(255, 0, 0)

  .review-overlay .content-wrapper
    position: absolute
    top: 50%
    left: 50%
    transform: translate(-50%, -50%)
    width: 90%
    display: flex
    justify-content: space-between
    align-items: center

  .review-overlay .left-content, .review-overlay .right-content
    width: 20%
    font-size: 14px
    line-height: 1.5

  .review-overlay .right-content
    text-align: right
    right: 30%

  .shortcut
    display: flex
    align-items: center
    margin-bottom: 10px

  .shortcut kbd
    background-color: #d5184b
    border-radius: 4px
    padding: 1px 3px
    font-family: "Courier New", monospace
    font-size: 11px
    margin-right: 2px
    position: relative
    top: -1px

  .unread-count
    display: inline-block
    color: white
    font-size: 10px
    font-weight: bold
    padding: 2px 5px
    border-radius: 8px
    margin-left: 6px
    line-height: 1

  .unread-inbox
    background-color: #d5184b

  .unread-archive
    background-color: #555
    
  .unread-count.hidden
    display: none
    
  .shortcut.left
    justify-content: flex-start

  .shortcut.right
    justify-content: flex-end

  .shortcut.right kbd
    order: 1
    margin-left: 5px
    margin-right: 0px
"""

render: -> """
<div>
  <div class="container" style="position:absolute; bottom:0px; left:0px; right:0px; top:0px;"></div>

  <div class="review-overlay today-plan-overlay hidden">
    <div class="review-title"><span>Today Plan</span></div>
    <div class="content-wrapper">
      <div class="left-content">
        <a href="#" class="calendar-trigger" style="pointer-events: all;"><div class="shortcut left"><span><kbd>C</kbd> Calendar</span></div></a>
        <a href="#" class="mail-trigger" style="pointer-events: all;"><div class="shortcut left"><span><kbd>M</kbd> Mail </span><span class="unread-count unread-inbox hidden"></span><span class="unread-count unread-archive hidden"></span></div></a>
        <a href="#" class="safari-trigger" style="pointer-events: all; margin-bottom:20px;"><div class="shortcut left"><span><kbd>S</kbd> DF Plan</span></div></a>
      </div>
      <div class="right-content">
        <div class="shortcut right"><span>Review TOMORROW</span> <kbd>CMD+R</kbd></div>
        <div class="shortcut right"><span>Review Next Week</span> <kbd>CTRL+W</kbd></div>
        <div class="shortcut right"><span>Review Next Month</span> <kbd>CTRL+M</kbd></div>
        <div class="shortcut right"><span>Review Next Trimester</span> <kbd>CTRL+T</kbd></div>
        <div class="shortcut right"><span>Review Next Year</span> <kbd>CTRL+Y</kbd></div>
      </div>
    </div>
  </div>

  <div class="review-overlay daily-review-overlay hidden">
    <div class="review-title"><span>Daily Review</span></div>
    <div class="content-wrapper">
      <div class="left-content">
        <a href="#" class="calendar-trigger" style="pointer-events: all;"><div class="shortcut left"><span><kbd>C</kbd> Calendar</span></div></a>
        <a href="#" class="mail-trigger" style="pointer-events: all;"><div class="shortcut left"><span><kbd>M</kbd> Mail </span></div></a>
        <a href="#" class="safari-trigger" style="pointer-events: all; margin-bottom:20px;"><div class="shortcut left"><span><kbd>S</kbd> DF Plan</span></div></a>
        <div class="shortcut left"><kbd>CMD+t</kbd> <span>DO TODAY</span></div>
      </div>
      <div class="right-content">
        <div class="shortcut right"><span>Review TOMORROW</span> <kbd>CMD+R</kbd></div>
        <div class="shortcut right"><span>Review Next Week</span> <kbd>CTRL+W</kbd></div>
        <div class="shortcut right"><span>Review Next Month</span> <kbd>CTRL+M</kbd></div>
        <div class="shortcut right"><span>Review Next Trimester</span> <kbd>CTRL+T</kbd></div>
        <div class="shortcut right"><span>Review Next Year</span> <kbd>CTRL+Y</kbd></div>
      </div>
    </div>
  </div>
  <div class="review-overlay weekly-review-overlay hidden">
    <div class="review-title"><span>Weekly Review</span></div>
    <div class="content-wrapper">
      <div class="left-content">
        <div class="shortcut left"><span><kbd>CTRL+N</kbd> Review Everyday</span></div>
      </div>
      <div class="right-content">
        <div class="shortcut right"><span>Review Next Month</span><kbd>CTRL+M</kbd></div>
        <div class="shortcut right"><span>Review Next Trimester</span><kbd>CTRL+T</kbd></div>
        <div class="shortcut right"><span>Review Next Year</span><kbd>CTRL+Y</kbd></div>
      </div>
    </div>
  </div>
  <div class="review-overlay monthly-review-overlay hidden">
    <div class="review-title"><span>Monthly Review</span></div>
    <div class="content-wrapper">
      <div class="left-content">
        <div class="shortcut left"><span><kbd>CTRL+N</kbd> Review Everyday</span></div>
        <div class="shortcut left"><span><kbd>CTRL+W</kbd> Review Next Week</span></div>
      </div>
      <div class="right-content">
        <div class="shortcut right"><span>Review Next Trimester</span><kbd>CTRL+T</kbd></div>
        <div class="shortcut right"><span>Review Next Year</span><kbd>CTRL+Y</kbd></div>
      </div>
    </div>
  </div>
  <div class="review-overlay trimester-review-overlay hidden">
    <div class="review-title"><span>Trimester Review</span></div>
    <div class="content-wrapper">
      <div class="left-content">
        <div class="shortcut left"><span><kbd>CTRL+N</kbd> Review Everyday</span></div>
        <div class="shortcut left"><span><kbd>CTRL+W</kbd> Review Next Week</span></div>
        <div class="shortcut left"><span><kbd>CTRL+M</kbd> Review Next Month</span></div>
      </div>
      <div class="right-content">
        <div class="shortcut right"><span>Review Next Year</span><kbd>CTRL+Y</kbd></div>
      </div>
    </div>
  </div>
  <div class="review-overlay year-review-overlay hidden">
    <div class="review-title"><span>Year Review</span></div>
    <div class="content-wrapper">
      <div class="left-content">
        <div class="shortcut left"><span><kbd>CTRL+N</kbd> Review Everyday</span></div>
        <div class="shortcut left"><span><kbd>CTRL+W</kbd> Review Next Week</span></div>
        <div class="shortcut left"><span><kbd>CTRL+M</kbd> Review Next Month</span></div>
        <div class="shortcut left"><span><kbd>CTRL+T</kbd> Review Next Trimester</span></div>
      </div>
      <div class="right-content"></div>
    </div>
  </div>
  <div class="review-selector">
    <a href="#" class="review-btn review-open">R</a>
    <div class="review-options ">
      <a href="#" class="review-btn review-close" style="background-color:purple;">X</a>
      <a href="#" class="review-btn today-plan-trigger">H</a>
      <a href="#" class="review-btn daily-review-trigger">D</a>
      <a href="#" class="review-btn weekly-review-trigger">W</a>
      <a href="#" class="review-btn monthly-review-trigger">M</a>
      <a href="#" class="review-btn trimester-review-trigger">T</a>
      <a href="#" class="review-btn year-review-trigger">A</a>
    </div>
  </div>
</div>
"""

command: """
# --- NC Listener ---
# Lança o servidor nc só uma vez (se ainda não estiver a correr)
if ! pgrep -f "nc -lk 5555" > /dev/null; then
  nohup nc -lk 5555 > /tmp/uber-listener.log 2>/dev/null &
fi

# Lê a última linha do log e, se for "review", consome-a.
content=$(tail -n 1 /tmp/uber-listener.log | tr -d '\0')
if [ "$content" = "review" ]; then
  echo "" > /tmp/uber-listener.log
  echo "CMD:review"
fi

# --- Mail Unread Count ---
# Obtém a contagem de não lidos da caixa de entrada do Mail.app
INBOX_COUNT=$(osascript -e 'tell application "Mail" to return the unread count of inbox' 2>/dev/null)
echo "MAIL_INBOX:$INBOX_COUNT"

"""

update: (output, domEl) ->
  lines = output.split('\n')
  console.log("focus.widget output lines: ", lines)
  
  for line in lines
    if line.startsWith('CMD:')
      command = line.replace('CMD:', '').trim()
      if command == "review"
        console.log("focus.widget a processar o comando de toggle 'review'")
        reviewOpen = domEl.querySelector('.review-btn.review-open')
        reviewClose = domEl.querySelector('.review-btn.review-close')
        if reviewOpen.classList.contains('hidden')
          reviewClose?.click()
        else
          reviewOpen?.click()

    else if line.startsWith('MAIL_INBOX:')
      count = parseInt(line.replace('MAIL_INBOX:', '').trim())
      unreadEl = domEl.querySelector('.unread-inbox')
      if unreadEl
        if !isNaN(count) && count > 0
          unreadEl.innerText = count
          unreadEl.classList.remove('hidden')
        else
          unreadEl.classList.add('hidden')
          
    else if line.startsWith('MAIL_ARCHIVE:')
      count = parseInt(line.replace('MAIL_ARCHIVE:', '').trim())
      unreadEl = domEl.querySelector('.unread-archive')
      if unreadEl
        if !isNaN(count) && count > 0
          unreadEl.innerText = count
          unreadEl.classList.remove('hidden')
        else
          unreadEl.classList.add('hidden')
