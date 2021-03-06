" checksyntax.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-09-12.
" @Revision:    211


if !exists('g:checksyntax#failrx')
    let g:checksyntax#failrx = '\ *\(\d \f\{-}:\)\?\d\{-}:'
endif

if !exists('g:checksyntax#okrx')
    let g:checksyntax#okrx = ''
endif

if !exists('g:checksyntax')
    " A dictionary {name/filetype => definition} of syntax checkers, where 
    " definition is a dictionary with the following fields:
    " 
    " Mandatory (either one of the following):
    "   cmd  ... A shell command used as 'makeprg' to check the file.
    "   exec ... A vim command used to check the file.
    "   compiler ... A vim compiler that is used to check the file.
    " 
    " Optional:
    "   auto ... Run automatically when saving a file.
    "   live ... Run automatically when the buffer changed
    "   efm  ... An 'errorformat' string.
    "   okrx ... A |regexp| matching the command output if no error were 
    "            found.
    "   failrx ... A |regexp| matching the command output if an error 
    "            was found.
    "   alt  ... The name of an alternative syntax checker (see 
    "            |:CheckSyntax|).
    "   prepare ... An ex command that is run before doing anything.
    "   ignore_nr ... A list of error numbers that should be ignored.
    let g:checksyntax = {}   "{{{2
endif


""" Php
if !exists('g:checksyntax.php')
    let g:checksyntax['php'] = {
                \ 'auto': 1,
                \ 'live': 1,
                \ 'cmd': 'php -l -n -f',
                \ 'efm': '%*[^:]: %m in %f on line %l',
                \ 'okrx': 'No syntax errors detected in ',
                \ 'alt': 'phpp'
                \ }
endif

"""""" Parse php
if !exists('g:checksyntax.phpp')
    let g:checksyntax['phpp'] = {
                \ 'cmd': 'php -f',
                \ 'efm': g:checksyntax.php.efm,
                \ 'okrx': g:checksyntax.php.okrx
                \ }
endif

autocmd CheckSyntax BufReadPost *.php if exists(':EclimValidate') && !empty(eclim#project#util#GetCurrentProjectName()) | let b:checksyntax.php.auto = 0 | endif


""" JavaScript
if !exists('g:checksyntax.javascript')
    if executable('gjslint')
        let g:checksyntax['javascript'] = {
                    \ 'cmd': 'gjslint',
                    \ 'ignore_nr': [1, 110],
                    \ 'efm': '%P%*[^F]FILE%*[^:]: %f %*[-],Line %l%\, %t:%n: %m,%Q',
                    \ }
    elseif executable('jsl')
        let g:checksyntax['javascript'] = {
                    \ 'cmd': 'jsl -nofilelisting -nocontext -nosummary -nologo -process',
                    \ 'okrx': '0 error(s), 0 warning(s)',
                    \ }
    endif
endif


""" Ruby
if !exists('g:checksyntax.ruby')
    let g:checksyntax['ruby'] = {
                \ 'prepare': 'compiler ruby',
                \ 'cmd': 'ruby -c',
                \ 'okrx': 'Syntax OK\|No Errors'
                \ }
endif


""" Viki
if !exists('g:checksyntax.viki')
    let g:checksyntax['viki'] = {
                \ 'cmd': 'deplate -f null',
                \ }
endif


""" chktex (LaTeX)
if !exists('g:checksyntax.tex')
    if executable('chktex')
        let g:checksyntax['tex'] = {
                    \ 'cmd': 'chktex -q -v0',
                    \ 'efm': '%f:%l:%m',
                    \ }
    endif
endif


""" c, cpp
if !exists('g:checksyntax.c')
    if executable('splint')
        let g:checksyntax['c'] = {
                    \ 'compiler': 'splint',
                    \ }
    endif
endif

if !exists('g:checksyntax.cpp') && exists('g:checksyntax.c')
    let g:checksyntax['cpp'] = copy(g:checksyntax.c)
endif


