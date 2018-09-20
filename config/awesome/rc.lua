-- vim: fdm=marker

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup").widget

local freedesktop = require("freedesktop")
local fix_textbox = require("./widget/textbox")

-- {{{ AutoRun App
autorunApps =
{
    -- 'compton --config ~/.config/compton/config',
    'fcitx -D -r',
    'gnome-keyring-daemon -s',
    -- 'nm-applet',
    -- 'blueman-applet',
    -- 'xwinwrap -ni -fs -s -st -sp -a -nf -ov -- mpv -wid WID -ao null /usr/share/backgrounds/background.mp4',
}
for app = 1, #autorunApps do
    awful.util.spawn_with_shell(autorunApps[app])
end

-- }}}
awful.titlebars_enabled = false

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init("~/.config/awesome/theme.lua")
-- Changing Notify font size.
naughty.config.defaults['icon_size'] = 80

-- This is used later as the default terminal and editor to run.
terminal = "termite"
editor = "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    awful.layout.suit.tile.top,
    -- awful.layout.suit.tile.bottom,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

mymainmenu = freedesktop.menu.build({
    icon_size = 24,
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
    },
    after = {
        { "Open terminal", terminal, "terminal" },
    }
})

-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock(" %Y年%m月%d日 %H:%M:%S %A ", 1)

-- {{{ my widget
-- -- {{{ light function
-- function change_light(change)
--     --local max = tonumber(io.open('/sys/class/backlight/intel_backlight/max_brightness'):read())
--     local current =  tonumber(io.open('xrandr'):read())
--     --local step = max/10
--     local step = 85
--     if change == 1 then
--         if current+step > max then
--             current = max
--         else
--             current = current + step
--         end
--     else
--         if current-step < 0 then
--             current = 0
--         else
--             current = current - step
--         end
--     end
--     awful.util.spawn_with_shell('echo ' .. current .. '| sudo tee /sys/class/backlight/intel_backlight/brightness')
-- end
-- }}}
-- {{{ mailwatch indicator
function mailwidget_update()
    if mail_watch_time ~= nil then
        return
    end
    mailwidget.image = '/usr/share/icons/Adwaita/scalable/actions/mail-send-receive-symbolic.svg'
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
            mailwidget.image = '/usr/share/icons/Adwaita/scalable/actions/mail-mark-important-symbolic.svg'
            f:close()
            return
        end
        if new_mail_count > 0 then
            naughty.notify({
                title = '邮件监视器',
                text = '你有 ' .. new_mail_count .. ' 封新邮件\n来自 ' .. f:read(),
            })
            mailwidget.image = '/usr/share/icons/Adwaita/48x48/status/mail-unread.png'
            f:close()
            return
        end
        mailwidget.image = '/usr/share/icons/Adwaita/scalable/status/mail-unread-symbolic.svg'
    end)
    mail_watch_time:start()
end
mailwidget = wibox.widget.imagebox()
mailwidget.forced_height = 24
mailwidget.forced_width = 24
mailwidget:buttons(awful.util.table.join(
    awful.button({ }, 3, function () mailwidget_update() end),
    awful.button({ }, 1, function () awful.util.spawn('termite -e mutt') end)
))
mailwidget_update()
mailtimer = timer({ timeout = 60 * 10 })
mailtimer:connect_signal("timeout", function () mailwidget_update() end)
mailtimer:start()
-- }}}
-- {{{ network speed indicator
function update_netstat()
    local interval = netwidget_clock.timeout
    local netif, text
    for line in io.lines('/proc/net/route') do
        netif = line:match('^(%w+)%s+00000000%s')
        if netif then
            break
        end
    end

    if netif then
        local down, up
        for line in io.lines('/proc/net/dev') do
            -- Match wmaster0 as well as rt0 (multiple leading spaces)
            local name, recv, send = string.match(line, "^%s*(%w+):%s+(%d+)%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+)")
            if name == netif then
                if netdata[name] == nil then
                    -- Default values on the first run
                    netdata[name] = {}
                    down, up = 0, 0
                else
                    down = (recv - netdata[name][1]) / interval
                    up   = (send - netdata[name][2]) / interval
                end
                netdata[name][1] = recv
                netdata[name][2] = send
                break
            end
        end
        text = ' 🔻<span color="#c2ba62">'.. format_width(down) ..'</span> 🔺<span color="#5798d9">'.. format_width(up) ..'</span>'
    else
        netdata = {} -- clear as the interface may have been reset
        text = '(No network)'
    end
    netwidget:set_markup(text .. " ")
end
function format_width(num)
    speed = num / 1024
    if speed > 99 then
        return string.format('%4dKb', math.floor(speed))
    else
        return string.format('%4.1fKb', speed)
    end
end
netdata = {}
netwidget = fix_textbox('(net)')
netwidget_clock = timer({ timeout = 1 })
netwidget_clock:connect_signal("timeout", update_netstat)
netwidget_clock:start()
update_netstat()
-- }}}
-- {{{ memory usage indicator
function get_memory_usage()
    local ret = {}
    for l in io.lines('/proc/meminfo') do
        local k, v = l:match("([^:]+):%s+(%d+)")
        ret[k] = tonumber(v)
    end
    return ret
end
function update_memwidget()
    local meminfo = get_memory_usage()
    local free = meminfo.MemAvailable
    local total = meminfo.MemTotal
    local percent = 100 - math.floor(free / total * 100 + 0.5)
    memwidget:set_markup(' MEM <span color="#90ee90">'.. string.format("%2d", percent) ..'%</span>')
end
memwidget = fix_textbox(' MEM ??')
update_memwidget()
mem_clock = timer({ timeout = 5 })
mem_clock:connect_signal("timeout", update_memwidget)
mem_clock:start()
-- }}}
-- {{{ CPU Temperature
function update_cputemp()
    local pipe = io.popen('sensors')
    if not pipe then
        cputempwidget:set_markup('CPU <span color="red">ERR</span>℃')
        return
    end
    local temp = 0
    for line in pipe:lines() do
        local newtemp = line:match('^temp3:%s+%+([0-9.]+)°C')
        if newtemp then
            newtemp = tonumber(newtemp)
            if temp == 0 then
                temp = newtemp
            end
        end
    end
    pipe:close()
    cputempwidget:set_markup(' CPU <span color="#008000">'..temp..'</span>℃')
end
cputempwidget = fix_textbox(' CPU ??℃')
update_cputemp()
cputemp_clock = timer({ timeout = 2 })
cputemp_clock:connect_signal("timeout", update_cputemp)
cputemp_clock:start()
-- }}}
-- {{{ Volume Controller
function volumectl (mode, widget)
    if mode == "update" then
        local f = io.popen("pamixer --get-volume")
        local volume = f:read("*all")
        f:close()
        if not tonumber(volume) then
            widget:set_markup("<span color='red'>ERR</span>")
            do return end
        end
        volume = string.format("% 3d", volume)

        f = io.popen("pamixer --get-mute")
        local muted = f:read("*all")
        f:close()
        if muted:gsub('%s+', '') == "false" then
            if notify_is_mute then
                volume = ' 🎵' .. volume .. '<span color="green">M</span>'
            else
                volume = ' 🎵' .. volume .. '%'
            end
        else
            volume = ' 🎵' .. volume .. '<span color="red">M</span>'
        end
        widget:set_markup(volume .. " ")
    elseif mode == "up" then
        local f = io.popen("pamixer --allow-boost --increase 5")
        f:read("*all")
        f:close()
        volumectl("update", widget)
    elseif mode == "down" then
        local f = io.popen("pamixer --allow-boost --decrease 5")
        f:read("*all")
        f:close()
        volumectl("update", widget)
    else
        local f = io.popen("pamixer --toggle-mute")
        f:read("*all")
        f:close()
        volumectl("update", widget)
    end
end
volume_clock = timer({ timeout = 10 })
volume_clock:connect_signal("timeout", function () volumectl("update", volumewidget) end)
volume_clock:start()

volumewidget = fix_textbox('(volume)')
volumewidget:buttons(awful.util.table.join(
    awful.button({ }, 4, function () volumectl("up", volumewidget) end),
    awful.button({ }, 5, function () volumectl("down", volumewidget) end),
    awful.button({ }, 3, function () awful.util.spawn("pavucontrol") end),
    awful.button({ }, 2, function ()
        notify_is_mute = not notify_is_mute
        volumectl("update", volumewidget)
    end),
    awful.button({ }, 1, function () volumectl("mute", volumewidget) end)
))
volumectl("update", volumewidget)

notify_is_mute = false
function naughty.config.notify_callback(args)
    if not notify_is_mute then
        awful.spawn{ "paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"}
    end
    return args
end
--}}}
-- }}}

