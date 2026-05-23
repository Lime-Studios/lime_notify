fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'lime Scripts'
description 'lime Notify - Modern Notification System with Sound Support'
version '1.0.1'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
    '_versioncheck.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/alert.ogg',
}

exports {
    'Notify',
}
