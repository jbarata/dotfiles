refreshFrequency: 3600000

afterRender: (domEl) ->
  widget = $(domEl)

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

  # Set initial state from localStorage
  if localStorage.getItem('planningMode') is 'on'
    togglePlanningMode(true)
  else
    togglePlanningMode(false)

  # togglePlanningMode(false)

  # Add click handlers
  widget.find('.review-open').on 'click', (e) =>
    togglePlanningMode(true)
    e.preventDefault()
    @run "osascript focus.widget/review_open.scpt"
    @run "osascript focus.widget/large_center.scpt"


  widget.find('.review-close').on 'click', (e) =>
    togglePlanningMode(false)
    e.preventDefault()
    @run "osascript focus.widget/review_close.scpt"

  widget.find('.daily-review-trigger').on 'click', (e) =>
    e.preventDefault()
    @run "osascript focus.widget/review_daily.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.weekly-review-trigger').on 'click', (e) =>
    e.preventDefault()
    @run "osascript focus.widget/review_weekly.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.monthly-review-trigger').on 'click', (e) =>
    e.preventDefault()
    @run "osascript focus.widget/review_monthly.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.trimester-review-trigger').on 'click', (e) =>
    e.preventDefault()
    @run "osascript focus.widget/review_trimester.scpt"
    @run "osascript focus.widget/large_center.scpt"

  widget.find('.year-review-trigger').on 'click', (e) =>
    e.preventDefault()
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
"""


render: -> """
<div>

  <div class="container" style="position:absolute; bottom:0px; left:0px; right:0px; top:0px;"></div>
 
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
