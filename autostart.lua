local run = require("runonce").run
local spawn = require("awful.util").spawn

if rc.conf.dbus and rc.conf.phone then
    spawn "kdeinit4" -- start kded dbus service
    spawn "dbus-send --session --print-reply --dest='org.kde.kded' /kded org.kde.kded.loadModule string:kdeconnect"
end

-- run "unagi" -- http://unagi.mini-dweeb.org/
-- run "nm-applet"
-- run "kmix"
run "akonaditray"


