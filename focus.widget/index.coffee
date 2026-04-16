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
    if(type == 'today' || type == 'daily')
      updateUnreadCount()
      updateEventsCount()

  updateUnreadCount = =>
    @run("osascript focus.widget/get_unread_count.scpt").then (output) ->
      count = parseInt(output.trim())
      unreadEls = domEl.querySelectorAll('.unread-total')
      for unreadEl in unreadEls
        if unreadEl
          if !isNaN(count) && count > 0
            unreadEl.innerText = count
            unreadEl.classList.remove('hidden')
          else
            unreadEl.classList.add('hidden')

  updateEventsCount = =>
    # brew install gcalcli
    # gcalcli list
    # 1pw Desktop MM Ubershitch - Calendar API
    @run('BREW_PREFIX=$([[ -d /opt/homebrew ]] && echo /opt/homebrew || echo /usr/local); $BREW_PREFIX/bin/gcalcli agenda now tomorrow --tsv --calendar MM@CoB | awk -v now="$(date +%H:%M)" \'$2 > now\' | tail -n +2 | wc -l').then (output) ->
      count = parseInt(output.trim())
      eventEls = domEl.querySelectorAll('.events-today')
      for eventEl in eventEls
        if eventEl
          if !isNaN(count) && count > 0
            eventEl.innerText = count
            eventEl.classList.remove('hidden')
          else
            eventEl.classList.add('hidden')

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
      showOverlay('today')
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
  height: 100%
  color: #fff
  font-family: Helvetica Neue

  .container
    display: none

  .container.planning
    display: block
    width: 100vw
    background-image: url('links.widget/images/calm.png')
    background-size: cover
    background-position: center

  .links.hidden
    display: none

  .review-selector
    position: absolute
    bottom: 7px
    left: 7px
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
    z-index: 10
    display: inline-block
    width: 24px
    height: 15px
    line-height:15px
    border-radius: 4px
    color: #fff
    font-family: verdana
    font-weight: bolder
    font-size: 10px
    text-align: center
    cursor: pointer

  .review-btn.review-open
    background-color: #d5184b
  .review-btn.today-plan-trigger
    background-color: rgb(0, 128, 0)
  .review-btn.daily-review-trigger
    background-color: rgb(100, 128, 0)
  .review-btn.weekly-review-trigger
    background-color: rgb(170, 128, 0)
  .review-btn.monthly-review-trigger
    background-color: rgb(200, 80, 0)
  .review-btn.trimester-review-trigger
    background-color: rgb(225, 40, 0)
  .review-btn.year-review-trigger
    background-color: rgb(255, 0, 0)

  .badge-style
    display: inline-flex
    background-color: rgba(0,0,0,0.25)
    padding: 3px 8px
    border-radius: 16px
    text-decoration: none
    color: #fff
    transition: background-color 0.2s ease
  .os-links .badge-style
    background-color: rgba(0,0,0,0.5)

  .badge-style:hover
    background-color: rgba(0,0,0,0.4)

  .badge-today
    background-color: rgba(0, 128, 0, 0.7)
    z-index: 1
  .badge-daily
    background-color: rgba(31, 136, 194, 0.7)
  .badge-weekly
    background-color: rgba(170, 128, 0, 0.7)
  .badge-monthly
    background-color: rgba(200, 80, 0, 0.7)
  .badge-trimester
    background-color: rgba(225, 40, 0, 0.7)
  .badge-year
    background-color: rgba(255, 0, 0, 0.7)

  a
    text-decoration:none

  .review-overlay
    position: absolute
    top: 0
    left: 0
    width: 100vw
    height: 100%
    color: #fff
    font-family: "Helvetica Neue"
    font-weight: 200
    box-sizing: border-box
    pointer-events: none

  .review-overlay.hidden
    display: none

  .review-schedule
    position: absolute
    top: 5px
    right: 10px
    font-size: 18px
    font-weight: 200
    color: rgba(255, 255, 255, 0.7)
    background-color: rgba(0,0,0,0.3)
    padding: 4px 6px
    border-radius: 5px
    text-shadow: 0 1px 1px rgba(0,0,0,0.2)

  .today-plan-overlay
    background-color: rgba(121, 255, 121, 0.3) // Lightest Green
  .daily-review-overlay
    background-color: rgba(31, 136, 194, 0.32) // Green-Blue
  .weekly-review-overlay
    background-color: rgba(170, 128, 0, 0.3) // Yellow-Orange
  .monthly-review-overlay
    background-color: rgba(200, 80, 0, 0.3) // Orange-Red
  .trimester-review-overlay
    background-color: rgba(225, 50, 0, 0.3) // Red
  .year-review-overlay
    background-color: rgba(255, 0, 0, 0.3) // Darkest Red
  .review-title
    position: absolute
    top: 15px
    width: 100%
    text-align: center
    padding-right: 24px
    box-sizing: border-box

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
    white-space: nowrap

  .shortcut kbd
    background-color: #d5184b
    border-radius: 4px
    padding: 1px 3px
    font-family: "Courier New", monospace
    font-size: 11px
    margin-right: 2px

  .badge-daily kbd, .badge-today kbd, , kbd.badge-daily
    background-color: orange

  .unread-count
    display: inline-block
    color: white
    font-size: 10px
    font-weight: bold
    padding: 2px 5px
    border-radius: 8px
    margin-left: 6px
    line-height: 1

  .unread-total
    background-color: #d5184b

  .events-today
    background-color: #4A90E2
    
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

  .shortcut.left kbd
    margin-left: 0px
    margin-right: 5px

  .os-links
    position: absolute
    bottom: 5px
    left: 0
    width: 100%
    text-align: center
    pointer-events: all

  .os-links a
    display: inline-block
    margin: 0 5px

  .os-links .shortcut
    margin-bottom: 0
    padding:0px 10px 2px 10px
