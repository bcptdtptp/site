_ = require './_util'

class ColorSwitch
  splitRGB = (color6Digit) ->
    [0, 2, 4].map (e) -> parseInt(color6Digit[e...e + 2], 16)

  constructor: (option = {}) ->
    @location = document.location
    @sheet = document.createElement 'style'
    @sheet.id = 'colorSheet'
    @mainColor
    @secondaryColor
    @hashtagManager = option.hash
    throw Error 'No hashtag manager' unless @hashtagManager?
    @hashtagManager.onHashChange @checkHashTag
    @checkHashTag @hashtagManager.obj
    @bindSwitch option

  bindSwitch: (option) =>
    document.head.appendChild @sheet
    if option.triggerEvent? && option.triggerElem?
      option.triggerElem.addEventListener option.triggerEvent,
        @randomColor,
        false

  checkHashTag: (hashObj) =>
    if hashObj.color?
      @parseColor hashObj.color
      @updateSheet()

  parseColor: (color) =>
    if color? and color.length?
      wColor = color
      if wColor.length is 3
        wColor = wColor.split('').map((e) -> e + e).join('')
      @mainColor = "##{wColor}"
      @secondaryColor =
        "rgba(#{splitRGB(wColor).join(',')},0.8)"

  randomColor: =>
    colorString = (~~(Math.random() * 0xFFFFFF)).toString(16)
    if colorString.length < 6
      colorString = _.arr(6 - colorString.length).join('') + colorString
    @hashtagManager.setHash 'color', "#{colorString}"

  updateSheet: =>
    @sheet.innerHTML = """
      *::selection {
        color: #{@mainColor} !important;
      }
      .color {
        color: #{@mainColor} !important;
      }
      .color::before,
      .color::after {
        background-color: #{@mainColor} !important;
      }
      .colorBg {
        background-color: #{@mainColor} !important;
      }
      .colorLight {
        color: #{@secondaryColor} !important;
      }
      .colorLight::before,
      .colorLight::after {
        background-color: #{@secondaryColor} !important;
      }
      .colorHover:hover {
        color: #{@mainColor} !important;
      }
      .colorScroll::-webkit-scrollbar {
        background-color: #{@secondaryColor} !important;
      }
    """
exports = module.exports = ColorSwitch
