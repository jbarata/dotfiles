command: "next-event.widget/GetNextEvent"

refreshFrequency: 6000

style: """
  bottom: 3px
  right: 322px
  
  color: #fff
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif
  white-space: nowrap
  z-index: 1000
  font-size: 14px
  font-weight: 500
  cursor: pointer
  border-radius: 1rem
  
  .event-bg {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 60px;
    border-radius: 1rem;
    background-color: rgba(0, 0, 0, 0.6);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    z-index: 0;
    transition: background-color 0.5s ease, border-color 0.5s ease;
  }
  
  .event-content {
    position: relative;
    z-index: 1;
    padding: 0.9rem 1.5rem;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    text-align: right;
  }
  
  .separator {
    opacity: 0.5
    margin: 0 6px;
  }
    
  .no-event {
    font-style: italic;
    opacity: 0.3;
  }
"""

render: (output) -> """
  <div class="event-bg"></div>
  <div class="event-content" id="next-event-content">
    <div class="no-event">Checking calendar...</div>
  </div>
"""

afterRender: (domEl) ->
  $(domEl).on 'click', =>
    container = $(domEl).find('#next-event-content')
    key = container.attr('data-key')
    bg = $(domEl).find('.event-bg')
    
    if key
      if localStorage.getItem(key) == 'true'
        localStorage.removeItem(key)
      else
        localStorage.setItem(key, 'true')
        # Stop blinking
        timer = $(domEl).data('blinkTimer')
        if timer
            clearInterval(timer)
            $(domEl).data('blinkTimer', null)
        
        bg.css('opacity', '1')
        bg.css('background-color', 'rgba(255, 0, 0, 0.6)')
        bg.css('border-color', 'rgba(255, 0, 0, 0.3)')

update: (output, domEl) ->
  bg = $(domEl).find('.event-bg')
  content = $(domEl).find('#next-event-content')
  output = output.trim()

  if output.includes("Access denied")
    content.html('<div class="no-event" style="color:#ff6b6b">Access Denied<br><span style="font-size:10px">Please run the binary in Terminal once to grant permission.</span></div>')
    return
  
  if output == "None" or output == ""
    content.html('<div class="no-event">sem eventos até</div><div class="no-event">ao fim do dia</div>')
    
    timer = $(domEl).data('blinkTimer')
    if timer
        clearInterval(timer)
        $(domEl).data('blinkTimer', null)
        
    bg.css('opacity', '0.3')
    bg.css('background-color', 'rgba(0, 0, 0, 0.6)')
    bg.css('border-color', 'rgba(255, 255, 255, 0.1)')
    return

  parts = output.split('~')
  if parts.length < 4
    content.html('<div class="no-event">Error parsing event</div>')
    return

  title = parts[0]
  startStr = parts[1]
  location = parts[2]
  isAllDay = parts[3]

  # Parse Date
  startDate = new Date(startStr)
  
  # Format time display
  optionsTime = { hour: '2-digit', minute: '2-digit', hour12: false }
  
  timeDisplay = ""
  remainingText = ""
  
  if isAllDay == "true"
    timeDisplay = "All Day"
  else if !isNaN(startDate)
    timeDisplay = startDate.toLocaleTimeString([], optionsTime)
    
    # Calculate remaining time
    now = new Date()
    diffMs = startDate - now
    diffMins = diffMs / 1000 / 60
    
    if diffMins > 0
      totalMins = Math.ceil(diffMins)
      hours = Math.floor(totalMins / 60)
      mins = Math.floor(totalMins % 60)
      
      rt = ""
      if hours > 0
        rt = "#{hours}h#{mins}m"
      else
        rt = "#{mins}m"
        
      remainingText = " <span style='font-size: 0.8em; opacity: 0.7;'>(" + rt + ")</span>"
  else
    timeDisplay = startStr

  line1 = title
  if location and location != "" and location != "missing value"
    line1 += " <span class='separator'>|</span> #{location}"

  html = """
    <div>#{line1}</div>
    <div style="font-size: 0.9em; opacity: 0.9;">#{timeDisplay}#{remainingText}</div>
  """
    
  content.html(html)
  
  # Set Data Key for Acknowledgment
  eventKey = "ack_#{title}_#{startStr}"
  content.attr('data-key', eventKey)

  # Urgency logic
  bgColor = 'rgba(0, 0, 0, 0.1)'
  borderColor = 'rgba(255, 255, 255, 0.05)'
  isBlinking = false
  
  if isAllDay != "true" and !isNaN(startDate)
    now = new Date()
    diffMs = startDate - now
    diffMins = diffMs / 1000 / 60
    
    if diffMins <= 1
        if diffMins >= -10
             # Started within last 5 mins
             if localStorage.getItem(eventKey) != 'true'
                 isBlinking = true
                 bgColor = 'rgba(255, 0, 0, 0.8)'
                 borderColor = 'rgba(255, 0, 0, 0.3)'
    else if diffMins <= 5
        # Critical: Red
        bgColor = 'rgba(255, 0, 0, 0.6)'
        borderColor = 'rgba(255, 0, 0, 0.6)'
    else if diffMins <= 30
        # Urgent: Light Orange
        bgColor = 'rgba(255, 140, 0, 0.3)'
        borderColor = 'rgba(255, 140, 0, 0.3)'
    else if diffMins <= 60
        # non-urgent: transparent orange
        bgColor = 'rgba(255, 140, 0, 0.15)'
        borderColor = 'rgba(255, 255, 255, 0.1)'

  # Apply State
  timer = $(domEl).data('blinkTimer')
  
  if isBlinking
    if !timer
      bg.css('background-color', bgColor)
      bg.css('border-color', borderColor)
      # Start blinking
      newTimer = setInterval ->
         currentOp = bg.css('opacity')
         if currentOp == '1'
            bg.css('opacity', '0.4')
         else
            bg.css('opacity', '1')
      , 500
      $(domEl).data('blinkTimer', newTimer)
  else
    if timer
       clearInterval(timer)
       $(domEl).data('blinkTimer', null)
       
    bg.css('opacity', '1')
    bg.css('background-color', bgColor)
    bg.css('border-color', borderColor)
