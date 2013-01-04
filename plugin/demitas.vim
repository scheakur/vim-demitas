"=============================================================================
" vim-demitas - Post to tumblr.com
" Copyright (c) 2013 Scheakur <http://scheakur.com/>
"
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

scriptencoding utf-8

" save 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" Post to tumblr.com
function! s:post()
	call demitas#post()
endfunction


let g:demitas_directory = get(g:, 'demitas_directory', expand('~/tmp/demitas'))


" Create an article
function! s:new_article()
	let demitas_dir = g:demitas_directory . strftime('/%Y/%m')
	if !isdirectory(demitas_dir)
		call mkdir(demitas_dir, 'p')
	endif
	let file = demitas_dir . strftime('/%Y-%m-%d-%H%M%S') . '.md'
	execute 'edit' file
	call append(0, [
	\	'---',
	\	'title:',
	\	'tags:',
	\	'---'
	\])
endfunction


" Post command
command!
\	-nargs=0
\	DemitasPost
\	call s:post()


" Create command
command!
\	-nargs=0
\	DemitasNew
\	call s:new_article()


" restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:fdm=marker:fen:

