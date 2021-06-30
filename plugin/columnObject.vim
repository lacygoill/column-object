vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

xnoremap <unique> io <C-\><C-N><Cmd>call columnObject#main('iw')<CR>
xnoremap <unique> iO <C-\><C-N><Cmd>call columnObject#main('iW')<CR>
xnoremap <unique> ao <C-\><C-N><Cmd>call columnObject#main('aw')<CR>
xnoremap <unique> aO <C-\><C-N><Cmd>call columnObject#main('aW')<CR>

onoremap <unique> io <Cmd>call columnObject#main('iw')<CR>
onoremap <unique> iO <Cmd>call columnObject#main('iW')<CR>
onoremap <unique> ao <Cmd>call columnObject#main('aw')<CR>
onoremap <unique> aO <Cmd>call columnObject#main('aW')<CR>
