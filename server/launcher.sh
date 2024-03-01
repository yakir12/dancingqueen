#!/bin/sh
cd $HOME/dancingqueen/server
$HOME/julia/julia --project=$HOME/dancingqueen/server/Project.toml --threads=4 $HOME/dancingqueen/server/server.jl &
