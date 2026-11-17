function findmk()
{
	if ! [ -d $1 ] || [ "$2" == "" ]
	then
		echo "usage: $0 DIR PATTERN"
		return 255
	fi
	SEARCH_DIR=$1
	shift
	find $SEARCH_DIR -type f -name Makefile -or -name \*.mk |xargs grep "$@"
}

function make_cs()
{
	find -type f -name \*.cpp -or -name \*.[chsS] > cscope.files
}

function show_epop_dim()
{
	file *.png  |tr -s ' ' |cut -d ' ' -f1,5,6,7 |tr -d ' ,' |sed -e 's/:/:\t/g'
}

function p4log()
{
	p4 changes "$1" |awk '{print $2}' |xargs -i p4 describe -du {} |less -F
}

function find_epop()
{
	find -type f -name \*.png |sort 
}

function openfile_gui()
{
	nautilus $1 2>&1 >/dev/null &
}

function p4sync()
{
	CNT=-0
	while [ $CNT -lt 10 ];
	do
		CNT=$((CNT+1))
		echo CNT=$CNT
		p4 sync $@
		if [ "$?" == "0" ]
		then
			break;
		fi
	done
}


function edid_diff()
{
	file1=$1
	file2=$2

	if ! [ -f $file1 ]
	then
		echo "$file1 is not a file!"
		return -1
	fi

	if ! [ -f $file2 ]
	then
		echo "$file2 is not a file!"
		return -1
	fi
	
	#vimdiff <(edid-decode $file1)   <(edid-decode $file2)
	icdiff <(edid-decode $file1)   <(edid-decode $file2)
}

function edid_vimdiff()
{
	file1=$1
	file2=$2

	if ! [ -f $file1 ]
	then
		echo "$file1 is not a file!"
		return -1
	fi

	if ! [ -f $file2 ]
	then
		echo "$file2 is not a file!"
		return -1
	fi
	
	vimdiff <(edid-decode $file1)   <(edid-decode $file2)
	#icdiff <(edid-decode $file1)   <(edid-decode $file2)
}

function curlo()
{
  echo curl -O --cookie ~/cookies.txt $@
  curl -O --cookie ~/cookies.txt $@
}

function du1()
{
  du --max-depth=1 -h
}


function md5_diff()
{
	md5sum $1
	md5sum $2
	echo "$(md5sum $1 |cut -d ' ' -f 1) $2" |md5sum -c -
}


function repo_manifest()
{
	cat  .repo/manifests/default.xml  |grep groups | sed -e "s/.*groups=\(\"[^\"]*\"\).*/\1/g" |sort|uniq
}

