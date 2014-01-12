client = require '../src/httpclient.coffee'

opts = [
        {name: "from", value: "control"}
        {name: "f", value: "EQQ.Model.ChatMsg.callbackSendPicGroup"}
        {name: "vfwebqq", value: "vfwebqqtest"}
        {name: "custom_face", filename: "group_upload.jpg", "Content-Type": "image/jpeg", value: "/Users/Sai/Pictures/0.jpeg"} # TODO这个value待获取
        {name: "fileid", value: 8}
    ]

result = client.format_multipart_data opts
console.log result.length