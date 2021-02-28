vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# FIXME:
#         let maybe_nl = empty(lines) ? '' : "\n"
#         let text = work_on_code
#                \ ?     join(             lines,  "\n") .. maybe_nl ..              text_before_cursor
#                \ :     join(s:remove_cml(lines), "\n") .. maybe_nl .. s:remove_cml(text_before_cursor)
#                          ^
#
# Press `vio` right above the `^`.
# The first/last character of any line in the selection should match a word boundary.
# Here, it's not the case for the 1st and 4th line.
# The selection should only cover 2 lines, with the words `join`.
#
# 2 possible algo:
#
# 1.
# Select current word on current line.
# On next line, from same original column position, select current word:
#
#    - if the new set of column indexes is included in the previous one,
#      go on to next line
#
#    - if it's not check whether the 1st/last column index is the
#      first/last character in a word, in ALL previous lines:
#
#        * if they don't, stop the object on the previous line
#        * if they do, go on to next line
#
# 2.
# Same as before,  except, don't check whether the 1st/last  column index is the
# 1st/last character in  a word, in all previous lines.   Instead, check whether
# they are whitespace, which is more restrictive.
# I prefer  this algo,  because it  seems smarter.   It will  react differently,
# depending on where we press `io`.
# Besides, if,  sometimes, the selection is  not big enough compared  to what we
# expected, all we need to do, is move the cursor (l,j,…), then repress `io`.
#
#         abcd  xy
#         efghij
#         klmnopqr
#
# Our current algorithm is fundamentally different.  It starts to search for the
# lines, then the columns.
# If we want to implement one of the previous 2 algo, we need to start searching
# for the columns, then the lines.

def columnObject#main(iw_aw: string) #{{{1
    if getline('.') =~ '^\s*$'
        return
    endif

    # let [orig_col, orig_line] = [col('.'), line('.')]
    # let [word, fcol, lcol] = getline('.')->matchstrpos('\<\k\{-}\%'.orig_col.'c\k\{-}\>')

    # let fline = orig_line - 1
    # while fline >= 1
    #     let [word, col1, col2] =
    #     \         getline(fline)->matchstrpos('\<\k\{-}\%' .. orig_col .. 'c\k\{-}\>')
    #     if col1 < 0 || col2 < 0
    #         let fline += 1
    #         break
    #     endif
    #     let [col1, col2] = [col1 + 1, col2 + 1]
    #     let get_out = 0
    #     " NOTE: don't use `matchstr()` in a for loop to get the index of an item
    #     " where a pattern match.  Simply, use `matchstrpos()`.
    #     for a_line in range(fline - 1, orig_line)
    #         if getline(a_line)->matchstr('\%' .. col1 .. 'c\<\k\{-}\%' .. col2 .. 'c\>') == ''
    #             let get_out = 1
    #             let fline += 1
    #             break
    #         endif
    #     endfor
    #     if get_out
    #         break
    #     endif
    #     let [fcol, lcol] = [col1, col2]
    #     let fline -= 1
    # endwhile

    # let lline = orig_line + 1
    # while lline <= line('$')
    #     let [word, col1, col2] = getline(lline)->matchstrpos('\<\k\{-}\%' .. orig_col .. 'c\k\{-}\>')
    #     if col1 < 0 || col2 < 0
    #         let lline -= 1
    #         break
    #     endif
    #     let [col1, col2] = [col1 + 1, col2 + 1]
    #     let get_out = 0
    #     " NOTE: don't use `matchstr()` in a for loop to get the index of an item
    #     " where a pattern match.  Simply, use `matchstrpos()`.
    #     for a_line in range(orig_line, lline - 1)
    #         if getline(a_line)->matchstr('\%' .. col1 .. 'c\<\k\{-}\%' .. col2 .. 'c\>') == ''
    #             let get_out = 1
    #             let lline -= 1
    #             break
    #         endif
    #     endfor
    #     if get_out
    #         break
    #     endif
    #     let [fcol, lcol] = [col1, col2]
    #     let lline += 1
    # endwhile

    # call cursor(fline, fcol-1)
    # exe "norm! \<c-v>" .. lline .. 'G'
    # call cursor(lline, lcol-1)

    # Select current word on current line.
    # On next line, from same original column position, select current word:
    #
    #    - if the new set of column indexes is included in the previous one,
    #      go on to next line
    #
    #    - if it's not check whether the 1st/last column index is the
    #      first/last character in a word, in ALL previous lines:
    #
    #        * if they don't, stop the object on the previous line
    #        * if they do, go on to next line

    var on_space: bool = getline('.')->strpart(col('.') - 1)[0] =~ '\s'

    #                               ┌ necessary to set the mark '<
    #                               │
    exe 'keepj norm! v' .. iw_aw .. "\e"

    var top_line: number = FindBoundaryLines(
        line('.'),
        indent('.'),
        col("'<"),
        virtcol("'<"),
        -1
        )
    var bottom_line: number = FindBoundaryLines(
        line('.'),
        indent('.'),
        col("'<"),
        virtcol("'<"),
        1
        )
    var vcol1: number
    var vcol2: number
    [vcol1, vcol2] = FindBoundaryColumns(
        top_line,
        bottom_line,
        virtcol("'<"),
        iw_aw,
        on_space
        )

    exe 'keepj norm! ' .. top_line .. 'G' .. vcol1 .. "|\<c-v>" .. bottom_line .. 'G' .. vcol2 .. '|'
