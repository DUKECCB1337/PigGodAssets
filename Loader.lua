
-- 1. Get necessary services and player information / 获取必要的服务和玩家信息
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 2. Get the player's language code / 获取玩家的语言代码
-- 使用 player.LocaleId 获取语言代码，这是现代且推荐的方法
-- Use player.LocaleId to get the language code, this is the modern and recommended method
local locale = player.LocaleId

-- 3. Determine if the language is Chinese / 判断语言是否为中文
-- Use string.find to match all Chinese language variants (e.g., zh-cn, zh-tw, etc.)
-- 使用 string.find 来匹配所有中文语言变体 (如 zh-cn, zh-tw 等)
local isChinese = false
if string.find(locale, "zh") then
    isChinese = true
    print("Chinese language detected (" .. locale .. ") / 检测到中文语言 (" .. locale .. ")")
else
    print("Chinese not detected (" .. locale .. "), defaulting to other language. / 未检测到中文 (" .. locale .. ")，默认为其他语言。")
end

-- 4. Load the appropriate script based on language detection / 根据语言检测加载相应的脚本
if isChinese then
    -- 如果是中文，加载中文脚本
    -- If it's Chinese, load Chinese script
    print("正在加载中文脚本... / Loading Chinese script...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/DUKECCB1337/PigGodAssets/main/ChenfengHu-zh.lua"))()
else
    -- 如果不是中文，加载英文脚本
    -- If it's not Chinese, load English script
    print("正在加载英文脚本... / Loading English script...")
    loadstring(game:HttpGet("https://raw.githubusercontent.com/DUKECCB1337/PigGodAssets/main/ChenfengHu-en.lua"))()
end