""" java
if !exists('g:checksyntax.java')
    if executable('jlint')
        let g:checksyntax['java'] = {
                    \ 'exec': 'call checksyntax#Jlint()',
                    \ 'alt': 'javaCheckstyle'
                    \ }

        " :nodoc:
        function! checksyntax#Jlint() "{{{3
            let filename = expand('%:r') .'.class'
            " TLogVAR filename
            " echom '! jlint -done '. shellescape(filename)
            exec '! jlint -done '. shellescape(filename)
        endf
    endif
endif

if !exists('g:checksyntax.javaCheckstyle')
    if executable('checkstyle')
        let g:checksyntax['javaCheckstyle'] = {
                    \ 'compiler': 'checkstyle',
                    \ }
    endif
endif


""" lua
if !exists('g:checksyntax.lua')
    " efm: File:Line:Column:Warning number:Warning message
    let g:checksyntax['lua'] = {
                \ 'auto': 1,
                \ 'cmd': 'luac -p',
                \ 'efm': 'luac\:\ %f:%l:\ %m'
                \ }
endif


""" tidy (HTML)
if !exists('g:checksyntax.html')
    let g:checksyntax['html'] = {
                \ 'auto': 1,
                \ 'live': 1,
                \ 'cmd': 'tidy -eq',
                \ 'efm': 'line %l column %c - %m'
                \ }
endif
if !exists('g:checksyntax.xhtml')
    let g:checksyntax['xhtml'] = copy(g:checksyntax.html)
endif


""" XML
if !exists('g:checksyntax.xml')
    let g:checksyntax['xml'] = {
                \ 'compiler': 'xmllint'
                \ }
endif
if !exists('g:checksyntax.docbk')
    let g:checksyntax['docbk'] = copy(g:checksyntax.xml)
endif


if !exists('*CheckSyntaxSucceed')
    " :nodoc:
    function! CheckSyntaxSucceed(manually)
        cclose
        if a:manually
            echo
            echo 'Syntax ok.'
        endif
        if exists("*QuickfixsignsUpdate")
          call QuickfixsignsUpdate()
        endif
    endf
endif


if !exists('*CheckSyntaxFail')
    " :nodoc:
    function! CheckSyntaxFail(manually)
        
    let totalerrors=0
    "let openqf=0
    for error in getqflist()
      if error['valid'] > 0
        "if s:getOption('openfornotice') || error['text']  !~ '\cnotice'
        "if error['text']  !~ '\cnotice'
        "  let openqf=1
        "endif
        let totalerrors+= 1
      endif
    endfor
        let winnum = winnr() " get current window number
        let height=min([totalerrors,10])
        if height == 0
          cw
        else
          "execute "cw ".height 
          execute "copen ".height 
          execute height."wincmd _"
        endif
        execute winnum . "wincmd w"
        if exists("*QuickfixsignsUpdate")
          call QuickfixsignsUpdate()
        endif
        "copen
    endf
endif


function! s:Make(def)
    let bufnr = bufnr('%')
    let pos = getpos('.')
"    try
        if has_key(a:def, 'compiler')

            if exists('g:current_compiler')
                let cc = g:current_compiler
            else
                let cc = ''
            endif
            try
                exec 'compiler '. a:def.compiler
                silent make
                return 1
            finally
                if cc != ''
                    let g:current_compiler = cc
                    exec 'compiler '. cc
                endif
            endtry

        else
            let makeprg = &makeprg
            let shellpipe = &shellpipe
            let errorformat = &errorformat
            if has_key(a:def, 'shellpipe')
                let &l:shellpipe = get(a:def, 'shellpipe')
            endif
            if has_key(a:def, 'efm')
                let &l:errorformat = get(a:def, 'efm')
            endif
            try
                if has_key(a:def, 'cmd')
                    let &l:makeprg = a:def.cmd
                    " TLogVAR &l:makeprg, &l:errorformat

                    if has_key(a:def, 'live') && a:def.live
                      "echo "live"
                      if !exists('b:tmpfile') || !file_readable(b:tmpfile)
                        call s:MakeTempFile()
                      endif
                      "echo a:def.cmd." /dev/stdin | sed 's/\\/dev\\/stdin/".escape(bufname("%"),'/')."/g' >".b:tmpfile
                      let test= system(a:def.cmd." /dev/stdin  2>&1 | sed 's/\\/dev\\/stdin/".escape(bufname("%"),'/')."/g' >".b:tmpfile,s:SafeGetCode())
                      execute "cg ".b:tmpfile
                      "call s:ShowQuickFix()
                    else
                      "echo "making. ".&errorformat." / ".&makeprg
                      silent! make %
                    endif
                    return 1
                elseif has_key(a:def, 'exec')
                    exec a:def.exec
                    return 1
                endif
            finally
                if &l:makeprg != makeprg
                    let &l:makeprg = makeprg
                endif
                if &l:shellpipe != shellpipe
                    let &l:shellpipe = shellpipe
                endif
                if &l:errorformat != errorformat
                    let &l:errorformat = errorformat
                endif
            endtry

        endif
 "   catch
 "       echohl Error
 "       echom v:errmsg
 "       echohl NONE
 "   finally
        if bufnr == bufnr('%')
            call setpos('.', pos)
        endif
 "   endtry
    return 0
