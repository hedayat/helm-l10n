#!/bin/bash

DEFAULT_KEYWORDS="--keyword= --keyword=Name --keyword=Instance --keyword=Comment"

function help()
{
    cat <<-EOF
	Usage:
	    helm l10n [flags] [command] <chart_path>
	
	Available Commands:
	    help               This help text
	    init               Create basic structure for localization support
	    update_messages    Generate pot file and update any .po files inside po/
	    compile            Generate chart.l10n in chart's directory
	
	Flags:
	    -k string |
	    --add-keyword string    Add a custom keyword for translation strings
	    --no-default-keywords   Don't use default keywords for translation strings
	EOF
}

function init()
{
    chart=$1
    [ -z "$chart" ] && echo "ERROR: chart path parameter is required" && exit 1
    chart_name=$(basename $(realpath $1))
    if ! grep -q chart.l10n.in "$chart/.helmignore"; then
        echo chart.l10n.in >> $chart/.helmignore
        echo po/ >> $chart/.helmignore
    fi
    sed "s/CHARTNAME/$chart_name/g" $HELM_PLUGIN_DIR/l10n.yaml > $chart/templates/l10n.yaml
    sed "s/CHARTNAME/$chart_name/g" $HELM_PLUGIN_DIR/l10n-subcharts.yaml > $chart/templates/l10n-subcharts.yaml
    mkdir $chart/po 2> /dev/null || :
    if [ ! -f "$chart/chart.l10n.in" ]; then
        cat > $chart/chart.l10n.in <<-EOF
	Name=$chart_name
	Instance={{ .Release.Name }}

	#[subchart:name:instance:3]
	#Instance=the instance in {{ .Release.Name }}
	
	#[bahman:postgres]
	#Instance=Bahman subchart of postgres
	EOF
    fi
    echo "Basic l10n structure created. You can now add source strings to $chart/chart.l10n.in"
}

function update_messages()
{
    chart=$1
    [ -z "$chart" ] && echo "ERROR: chart path parameter is required" && exit 1
    chart_name=$(basename $(realpath $chart))
    echo "Generating message catalogue file: $chart/po/$chart_name.pot"
    xgettext -Ldesktop $KEYWORDS "$chart/chart.l10n.in" -o "$chart/po/$chart_name.pot"
    POFILES=$(ls "$chart/po/"*.po 2> /dev/null)
    if [ -z "$POFILES" ]; then
        echo "WARNING: No .po files found in $chart/po directory to update."
    else
        for pofile in $POFILES; do
            echo "Updating translation file: $pofile"
            msgmerge -U "$pofile" "$chart/po/$chart_name.pot"
        done
    fi
}

function compile()
{
    chart=$1
    [ -z "$chart" ] && echo "ERROR: chart path parameter is required" && exit 1
    POFILES=$(ls "$chart/po/"*.po 2> /dev/null)
    LINGUAS=()
    for pofile in $POFILES; do
        LINGUAS+=($(basename "$pofile" .po))
    done
    cat > "$chart/po/LINGUAS" <<-EOF
	# Automatically generated. Will be overwritten by 'helm l10n compile'
	${LINGUAS[*]}
	EOF
    echo "Compiling l10n strings into $chart/chart.l10n..."
    msgfmt --desktop $KEYWORDS --template "$chart/chart.l10n.in" -d "$chart/po" -o "$chart/chart.l10n"
}


TEMP=$(getopt -o "hk:" --long 'help,add-keyword:,no-default-keywords' -n 'helm l10n' -- "$@")
if [ $? -ne 0 ]; then
    exit 1
fi

eval set -- "$TEMP"
unset TEMP

while true; do
    case $1 in
        --help|-h)
            help
            exit 0
            ;;
        --add-keyword|-k)
            CUSTOM_KEYWORDS+=("--keyword=$2")
            shift 1
            ;;
        --no-default-keywords)
            DEFAULT_KEYWORDS="--keyword="
            ;;
        --)
            shift
            break
            ;;
        *)
            # Should've already failed at getopt!
            echo "ERROR: Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

KEYWORDS="$DEFAULT_KEYWORDS ${CUSTOM_KEYWORDS[*]}"
case $1 in
    help|'')
        help
        ;;
    init)
        shift
        init $@
        ;;
    update_messages)
        shift
        update_messages $@
        ;;
    compile)
        shift
        compile $@
        ;;
    *)
        echo "ERROR: Unknown command: $1"
        exit 1
        ;;
esac
