" FIXME:
"         let maybe_nl = empty(lines) ? '' : "\n"
"         let text = work_on_code
"         \?             join(             lines,  "\n").maybe_nl.             text_before_cursor
"         \:             join(s:remove_cml(lines), "\n").maybe_nl.s:remove_cml(text_before_cursor)
"                          ^
"
" Press `vio` right above the `^`.
" The first/last character of any line in the selection should match a word boundary.
" Here, it's not the case for the 1st and 4th line.
" The selection should only cover 2 lines, with the words `join`.
"
" 2 possible algo:
"
" 1.
" Select current word on current line.
" On next line, from same original column position, select current word:
"
"         • if the new set of column indexes is included in the previous one,
"           go on to next line
"
"         • if it's not check whether the 1st/last column index is the
"           first/last character in a word, in ALL previous lines:
"
"               - if they don't, stop the object on the previous line
"               - if they do, go on to next line
"
" 2.
" Same as before,  except, don't check whether the 1st/last  column index is the
" 1st/last character  in a word,  in all previous lines. Instead,  check whether
" they are whitespace, which is more restrictive.
" I  prefer this  algo, because  it  seems smarter. It  will react  differently,
" depending on where we press `io`.
" Besides, if,  sometimes, the selection is  not big enough compared  to what we
" expected, all we need to do, is move the cursor (l,j,…), then repress `io`.
"
"         abcd  xy
"         efghij
"         klmnopqr
"
" Our current algorithm is fundamentally  different. It starts to search for the
" lines, then the columns.
" If we want to implement one of the previous 2 algo, we need to start searching
" for the columns, then the lines.

fu! s:find_boundary_lines(lnum, indent, col, vcol, dir) abort "{{{1
    let cur_lnum = a:lnum
    let limit = a:dir == 1 ? line('$') : 1

    let is_code = synIDattr(synIDtrans(synID(cur_lnum, a:col, 1)), 'name') isnot# 'Comment'
    while cur_lnum != limit
        let next_lnum = cur_lnum + a:dir
        let line      = getline(next_lnum)

        let has_same_indent = indent(next_lnum) == a:indent
        let is_not_empty    = line =~ '\S'
        let is_long_enough  = line =~ '\%'.a:vcol.'v'
        let is_not_folded   = line !~ '\%({{{\|}}}\)\%(\d\+\)\?\s*$'
        let is_relevant     = is_code && synIDattr(synIDtrans(synID(next_lnum, a:col, 1)), 'name') isnot# 'Comment'
        \||                  !is_code && synIDattr(synIDtrans(synID(next_lnum, a:col, 1)), 'name') is# 'Comment'

        if has_same_indent && is_not_empty && is_long_enough && is_not_folded && is_relevant
            let cur_lnum = next_lnum
        else
            return cur_lnum
        endif
    endwhile

    return limit
endfu

fu! s:find_boundary_columns(top_line, bottom_line, vcol, iw_aw, on_space) abort "{{{1
    let [ vcol1, vcol2 ]  = [-1, -1]
    let l:lnum   = a:top_line
    let on_space = a:on_space

    while l:lnum <= a:bottom_line

        "                                 ┌─ necessary to set the marks '< and '>
        "                                 │
        exe printf("keepj norm! %dG%d|v%s\e", l:lnum, a:vcol, a:iw_aw)

        if [ vcol1, vcol2 ] == [-1, -1]
            let [ vcol1, vcol2 ] = [ virtcol("'<"), virtcol("'>") ]
        else
            let word_selected_is_not_empty =
            \      matchstr(getline('.'), '\%'.virtcol("'<").'v.*\%'.virtcol("'>").'v.') =~ '\S'
            if  !on_space &&  word_selected_is_not_empty
            \||  on_space && !word_selected_is_not_empty
                let vcol1 = min([ vcol1, virtcol("'<") ])
                let vcol2 = max([ vcol2, virtcol("'>") ])
            endif
        endif
        let l:lnum += 1
    endwhile

    return [ vcol1, vcol2 ]
endfu

fu! column_object#main(iw_aw) abort "{{{1
    if getline('.') =~ '^\s*$'
        return
    endif

    " let [ orig_col, orig_line ] = [ col('.'), line('.') ]
    " let [ word, fcol, lcol ] =
    " \         matchstrpos(getline('.'), '\<\k\{-}\%'.orig_col.'c\k\{-}\>')

    " let fline = orig_line - 1
    " while fline >= 1
    "     let [ word, col1, col2 ] =
    "     \         matchstrpos(getline(fline), '\<\k\{-}\%'.orig_col.'c\k\{-}\>')
    "     if col1 < 0 || col2 < 0
    "         let fline += 1
    "         break
    "     endif
    "     let [ col1, col2 ] = [ col1+1, col2+1 ]
    "     let get_out = 0
    "     " NOTE: don't use `matchstr()` in a for loop to get the index of an item
    "     " where a pattern match. Simply, use `matchstrpos()`.
    "     for a_line in range(fline - 1, orig_line)
    "         if matchstr(getline(a_line), '\%'.col1.'c\<\k\{-}\%'.col2.'c\>') isnot# ''
    "             let get_out = 1
    "             let fline += 1
    "             break
    "         endif
    "     endfor
    "     if get_out
    "         break
    "     endif
    "     let [ fcol, lcol ] = [ col1, col2 ]
    "     let fline -= 1
    " endwhile

    " let lline = orig_line + 1
    " while lline <= line('$')
    "     let [ word, col1, col2 ] =
    "     \         matchstrpos(getline(lline), '\<\k\{-}\%'.orig_col.'c\k\{-}\>')
    "     if col1 < 0 || col2 < 0
    "         let lline -= 1
    "         break
    "     endif
    "     let [ col1, col2 ] = [ col1+1, col2+1 ]
    "     let get_out = 0
    "     " NOTE: don't use `matchstr()` in a for loop to get the index of an item
    "     " where a pattern match. Simply, use `matchstrpos()`.
    "     for a_line in range(orig_line, lline - 1)
    "         if matchstr(getline(a_line), '\%'.col1.'c\<\k\{-}\%'.col2.'c\>') isnot# ''
    "             let get_out = 1
    "             let lline -= 1
    "             break
    "         endif
    "     endfor
    "     if get_out
    "         break
    "     endif
    "     let [ fcol, lcol ] = [ col1, col2 ]
    "     let lline += 1
    " endwhile

    " call cursor(fline, fcol-1)
    " exe "norm! \<c-v>".lline.'G'
    " call cursor(lline, lcol-1)

    " Select current word on current line.
    " On next line, from same original column position, select current word:
    "
    "         • if the new set of column indexes is included in the previous one,
    "           go on to next line
    "
    "         • if it's not check whether the 1st/last column index is the
    "           first/last character in a word, in ALL previous lines:
    "
    "               - if they don't, stop the object on the previous line
    "               - if they do, go on to next line
    "

    let on_space = matchstr(getline('.'), '\%'.col('.').'c.') =~ '\s'

    "                             ┌─ necessary to set the mark '<
    "                             │
    exe 'keepj norm! v'.a:iw_aw."\e"

    let top_line         = s:find_boundary_lines(line('.'), indent('.'), col("'<"), virtcol("'<"), -1)
    let bottom_line      = s:find_boundary_lines(line('.'), indent('.'), col("'<"), virtcol("'<"), 1)
    let [ vcol1, vcol2 ] = s:find_boundary_columns(top_line, bottom_line, virtcol("'<"), a:iw_aw, on_space)

    exe 'keepj norm! '.top_line.'G'.vcol1."|\<c-v>".bottom_line.'G'.vcol2.'|'
endfu