enddef

def FindBoundaryLines( #{{{1
    lnum: number,
    indent: number,
    col: number,
    vcol: number,
    dir: number
    ): number

    var cur_lnum: number = lnum
    var limit: number = dir == 1 ? line('$') : 1

    var is_code: bool = synID(cur_lnum, col, true)
        ->synIDtrans()
        ->synIDattr('name') != 'Comment'
    while cur_lnum != limit
        var next_lnum: number = cur_lnum + dir
        var line: string = getline(next_lnum)

        var has_same_indent: bool = indent(next_lnum) == indent
        var is_not_empty: bool = line =~ '\S'
        var is_long_enough: bool = line =~ '\%' .. vcol .. 'v'
        var is_not_folded: bool = line !~ '\%({{' .. '{\|}}' .. '}\)\%(\d\+\)\=\s*$'
        var is_relevant: bool = is_code && synID(next_lnum, col, 1)
            ->synIDtrans()
            ->synIDattr('name') != 'Comment'
            || !is_code && synID(next_lnum, col, 1)
            ->synIDtrans()
            ->synIDattr('name') == 'Comment'

        if has_same_indent && is_not_empty && is_long_enough && is_not_folded && is_relevant
            cur_lnum = next_lnum
        else
            return cur_lnum
        endif
    endwhile

    return limit
enddef

def FindBoundaryColumns( #{{{1
    top_line: number,
    bottom_line: number,
    vcol: number,
    iw_aw: string,
    on_space: bool
    ): list<number>

    var vcol1: number = -1
    var vcol2: number = -1
    var lnum: number = top_line

    while lnum <= bottom_line

        #                                 ┌ necessary to set the marks '< and '>
        #                                 │
        exe printf("keepj norm! %dG%d|v%s\e", lnum, vcol, iw_aw)

        if [vcol1, vcol2] ==# [-1, -1]
            [vcol1, vcol2] = [virtcol("'<"), virtcol("'>")]
        else
            var word_selected_is_not_empty: bool = getline('.')
                ->matchstr('\%' .. virtcol("'<") .. 'v.*\%' .. virtcol("'>") .. 'v.')
                =~ '\S'
            if !on_space && word_selected_is_not_empty
             || on_space && !word_selected_is_not_empty
                vcol1 = min([vcol1, virtcol("'<")])
                vcol2 = max([vcol2, virtcol("'>")])
            endif
        endif
        lnum += 1
    endwhile

    return [vcol1, vcol2]
enddef

