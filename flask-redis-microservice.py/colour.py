#!/usr/bin/env python3

USECOLOUR=False

C_BLACK='';    C_B_BLACK='';    C_BG_BLACK=''
C_WHITE='';    C_B_WHITE='';    C_BG_WHITE=''
C_RED='';      C_B_RED='';      C_BG_RED=''
C_GREEN='';    C_B_GREEN='';    C_BG_GREEN=''
C_YELLOW='';   C_B_YELLOW='';   C_BG_YELLOW=''
C_BLUE='';     C_B_BLUE='';     C_BG_BLUE=''
C_MAGENTA='';  C_B_MAGENTA='';  C_BG_MAGENTA=''
C_CYAN='';     C_B_CYAN='';     C_BG_CYAN=''

C_NORMAL='\033[00m'

def colour(enable=True):
    global C_BLACK,    C_B_BLACK,    C_BG_BLACK
    global C_WHITE,    C_B_WHITE,    C_BG_WHITE
    global C_RED,      C_B_RED,      C_BG_RED
    global C_GREEN,    C_B_GREEN,    C_BG_GREEN
    global C_YELLOW,   C_B_YELLOW,   C_BG_YELLOW
    global C_BLUE,     C_B_BLUE,     C_BG_BLUE
    global C_MAGENTA,  C_B_MAGENTA,  C_BG_MAGENTA
    global C_CYAN,     C_B_CYAN,     C_BG_CYAN

    if enable:
        C_BLACK='\033[00;30m';    C_B_BLACK='\033[01;30m';    C_BG_BLACK='\033[07;30m'
        C_WHITE='\033[00;37m';    C_B_WHITE='\033[01;37m';    C_BG_WHITE='\033[07;37m'
        C_RED='\033[00;31m';      C_B_RED='\033[01;31m';      C_BG_RED='\033[07;31m'
        C_GREEN='\033[00;32m';    C_B_GREEN='\033[01;32m';    C_BG_GREEN='\033[07;32m'
        C_YELLOW='\033[00;33m';   C_B_YELLOW='\033[01;33m';   C_BG_YELLOW='\033[07;33m'
        C_BLUE='\033[00;34m';     C_B_BLUE='\033[01;34m';     C_BG_BLUE='\033[07;34m'
        C_MAGENTA='\033[00;35m';  C_B_MAGENTA='\033[01;35m';  C_BG_MAGENTA='\033[07;35m'
        C_CYAN='\033[00;36m';     C_B_CYAN='\033[01;36m';     C_BG_CYAN='\033[07;36m'

if __name__ == "__main__":
    colour()
    #colour(False)

    print(f'{C_RED}red{C_NORMAL}')
    print(f'{C_GREEN}green{C_NORMAL}')
    print(f'{C_BLUE}blue{C_NORMAL}')
    print(f'{C_YELLOW}yellow{C_NORMAL}')
    print(f'{C_MAGENTA}MAGENTA{C_NORMAL}')
    print(f'{C_CYAN}CYAN{C_NORMAL}')
    print(f'{C_WHITE}white{C_NORMAL}')

    print(f'{C_B_RED}bold red{C_NORMAL}')
    print(f'{C_B_GREEN}bold green{C_NORMAL}')
    print(f'{C_B_BLUE}bold blue{C_NORMAL}')
    print(f'{C_B_YELLOW}bold yellow{C_NORMAL}')
    print(f'{C_B_MAGENTA}bold MAGENTA{C_NORMAL}')
    print(f'{C_B_CYAN}bold CYAN{C_NORMAL}')
    print(f'{C_B_WHITE}bold white{C_NORMAL}')

