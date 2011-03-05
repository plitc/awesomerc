 -- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Widget and layout library
require("wibox")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Widget library
require("vicious")
require("wibox.widget.textbox")
-- Load Debian menu entries
require("debian.menu")
-- Load freedesktop menu
require('freedesktop.utils')
require('freedesktop.menu')
-- utils Library
require("uzful")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init(awful.util.getdir("config") .. "/theme.lua")
uzful.notifications.patch()
uzful.util.patch.vicious()

-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

freedesktop.utils.terminal = terminal
freedesktop.utils.icon_theme = 'default.kde4'

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
names = {"☼", "✪", "⌥", "✇", "⌤", "⍜", "⌬", "♾", "⌘" }
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag(names, s, layouts[10])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu

detailed_graphs = uzful.menu.toggle_widgets()

local menu_graph_text = function ()
    return (detailed_graphs.visible() and "disable" or "enable") .. " graphs"
end

myfreedesktopmenu = freedesktop.menu.new()
myawesomemenu = {
   { menu_graph_text(), function (m)
        detailed_graphs.toggle()
        m.label:set_text(menu_graph_text())
     end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit },
}

mymainmenu = uzful.menu({
    { "awesome", myawesomemenu, beautiful.awesome_icon },
    { "Menu", myfreedesktopmenu, freedesktop.utils.lookup_icon({ icon = 'kde' }) },
    { "Debian", debian.menu.Debian_menu.Debian, freedesktop.utils.lookup_icon({ icon = 'debian-logo' }) },
    { "open terminal", terminal, freedesktop.utils.lookup_icon({ icon = 'terminal' }) },
                        })

-- mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
--                                      menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock('<span size="x-small"> %H:%M </span>')
mycal = uzful.widget.calendar({
    all = '<span size="small">$1</span>',
    head = '<span color="#666666">$1</span>',
    week = '<span color="#999999">$1</span>',
    day  = '<span color="#BBBBBB">$1</span>',
    number  = '<span color="#EEEEEE">$1</span>',
    current = '<span color="green">$1</span>',
})

mytextclock:buttons(awful.util.table.join(
    awful.button({         }, 1, function()  mycal:switch_month(-1)  end),
    awful.button({         }, 2, function()  mycal:now()             end),
    awful.button({         }, 3, function()  mycal:switch_month( 1)  end),
    awful.button({         }, 4, function()  mycal:switch_month(-1)  end),
    awful.button({         }, 5, function()  mycal:switch_month( 1)  end),
    awful.button({ 'Shift' }, 1, function()  mycal:switch_year(-1)  end),
    awful.button({ 'Shift' }, 2, function()  mycal:now()             end),
    awful.button({ 'Shift' }, 3, function()  mycal:switch_year( 1)  end),
    awful.button({ 'Shift' }, 4, function()  mycal:switch_year(-1)  end),
    awful.button({ 'Shift' }, 5, function()  mycal:switch_year( 1)  end)
))

-- Memory Progressbar
mymem = uzful.widget.progressimage({
    x = 2, y = 2, width = 5, height = 10,
    image = theme.memory, draw_image_first = false })
uzful.widget.set_properties(mymem.progress, {
    vertical = true, background_color = theme.bg_normal,
    border_color = nil, color = "#0173FF" })
--mymem:set_color({ "#001D40", "#535d6c", "#0173FF" })
vicious.register(mymem.progress, vicious.widgets.mem, "$1", 13)

-- Battery Progressbar
mybat = uzful.widget.progressimage(
    { x = 3, y = 4, width = 3, height = 7, image = theme.battery })
uzful.widget.set_properties(mybat.progress, {
    ticks = true, ticks_gap = 1,  ticks_size = 1,
    vertical = true, background_color = theme.bg_normal,
    border_color = nil, color = "#FFFFFF" })
vicious.register(mybat.progress, vicious.widgets.bat, "$2", 45, "BAT0")

myimgbat = uzful.util.listen.vicious("text", function (val)
        if val == "-" then
            mybat.draw_image_first()
        elseif val == "+" or val == "↯" then
            mybat.draw_progress_first()
        end
    end )
vicious.register(myimgbat, vicious.widgets.bat, "$1", 90, "BAT0")

local mynotibat, mycritbat_old_val = nil, nil
mycritbat = uzful.util.threshold(0.2,
    function (val)
        mycritbat_old_val = val
        mybat.progress:set_background_color(theme.bg_normal)
        if mynotibat ~= nil then  naughty.destroy(mynotibat)  end
    end,
    function (val)
        mybat.progress:set_background_color("#8C0000")
        if val < 0.1 and val <= mycritbat_old_val then
            if mynotibat ~= nil then  naughty.destroy(mynotibat)  end
            mynotibat = naughty.notify({
                preset = naughty.config.presets.critical,
                title = "Critical Battery Charge",
                text =  "only " .. (val*100) .. "% remaining."})
        end
        mycritbat_old_val = val
    end)
vicious.register(mycritbat, vicious.widgets.bat, "$2", 90, "BAT0")


-- Battery Text
mybtxt = wibox.widget.textbox()
vicious.register(mybtxt, vicious.widgets.bat,
    '<span size="small">$1$3 $2%</span>', 60, "BAT0")

-- Temperature Text
mytemp = wibox.widget.textbox()
mycrittemp = uzful.util.threshold(0.8,
    function (val)
        mytemp:set_markup('<span color="red" size="small">' ..
            (val*100) .. '°</span>')
    end,
    function (val)
        mytemp:set_markup('<span color="#666666" size="x-small">' ..
            (val*100) .. '°</span>')
    end)
