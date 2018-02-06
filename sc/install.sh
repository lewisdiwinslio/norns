#!/bin/bash

norns_ext_dir=~/.local/share/SuperCollider/Extensions/norns
rm -rf $norns_ext_dir
mkdir -p $norns_ext_dir

link() {
    base=`basename $1`
    src=`pwd`/$1
    dst=$norns_ext_dir/$base
    echo $dst
    ln -sf $src $dst
}

for file in $(find . -name '*.sc'); do
    link $file
done

for file in $(find . -name '*.so'); do
    link $file
done
