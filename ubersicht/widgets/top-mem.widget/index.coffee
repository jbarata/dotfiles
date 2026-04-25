command: "ps axmo \"pid, %mem, ucomm\" | awk 'FNR>1' | head -n 2 | awk '{ printf \"%5.1f%%,%s,%s\\n\", $2, $3, $1}' && memory_pressure | grep 'free percentage' | awk '{print substr($5, 0, length($5)-1)}'"

refreshFrequency: 9000

style: """
  bottom: 80px
  right: 90px
  color: rgba(255,255,255,0.35)
  font-family: Helvetica Neue

  table
    border-collapse: collapse
    table-layout: fixed
    transition: opacity 0.4s ease

  table.dimmer
    opacity: 0.5

  table.invisible
    opacity: 0

  .alarm
    background: rgba(#f00, 0.4)

  td
    border: 1px solid rgba(255,255,255,0.1)
    font-size: 24px
    font-weight: 100
    width: 110px
    max-width: 110px
    overflow: hidden
    text-shadow: 0 0 1px rgba(#000, 0.5)

  .wrapper
    padding: 4px 6px 4px 6px
    position: relative
    background: rgba(#fff, 0.0)

  p
    padding: 0
    margin: 0
    font-size: 11px
    font-weight: normal
    max-width: 100%
    color: rgba(255,255,255,0.35)
    text-overflow: ellipsis
    text-shadow: none

  .type
    position: absolute
    top: 2px
    right: 2px
    font-size: 15px
    font-weight: normal

  @media (max-width: 1999px)
    bottom: 36px
    td
      font-size: 14px
      width: 80px
      max-width: 80px
    .wrapper
      padding: 2px 4px 2px 4px
    p
      font-size: 9px
    .type
      font-size: 10px

"""


render: -> """
  <table>
    <tr>
      <td class='col1'></td>
    </tr>
  </table>
"""

update: (output, domEl) ->
  processes = output.split('\n')
  table     = $(domEl).find('table')

  renderProcess = (mem, name, id) ->
    "<div class='wrapper'>" +
      "#{mem}<p>#{name}</p>" +
      "<div class='type'>mem</div>" +
    "</div>"

  for process, i in processes
    args = process.split(',')
    table.find(".col#{i+1}").html renderProcess(args...)

  memUsage = 100 - parseFloat(processes[2])

  table.removeClass("dimmer invisible")
  if memUsage < 20
    table.addClass("invisible")
  else if memUsage < 30
    table.addClass("dimmer")

  table.find("td").toggleClass("alarm", memUsage >= 50)
