-- 引入 ThingsCloud 接入库
-- 接入协议参考：ThingsCloud MQTT 接入文档 https://docs.thingscloud.xyz/guide/connect-device/mqtt.html
local ThingsCloud = require "ThingsCloud"

-- 进入 ThingsCloud 控制台：https://www.thingscloud.xyz
-- 创建设备，进入设备详情页的【连接】页面，复制设备证书和MQTT接入点地址。请勿泄露你的设备证书。
-- ProjectKey
local projectKey = ""
-- AccessToken
local accessToken = ""
-- MQTT 接入点，只需主机名部分
local host = ""

-- UART 初始化，用于和主控MCU通信，使用JSON格式
local UART_ID = 1
uart.setup(UART_ID, -- 串口id
115200, -- 波特率
8, -- 数据位
1 -- 停止位
)

uart.on(UART_ID, "receive", function(id, len)
    local data = ""
    repeat
        -- 如果是air302, len不可信, 传1024
        -- data = uart.read(id, 1024)
        data = uart.read(id, len)
        if #data > 0 then
            log.info("uart", "receive", id, #data, data)
            -- 将串口收到的 JSON 数据，作为属性上报到云平台。注意 data 必须是 JSON 格式文本。
            ThingsCloud.publish("attributes", data)
        end
    until data == ""
end)


-- 设备成功连接云平台后，触发该函数
local function onConnect(result)
    if result then
        -- 当设备连接成功后

        -- 例如：切换设备的LED闪烁模式，提示用户设备已正常连接。

    end
end

-- 设备接收到云平台下发的属性时，触发该函数
local function onAttributesPush(attributes)
    log.info("recv attributes push", json.encode(attributes))

    -- 将云平台下发的属性 JSON，发送到串口
    uart.write(UART_ID, json.encode(attributes))
end

-- 设备接入云平台的初始化逻辑，在独立协程中完成
sys.taskInit(function()
    -- 连接云平台，内部支持判断网络可用性、MQTT自动重连
    -- 这里采用了设备一机一密方式，需要为每个设备固件单独写入证书。另外也支持一型一密，相同设备类型下的所有设备使用相同固件。
    ThingsCloud.connect({
        host = host,
        projectKey = projectKey,
        accessToken = accessToken
    })

    -- 注册各类事件的回调函数，在回调函数中编写所需的硬件端操作逻辑
    ThingsCloud.on("connect", onConnect)
    ThingsCloud.on("attributes_push", onAttributesPush)

end)
