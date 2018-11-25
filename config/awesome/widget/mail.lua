local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")

local function mail_widget_update()
    if mail_watch_time ~= nil then
        return
    end
    mail_widget.image = '/usr/share/icons/Adwaita/scalable/actions/mail-send-receive-symbolic.svg'
    awful.util.spawn('fetch_mail.py')
    mail_watch_time = timer({ timeout = 1 })
    mail_watch_time:connect_signal("timeout", function ()
        local f = io.open('/tmp/fetch_mail_count', 'r')
        local new_mail_count = tonumber(f:read())
        if new_mail_count == -1 then
            f:close()
            return
        end
        mail_watch_time:stop()
        mail_watch_time = nil
        if new_mail_count == -2 then
            naughty.notify({
                title = '邮件监视器',
                text = f:read(),
            })
            mail_widget.image = '/usr/share/icons/Adwaita/scalable/actions/mail-mark-important-symbolic.svg'
            f:close()
            return
        end
        if new_mail_count > 0 then
            naughty.notify({
                title = '邮件监视器',
                text = '你有 ' .. new_mail_count .. ' 封新邮件\n来自 ' .. f:read(),
            })
            mail_widget.image = '/usr/share/icons/Adwaita/48x48/status/mail-unread.png'
            f:close()
            return
        end
        mail_widget.image = '/usr/share/icons/Adwaita/scalable/status/mail-unread-symbolic.svg'
    end)
    mail_watch_time:start()
end
mail_widget = wibox.widget.imagebox()
mail_widget.forced_height = 24
mail_widget.forced_width = 24
mail_widget:buttons(awful.util.table.join(
    awful.button({ }, 3, function () mail_widget_update() end),
    awful.button({ }, 1, function () awful.util.spawn('termite -e mutt') end)
))
mail_widget_update()
mailtimer = timer({ timeout = 60 * 10 })
mailtimer:connect_signal("timeout", function () mail_widget_update() end)
mailtimer:start()

return mail_widget