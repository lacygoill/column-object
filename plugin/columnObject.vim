vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

xno <unique> io <c-\><c-n><cmd>call columnObject#main('iw')<cr>
xno <unique> iO <c-\><c-n><cmd>call columnObject#main('iW')<cr>
xno <unique> ao <c-\><c-n><cmd>call columnObject#main('aw')<cr>
xno <unique> aO <c-\><c-n><cmd>call columnObject#main('aW')<cr>

ono <unique> io <cmd>call columnObject#main('iw')<cr>
ono <unique> iO <cmd>call columnObject#main('iW')<cr>
ono <unique> ao <cmd>call columnObject#main('aw')<cr>
ono <unique> aO <cmd>call columnObject#main('aW')<cr>
