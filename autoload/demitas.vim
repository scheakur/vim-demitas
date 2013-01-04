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
	if !has_key(ctx, 'request_token')
		echomsg 'Need webapi-vim (https://github.com/mattn/webapi-vim)'
		return
	endif

	let url = auth_url . '?oauth_token=' . ctx.request_token
	call openbrowser#open(url)
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
	let hostname = get(g:, 'demitas_tumblr_hostname', '')
	if empty(hostname)
		echoerr 'Please set g:demitas_tumblr_hostname'
		return
	endif

	let ctx = demitas#prepare()
	if empty(ctx)
		return
	endif

	let meta = s:read_meta_data()
	if !empty(meta)
		return s:post_with_meta(meta, hostname, ctx)
	endif

	if (line('$') >= 3 && !empty(getline(1)) && empty(getline(2)))
		return s:post_with_plain_format(hostname, ctx)
	endif

	return s:post_simple(hostname, ctx)
endfunction


" Keys for meta data
let s:MetaKey = {
\	'BODY_START': ' body start ',
\}


function! s:post_simple(hostname, ctx)
	let content = join(getline(1, line('$')), "\n")
	return s:do_post(content, {}, a:hostname, a:ctx)
endfunction


function! s:post_with_plain_format(hostname, ctx)
	let title =  getline(1)
	let content = join(getline(3, line('$')), "\n")
	return s:do_post(content, {'title': title}, a:hostname, a:ctx)
endfunction


function! s:post_with_meta(meta, hostname, ctx)
	let start = a:meta[s:MetaKey.BODY_START]
    call remove(a:meta, s:MetaKey.BODY_START)
	let content = join(getline(start, line('$')), "\n")
	return s:do_post(content, a:meta, a:hostname, a:ctx)
endfunction


function! s:do_post(content, option, hostname, ctx)
	let url = 'http://api.tumblr.com/v2/blog/' . a:hostname . '/post'
	try
		let data = extend(a:option, {
		\	'type': 'text',
		\	'format': 'markdown',
		\	'body': a:content,
		\})
		if has_key(data, 'tags') && type(data.tags) == type([])
			let data.tags = join(data.tags, ',')
		endif
		let ret = webapi#oauth#post(url, a:ctx, {}, data)
		echo 'Post succeeded'
		return ret
	catch
		call demitas#remove_config()
	endtry
endfunction


function! s:read_meta_data()
	let start = 1
	let end = line('$')

	let sep = '---'
	let re_key = '\v^[a-zA-Z0-9 ]+\zs:'

	let first = getline(start)
	if (first != sep)
		echomsg 'No metadata'
		return {}
	endif

	let body_start = 0
	let yaml = []
	for num in range(2, end)
		let line = getline(num)
		if (line == sep)
			let body_start = num + 1
			break
		endif
		call add(yaml, line)
	endfor

	let meta = s:yaml2obj(join(yaml, "\n"))
	if (body_start != 0)
		let meta[s:MetaKey.BODY_START] = body_start
	endif

	return meta
endfunction


function! s:yaml2obj(yaml)
perl << EOF
	use YAML::Syck qw(Load);
	use JSON::Syck qw(Dump);
	eval {
		my $yaml = Dump(Load('' . VIM::Eval('a:yaml')) || {});
		VIM::DoCommand("let obj = " . $yaml);
	};
EOF
	if !exists('obj')
		return {}
	endif
	return obj
endfunction
