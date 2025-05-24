# shellcheck disable=SC2148
# kaiju functions
#

# die [what]
die () {
    _errc=$?
    if [ -n "$1" ]; then
        echo ">>> $1 failed ($_errc)"
    fi
    exit $_errc
}

fetch_freebsd_ports() {
    if [ ! -d "freebsd-ports" ]; then
        mkdir freebsd-ports || die
        git clone https://github.com/freebsd/freebsd-ports.git freebsd-ports || die "clone FreeBSD-ports"
    else
        cd freebsd-ports || die
        git pull || die "FreeBSD-ports update: "
        cd ..
    fi
}

# electron versions from freebsd-ports
get_value() {
    cat freebsd-ports/devel/$2/Makefile.version \
        freebsd-ports/devel/$2/Makefile \
        | sed -n "s|^$1=[[:space:]]*\(.*\)|\1|p"
}

# sub folder of chromium release 
get_urlsf_chr() {
    cat freebsd-ports/devel/$1/Makefile \
        | sed -n "s|.*download/v\(.*\)/:chromium.*|\1|p"
}
