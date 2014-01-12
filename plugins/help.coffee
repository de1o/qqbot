HELP_INFO = """
    version/about   #版本信息和关于
    plugins         #查看载入的插件
    time            #显示时间
    echo 爱你        #重复后面的话
    help            #本内容
    uptime          #服务运行时间
"""

Log = require 'log'
log = new Log('debug')

fs = require 'fs'
Path = require 'path'
file_path = Path.join __dirname, "..", "package.json"
bundle = JSON.parse( fs.readFileSync file_path )

VERSION_INFO = """
    v#{bundle.version} qqbot
    http://github.com/xhan/qqbot
    本工具还由 糗事百科 热血赞助！
"""

# 毫秒亲
start_at = new Date().getTime()
###
 @param content 消息内容
 @param send(content)  回复消息
 @param robot qqbot instance
 @param message 原消息对象
###

# 问题：方式不优雅，应该是一个模式识别成功，别的就不应调用到
module.exports = (content ,send, robot, message)->

    if content.match /^help$/i
        send HELP_INFO

    if content.match /^VERSION|ABOUT$/i
      send VERSION_INFO

    if content.match /^plugins$/i
        send "插件列表：\n" + robot.dispatcher.plugins.join('\r\n')

    if content.match /^time$/i
        send "神奇海螺为您报时" + new Date()

    if content.match /roll/
        rd = Math.floor(Math.random()*100+1)
        if rd == 100
            eggs = "，恭喜爹"
        else if rd == 42
            eggs = "，您得到了宇宙一切问题的终极答案！"
        else
            eggs = ""
        send message.user_card.card + "掷出了" + rd + eggs

    ret = content.match /^echo (.*)/i
    if ret
        send ret[1]

    ret = content.match /^叫(.*)/i
    if ret
        send ret[1]

    ret = content.match /^有问题$/i
    if ret
        send "hailuo.jpg"

    if content.match /^uptime$/i
      secs = (new Date().getTime() - start_at) / 1000
      aday  = 86400 
      ahour = 3600
      [day,hour,minute,second] = [secs/ aday,secs%aday/ ahour,secs%ahour/ 60,secs%60].map (i)-> parseInt(i)
      send "up #{day} days, #{hour}:#{minute}:#{second}"
