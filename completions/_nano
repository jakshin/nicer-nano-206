#compdef nano
# Zsh completions for GNU nano v2.0.6
# (Also for nano-smart-indent.sh's '--tabs' option)

local whence_nano="$(whence -c nano)"
if [[ $whence_nano == *"nano-smart-indent"* ||
	(-L $whence_nano && "$(readlink "$whence_nano")" == *"nano-smart-indent.sh"*) ]]
then
	local nano_smart_indent_opts='--tabs[Tabs are the one true indentation character]'
else
	unset nano_smart_indent_opts
fi

_arguments -s -S : \
	'(- *)'{-h,--help}'[Show help text and exit]' \
	'(- *)'{-V,--version}'[Print version information and exit]' \
	{-A,--smarthome}'[A smart Home key is a happy Home key]' \
	{-B,--backup}'[Back up existing files before saving]' \
	{-C+,--backupdir=}'[Set directory for saving backup files]:dir:_dirs' \
	{-D,--boldtext}'[Use bold instead of reverse video text]' \
	{-E,--tabstospaces}'[Convert typed tabs to spaces]' \
	{-F,--multibuffer}'[Enable multiple file buffers]' \
	{-H,--historylog}'[Log & read search/replace string history]' \
	{-I,--ignorercfiles}'[Ignore nanorc files]' \
	{-K,--rebindkeypad}'[Fix numeric keypad key confusion problem]' \
	{-L,--nonewlines}'[Do not add newlines to the ends of files]' \
	{-N,--noconvert}'[Do not convert files from DOS/Mac format]' \
	{-O,--morespace}'[Use one more line for editing]' \
	{-Q+,--quotestr=}'[Set quoting string]:str' \
	{-R,--restricted}'[Restricted mode]' \
	{-S,--smooth}'[Smooth scrolling]' \
	{-T+,--tabsize=}'[Set width of a tab (number of columns)]' \
	{-U,--quickblank}'[Use quick statusbar blanking]' \
	{-W,--wordbounds}'[Detect word boundaries more accurately]' \
	{-Y+,--syntax=}'[Set syntax definition to use for coloring]' \
	{-c,--const}'[Constantly show cursor position]' \
	{-d,--rebinddelete}'[Fix Backspace/Delete confusion problem]' \
	{-i,--autoindent}'[Indent new lines automatically]' \
	{-k,--cut}'[Cut from cursor to end of line]' \
	{-l,--nofollow}'[Do not follow symbolic links, overwrite]' \
	{-m,--mouse}'[Enable the use of the mouse]' \
	{-n,--noread}'[Do not read the file (only write it)]' \
	{-o+,--operatingdir=}'[Set operating directory]:dir:_dirs' \
	{-p,--preserve}'[Preserve XON (^Q) and XOFF (^S) keys]' \
	{-r+,--fill=}'[Set wrapping point (number of columns)]' \
	{-s+,--speller=}'[Set alternate spell-checker]:prog' \
	{-t,--tempfile}'[Auto save on exit, without prompting]' \
	{-v,--view}'[View mode (read-only)]' \
	{-w,--nowrap}'[Do not hard-wrap long lines]' \
	{-x,--nohelp}'[Do not show the two help lines]' \
	{-z,--suspend}'[Enable suspension with ^Z]' \
	$nano_smart_indent_opts \
	"*:file:_files"
