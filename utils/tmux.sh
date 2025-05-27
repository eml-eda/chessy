#!/bin/bash

SESSION_NAME="ceshire"

if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    tmux attach-session -t $SESSION_NAME
    exit 0
fi

tmux new-session -d -s $SESSION_NAME -c "/home/zcu102/git/cheshire/" -n "compile"

tmux new-window -t $SESSION_NAME:1 -c "/home/zcu102/git/cheshire/target/openocd" -n "openocd"

tmux new-window -t $SESSION_NAME:2 -c "/home/zcu102/git/cheshire/sw/tests" -n "gdb"

tmux new-window -t $SESSION_NAME:3 -c "/home/zcu102/git/uart-script/" -n "uart_script"

tmux select-window -t $SESSION_NAME:0

tmux attach-session -t $SESSION_NAME