"""

render: -> """
  <div>
    <div class="container" style="position:absolute; bottom:0px; left:0px; right:0px; top:0px;"></div>

    <div class="review-overlay today-plan-overlay hidden">
      <div class="review-title"><span>Today</span></div>
      <div class="content-wrapper">
        <div class="left-content">
          </div>
          <div class="right-content">
            <div class="shortcut right badge-style badge-daily"><span> Not Today</span> <kbd>CMD+R</kbd></div>
          </div>
        </div>
      <div class="os-links">
        <a href="#" class="mail-trigger"><div class="shortcut badge-style badge-today"><span>Mail </span><span class="unread-count unread-total hidden"></span></div></a>
        <a href="#" class="calendar-trigger"><div class="shortcut badge-style badge-today"><span>Calendar </span><span class="unread-count events-today hidden"></span></div></a>
        <a href="#" class="safari-trigger"><div class="shortcut badge-style badge-today"><span>Dogfooding</span></div></a>
      </div>
      <div class="review-schedule">Muitas vezes ao dia</div>
    </div>
    <div class="review-overlay daily-review-overlay hidden">
      <div class="review-title"><span>This Week</span></div>
      <div class="content-wrapper">
        <div class="left-content">
          <div class="shortcut left badge-style badge-today"><kbd>CMD+T</kbd> <span>Today</span></div>
        </div>
        <div class="right-content">
          <div class="shortcut right badge-style badge-daily"><span>Not Today</span> <kbd>CMD+R</kbd> </div>
          <div class="shortcut right badge-style badge-weekly"><span>Maybe Next Week</span> <kbd>CTRL+W</kbd> <kbd class="badge-daily">CMD+O</kbd></div>
        </div>
        </div>
        <div class="os-links">
          <a href="#" class="mail-trigger"><div class="shortcut badge-style"><span>Mail </span><span class="unread-count unread-total hidden"></span></div></a>
          <a href="#" class="calendar-trigger"><div class="shortcut badge-style"><span>Calendar </span><span class="unread-count events-today hidden"></span></div></a>
          <a href="#" class="safari-trigger"><div class="shortcut badge-style"><span>Dogfooding</span></div></a>
      </div>
      <div class="review-schedule">Day Review: todos os dias às 9h00</div>
    </div>
    <div class="review-overlay weekly-review-overlay hidden">
      <div class="review-title"><span>Maybe Next Week</span></div>
      <div class="content-wrapper">
        <div class="left-content">
          <div class="shortcut left badge-style badge-daily"><kbd>CMD+R</kbd> <span>This Week</span></div>
        </div>
        <div class="right-content">
          <div class="shortcut right badge-style badge-monthly"><span>Maybe Next Month</span><kbd>CTRL+M</kbd></div>
        </div>
      </div>
      <div class="review-schedule">Week Review: todas as Segundas às 8h45</div>
    </div>
    <div class="review-overlay monthly-review-overlay hidden">
      <div class="review-title"><span>Maybe Next Month</span></div>
      <div class="content-wrapper">
        <div class="left-content">
          <div class="shortcut left badge-style badge-weekly"><kbd>CTRL+W</kbd> <span>This Month</span></div>
        </div>
        <div class="right-content">
          <div class="shortcut right badge-style badge-trimester"><span>Maybe Next Trimester</span><kbd>CTRL+T</kbd></div>
        </div>
      </div>
      <div class="review-schedule">Month Review: todos os dias 1 | 8h30</div>
    </div>
    <div class="review-overlay trimester-review-overlay hidden">
      <div class="review-title"><span>Maybe Next Trimester</span></div>
      <div class="content-wrapper">
        <div class="left-content">
          <div class="shortcut left badge-style badge-monthly"><kbd>CTRL+M</kbd> <span>This Trimester</span></div>
        </div>
        <div class="right-content">
          <div class="shortcut right badge-style badge-year"><span>Maybe Next Year</span><kbd>CTRL+Y</kbd></div>
        </div>
      </div>
      <div class="review-schedule">Trimester Review: 2 Jan | 2 Abr | 2 Jul | 2 Out | 09:30</div>
    </div>
    <div class="review-overlay year-review-overlay hidden">
      <div class="review-title"><span>Maybe Next Year</span></div>
      <div class="content-wrapper">
        <div class="left-content">
          <div class="shortcut left badge-style badge-trimester"><kbd>CTRL+T</kbd> <span>This Year</span></div>
        </div>
        <div class="right-content"></div>
      </div>
      <div class="review-schedule">Year Review: 2 Jan</div>
    </div>
    <div class="review-selector">
      <a href="#" class="review-btn review-open">R</a>
      <div class="review-options ">
        <a href="#" class="review-btn review-close" style="background-color:purple;">X</a>
        <a href="#" class="review-btn today-plan-trigger">T</a>
        <a href="#" class="review-btn daily-review-trigger">DR</a>
        <a href="#" class="review-btn weekly-review-trigger">WR</a>
        <a href="#" class="review-btn monthly-review-trigger">MR</a>
        <a href="#" class="review-btn trimester-review-trigger">TR</a>
        <a href="#" class="review-btn year-review-trigger">YR</a>
      </div>
    </div>
  </div>
"""

command: """

# Lê a última linha do log do uber-listener, o ficheiro de comunicação entre o widget e o script de escuta de comandos
touch /tmp/uber-listener.log
content=$(tail -n 1 /tmp/uber-listener.log | tr -d '\0')

  if [ "$content" = "review" ]; then
    echo "" > /tmp/uber-listener.log
    echo "review"
  fi
"""

update: (output, domEl) ->
  command = output.trim()
  
  if command == "review"
    reviewOpen = domEl.querySelector('.review-btn.review-open')
    reviewClose = domEl.querySelector('.review-btn.review-close')
    if reviewOpen.classList.contains('hidden')
      reviewClose?.click()
    else
      reviewOpen?.click()