endf


function! s:GetDef(ft) "{{{3
    if exists('b:checksyntax') && has_key(b:checksyntax, a:ft)
        return b:checksyntax[a:ft]
    elseif has_key(g:checksyntax, a:ft)
        return g:checksyntax[a:ft]
    else
        return {}
    endif
endf

function! s:DeleteTempFile()
    if exists('b:tmpfile') && b:tmpfile != '' && file_readable(b:tmpfile)
       call delete(b:tmpfile)
    endif
endf

function! s:MakeTempFile()
    call s:DeleteTempFile()
    let b:tmpfile = tempname()
endf

function! s:SafeGetCode()
    " this code dont cause a redraw :
    let code= ""
    for line_content in getline(1,"$")
    let code .= line_content."\n"
    endfor
    return code[:-2] " remonve the last \n (added by the loop)
endf

function! checksyntax#LiveCheck(reload)
    let def = s:GetDef(&filetype .',auto')
    if empty(def)
      let def = s:GetDef(&filetype)
    endif
    if empty(def)
        return
    endif
    let live = get(def, 'live', 0)
    if live
      if a:reload
        if !exists('b:tmpfile') || !file_readable(b:tmpfile)
          let b:tmpfile = ""
          let b:lastchanges = 0
        else
          "echom "MARK"
          "call phpErrorMarker#showquickfix()
        endif
      endif
      call checksyntax#Check(0)
    endif
endf

" :def: function! checksyntax#Check(manually, ?bang='', ?type=&ft)
function! checksyntax#Check(manually, ...)
    let bang = a:0 >= 1 && a:1 != '' ? 1 : 0
    let ft   = a:0 >= 2 && a:2 != '' ? a:2 : &filetype
    let def = a:manually ? {} : s:GetDef(ft .',auto')
    if empty(def)
        let def  = s:GetDef(ft)
    endif
    if bang && has_key(def, 'alt')
        let def = s:GetDef(def.alt)
    endif
    " TLogVAR def
    if empty(def)
        return
    endif
    let auto = get(def, 'auto', 0)
    " TLogVAR auto
    let live = get(def, 'live', 0)
    " TLogVAR live
    if !(a:manually || auto || live)
        return
    endif
"    if &modified
"        echom "Buffer was modified. Please save it before calling :CheckSyntax."
"        return
"    end

    if !exists('b:lastchanges') || a:manually
        let b:lastchanges = b:changedtick
    else
        if b:lastchanges == b:changedtick
          return
        endif
    endif

    " TLogVAR &makeprg, &l:makeprg, &g:makeprg, &errorformat
    exec get(def, 'prepare', '')
    if s:Make(def)
        let failrx = get(def, 'failrx', g:checksyntax#failrx)
        let okrx   = get(def, 'okrx', g:checksyntax#okrx)
        let qfl = getqflist()
        let bnr = bufnr('%')
        let wnr = winnr()
        call filter(qfl, 's:FilterItem(def, v:val)')
        call map(qfl, 's:CompleteItem(def, v:val)')
        call setqflist(qfl)
        " echom "DBG 1" string(qfl)
        if len(qfl) == 0
            call CheckSyntaxSucceed(a:manually)
        else
            call CheckSyntaxFail(a:manually)
        endif
        execute wnr."wincmd w"
        if ! live
          redraw!
        endif
    endif
endf


function! s:CompleteItem(def, val) "{{{3
    if get(a:val, 'bufnr', 0) == 0
        let a:val.bufnr = bufnr('%')
    endif
    return a:val
endf


function! s:FilterItem(def, val) "{{{3
    if a:val.lnum == 0 && a:val.pattern == ''
        return 0
    elseif has_key(a:val, 'nr') && has_key(a:def, 'ignore_nr') && index(a:def.ignore_nr, a:val.nr) != -1
        return 0
    endif
    return 1
endf

