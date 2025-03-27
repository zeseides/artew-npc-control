fx_version 'cerulean'
game 'gta5'

author 'Artew'
description 'FPS Dostu Araç ve NPC Yönetimi'
version '1.1.1'

shared_script 'config.lua'
client_script {
	'version_checker.lua',
	'client.lua'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'

dependencies {
	'/server:5848',
	'/onesync',
}
