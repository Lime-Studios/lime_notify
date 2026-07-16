fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'lime Scripts'
description 'lime Notify - Modern Notification System with Sound Support'
version '2.0.0'

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
    'web/dist/alert.ogg',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
    'web/dist/assets/*.woff2',
}

exports {
    'Notify',
    'Progress',
    'Dismiss',
}
