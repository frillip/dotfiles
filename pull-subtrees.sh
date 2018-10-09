#!/bin/bash

# vim
git subtree pull -m 'update gruvbox' --squash --prefix=home/.vim/bundle/gruvbox https://github.com/morhetz/gruvbox.git master
git subtree pull -m 'update supertab' --squash --prefix=home/.vim/bundle/supertab https://github.com/ervandew/supertab.git master
git subtree pull -m 'update trailing-whitespace' --squash --prefix=home/.vim/bundle/trailing-whitespace https://github.com/vim-scripts/trailing-whitespace.git master
git subtree pull -m 'update multiple-cursors' --squash --prefix=home/.vim/bundle/vim-multiple-cursors https://github.com/terryma/vim-multiple-cursors.git master
git subtree pull -m 'update css-color' --squash --prefix=home/.vim/bundle/vim-css-color https://github.com/ap/vim-css-color.git master
git subtree pull -m 'update pathogen' --squash --prefix=home/.vim/bundle/pathogen https://github.com/tpope/vim-pathogen.git master
git subtree pull -m 'update polyglot' --squash --prefix=home/.vim/bundle/vim-polyglot https://github.com/sheerun/vim-polyglot.git master
git subtree pull -m 'update lightline' --squash --prefix=home/.vim/bundle/lightline.vim https://github.com/itchyny/lightline.vim.git master
git subtree pull -m 'update vim-rooter' --squash --prefix=home/.vim/bundle/vim-rooter https://github.com/airblade/vim-rooter.git master
git subtree pull -m 'update vim-openscad' --squash --prefix=home/.vim/bundle/openscad https://github.com/sirtaj/vim-openscad.git master
git subtree pull -m 'update vim-uci' --squash --prefix=home/.vim/bundle/vim-uci https://github.com/cmcaine/vim-uci.git master
git subtree pull -m 'update vim requirements.txt' --squash --prefix=home/.vim/bundle/requirements.txt.vim https://github.com/raimon49/requirements.txt.vim.git master

# misc
git subtree pull -m 'update powerline-fonts' --squash --prefix=etc/powerline-patched https://github.com/Lokaltog/powerline-fonts.git master
git subtree pull -m 'update zsh-git-prompt' --squash --prefix=home/.zsh/zsh-git-prompt https://github.com/olivierverdier/zsh-git-prompt.git master
git subtree pull -m 'update zsh-syntax-highlighting' --squash --prefix=home/.zsh/zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git master
git subtree pull -m 'update zsh-history-substring-search' --squash --prefix=home/.zsh/zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search.git master
