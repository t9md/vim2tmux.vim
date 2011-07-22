function! tmux#send_keys(cmds) "{{{1
  let cmd_tmpl = "tmux send-keys '%s' Enter"
  let cmds = map(a:cmds, "printf(cmd_tmpl, v:val)")
  for cmd in cmds
    call vimproc#system(cmd)
  endfor
endfunction

function! tmux#send_key(cmd) "{{{1
  call tmux#send_keys([a:cmd])
endfunction

let s:task = {}
function s:task.new(name, desc, cmds) "{{{1
  return { "name": a:name,
        \ "desc": a:desc,
        \ "cmds": a:cmds,
        \ }
endfunction

let s:tmux = {}
let s:tmux.tasks = []

function! tmux#define_task(name, desc, cmds) "{{{1
  call add(s:tmux.tasks, s:task.new(a:name, a:desc, a:cmds))
endfunction
function! tmux#do_task(name) "{{{1
  let task = tmux#find_task(a:name)
  if task == {}
    echoerr "can't find task '" . a:name . "'"
    return
  endif
  call tmux#send_keys(task.cmds)
endfunction
function! tmux#find_task(name) "{{{1
  for task in s:tmux.tasks
    if task.name ==# a:name
      return task
    endif
  endfor
  return {}
endfunction
function! tmux#add_task(task) "{{{1
  call add(s:tmux.tasks, a:task)
endfunction
function! tmux#register_tasks(tasks) "{{{1
  call tmux#clear_task()
  for task in a:tasks
    call tmux#add_task(task)
  endfor
endfunction

function! tmux#show_task() "{{{1
  for task in s:tmux.tasks
    echo printf("%-8s %-10s %s", task.name . " :", task.desc, string(task.cmds))
  endfor
endfunction
function! tmux#clear_task() "{{{1
  let s:tmux.tasks = []
endfunction
