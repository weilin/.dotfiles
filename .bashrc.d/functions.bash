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