-- {{{ Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end
-- }}}
-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "编程", "文档", "网络", "聊天", "音乐" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", height = 28, screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            netwidget,
            memwidget,
            cputempwidget,
            batwidget,
            volumewidget,
            wibox.container.margin(mailwidget,0,0,3,3),
--            mykeyboardlayout,
            wibox.container.margin(wibox.widget.systray(),3,3,3,3),
            mytextclock,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    -- awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
    --           {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),

    -- {{{ user bindings
    awful.key({modkey}, "s",
        function()
            local c = client.focus
            if c then
                c.sticky = not c.sticky
            end
        end),
    awful.key({}, "Print", function() awful.util.spawn_with_shell("gnome-screenshot -i") end),
    awful.key({modkey}, "Delete", function() awful.util.spawn_with_shell("slock") end),
    awful.key({}, "XF86Display", function() awful.util.spawn_with_shell("arandr") end),
    awful.key({}, "XF86AudioRaiseVolume", function() volumectl("up", volumewidget) end),
    awful.key({}, "XF86AudioLowerVolume", function() volumectl("down", volumewidget) end),
    awful.key({}, "XF86AudioMute", function() volumectl("mute", volumewidget) end)
    -- awful.key({}, "XF86MonBrightnessDown", function() change_light(-1) end),
    -- awful.key({}, "XF86MonBrightnessUp", function() change_light(1) end)
    -- }}}
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gimp",
          "Wine",
          "Minecraft",
          "Steam",
          "Display",
          "Animation",
          "matplotlib",
          },
        name = {
          "Event Tester",  -- xev.
          "Gnuplot",
        },
        role = {
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }
    },

    -- Add titlebars to normal clients and dialogs
    { rule_any = { type = { "dialog" }
      }, properties = { titlebars_enabled = true }
    },
    { rule = { class = "jetbrains-idea"},
        properties = { titlebars_enabled = false }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    { rule = { name = "Steam" },
       properties = { screen = 1, tag = "文档", maximized = true } },
    { rule = { name = "Firefox" },
       properties = { screen = 1, tag = "网络", maximized = true } },
    { rule = { class = "netease-cloud-music" },
        properties = { screen = 1, tag = "音乐" } },
    { rule = { class = "Deadbeef" },
        properties = { screen = 1, tag = "音乐", maximized = true } },
    { rule = { class = "TelegramDesktop" },
        properties = { screen = 1, tag = "聊天", maximized = true } },
    { rule = { name = "WeeChat" },
        properties = { screen = 1, tag = "聊天" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = awful.util.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
