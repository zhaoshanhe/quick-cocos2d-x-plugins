
local SDKNdCom = {}

local SDK_GLOBAL_NAME = "api.SDKNdCom"
local SDK_CLASS_NAME = "SDKNdCom"

local sdk = __FRAMEWORK_GLOBALS__[SDK_GLOBAL_NAME]

local function onEnterPlatform()
    CCDirector:sharedDirector():pause()
end

local function onLeavePlatform()
    CCDirector:sharedDirector():resume()
end

--[[--

初始化

初始化完成后，可以使用：

    SDKNdCom.addCallback() 添加回调处理函数

支持的事件包括：

-   SDKNDCOM_LEAVE_PLATFORM 用户离开 91 平台
-   SDKNDCOM_GUEST_LOGINED 以游客身份登录
-   SDKNDCOM_GUEST_REGISTERED 游客转为正式用户成功
-   SDKNDCOM_LOGINED 正常登录
-   SDKNDCOM_NOT_LOGINED 登录失败
-   SDKNDCOM_HAS_ASSOCIATE 设备上有关联的 91 账号，不能以游客方式登录
-   SDKNDCOM_UNKNOWN_LOGIN_ERROR 未知登录错误
-   SDKNDCOM_INVALID_APPID_OR_APPKEY 无效的 appId 或 appKey
-   SDKNDCOM_INVALID_APPID 无效的 appId
-   SDKNDCOM_SESSION_INVALID session 失效

]]
function SDKNdCom.init()
    if sdk then return end

    local sdk_ = {callbacks = {}}
    sdk = sdk_
    __FRAMEWORK_GLOBALS__[SDK_GLOBAL_NAME] = sdk

    local function callback(event)
        echoInfo("## SDKNdCom CALLBACK, event %s", tostring(event))

        for name, callback in pairs(sdk.callbacks) do
            callback(event)
        end
        onLeavePlatform()
    end

    luaoc.callStaticMethod(SDK_CLASS_NAME, "registerScriptHandler", {listener = callback})
end

--[[--

清理

]]
function SDKNdCom.cleanup()
    sdk.callbacks = {}
    luaoc.callStaticMethod(SDK_CLASS_NAME, "unregisterScriptHandler")
end

--[[--

添加指定名称回调处理函数

用法:

    local function callback(event)
        print(event)
    end

    -- 回调函数名称用于区分不同场合使用的回调函数，removeCallback() 也需要使用同样的名称才能移除回调函数
    SDKNdCom.addCallback("mycallback", callback)

]]
function SDKNdCom.addCallback(name, callback)
    sdk.callbacks[name] = callback
end

--[[--

删除指定名称的回调函数

]]
function SDKNdCom.removeCallback(name)
    sdk.callbacks[name] = nil
end

--[[--

普通登录

]]
function SDKNdCom.login()
    return luaoc.callStaticMethod(SDK_CLASS_NAME, "login")
end

--[[--

登录(支持游客登录)

]]
function SDKNdCom.loginEx()
    return luaoc.callStaticMethod(SDK_CLASS_NAME, "loginEx")
end

--[[--

注销

]]
function SDKNdCom.logout(cleanAutoLogin)
    if cleanAutoLogin then
        cleanAutoLogin = 1
    else
        cleanAutoLogin = 0
    end
    return luaoc.callStaticMethod(SDK_CLASS_NAME, "logout", {clean = cleanAutoLogin})
end

--[[--

游客账户转正式账户

]]
function SDKNdCom.guestRegister()
    return luaoc.callStaticMethod(SDK_CLASS_NAME, "guestRegister")
end

--[[--

判断用户登录状态

]]
function SDKNdCom.isLogined()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "isLogined")
    assert(ok, format("SDKNdCom.isLogined() - call API failure, error code: %s", tostring(ret)))
    return ret
end

--[[--

判断用户登录状态

返回三种值：

-   SDKNDCOM_NOT_LOGINED 未登录
-   SDKNDCOM_GUEST_LOGINED 游客登录
-   SDKNDCOM_LOGINED 正常登录

]]
function SDKNdCom.getCurrentLoginState()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "getCurrentLoginState")
    assert(ok, format("SDKNdCom.getCurrentLoginState() - call API failure, error code: %s", tostring(ret)))
    if ret == 0 then
        return "SDKNDCOM_NOT_LOGINED"
    elseif ret == 1 then
        return "SDKNDCOM_GUEST_LOGINED"
    else
        return "SDKNDCOM_LOGINED"
    end