vicious.register(mycrittemp, vicious.widgets.thermal, "$1", 30, "thermal_zone0")

-- net usage graphs

mynetgraphs = uzful.widget.netgraphs({ default = "wlan0",
    up_fgcolor = "#D00003", down_fgcolor = "#95D043",
    highlight = ' <span size="x-small"><b>$1</b></span>',
    normal    = ' <span color="#666666" size="x-small">$1</span>',
    big = { width = 161, height = 42, interval = 2, scale = "kb" },
    small = { width = 23, height = theme.menu_height, interval = 2 } })

mynetgraphs.small.layout:connect_signal("button::release", mynetgraphs.switch)

for _, widget in ipairs(mynetgraphs.big.widgets) do
    table.insert(detailed_graphs.widgets, widgets)
end

-- CPU graphs

mycpugraphs = uzful.widget.cpugraphs({
    fgcolor = "#D0752A", bgcolor = theme.bg_normal,
    load = { interval = 20,
        text = ' <span size="x-small"><span color="#666666">$1</span>' ..
               '  <span color="#9A9A9A">$2</span>' ..
               '  <span color="#DDDDDD">$3</span></span>' },
    big = { width = 161, height = 42, interval = 1 },
    small = { width = 42, height = theme.menu_height, interval = 1 } })

table.insert(detailed_graphs.widgets, mycpugraphs.load)
for _, widget in ipairs(mycpugraphs.big.widgets) do
    table.insert(detailed_graphs.widgets, widgets)
end


mylayoutmenu = uzful.menu.layouts(layouts)

-- Create a wibox for each screen and add it
mywibox = {}
mynotification = {}
myinfobox = { net = {}, cpu = {}, cal = {}, bat = {} }
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 2, function () mylayoutmenu:toggle() end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create a notification manager widget
    mynotification[s] = uzful.notifications(s, {
        max = 605, menu = { theme = { menu_width = 242 } },
        text = '<span size="small">$1</span>' })

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = theme.menu_height })
    myinfobox.net[s] = uzful.widget.infobox({ screen = s,
            position = "top", align = "right",
            widget = mynetgraphs.big.layout,
            height = mynetgraphs.big.height,
            width = mynetgraphs.big.width })
    myinfobox.cpu[s] = uzful.widget.infobox({ screen = s,
            position = "top", align = "right",
            widget = mycpugraphs.big.layout,
            height = mycpugraphs.big.height,
            width = mycpugraphs.big.width })
    myinfobox.cal[s] = uzful.widget.infobox({ screen = s,
            size = function () return mycal.width,mycal.height end,
            position = "top", align = "right",
            widget = mycal.widget })
    myinfobox.bat[s] = uzful.widget.infobox({ screen = s,
            size = function () return mybtxt:fit(-1, -1) end,
            position = "top", align = "right",
            widget = mybtxt })

    local layout = uzful.layout.build({
        layout = wibox.layout.align.horizontal,
        left = { layout = wibox.layout.fixed.horizontal,
            --mylauncher,
            mytaglist[s],
            mypromptbox[s] },
        middle = mytasklist[s],
        right = { layout = wibox.layout.fixed.horizontal,
            function () return s == 1 and wibox.widget.systray() or nil end,
            mynotification[s].text,
            mynetgraphs.small.layout,
            mycpugraphs.small.widget,
            mytemp,
            mytextclock,
            mybat,
            mymem,
            mylayoutbox[s] }
    })

    mywibox[s]:set_widget(layout)

    -- infoboxes funs

    mynotification[s].text:buttons(awful.util.table.join(
        awful.button({ }, 1, function () mynotification[s]:toggle_menu() end),
        awful.button({ }, 3, function () mynotification[s]:toggle() end)
    ))

    mynetgraphs.small.layout:connect_signal("mouse::enter", function ()
        if detailed_graphs.visible() then
            myinfobox.net[s]:show()
        end
    end)

    mycpugraphs.small.widget:connect_signal("mouse::enter", function ()
        if detailed_graphs.visible() then
            myinfobox.cpu[s]:show()
        end
    end)

    mytextclock:connect_signal("mouse::enter", function ()
        mycal:update()
        myinfobox.cal[s]:update()
        myinfobox.cal[s]:show()
    end)

    mybat:connect_signal("mouse::enter", function ()
        myinfobox.bat[s]:update()
        myinfobox.bat[s]:show()
    end)

    mynetgraphs.small.layout:connect_signal("mouse::leave", myinfobox.net[s].hide)
    mycpugraphs.small.widget:connect_signal("mouse::leave", myinfobox.cpu[s].hide)
    mytextclock:connect_signal("mouse::leave", myinfobox.cal[s].hide)
    mybat:connect_signal("mouse::leave", myinfobox.bat[s].hide)

end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

volume = uzful.util.volume("Master")

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({}, "XF86Launch1", function () awful.util.spawn_with_shell("xtrlock") end),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:toggle() end),
    awful.key({ modkey, "Shift"   }, "w", function () mymainmenu:toggle({keygrabber=true}) end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- control sound
    awful.key({ modkey            }, "<",      function () volume.lower() end),
    awful.key({ modkey, "Shift"   }, "<",      function () volume.raise() end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey,           }, "q",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey, "Control" }, "n",      awful.client.restore                             ),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "feh" },
      properties = { floating = true, maximized_vertical = true, maximized_horizontal = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 1 of screen 1.
     { rule = { class = "Firefox" },
       properties = { tag = tags[1][1] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.connect_signal("focus",   function(c) c.border_color = beautiful.border_focus  end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

require("autostart")

