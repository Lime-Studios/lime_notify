fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'lime Scripts'
description 'lime Notify - Modern Notification System with Sound Support'
version '1.0.2'

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

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/index.js',
    'web/dist/assets/index.css',
    'web/dist/alert.ogg',
}

exports {
    'Notify',
}
