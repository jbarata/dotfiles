refreshFrequency: 3600000

afterRender: (domEl) ->
  widget = $(domEl)

  overlays =
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
  widget.find('.review-open').on 'click', (e) =>
    togglePlanningMode(true)
    hideAllOverlays()
    e.preventDefault()
    @run "osascript focus.widget/review_open.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.review-close').on 'click', (e) =>
    togglePlanningMode(false)
    e.preventDefault()
    @run "osascript focus.widget/review_close.scpt"

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
    bottom: 35px
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

  <div class="review-overlay daily-review-overlay hidden">
    <div class="content-wrapper">
      <div class="left-content"></div>
      <div class="right-content">
        <div class="shortcut right"><span>Review Next Week</span> <kbd>CTRL+W</kbd></div>
        <div class="shortcut right"><span>Review Next Month</span> <kbd>CTRL+M</kbd></div>
        <div class="shortcut right"><span>Review Next Trimester</span> <kbd>CTRL+T</kbd></div>
        <div class="shortcut right"><span>Review Next Year</span> <kbd>CTRL+Y</kbd></div>
      </div>
    </div>
  </div>
  <div class="review-overlay weekly-review-overlay hidden">
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
      <a href="#" class="review-btn review-close">X</a>
      <a href="#" class="review-btn daily-review-trigger">D</a>
      <a href="#" class="review-btn weekly-review-trigger">W</a>
      <a href="#" class="review-btn monthly-review-trigger">M</a>
      <a href="#" class="review-btn trimester-review-trigger">T</a>
      <a href="#" class="review-btn year-review-trigger">A</a>
    </div>
  </div>
</div>
"""
