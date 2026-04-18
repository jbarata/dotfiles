command: "ps axro \"pid, %cpu, ucomm\" | awk 'FNR>1' | sort -r | awk 'BEGIN { sum = 0 }  { sum += $2 }; END { printf \"%5.1f%%,%s,%s\\n\", $2, $3, $1; print sum }' && sysctl hw.ncpu | awk '{print $2}'"

refreshFrequency: 9000

style: """
  bottom: 17px
  right: 17px
  color: rgba(255,255,255,0.35)
  font-family: Helvetica Neue

  table
    border-collapse: collapse
    table-layout: fixed

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
    background: rgba(#fff, 0)

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
    bottom: 8px
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

  renderProcess = (cpu, name, id) ->
    "<div class='wrapper'>" +
      "#{cpu}<p>#{name}</p>" +
      "<div class='type'>cpu</div>" +
    "</div>"

  for process, i in processes
    args = process.split(',')
    table.find(".col#{i+1}").html renderProcess(args...)

  totalCpuUsage = processes[2]
  cpuQuantity = processes[3]
  alarm = parseInt(totalCpuUsage/cpuQuantity) > 50

  if(alarm)
    table.find("td").toggleClass("alarm")
