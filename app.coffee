parseSrt = (txt) ->
  if txt.search /\d+:\d+:\d+([.,]\d+)? -->/
    console.log "type A"
    return parseSrt_typeA txt

  console.error "could not recognise srt format"

parseSrt_typeA = (txt) ->
  lines = txt.replace('\r', '').split('\n')
  console.log "#{lines.length} lines"

  events = []

  startTs = 0
  endTs = 0
  content = null
  for line in lines
    xs = line.replace(',','.').match(/(\d+):(\d+):([\d.]+) --> (\d+):(\d+):([\d.]+)/)

    if line.trim().match(/^\d+$/)
      if content != null
        events.push({ts: startTs, text: content})
        events.push({ts: endTs, text: ''})
        content = ''

      # console.debug "event number #{line}"

    else if xs
      startTs = \
        parseInt(xs[1]) * 3600 \
        + parseInt(xs[2]) * 60 \
        + parseFloat(xs[3])

      endTs = \
        parseInt(xs[4]) * 3600 \
        + parseInt(xs[5]) * 60 \
        + parseFloat(xs[6])

      # console.debug "timestamp! #{startTs} --> #{endTs}"

    else
      content = content + ' ' + line
      # console.debug "plain content: #{line}"

  events.push({ts: startTs, text: content})
  events.push({ts: endTs, text: ''})

  return {
    events: events,
    duration: events[events.length-1].ts - events[0].ts,
  }

class Application
  loadSubtitles: ->
    fname = 'srt/' + $('#fname').val()
    $.get fname, (data, xhr) ->
      @srt = parseSrt data
      console.log @srt.events
      console.log "duration: #{@srt.duration/60} minutes"

  constructor: ->
    @srt = null

    for fname in window.SRTS
      $('#fname').append(
        $('<option>').attr('value', fname).text(fname)
      )

    $('#load').click =>
      @loadSubtitles()

$ -> new Application()
