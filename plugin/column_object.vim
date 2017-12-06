if exists('g:loaded_column_object')
    finish
endif
let g:loaded_column_object = 1

xno <silent><unique> io :<c-u>call column_object#main('iw')<cr>
xno <silent><unique> iO :<c-u>call column_object#main('iW')<cr>
xno <silent><unique> ao :<c-u>call column_object#main('aw')<cr>
xno <silent><unique> aO :<c-u>call column_object#main('aW')<cr>

ono <silent><unique> io :call column_object#main('iw')<cr>
ono <silent><unique> iO :call column_object#main('iW')<cr>
ono <silent><unique> ao :call column_object#main('aw')<cr>
ono <silent><unique> aO :call column_object#main('aW')<cr>
