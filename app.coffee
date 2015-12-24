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
  content = ''
  for line in lines
    xs = line.replace(',','.').match(/(\d+):(\d+):([\d.]+) --> (\d+):(\d+):([\d.]+)/)

    if line.trim().match(/^\d+$/)
      if content != ''
        events.push({ts: startTs, text: content})
        #events.push({ts: endTs, text: ''})
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
  #events.push({ts: endTs, text: ''})

  return {
    events: events,
    duration: events[events.length-1].ts - events[0].ts,
  }

now = ->
  d = new Date()
  return d.getTime()

class Application
  tick: ->
    curTs = (now() - @startTs) / 1000.0
    console.log "tick: #{curTs}"

    while curTs - @srt.events[@pos].ts > -0.2  # also accept 0.2s in future
      $('#content').text(@srt.events[@pos].text)
      @pos++

    nextDelay = @srt.events[@pos].ts - curTs
    console.log "nextDelay = #{nextDelay}"

    @clockHandle = window.setTimeout (=> @tick()), Math.floor(1000 * nextDelay)

  reset: ->
    console.log 'reset'
    @pos = 0

  # t' = at + b
  transform: (a, b) ->
    @srt = {
      events: ({ts: a*e.ts + b, text: e.text} for e in @rawSrt.events),
      duration: a*@rawSrt.duration
    }

  load: ->
    @stop()

    fname = 'srt/' + $('#fname').val()
    $.get fname, (data, xhr) =>
      @rawSrt = parseSrt data
      @transform 1.0, 0.0
      console.log @srt.events
      console.log "duration: #{@srt.duration/60} minutes"

  play: ->
    console.log 'play'

    if @state == 'stopped'
      @startTs = now()

    @state = 'playing'
    @tick()

  pause: ->
    console.log 'pause'
    @state = 'paused'
    window.clearTimeout @clockHandle

  stop: ->
    console.log 'stop'
    @pause()
    @reset()
    @state = 'stopped'

  constructor: ->
    @rawSrt = null
    @srt = null
    @startTs = null
    @clockHandle = null
    @state = 'stopped'

    for fname in window.SRTS
      $('#fname').append(
        $('<option>').attr('value', fname).text(fname)
      )

    $('#load').click => @load()
    $('#play').click => @play()
    $('#pause').click => @pause()
    $('#stop').click => @stop()

$ -> new Application()
