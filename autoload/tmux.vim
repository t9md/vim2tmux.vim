" Utility: {{{
function! s:parse_line()
  let [pane, hostname] = matchlist(getline('.'), '\zs\(\d\+\)\s*:\s*\(\S\+\)')[1:2]
  let b:host2pane_table[hostname] = pane
endfunction

function! s:shell_escape(str)
  let val = substitute(a:str, "'", "'\\\\''", 'g')
  " strip
  return substitute(val, '^\s\+', "", '')
endfunction
" }}}

" PublicInterface: {{{
" function! tmux#send_key(cmd) "{{{1
  " call tmux#send_keys([a:cmd])
" endfunction

function! tmux#sendkey(pane, cmd)
  let pane_opt =
        \ a:pane == "default" ? self.default_pane :
        \ a:pane == "current" ? "" : "-t" . a:pane_opt

  let cmd_tmpl = "tmux send-keys " . pane_opt . " '%s' Enter"
  call vimproc#system( printf(cmd_tmpl, s:shell_escape(a:cmd)) )
endfunction
finish

let s:tmux2vim = {}

function! s:tmux2vim.set_default_pane(pane)
  let self.default_pane = a:pane
endfunction

function! s:tmux2vim.sendkey(pane, cmd)
  let pane_opt =
        \ a:pane == "default" ? self.default_pane :
        \ a:pane == "current" ? "" : a:whre

  let cmd_tmpl = "tmux send-keys '%s' Enter"
  let cmds = map(a:cmds, "printf(cmd_tmpl, v:val)")
  for cmd in cmds
    call vimproc#system(cmd)
  endfor
endfunction

function! s:tmux2vim.status_write(msg)
  for [msg, color ] in a:messages
    exe 'echohl '. color
    echon msg
    echohl Normal
  endfor
endfunction

function! s:tmux2vim.process(input)
  let result = s:parse_line(a:input)

  if result.cmd == 'set_pane'

    let self.target_pane = result.val
    call self.status_write(["SetPane", "Special"])
  elseif result['cmd'] == 'exe'

    call self.sendkey(result.val)
    call self.status_write(["SendKey", "Special"])
  elseif result['cmd'] == 'error'

    call self.status_write(["Error", "Error"])
  endif
endfunction

function! s:show_host2pane()
  for [host, pane] in items(b:host2pane_table)
    echo printf("%s => %s", host, pane)
  endfor
endfunction
command! TmuxShowHost2Pane :call <SID>show_host2pane()


function! TmuxParse()
" ## web01
      " ls
" ## web02
      " curl localhost
  let hostname = matchstr(getline('.'), '^#\+\s\+\zs\S\+\ze\s*')
  if empty(hostname)
    return
  endif

  let pane = get(b:host2pane_table, hostname, -1)
  if pane == -1
    return
  endif
  echo pane
  " return {'cmd': 'pane', 'val': pane, 'hostname': hostname }
  " return {'cmd': 'exe', 'val': s:shell_escape(a:str) }
endfunction
" }}}

" vim: set fdm=marker:
