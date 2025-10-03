afterRender: (domEl) ->
  widget = $(domEl)

  togglePlanningMode = (state) ->
    container = widget.find('.container')
    links = widget.find('.links')
    reviewOptions = widget.find('.review-options')
    reviewToggle = widget.find('.review-toggle')

    if state
      localStorage.setItem('planningMode', 'on')
      container.addClass 'planning'
      links.addClass 'hidden'
      reviewToggle.addClass 'hidden'
      reviewOptions.removeClass 'hidden'
    else
      localStorage.removeItem('planningMode')
      container.removeClass 'planning'
      links.removeClass 'hidden'
      reviewToggle.removeClass 'hidden'
      reviewOptions.addClass 'hidden'

  # Set initial state from localStorage
  if localStorage.getItem('planningMode') is 'on'
    togglePlanningMode(true)
  else
    togglePlanningMode(false)

  # Add click handlers
  widget.find('.review-toggle').on 'click', (e) ->
    e.preventDefault()
    togglePlanningMode(true)

  widget.find('.review-close').on 'click', (e) ->
    togglePlanningMode(false)

style: """
  top: 0px
  left: 0px
  width: -webkit-fill-content
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
    bottom: 35px
    left: 15px
    text-align: center

  .review-options
    display: flex
    justify-content: center
    gap: 10px

  .review-options.hidden
    display: none

  .review-toggle.hidden
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

"""


render: -> """
<div>

  <div  class="container" style="position:absolute; bottom:0px; left:0px; right:0px; top:0px;">
  </div>

  <div class="review-selector">
    <a href="#" class="review-toggle review-btn">R</a>
    <div class="review-options ">
      <a href="shortcuts://run-shortcut?name=Things%20CLOSE%20Review" class="review-btn review-close">X</a>
      <a href="shortcuts://run-shortcut?name=Things%20DAYLY%20Review" class="review-btn">D</a>
      <a href="shortcuts://run-shortcut?name=Things%20WEEK%20Review" class="review-btn">W</a>
      <a href="shortcuts://run-shortcut?name=Things%20MONTH%20Review" class="review-btn">M</a>
      <a href="shortcuts://run-shortcut?name=Things%20TRiMESTER%20Review" class="review-btn">T</a>
      <a href="shortcuts://run-shortcut?name=Things%20YEAR%20Review" class="review-btn">A</a>
    </div>
  </div>

  </div>
</div>
"""
