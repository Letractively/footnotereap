"==================================================
" File:         code_complete.vim
" Brief:        function parameter complete, code snippets, and much more.
" Author:       Mingbai <mbbill AT gmail DOT com>
" Last Change:  2007-01-25 11:41:13
" Version:      2.5
"
" Install:      1. Put code_complete.vim to plugin 
"                  directory.
"               2. Use the command below to create tags 
"                  file including signature field.
"                  ctags -R --c-kinds=+p --fields=+S .
"
" Usage:        
"           hotkey:
"               "("     complete funtion parameters.
"               "<tab>" complete key words.
"
"           variables:
"               g:completekey
"                   the key used to complete function 
"                   parameters and key words.
"               s:rs, s:re
"                   region start and stop
"               you can change them as you like.
"
"           key words:
"               see "templates" below.
"==================================================

" Variable Definations: {{{1
" options, change them as you like:
let g:completekey="<Leader><tab>"   "hotkey
let s:rs='`<'    "region start
let s:re='>`'    "region stop

" ----------------------------
let s:expanded=0  "in case of inserting char after expand
let s:signature_list=[]

" Autocommands: {{{1
autocmd BufReadPost * call CodeCompleteStart()

" Menus:
menu <silent>       &Tools.Code\ Complete\ Start          :call CodeCompleteStart()<CR>
menu <silent>       &Tools.Code\ Complete\ Stop           :call CodeCompleteStop()<CR>

" Function Definations: {{{1

function! CodeCompleteStart()
    set selection=inclusive"{{{
    silent! iunmap  <buffer>    (
    "inoremap        <buffer>    (         <c-r>=FunctionComplete()<cr><c-r>=SwitchRegion('')<cr>
    exec "silent! iunmap  <buffer> ".g:completekey
    exec "inoremap        <buffer> ".g:completekey." <c-r>=ExpandTemplate()<cr><c-r>=SwitchRegion(g:completekey)<cr>"
endfunction"}}}

function! CodeCompleteStop()
    silent! iunmap      <buffer>    ("{{{
    exec "silent! iunmap <buffer> ".g:completekey
endfunction"}}}


function! FunctionComplete() 
    let s:signature_list=[]"{{{
    let signature_word=[]
    "let fun=substitute(getline('.')[:(col('.')-1)],'\zs.*\W\ze\w*$','','g') " get function name
    if g:Perl_Project != 'Panorama Live'
        let fun=matchstr(getline('.')[:(col('.')-2)],'\w*$')
        let ftags=taglist("^".fun."$")
        if type(ftags)==type(0) || ((type(ftags)==type([])) && ftags==[])
            return '('
        endif
        for i in ftags
            if has_key(i,'kind') && has_key(i,'name') && has_key(i,'signature')
                if (i.kind=='p' || i.kind=='f') && i.name==fun  " p is declare, f is defination
                    let tmp=substitute(i.signature,',',s:re.','.s:rs,'g')
                    let tmp=substitute(tmp,'(\(.*\))','('.s:rs.'\1'.s:re.')','g')
                    if index(signature_word,tmp)==-1
                        let signature_word+=[tmp]
                        let item={}
                        let item['word']=tmp
                        let item['menu']=i.filename
                        let s:signature_list+=[item]
                    endif
                endif
            endif
        endfor
        if s:signature_list==[]
            return '('
        endif
        if len(s:signature_list)==1
            return s:signature_list[0]['word']
        else
            call  complete(col('.'),s:signature_list)
            return ''
        endif
    endif
    return '('
endfunction"}}}

function! SwitchRegion(key)
    if len(s:signature_list)>1
        let s:signature_list=[]
        return ''
    endif
    if match(getline('.'),s:rs.'.*'.s:re)!=-1 || search(s:rs.'.\{-}'.s:re)!=0
        let s:expanded=0
        normal 0
        call search(s:rs,'c',line('.'))
        normal v
        call search(s:re,'e',line('.'))
        return "\<c-\>\<c-n>gvo\<c-g>"
    else
        if s:expanded==1
            let s:expanded=0
            return ''
        elseif g:completekey=="<C-tab>"
            exec 'return "'.escape(a:key,'<').'"'
        else
            return ''
        endif
    endif
endfunction

function! ExpandTemplate()
    let cword = substitute(getline('.')[:(col('.')-2)],'\zs.*\W\ze\w*$','','g')
    if has_key(g:template,&ft)
        if has_key(g:template[&ft],cword)
            let s:expanded=1  "in case of insert char after expanded
            return "\<C-W>" . g:template[&ft][cword]
        endif
    endif
    if has_key(g:template['_'],cword)
        let s:expanded=1
        return "\<C-W>" . g:template['_'][cword]
    endif 
    return ""
endfunction

" [Get converted file name like __THIS_FILE__ ]
function! GetFileName()
    let filename = expand("%:t")
    let filename=toupper(filename)
    let _name=substitute(filename,'\.','_',"g")
    let _name="__"._name."__"
    return _name
endfunction


" Templates: {{{1
" to add templates for new file type, see below
"
" "some new file type
" let g:template['newft'] = {}
" let g:template['newft']['keyword'] = "some abbrevation"
" let g:template['newft']['anotherkeyword'] = "another abbrevation"
" ...
"
" ---------------------------------------------
" C templates
let g:template = {}
let g:template['c'] = {}
let g:template['c']['co'] = "/*  */\<left>\<left>\<left>"
let g:template['c']['cc'] = "/**<  */\<left>\<left>\<left>"
let g:template['c']['de'] = "#define  "
let g:template['c']['ic'] = "#include  \"\"\<left>"
let g:template['c']['ii'] = "#include  <>\<left>"
let g:template['c']['guard'] = "#ifndef  \<c-r>=GetFileName()\<cr>\<cr>#define  \<c-r>=GetFileName()\<cr>".
            \repeat("\<cr>",2)."#if _MSC_VER > 1000\<cr>#pragma once\<cr>#endif\<cr>".
            \repeat("\<cr>",5)."#endif  /*\<c-r>=GetFileName()\<cr>*/".repeat("\<up>",3)
let g:template['c']['for'] = "for(".s:rs."...".s:re."; ".s:rs."...".s:re."; ".s:rs."...".s:re.")\<cr>{\<cr>".
            \s:rs."...".s:re."\<cr>}\<cr>"
let g:template['c']['main'] = "int main(int argc, char \*argv\[\])\<cr>{\<cr>".s:rs."...".s:re."\<cr>}"
let g:template['c']['switch'] = "switch (".s:rs."...".s:re.")\<cr>{\<cr>case ".s:rs."...".s:re." :\<cr>break;\<cr>case ".
            \s:rs."...".s:re." :\<cr>break;\<cr>default :\<cr>break;\<cr>}"
let g:template['c']['if'] = "if(".s:rs."...".s:re.")\<cr>{\<cr>".s:rs."...".s:re."\<cr>}"
let g:template['c']['while'] = "while(".s:rs."...".s:re.")\<cr>{\<cr>".s:rs."...".s:re."\<cr>}"
let g:template['c']['ife'] = "if(".s:rs."...".s:re.")\<cr>{\<cr>".s:rs."...".s:re."\<cr>} else\<cr>{\<cr>".s:rs."...".
            \s:re."\<cr>}"

let g:template['c']['he'] = "/".repeat("\*",78)."/\<cr>".
                            \"/*!\<cr>".
                            \repeat("\<BS>",3).
                            \"@brief\<cr>\<cr>".
                            \s:rs."...".s:re."\<cr>\<cr>".
                            \"@file\<tab>\<tab>\<c-r>=expand(\"%:t\")\<cr>\<cr>".
                            \"@author\<tab>\<tab>Dustin Darcy\<cr>".
                            \"@par\<tab>\<tab>email: ddarcy\@pandemicstudios.com\<cr>".
                            \"@date\<tab>\<tab>\<c-r>=strftime(\"%Y-%m-%d %H:%M\")\<cr> -- ".s:rs."...".s:re." -- Dustin\<cr>\<cr>".
                            \"*/\<cr>".
                            \"/".repeat("*",78)."/\<cr>"

let g:template['c']['cl'] = "/".repeat("\*",78)."/\<cr>".
                                \"/*!\<cr>".
                                \repeat("\<BS>",2)."\<Space>".
                                \"@class ".s:rs."name".s:re." ".s:rs."header-file".s:re." ".s:rs."header-name".s:re."\<cr>\<cr>".
                                \"@brief ".s:rs."...".s:re."\<cr>\<cr>".
                                \s:rs."...".s:re."\<cr>\<cr>".
                                \"@date\<tab>\<tab>\<c-r>=strftime(\"%Y-%m-%d %H:%M\")\<cr> -- ".s:rs."...".s:re." -- Dustin\<cr>\<cr>".
                                \"@BUG\<tab>\<cr>\<tab>".s:rs."...".s:re."\<cr>\<cr>".
                                \"\<BS>".repeat("\<SPACE>",2)."@par Examples\<cr>".
                                \"@code\<cr>".
                                \"\<tab>".s:rs."...".s:re."\<cr>".
                                \repeat("\<BS>",1).repeat("\<SPACE>",2)."@endcode\<cr>\<cr>".
                                \"\<BS>*/\<cr>".
                                \"/".repeat("*",78)."/"

let g:template['c']['fu'] = "/".repeat("\*",78)."/\<cr>".
                            \"/*!\<cr>".
                            \repeat("\<BS>",2)."\<Space>".
							\"\<cr>".s:rs."...".s:re."\<cr>\<cr>".
                            \"@date\<tab>\<tab>\<c-r>=strftime(\"%Y-%m-%d %H:%M\")\<cr> -- ".s:rs."...".s:re." -- Dustin\<cr>\<cr>".
                            \"@param\<tab>".s:rs."...".s:re."\<tab>".s:rs."...".s:re."\<cr>\<cr>".
                            \"@return\<tab>".s:rs."...".s:re."\<cr>\<cr>".
                            \"@BUG\<tab>\<cr>\<tab>".s:rs."...".s:re."\<cr>\<cr>".
                            \"\<BS>".repeat("\<SPACE>",2)."@par Examples\<cr>\<tab>".s:rs."...".s:re."\<cr>\<cr>".
                            \"\<BS>*/\<cr>".
                            \"\<BS>/".repeat("*",78)."/"

let g:template['c']['return'] = "@return\<tab>".s:rs."...".s:re."\<cr>\<cr>"
let g:template['c']['param'] = "@param\<tab>".s:rs."...".s:re."\<tab>".s:rs."...".s:re."\<cr>"
let g:template['c']['date'] = "@date\<tab>\<tab>\<c-r>=strftime(\"%Y-%m-%d %H:%M\")\<cr> -- ".s:rs."...".s:re." -- Dustin\<cr>"
let g:template['c']['email'] = "@par\<tab>email: ddarcy\@pandemicstudios.com\<cr>"
let g:template['c']['bug'] = "@BUG\<tab>\<cr>\<tab>".s:rs."...".s:re."\<cr>\<cr>"
let g:template['c']['examples'] = "@par Examples\<cr>\<tab>".s:rs."...".s:re."\<cr>\<cr>"
" ---------------------------------------------
" C++ templates
let g:template['cpp'] = g:template['c']
let g:template['h'] = g:template['c']

" ---------------------------------------------
" common templates
let g:template['_'] = {}
let g:template['_']['xt'] = "\<c-r>=strftime(\"%Y-%m-%d %H:%M:%S\")\<cr>"


" vim: set ft=vim ff=unix fdm=marker :
