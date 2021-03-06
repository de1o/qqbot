https = require "https"
http  = require 'http'
querystring  = require 'querystring'
URL  = require('url')
jsons = JSON.stringify
fs = require 'fs'
request = require 'request'
streams = require 'memory-streams'
path = require 'path'
im = require "imagemagick"
gm = require "gm"

# 剥离出来的 HttpClient ，目前仅适合 qqapi 使用
# 返回值：已经解析的json


# 设置全局cookie
all_cookies = []
global_cookies = (cookie)->
    all_cookies = cookie if cookie
    return all_cookies

mboundary = "------WebKitFormBoundaryqBJ7wdNDl8BgnBFD"

format_multipart_data = (options, picdata) ->
    fs.writeFileSync("./thispic.jpg", picdata)
    rstring = ""
    for item in options
        rstring += mboundary + "\r\n"
        rstring += "Content-Disposition: form-data; "
        rstring += "name=\""
        rstring += (item["name"] + "\"")
        if item["name"] == "custom_face"
            rstring += "; filename=\""
            rstring += (item["filename"] + "\"")

        rstring += "\r\n"
        if item["name"] == "custom_face"
            rstring += "Content-Type: "
            rstring += item["Content-Type"]
            rstring += "\r\n"
            rstring += "\r\n"
            rstring += "FILEDATA"
        else
            rstring += "\r\n"
            rstring += (item["value"] + "\r\n")

    rstring += (mboundary + "--")
    parts = rstring.split "FILEDATA"
    parts0 = new Buffer parts[0]
    parts1 = new Buffer parts[1]
    imgdata = new Buffer picdata, 'binary'
    console.log "before concat"
    multipartBody = Buffer.concat [parts0, imgdata, parts1]
    console.log "after concat"
    multipartBody

downloadpic = (uri, callback) ->
    request.head uri, (err, resp, body) =>
        console.log('content-type:', resp.headers['content-type']);
        console.log('content-length:', resp.headers['content-length']);
        filename = Date.now() + path.basename(uri)
        console.log "start pipe"
        r = request(uri).pipe fs.createWriteStream(filename)
        r.on 'close', () =>
            console.log("fs closed")
            gm(filename).quality(10)
            .write filename, (err) =>
                console.log "#{resp.headers['content-type']} #{filename} done" if !err
                if resp.headers['content-type'] != "image/jpeg"
                    im.convert [filename, filename+".jpg"], (err, stdout) =>
                        throw err if err
                        console.log "converted to jpg"
                        callback uri, filename
                else
                    callback uri, filename



http_request = (options , params , picdata, callback) ->
    aurl = URL.parse( options.url )
    options.host = aurl.host
    options.path = aurl.path
    options.headers ||= {}
    client =  if aurl.protocol == 'https:' then https else http

    body = ''
    if params and options.method == 'POST'
        if picdata
            data = format_multipart_data params, picdata
            options.headers['Content-Type'] = 'multipart/form-data; boundary=----WebKitFormBoundaryqBJ7wdNDl8BgnBFD'
            options.headers['Content-Length'] = data.length
        else    
            data = querystring.stringify params
            options.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
            options.headers['Content-Length'] = Buffer.byteLength(data)

    options.headers['Cookie'] = all_cookies
    options.headers['Referer'] = 'http://d.web2.qq.com/proxy.html?v=20110331002&callback=1&id=3'

    req = client.request options, (resp) ->
        # log "response: #{resp.statusCode}"
        resp.on 'data', (chunk) ->
            body += chunk
        resp.on 'end', ->
            handle_resp_body(body, callback)
    req.on "error" , (e)->
        callback(null,e)

    if params and options.method == 'POST'
        req.write(data)
    req.end();

handle_resp_body = (body , callback) ->
    err = null
    try
        ret = JSON.parse body
    catch error
        try
            i = body.indexOf 'callbackSendPicGroup('
            leftbody = body[i+'callbackSendPicGroup('.length..]
            jsonbody = leftbody[0..leftbody.indexOf "})"]
            i = jsonbody.indexOf("msg':'")
            leftbody = jsonbody[(i+"msg':'".length)..]
            ret = leftbody[0..((leftbody.indexOf "jPg")+2)]
        catch error
            console.log "解析出错",body
            console.log error
            err = error
            ret = null
    callback(ret,err)


http_get  = (options , callback) ->
    options.method = 'GET'
    http_request( options , null , null, callback)

http_post = (options , body, callback) ->
    options.method = 'POST'
    http_request( options , body , null, callback)

http_multip_post = (options, body, callback) ->
    options.method = 'POST'
    picurl = ""
    for item in body
        if item.name == "custom_face"
            picurl = item.value
            item.value = "upload.jpg"
    console.log "picurl", picurl
    if picurl.match "^http"
        console.log "fetch http pic"
        downloadpic picurl, (url, filename) =>
            picdata = fs.readFileSync filename
            http_request( options , body , picdata, callback)
            fs.unlinkSync(filename)
    else
        http_request( options , body , null, callback)


# 导出方法
module.exports =
    global_cookies: global_cookies
    request: http_request
    get:     http_get
    post:    http_post
    mpost:   http_multip_post
    format_multipart_data: format_multipart_data    