# Extract into an archive-named directory under PARENT_DIR (default: current directory).
# Example: extract_archive /path/to/AAA.tar.gz /output  ->  /output/AAA/
extract_archive() {
    if (( $# < 1 || $# > 2 )); then
        printf 'Usage: extract_archive ARCHIVE_FILE [PARENT_DIR]\n' >&2
        return 2
    fi

    local archive=$1
    local archive_name=${archive##*/}
    local parent=${2:-.}
    local lower_name suffix format extractor stem answer destination

    if [[ $archive != /* ]]; then
        archive=./$archive
    fi
    if [[ $parent != /* && $parent != . && $parent != ./* ]]; then
        parent=./$parent
    fi

    if [[ ! -f $archive ]]; then
        printf 'Error: file not found: %s\n' "$archive" >&2
        return 1
    fi

    lower_name=${archive_name,,}
    case $lower_name in
        *.tar.gz)  suffix=.tar.gz;  format=tar ;;
        *.tar.bz2) suffix=.tar.bz2; format=tar ;;
        *.tar.xz)  suffix=.tar.xz;  format=tar ;;
        *.tar.zst) suffix=.tar.zst; format=tar ;;
        *.tgz)     suffix=.tgz;     format=tar ;;
        *.tbz2)    suffix=.tbz2;    format=tar ;;
        *.tbz)     suffix=.tbz;     format=tar ;;
        *.txz)     suffix=.txz;     format=tar ;;
        *.tzst)    suffix=.tzst;    format=tar ;;
        *.tar)     suffix=.tar;     format=tar ;;
        *.zip)     suffix=.zip;     format=zip ;;
        *.7z)      suffix=.7z;      format=7z ;;
        *.rar)     suffix=.rar;     format=rar ;;
        *)
            printf 'Error: unsupported archive format: %s\n' "$archive" >&2
            return 1
            ;;
    esac

    stem=${archive_name:0:${#archive_name}-${#suffix}}
    if [[ -z $stem ]]; then
        printf 'Error: archive filename must have a name before its extension\n' >&2
        return 1
    fi
    destination=$parent/$stem

    if command -v bsdtar >/dev/null 2>&1; then
        extractor=bsdtar
    else
        case $format in
            zip)
                command -v unzip >/dev/null 2>&1 && extractor=unzip
                ;;
            tar)
                command -v tar >/dev/null 2>&1 && extractor=tar
                ;;
            7z)
                if command -v 7zz >/dev/null 2>&1; then
                    extractor=7zz
                elif command -v 7z >/dev/null 2>&1; then
                    extractor=7z
                fi
                ;;
            rar)
                if command -v unrar >/dev/null 2>&1; then
                    extractor=unrar
                elif command -v 7zz >/dev/null 2>&1; then
                    extractor=7zz
                elif command -v 7z >/dev/null 2>&1; then
                    extractor=7z
                fi
                ;;
        esac
    fi

    if [[ -z $extractor ]]; then
        printf 'Error: no installed extraction tool supports %s archives\n' "$format" >&2
        return 1
    fi

    if [[ -e $destination || -L $destination ]]; then
        read -r -p "Destination '$destination' exists. Remove it and extract again? [y/N] " answer
        if [[ $answer != [yY] ]]; then
            printf 'Cancelled; destination was not changed.\n'
            return 0
        fi
        rm -rf -- "$destination" || return
    fi

    mkdir -p -- "$destination" || return
    printf 'Extracting with %s...\n' "$extractor"
    case $extractor in
        bsdtar) bsdtar -xf "$archive" -C "$destination" ;;
        unzip)  unzip -- "$archive" -d "$destination" ;;
        tar)    tar -xf "$archive" -C "$destination" ;;
        7z|7zz) "$extractor" x -y "-o$destination" -- "$archive" ;;
        unrar)  unrar x -idq -o+ "$archive" "$destination/" ;;
    esac
    if (( $? == 0 )); then
        printf 'Extracted to: %s\n' "$destination"
    else
        printf 'Error: extraction failed; partial output may remain in %s\n' "$destination" >&2
        return 1
    fi
}

# Backward-compatible name for existing usage.
extract_zip() {
    extract_archive "$@"
}

# Download a Box shared archive, verify it, and extract into an archive-named folder.
# Example: box_extract https://clover.box.com/s/SHARED_LINK /output
box_extract() {
    if (( $# < 1 || $# > 2 )); then
        printf 'Usage: box_extract SHARED_URL [PARENT_DIR]\n' >&2
        return 2
    fi

    local dependency metadata name file_id expected_size expected_sha1
    local parent=${2:-.} lower_name suffix candidate stem destination archive
    local kind='Generic archive' stage staged_file actual_size actual_sha1
    local version_pattern='^(.+)-(eng|userdebug|user)-([0-9]+\.[0-9]+\.[0-9]+)\.zip$'
    local -a details

    for dependency in box jq sha1sum extract_archive; do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            printf 'Error: required command is unavailable: %s\n' "$dependency" >&2
            return 1
        fi
    done

    if ! metadata=$(box shared-links:get "$1" --json --fields type,id,name,size,sha1,permissions); then
        printf 'Error: could not resolve the Box shared file; check CLI authentication and access.\n' >&2
        return 1
    fi
    if ! jq -e '
        type == "object" and .type == "file" and .permissions.can_download == true
        and (.id | type == "string" and test("^[0-9]+$"))
        and (.name | type == "string" and length > 0 and (explode | all(. > 31 and . != 127)))
        and (.size | type == "number" and . > 0 and floor == .)
        and (.sha1 | type == "string" and test("^[0-9a-fA-F]{40}$"))
    ' <<< "$metadata" >/dev/null 2>&1; then
        printf 'Error: expected a downloadable Box file with valid name, size, and SHA1 metadata.\n' >&2
        return 1
    fi
    name=$(jq -r '.name' <<< "$metadata") || return 1
    if [[ $name == */* || $name == *\\* || $name == *[[:cntrl:]]* ]]; then
        printf 'Error: Box returned an unsafe filename.\n' >&2
        return 1
    fi
    mapfile -t details < <(jq -r '.id, .size, .sha1' <<< "$metadata")
    file_id=${details[0]}
    expected_size=${details[1]}
    expected_sha1=${details[2],,}

    lower_name=${name,,}
    suffix=
    for candidate in .tar.gz .tar.bz2 .tar.xz .tar.zst .tgz .tbz2 .tbz .txz .tzst .tar .zip .7z .rar; do
        if [[ $lower_name == *"$candidate" ]]; then
            suffix=$candidate
            break
        fi
    done
    if [[ -z $suffix ]]; then
        printf 'Error: unsupported archive format: %s\n' "$name" >&2
        return 1
    fi
    stem=${name:0:${#name}-${#suffix}}
    if [[ -z $stem || $stem == . || $stem == .. ]]; then
        printf 'Error: archive filename has no usable folder name.\n' >&2
        return 1
    fi

    case $lower_name in
        kernel-debug-*)    kind='Kernel debug package' ;;
        full-ota-*)        kind='Full OTA package' ;;
        target_files-*)    kind='Target files package' ;;
        symbols-*)         kind='Symbols package' ;;
        clover-*)          kind='Clover ROM bundle' ;;
        mfg-*)             kind='Manufacturing bundle' ;;
        static_analysis.zip) kind='Static analysis package' ;;
    esac
    printf 'File: %s\nType: %s\n' "$name" "$kind"
    if [[ $kind != 'Generic archive' && $lower_name =~ $version_pattern ]]; then
        printf 'Build: %s\nVersion: %s\n' "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
    fi

    if [[ $parent != /* ]]; then
        parent=./$parent
    fi
    mkdir -p -- "$parent" || return 1
    parent=$(cd -- "$parent" && pwd -P) || return 1
    archive=$parent/$name
    destination=$parent/$stem
    if [[ -e $archive || -L $archive || -e $destination || -L $destination ]]; then
        printf 'Error: archive or extraction folder already exists in %s; choose another parent directory.\n' "$parent" >&2
        return 1
    fi
    stage=$(mktemp -d -- "$parent/.box-extract.XXXXXXXX") || return 1
    staged_file=$stage/$name
    if ! box files:download "$file_id" --destination "$stage" --save-as "$name" --no-overwrite; then
        printf 'Error: Box download failed; check direct file access. Staging directory retained: %s\n' "$stage" >&2
        return 1
    fi
    if [[ ! -f $staged_file || -L $staged_file ]]; then
        printf 'Error: Box did not produce a regular archive. Staging directory retained: %s\n' "$stage" >&2
        return 1
    fi
    actual_size=$(stat -c %s -- "$staged_file") || return 1
    actual_sha1=$(sha1sum -- "$staged_file") || return 1
    actual_sha1=${actual_sha1%% *}
    if [[ $actual_size != "$expected_size" || $actual_sha1 != "$expected_sha1" ]]; then
        printf 'Error: archive size or SHA1 mismatch. Staging directory retained: %s\n' "$stage" >&2
        return 1
    fi

    # Publish without overwriting a file created while the download was running.
    if ! ln -T -- "$staged_file" "$archive"; then
        printf 'Error: could not retain the verified archive. Staging directory retained: %s\n' "$stage" >&2
        return 1
    fi
    rm -- "$staged_file" && rmdir -- "$stage" || return 1
    printf 'Verified archive: %s\n' "$archive"
    if [[ -e $destination || -L $destination ]]; then
        printf 'Error: extraction folder now exists: %s\n' "$destination" >&2
        return 1
    fi
    # Never answer the existing extractor's replacement prompt in this workflow.
    extract_archive "$archive" "$parent" < /dev/null
}