end

--[[--

获得已登录用户的信息

返回值是一个表格，包括：

-   uin
-   sessionId
-   nickname 可能为空
-   headCheckSum 头像图片的校验值

]]
function SDKNdCom.getUserinfo()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "getUserinfo")
    assert(ok, format("SDKNdCom.getUserinfo() - call API failure, error code: %s", tostring(ret)))
    return ret
end

--[[--

切换账户

]]
function SDKNdCom.switchAccount()
    onEnterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "switchAccount")
    if not ok then onLeavePlatform() end
    assert(ok, format("SDKNdCom.switchAccount() - call API failure, error code: %s", tostring(ret)))
end

--[[--

切换账户，进入账号管理列表

]]
function SDKNdCom.enterAccountManager()
    onEnterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "enterAccountManager")
    if not ok then onLeavePlatform() end
    assert(ok, format("SDKNdCom.enterAccountManager() - call API failure, error code: %s", tostring(ret)))
end

--[[--

用户反馈

]]
function SDKNdCom.userFeedback()
    onEnterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "userFeedback")
    if not ok then onLeavePlatform() end
    assert(ok, format("SDKNdCom.userFeedback() - call API failure, error code: %s", tostring(ret)))
    return ret
end

--[[--

进入平台中心

]]
function SDKNdCom.enterPlatform()
    onEnterPlatform()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "enterPlatform")
    if not ok then onLeavePlatform() end
    assert(ok, format("SDKNdCom.enterPlatform() - call API failure, error code: %s", tostring(ret)))
end

--[[--

代币充值

参数：

-   coins 要充值多少代币，例如 1000 表示需要充值 1000 金币；如果 coins 不提供或为 0，表示不限制充值数量

调用后返回一个数组，包含：

-   orderId 订单 Id，用于发送到服务器进行验证
-   error 错误代码，为 0 表示没有发生错误

]]
function SDKNdCom.payForCoins(coins)
    onEnterPlatform()
    local args = {coins = toint(coins)}
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "payForCoins", args)
    if not ok then onLeavePlatform() end
    assert(ok, format("SDKNdCom.payForCoins() - call API failure, error code: %s", tostring(ret)))
    return ret
end

function SDKNdCom.getAvatar(uin, callback, imageType, checksum)
    assert(type(uin) == "string", format("SDKNdCom.getAvatar() - invalid uin %s", tostring(uin)))
    assert(type(callback) == "function", "SDKNdCom.getAvatar() - invalid callback")
    if not imageType then imageType = "middle" end
    local args = {uin = uin, type = imageType, checksum = checksum, callback = callback}
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "getAvatar", args)
    assert(ok, format("SDKNdCom.getAvatar() - call API failure, error code: %s", tostring(ret)))
end

function SDKNdCom.share(message, image)
    onEnterPlatform()
    assert(type(message) == "string", format("SDKNdCom.share() - invalid message %s", tostring(message)))
    local args = {message = message, image = image}
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "share", args)
    if not ok then onLeavePlatform() end
    assert(ok, format("SDKNdCom.share() - call API failure, error code: %s", tostring(ret)))
end

function SDKNdCom.localNotification(message, delay)
    assert(type(message) == "string", format("SDKNdCom.localNotification() - invalid message %s", tostring(message)))
    assert(type(delay) == "number" and delay > 0, format("SDKNdCom.localNotification() - invalid delay %s", tostring(delay)))
    local args = {message = message, delay = delay}
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "localNotification", args)
    assert(ok, format("SDKNdCom.localNotification() - call API failure, error code: %s", tostring(ret)))
end

function SDKNdCom.cleanLocalNotification()
    local ok, ret = luaoc.callStaticMethod(SDK_CLASS_NAME, "cleanLocalNotification", args)
    assert(ok, format("SDKNdCom.cleanLocalNotification() - call API failure, error code: %s", tostring(ret)))
end

return SDKNdCom
