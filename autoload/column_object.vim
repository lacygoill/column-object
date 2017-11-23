if exists('g:autoloaded_column_object')
    finish
endif
let g:autoloaded_column_object = 1

fu! s:find_boundary_lines(lnum, indent, col, vcol, step) abort "{{{1
    let orig_lnum = a:lnum
    let limit    = a:step == 1 ? line('$') : 1

    " We must distinguish 2 addresses: `orig_lnum` and `next_lnum`.
    "
    " `orig_lnum` is the address of the latest line which we've tested, and
    " which we know has text inside the column.
    "
    " Initially, it's the address of the current line on which the cursor
    " is when we hit one of our mappings (`ic`, `ac`, …):    `a:lnum`
    " Then, it may be increased or decreased at the end of each iteration of
    " the `while` loop:    `let orig_lnum = next_lnum`
    "
    " `next_line` is the address of the next line to test.

    let is_code = synIDattr(synIDtrans(synID(orig_lnum, a:col, 1)), 'name') !=# 'Comment'
    while orig_lnum != limit
        let next_lnum       = orig_lnum + a:step
        let line            = getline(next_lnum)

        let has_same_indent = indent(next_lnum) == a:indent
        let is_not_empty    = line =~ '\S'
        let is_long_enough  = line =~ '\%'.a:vcol.'v'
        let no_fold         = line !~ '\%({{{\|}}}\)\%(\d\+\)\?\s*$'
        let is_relevant     = is_code && synIDattr(synIDtrans(synID(next_lnum, a:col, 1)), 'name') !=# 'Comment'
        \||                  !is_code && synIDattr(synIDtrans(synID(next_lnum, a:col, 1)), 'name') ==# 'Comment'
        if has_same_indent && is_not_empty && is_long_enough && no_fold && is_relevant
            let orig_lnum = next_lnum
        else
            return orig_lnum
        endif
    endwhile

    return limit
endfu

fu! s:find_boundary_columns(top_line, bottom_line, vcol, word_obj, on_space) abort "{{{1
    let columns  = []
    let l:lnum   = a:top_line
    let on_space = a:on_space

    while l:lnum <= a:bottom_line

        " necessary to set the marks '< and '>
        exe printf("keepj norm! %dG%d|v%s\e", l:lnum, a:vcol, a:word_obj)

        if empty(columns)
            let columns = [virtcol("'<"), virtcol("'>")]
        else
            let word_selected_is_not_empty =
            \      matchstr(getline('.'), '\%'.virtcol("'<").'v.*\%'.virtcol("'>").'v.') =~ '\S'
            if !on_space &&  word_selected_is_not_empty
          \ ||  on_space && !word_selected_is_not_empty
                let columns[0] = min([columns[0], virtcol("'<")])
                let columns[1] = max([columns[1], virtcol("'>")])
            endif
        endif
        let l:lnum += 1
    endwhile

    return columns
endfu

fu! column_object#main(word_obj) abort "{{{1
    if getline('.') =~ '^\s*$'
        return
    endif

    let on_space = matchstr(getline('.'), '\%'.col('.').'c.') =~ '\s'

    " necessary to set the mark '<
    exe 'keepj norm! v'.a:word_obj."\e"

    let top_line    = s:find_boundary_lines(line('.'), indent('.'), col("'<"), virtcol("'<"), -1)
    let bottom_line = s:find_boundary_lines(line('.'), indent('.'), col("'<"), virtcol("'<"), 1)
    let columns     = s:find_boundary_columns(top_line, bottom_line, virtcol("'<"), a:word_obj, on_space)

    exe 'keepj norm! '.top_line.'G'.columns[0]."|\<c-v>".bottom_line.'G'.columns[1].'|'
endfu
