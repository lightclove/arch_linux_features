# colors
darkgrey="$(tput bold ; tput setaf 0)"
white="$(tput bold ; tput setaf 7)"
blue="$(tput bold; tput setaf 4)"
cyan="$(tput bold; tput setaf 6)"
nc="$(tput sgr0)"

# exports
export PATH="${HOME}/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:"
export PATH="${PATH}/usr/local/sbin:/opt/bin:/usr/bin/core_perl:/usr/games/bin:home/user/.local/lib/python3.10/site-packages/:/home/user/.local/bin/vosk-transcriber:$HOME/.local/bin:$PATH:"

if [[ $EUID -eq 0 ]]; then
  export PS1="\[$blue\][ \[$cyan\]\H \[$darkgrey\]\w\[$darkgrey\] \[$blue\]]\\[$darkgrey\]# \[$nc\]"
else
  export PS1="\[$blue\][ \[$cyan\]\H \[$darkgrey\]\w\[$darkgrey\] \[$blue\]]\\[$cyan\]\$ \[$nc\]"
fi

export LD_PRELOAD=""
export EDITOR="vim"

# alias
alias l="ls --color"
alias p="pycharm"
alias vi="vim"
alias shred="shred -zf"
#alias python="python2"
alias wget="wget -U 'noleak'"
alias curl="curl --user-agent 'noleak'"

# source files
[ -r /usr/share/bash-completion/completions ] &&
  . /usr/share/bash-completion/completions/*
. "$HOME/.cargo/env"


function backup_project() {
    CURRENT_DIR=$(basename "$PWD")  # Имя текущей директории
    PARENT_DIR=$(dirname "$PWD")   # Родительская директория
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")  # Текущая дата и время

    if [ "$CURRENT_DIR" = "$PARENT_DIR" ]; then
        echo "Ошибка: Вы находитесь в корневой директории. Архивирование не выполнено."
        return 1
    fi

    # Архивирование текущей директории
    tar -czvf "${PARENT_DIR}/${CURRENT_DIR}_${TIMESTAMP}.tar" \
        --exclude='htmlcov' \
        --exclude='.idea' \
        --exclude='.venv' \
        --exclude='venv' \
        --exclude='.mypy_cache' \
        --exclude='.pytest_cache' \
        --exclude='.git' \
        --exclude='logs' \
        --exclude='*/logs' \
        --exclude='*.zip' \
        --exclude='*.wav' \
        --exclude='*.tar.gz' \
        --exclude='*.pyc' \
        --exclude='*.pyo' \
        "$PWD"

    if [ $? -eq 0 ]; then
        echo "Архив ${CURRENT_DIR}_${TIMESTAMP}.tar.gz успешно создан в ${PARENT_DIR}."
    else
        echo "Ошибка: Архивирование не удалось."
    fi
}
