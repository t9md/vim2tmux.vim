" sign define NextCmd text=> texthl=Function"{{{
" sign undefine NextCmd

" finish
" sign place {id} line={lnum} name={name} file={fname}
" sign place {id} line={lnum} name={name} file={fname}
" sign undefine NextCmd

" nnoremap <F6> :CursorNext<CR>
let b:nextline = 1

" function! Clear()
  " sign unplace *
" endfunction


" function! CursorNext()
  " " let b:curline  = 11
  " let b:nextline = b:nextline + 1

  " echohl Function
  " echo getline(b:curline)
  " echohl Normal

  " let cmd = "sign place 1 line=".b:nextline." name=NextCmd buffer=".bufnr('%')
  " execute cmd
" endfunction

" command! CursorNext :call CursorNext()


" " function! g:set_tmux_host2pane() range
" " end
" let b:tmux_host2pane = {}"}}}

function! s:tmux_host2pane_add(host, pane)
  let b:tmux_host2pane[a:host] = a:pane
endfunction

function! s:tmux_host2pane_register() range
  let selection = getline(a:firstline, a:lastline)
  if !exists('b:tmux_host2pane')
    let b:tmux_host2pane = {}
  endif
  for line in selection
    let line = substitute(line, '^\s\+', "", '')
    let line = substitute(line, '\s\+$', "", '')
    let [hostname, pane;_] = split(line,'\s*:\s*')
    call s:tmux_host2pane_add(hostname, pane)
  endfor
endfunction

function! s:tmux_host2pane_clear()
  let s:tmux_host2pane = {}
endfunction

function! s:shell_escape(str)
  let val = substitute(a:str, "'", "'\\\\''", 'g')
  return substitute(val, '^\s\+', "", '')
endfunction

function! g:tmux_send_str(cmd)
  call system(a:cmd . " Enter")
endfunction

function! g:tmux_send(...) range
  let selection = a:0 > 0 ? a:000 : getline(a:firstline, a:lastline)

  for line in selection
    redraw
    let result = g:parse_line(line)

    if     result['cmd'] == 'pane'
      let g:tmux_target_pane = result['val']
      let g:status = "[".result['val']."]" . '[' .result['hostname']. "] "
      call s:update_status_line([[g:status, "Function"], ["Set pane","Special"]])
    elseif result['cmd'] == 'exe'
      let cmd = "tmux send-keys -t".g:tmux_target_pane." '".result['val']."' Enter"
      call s:update_status_line([[g:status, "Function"], [result['val'],"Normal"]])
      call system(cmd)

    elseif result['cmd'] == 'error'
      echohl Error
      echoerr result['val']
      echohl Normal
    endif
  endfor
endfunction

function! s:update_status_line(messages)
  for [msg, color ] in a:messages
    exe 'echohl '.color
    echon msg
    echohl Normal
  endfor
  " echo printf("%s %s", a:status, a:msg)
endfunction

function! s:clear_status_line(pane, msg)
  echo ""
endfunction

function! g:tmux_send_and_nextline()
  call g:tmux_send()
  normal! j
  " let curpos = getpos('.')
  " let curpos[1] = curpos[1] + 1
  " call setpos('.',curpos)
endfunction

function! g:tmux_send_to_current_pane() range
  let current_pane = system("tmux display-message -p '#P'")
  let selection = getline(a:firstline, a:lastline)
  for line in selection
    let cmd = s:shell_escape(line)
    let cmd = "tmux send-keys '".cmd."' Enter"
    call system(cmd)
  endfor
endfunction

function! g:tmux_send_with_select() range
  call system('tmux display-panes')
  let pane = input("Target Pane:")
  if empty(pane)
    echo "Canceled"
    return
  endif
  " call system('tmux display-pane -t'.pane)
  let selection = getline(a:firstline, a:lastline)
  for line in selection
    let cmd = s:shell_escape(line)
    let cmd = "tmux send-keys -t".pane." '".cmd."' Enter"
    call system(cmd)
  endfor
endfunction

function! g:parse_line(str)
  " ## <0>
  "    cd /etc
  " ## <1>
  "    curl localhost
  let regex = '^#\+\s\+<\(\d\)>.*$'
  if a:str =~# regex
    let pane = substitute(a:str, regex, '\1', '')
    return {'cmd': 'pane', 'val': pane , 'hostname': ""}
  endif

  " ## web01
  "     ls
  " ## web02
  "     curl localhost
  let regex = '^#\+\s\+\(\w\+\)\s*'
  if a:str =~# regex
    let hostname = substitute(a:str, regex, '\1', '')
    if has_key(b:tmux_host2pane, hostname)
      let pane = b:tmux_host2pane[hostname]
      return {'cmd': 'pane', 'val': pane, 'hostname': hostname }

    else
      return {'cmd': 'error', 'val': "can't determine pane for host " . hostname}
      
    end
  endif

  return {'cmd': 'exe', 'val': s:shell_escape(a:str) }
endfunction

function! s:tmux_set_target_pane(target_pane)
  let g:tmux_target_pane= a:target_pane
endfunction

" command! -nargs=1 TmuxSetTargetPane :call s:tmux_set_target_pane(<q-args>)
command! -range TmuxHost2PaneRegister :<line1>,<line2>call s:tmux_host2pane_register()
command! -range TmuxSend :<line1>,<line2>call g:tmux_send()
command! -range TmuxSendAndNextLine :call g:tmux_send_and_nextline()
command! -range TmuxSendToCurrentPane :<line1>,<line2>call g:tmux_send_to_current_pane()
command! -range TmuxSendWithSelectedPane :<line1>,<line2>call g:tmux_send_with_select()
command! SetBufferToTmuxMode :call g:set_buffer_to_tmux_mode()
command! -nargs=1 TmuxSetTargetPane :call s:tmux_set_target_pane(<q-args>)
command! -nargs=0 TmuxShowTask :call tmux#show_task()
command! -nargs=1 TmuxTaskDo :call tmux#do_task(<f-args>)
command! -nargs=1 TmuxDo :call tmux#send_key(<q-args>)

function! g:set_buffer_to_tmux_mode()
  " vnoremap <buffer> <silent> <M-t> :TmuxSend<CR>
  nnoremap <buffer> <silent> <F5>  :TmuxSendAndNextLine<CR>
  " 1split
endfunction
