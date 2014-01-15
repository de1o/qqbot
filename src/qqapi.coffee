###
  QQAPI 包含获取好友，群信息，发送消息，长轮询
  - 使用前需要设置 cookies()
###



all_cookies = []
fs = require 'fs'
jsons = JSON.stringify
client = require './httpclient'
log   = new (require 'log')('debug')

exports.cookies = (cookie)->
    if cookie
        all_cookies = cookie
        client.global_cookies(all_cookies)
    return all_cookies


# 长轮训，默认一分钟
#  @param : [clientid,psessionid]
#  @param callback: ret, e
#  @return ret retcode 102，正常空消息
long_poll = (auth_opts, callback) ->
    log.debug "polling..."
    [clientid, psessionid] = [auth_opts.clientid, auth_opts.psessionid]
    url = "http://d.web2.qq.com/channel/poll2"
    r =
        clientid: "#{clientid}"
        psessionid: psessionid
        key:0
        ids:[]
    params =
        clientid: clientid
        psessionid: psessionid
        r: jsons r

    client.post {url:url} , params , (ret,e)->
        long_poll( auth_opts , callback )
        callback(ret,e)

exports.long_poll = long_poll

# http://0.web.qstatic.com/webqqpic/pubapps/0/50/eqq.all.js
# uin, ptwebqq
hash_func =
`
function(b, i) {
                for (var a = [], s = 0; s < i.length; s++) a[s % 4] ^= i.charCodeAt(s);
                var j = ["EC", "OK"],
                    d = [];
                d[0] = b >> 24 & 255 ^ j[0].charCodeAt(0);
                d[1] = b >> 16 & 255 ^ j[0].charCodeAt(1);
                d[2] = b >> 8 & 255 ^ j[1].charCodeAt(0);
                d[3] = b & 255 ^ j[1].charCodeAt(1);
                j = [];
                for (s = 0; s < 8; s++) j[s] = s % 2 == 0 ? a[s >> 1] : d[s >> 1];
                a = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
                d = "";
                for (s = 0; s < j.length; s++) d += a[j[s] >> 4 & 15], d += a[j[s] & 15];
                return d
}
`


#  @param uin     : 登录后获得
#  @param ptwebqq : cookie
#  @param vfwebqq : 登录后获得
#  @param callback: ret, e
#  retcode 0
exports.get_buddy_list = (auth_opts, callback)->
    opt = auth_opts
    url = "http://s.web2.qq.com/api/get_user_friends2"
    r =
      h: "hello"
      hash: hash_func(opt.uin, opt.ptwebqq)
      vfwebqq: opt.vfwebqq

    client.post {url:url} , {r:jsons(r)} , (ret,e )->
        callback(ret,e)


#  @param auth_opts vfwebqq : 登录后获得
#  @param callback: ret, e
#  retcode 0
exports.get_group_list = ( auth_opts, callback)->
    aurl = "http://s.web2.qq.com/api/get_group_name_list_mask2"
    r    = vfwebqq:  auth_opts.vfwebqq

    client.post {url:aurl} , {r:jsons(r)} , (ret, e )->
            callback(ret,e)


#  @param group_code: code
#  @param auth_opts vfwebqq : 登录后获得
#  @param callback: ret, e
#  retcode 0
exports.get_group_member = (group_code, auth_opts, callback)->
    url = "http://s.web2.qq.com/api/get_group_info_ext2"
    url += "?gcode=#{group_code}&cb=undefined&vfwebqq=#{auth_opts.vfwebqq}&t=#{new Date().getTime()}"
    client.get {url:url}, (ret,e)->
        callback(ret,e)


#  @param to_uin: uin
#  @param msg, 消息
#  @param auth_opts: [clientid,psessionid]
#  @param callback: ret, e
#  @return ret retcode 0
exports.send_msg_2buddy = (to_uin , msg , auth_opts ,callback)->
    url = "http://d.web2.qq.com/channel/send_buddy_msg2"
    opt = auth_opts
    r =
      to: to_uin
      face: 0
      msg_id: parseInt Math.random()*100000 + 1000
      clientid: "#{opt.clientid}"
      psessionid: opt.psessionid
      content: jsons ["#{msg}" , ["font", {name:"宋体", size:"10", style:[0,0,0], color:"000000" }] ]

    params =
        r: jsons r
        clientid: opt.clientid
        psessionid: opt.psessionid

    # log params
    client.post {url:url} , params , (ret,e) ->
        log.debug 'send2user',jsons ret
        callback( ret , e )



exports.upload_img_2group = (picurl, auth_opts, callback)->
    url = "http://up.web2.qq.com/cgi-bin/cface_upload?time=" + Date.now().toString()
    params = [
        {name: "from", value: "control"}
        {name: "f", value: "EQQ.Model.ChatMsg.callbackSendPicGroup"}
        {name: "vfwebqq", value: auth_opts.vfwebqq}
        {name: "custom_face", filename: "group_upload.png", "Content-Type": "image/png", value: picurl}
        {name: "fileid", value: 8}
    ]
    log.debug "sending upload request"
    client.mpost {url:url}, params, (tmpImg, e) =>
        log.debug "upload img 2 group", tmpImg
        callback(tmpImg, e)


exports.send_tmpimg_2group = (tmpImg, gid, gcode, auth_opts, callback)->
    url = "http://d.web2.qq.com/channel/send_qun_msg2"
    opt = auth_opts
    r = 
        group_uin: gid
        group_code: gcode
        key: "m357cqr9m3Q6cSDT"
        sig: "e6c60ad563e63c60408cf2718b577a371957c00710909ad7a12178273420813cdacb1eef39b7ca5c4f3387bfa00405bf435db1799395d4e7"
        content: "[[\"cface\",\"group\",\"#{tmpImg}\"],\"\",\"\",[\"font\",{\"name\":\"微软雅黑\",\"size\":\"10\",\"style\":[0,0,0],\"color\":\"666699\"}]]"
        clientid: opt.clientid
        psessionid: opt.psessionid

    params = 
        r: jsons r
        clientid: opt.clientid
        psessionid: opt.psessionid
    
    log.debug "sending image..."
    client.post {url: url}, params, (ret, e)->
        log.debug "send_tmpimg_2group", jsons ret
        callback(ret, e)

#  @param gid: gid
#  @param msg, 消息
#  @param auth_opts: [clientid,psessionid]
#  @param callback: ret, e
#  @return ret retcode 0
exports.send_msg_2group = (gid, msg , auth_opts, callback)->
    url = 'http://d.web2.qq.com/channel/send_qun_msg2'
    opt = auth_opts
    r =
      group_uin:  gid
      msg_id:     parseInt Math.random()*100000 + 1000
      clientid:   "#{opt.clientid}"
      psessionid: opt.psessionid
      content:    jsons ["#{msg}" , ["font", {name:"宋体", size:"10", style:[0,0,0], color:"000000" }] ]
    params =
        r:         jsons r
        clientid:  opt.clientid
        psessionid:opt.psessionid
    client.post {url:url} , params , (ret,e)->
        log.debug 'send2group',jsons ret
        callback(ret,e)
