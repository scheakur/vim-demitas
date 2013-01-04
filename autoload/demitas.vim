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

let s:consumer_key = 'MWR3PEsv6O10RUzdUjjOypBzNI4BDAYNIBIUm6QlD0Se8CNnZl'
let s:consumer_secret = 'x08RduPmF5rFuXvhbMcLCaapPJ0Jj2uHddAY80j3pUDKUWR9Hz'


function! demitas#prepare()
	let ctx = {}
	let config_file = expand('~/.vim-demitas')
	if filereadable(config_file)
		let ctx = eval(join(readfile(config_file), ''))
		return ctx
	endif

	let ctx.consumer_key = s:consumer_key
	let ctx.consumer_secret = s:consumer_secret

	let request_token_url = 'http://www.tumblr.com/oauth/request_token'
	let auth_url = 'http://www.tumblr.com/oauth/authorize'
	let access_token_url = 'http://www.tumblr.com/oauth/access_token'

	let ctx = webapi#oauth#request_token(request_token_url, ctx)
	call system("open '" . auth_url . '?oauth_token=' . ctx.request_token . "'")
	let verifier = input('OAuth Verifier:')

	if !empty(verifier)
		let ctx = webapi#oauth#access_token(access_token_url, ctx, {
		\	'oauth_verifier': verifier
		\})
		call writefile([string(ctx)], config_file)
		return ctx
	endif

	echomsg 'Please input verifier'
endfunction


function! demitas#remove_config()
	let config_file = expand('~/.vim-demitas')
	if filewritable(config_file)
		call delete(config_file)
	endif
endfunction


function! demitas#post()
	if !(line('$') >= 3 && !empty(getline(1)) && empty(getline(2)))
		echomsg 'Invalid format'
		echomsg '1st line as title, empty 2nd line, under 3rd line as content'
		return
	endif

	let hostname = get(g:, 'demitas_tumblr_hostname', '')
	if empty(hostname)
		echoerr 'Please set g:demitas_tumblr_hostname'
		return
	endif

	let ctx = demitas#prepare()

	if empty(ctx)
		return
	endif

	let title =  getline(1)
	let content = join(getline(3, line('$')), "\n")
	call s:do_post(title, content, hostname, ctx)
endfunction


function! s:do_post(title, content, hostname, ctx)
	let url = 'http://api.tumblr.com/v2/blog/' . a:hostname . '/post'
	try
		let ret = webapi#oauth#post(url, a:ctx, {}, {
		\	'type': 'text',
		\	'format': 'markdown',
		\	'title': a:title,
		\	'body': a:content,
		\})
		echo 'Post succeeded'
	catch
		call demitas#remove_config()
	endtry
endfunction
