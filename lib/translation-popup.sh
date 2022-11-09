#!/usr/bin/env bash
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

scriptDir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
scriptName="$(basename "${BASH_SOURCE[0]}")"
tmpDir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename "$0").XXXXXX")
defaultInput="ocr"
defaultOutput="kitty"
defaultFromLang="zh-CN"
defaultToLang="en"
xwinClass="translation-popup"

kittyFontSize=16

usage() {
  cat <<EOF
Usage: $0 [-hvioft]

This shell script facilitates fast machine translation of on-screen text.

Options:
  -h, --help            Print this help and exit.
  -v, --verbose         Enable verbose mode.
  -i, --input=INPUT     Input method [default: $defaultInput].
  -o, --output=OUTPUT   Output method [default: $defaultOutput].
  -f, --from-lang=LANG  Input language [default: $defaultFromLang].
  -t, --to-lang=LANG    Output language [default: $defaultToLang].

Input methods:
  ocr        Draw a rectangle on the screen and translate text in that area.
  clipboard  Translate the contents of the clipboard.
  selection  Translate the selected text.
  stdin      Translate STDIN.

Output methods:
  kitty   Show the translated text in a kitty window.
  stdout  Write tranlated text to STDOUT.
EOF
  exit
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    [ -n "$tmpDir" ] && rm -rf "$tmpDir"
}

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m'
        ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m'
        CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE=''
        BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    msg "$msg"
    exit "$code"
}

opts() {
    getopt -n "$scriptName" \
           -o hvi:o:f:t: \
           -l help,verbose,input:,output:,from-lang:,to-lang: \
           -- "$@"
}

parse_params() {
    eval set -- "$(opts "$@")"

    input="$defaultInput"
    output="$defaultOutput"
    fromLang="$defaultFromLang"
    toLang="$defaultToLang"

    while :; do
        case "${1-}" in
            -h | --help) usage ;;
            -v | --verbose) set -x ;;
            -i | --input) input="$2"; shift ;;
            -o | --output) output="$2"; shift ;;
            -f | --from-lang) fromLang="$2"; shift ;;
            -t | --to-lang) toLang="$2"; shift ;;
            --) shift; break ;;
            -?*) die "Unknown option: $1" ;;
            *) break ;;
        esac
        shift
    done

    args=("$@")

    return 0
}

parse_params "$@"
setup_colors


grabScreenRegionPng() {
    flameshot gui --accept-on-select --raw > "$tmpDir/screen-region.png"
    echo "$tmpDir/screen-region.png"
}

translateText() {
    trans -from "$fromLang" \
          -to "$toLang" \
          -join-sentence \
          -show-languages n \
          -show-original y \
          -show-translation n \
          -speak \
          -player mpv
}

ocrImage() {
    local lang="$(translateShellLangToTesseractLang "$fromLang")"
    local imgPath="$1"
    tesseract -l "$lang" "$imgPath" stdout | tidyUpOcrText
}

tidyUpOcrText() {
    tr "\n" ' '
}

getXClipboard() {
    xclip -selection "$1" -o
}

kittyWindowTranslate() {
    cat > "$tmpDir/input.txt"
    kitty --hold \
          --class "$xwinClass" \
          --title "$(kittyWindowTitle)" \
          -o font_size="$kittyFontSize" \
          sh -c "'$scriptName' -i stdin -o stdout < '$tmpDir/input.txt'"
}

kittyWindowTitle() {
    printf "Translate %s → %s (%s)" "$fromLang" "$toLang" "$input"
}

translateShellLangToTesseractLang() {
    case "$1" in
        af) echo afr ;;
        sq) echo sqi ;;
        am) echo amh ;;
        ar) echo ara ;;
        as) echo asm ;;
        az) echo aze ;;
        eu) echo eus ;;
        be) echo bel ;;
        bn) echo ben ;;
        bs) echo bos ;;
        bg) echo bul ;;
        ca) echo cat ;;
        ceb) echo ceb ;;
        zh-CN) echo chi_sim ;;
        zh-TW) echo chi_tra ;;
        hr) echo hrv ;;
        cs) echo ces ;;
        da) echo dan ;;
        nl) echo nld ;;
        en) echo eng ;;
        eo) echo epo ;;
        et) echo est ;;
        fi) echo fin ;;
        fr) echo fra ;;
        gl) echo glg ;;
        ka) echo kat ;;
        de) echo deu ;;
        el) echo ell ;;
        gu) echo guj ;;
        ht) echo hat ;;
        he) echo heb ;;
        hi) echo hin ;;
        hu) echo hun ;;
        is) echo isl ;;
        id) echo ind ;;
        iu) echo iku ;;
        ga) echo gle ;;
        it) echo ita ;;
        ja) echo jpn ;;
        jv) echo jav ;;
        kn) echo kan ;;
        kk) echo kaz ;;
        km) echo khm ;;
        ko) echo kor ;;
        ku) echo kur ;;
        lo) echo lao ;;
        la) echo lat ;;
        lv) echo lav ;;
        lt) echo lit ;;
        mk) echo mkd ;;
        ms) echo msa ;;
        ml) echo mal ;;
        mt) echo mlt ;;
        mr) echo mar ;;
        my) echo mya ;;
        ne) echo nep ;;
        no) echo nor ;;
        fa) echo fas ;;
        pl) echo pol ;;
        pt-BR) echo por ;;
        pt-PT) echo por ;;
        pa) echo pan ;;
        ro) echo ron ;;
        ru) echo rus ;;
        sa) echo san ;;
        sr-Cyrl) echo srp ;;
        sr-Latn) echo srp_latn ;;
        si) echo sin ;;
        sk) echo slk ;;
        sl) echo slv ;;
        es) echo spa ;;
        sw) echo swa ;;
        sv) echo swe ;;
        tg) echo tgk ;;
        ta) echo tam ;;
        te) echo tel ;;
        th) echo tha ;;
        bo) echo bod ;;
        ti) echo tir ;;
        tr) echo tur ;;
        uk) echo ukr ;;
        ur) echo urd ;;
        ug) echo uig ;;
        uz) echo uzb ;;
        vi) echo vie ;;
        cy) echo cym ;;
        yi) echo yid ;;
        *) die "Unsupported language: $1" ;;
    esac
}

# script logic here
text=""
case "$input" in
    ocr)
        tmpFile="$(grabScreenRegionPng)"
        text="$(ocrImage "$tmpFile")"
        ;;
    clipboard) text="$(getXClipboard clipboard)" ;;
    selection) text="$(getXClipboard primary)" ;;
    stdin) text="$(</dev/stdin)" ;;
    *) die "Unknown input: $1" ;;
esac

case "$output" in
    kitty) kittyWindowTranslate <<< "$text" ;;
    stdout) translateText <<< "$text" ;;
    *) die "Unknown output: $1" ;;
esac
