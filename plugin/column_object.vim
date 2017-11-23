if exists('g:loaded_column_object')
    finish
endif
let g:loaded_column_object = 1

xno <silent> io :<c-u>call column_object#main('iw')<cr>
xno <silent> iO :<c-u>call column_object#main('iW')<cr>
xno <silent> ao :<c-u>call column_object#main('aw')<cr>
xno <silent> aO :<c-u>call column_object#main('aW')<cr>

ono <silent> io :call column_object#main('iw')<cr>
ono <silent> iO :call column_object#main('iW')<cr>
ono <silent> ao :call column_object#main('aw')<cr>
ono <silent> aO :call column_object#main('aW')<cr>
