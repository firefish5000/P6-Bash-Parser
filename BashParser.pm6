#!/usr/bin/perl6
use v6;
use BC::Debug::Color;
$BC::Debug::Color::DebugLevel=1;
################
# Project Goal #
# To automaticly create rtcwake events for every Cron Job.
#######################
# Implimantation Goal #
# Create an RTC wake event for the next CronJob occuring in 10min+
# By default, Set RTC wake event for 5min prior to CronJob execution time.
# On Wake, Imediantly create the RTCwake event for the next job that meats the criteria.
# Check Every 5min to see if cronfile has changed and update events(create a hook to notify us if possible)
# Allow the user to specify weather to create RTC wake events, both by default, and on individual jobs.
# Check to see if cron has a &wake(1) or similar command once done. (put your hard work to waste)
###############
# SubProjects #
# CronParser, a potentialy usefull Cron:: Grammar && Actions implimentation;
#########
# State #
# Unusable, no support garenty. Future versions will break this and no there will be no backwards compatibility until API version 0.0.1
# The API uses the following naming convention. <Complete Rewrite>.<Incompatible Changes>.<Compatible Changes> [Some testing/development tag/number]?
# For now our API and version is 0.0.0 and our code is broken.
# Other Thoughts:
# I need spell checking for vim or a some other good editor for perl6. (padre was crashing)
# Vim's syntax highlighting is AWFULY SLOW for perl6.

=begin comment
grammar Bash::PROMPT::Grammar { # The best guess for Bash::Prompt
	token Unparse { # Short for Unparsable. NOTE This should only be used durring testing, Never published ## Probably should eat the rest of the Input..
		(\N+) .* {Err "FAILED TO PARSE--<<$0>>"}
	}

	token Word { # Should IsA#Comment? be a word? (Probably, as it is in bash)
		[  <Literal>
		|| <Quote>
		|| <-[#]> & \S]+
	}
	token Literal { # FIXME Escaped whitspaces(including newlines) should be ignored, not taken literaly. (May need to be implimented elsewear).
		\\ \N
	}
	token Escape { # FIXME Escaped whitspaces(including newlines) should be ignored, not taken literaly. (May need to be implimented elsewear).
		\\
		[	  a alarm
			| d darw WeekdayAbrv Month dom
			| D\{.+\} strftime bracedseq
			| e ASCII escape
			| h	${HOSTNAME} ~~ s/\. .* $ //
			| H ${HOSTNAME}
			| j ${num of jobs}
			| l	
			| n "\n"
			| r "\r"
			| s basename ${SHELL} 
			| t time HH:MM:SS
			| T time HH:MM:SS         (12hr, no am/pm)
			| '@' time HH:MM:SS am/pm (12hr, am/pm)
			| A time HH:MM
			| u	${USER}
			| v ${BASH_VERSION} m{^\d+.\d+}
			| V	${BASH_VERSION}
			| w ${PROMPT_DIRTRIM}
			| W	basename ${PROMPT_DIRTRIM} || basename cwd, if cwd==${HOME} return '~'
			| '!' histnum this
			| '#' cmdnum this
			| '$' if ${EUID} == 0 { return '#' } else { return '$' }
			| \d{3} return octle
			| '[' bein contol seq
			| ']' end controle seq
		]
	}
	token Exec { # FIXME? Match unclosed quotes to EOF?
		# FIXME Escaped Closure for <">. ie " \" " should work as expected ( '\' stays the same ). Try [ <Literal> || <-[\"]> ]*
		  \` <-[\`]>* \` # backtics
		  | '$(' BASHING ')'
	}
	token Quote { # FIXME? Match unclosed quotes to EOF?
		# FIXME Escaped Closure for <">. ie " \" " should work as expected ( '\' stays the same ). Try [ <Literal> || <-[\"]> ]*
		  \' <-[\']>* \'
		| \"   [<Literal> || <-[\"]>]*   \" 
	}

	token Var { # FIXME % is not a var, but a Non-clasic CronJob format. CronVar should probably handle things like mail(no) after \&. 
		( <[ \! \% ]> <Word>)
	}
	token CronArg { # I dont think \& should be  part of the CronArg. (What is CronArg Anyway) What succeeds \& should be a CronVar or the like. 
		(  \&  <Word>?) 
	}
	token CronJob {
		 <CronArg> \h+ <CronTime> \h+  <Cmd> 
	}
	
	# TODO token User { ... }
	token Cmd {
		<Word> [\h+<Word>]+
	}
	token Comment { 
		'#' (\N*)
	}
		
	
	rule TOP {
		[ <Comment> 
		|| [ <CronJob>||<CronVar> ] \h* \n? 
		|| <Unparse> ]+
	#	[[  <Comment>
	##	|| <CronJob> <Comment>?
	#	|| <CronVar>
	#	|| <Unparse>
	#	] \h* \n? ]+
	}
}
=end comment
grammar Bash::Grammar { # The Best guess BashEvaluater
	token Unparse { # Short for Unparsable. NOTE This should only be used durring testing, Never published ## Probably should eat the rest of the Input..
		(\N+) .* {Err "FAILED TO PARSE--<<$0>>"}
	}
	token Shell_Variable {
		BASH
		BASHOPTS
		BASHPID
		BASH_ALIASES
		BASH_ARGC
		BASH_ARGV
		BASH_CMDS
		BASH_COMMAND
		BASH_EXECUTION_STRING
		BASH_LINENO
		BASH_REMATCH
		BASH_SOURCE
		BASH_SUBSHELL
		BASH_VERSINFO
			BASH_VERSINFO[0]
			BASH_VERSINFO[1]
			BASH_VERSINFO[2]
			BASH_VERSINFO[3]
			BASH_VERSINFO[4]
			BASH_VERSINFO[5]
		BASH_VERSION
		COMP_CWORD
		COMP_KEY
		COMP_LINE
		COMP_POINT
		COMP_TYPE
		COMP_WORDBREAKS
		COMP_WORDS
		COPROC
		DIRSTACK
		EUID
		FUNCNAME
		GROUPS
		HISTCMD
		HOSTNAME
		HOSTTYPE
		LINENO
		MACHTYPE
		MAPFILE
		OLDPWD
		OPTARG
		OPTIND
		OSTYPE
		PIPESTATUS
		PPID
		PWD
		RANDOM
		READLINE_LINE
		READLINE_POINT
		REPLY
		SECONDS
		SHELLOPTS
		SHLVL
		UID
		BASH_ENV
		BASH_XTRACEFD
		CDPATH
		COLUMNS
		COMPREPLY
		EMACS
		ENV
		FCEDIT
		FIGNORE
		FUNCNEST
		GLOBIGNORE
		HISTCONTROL
		HISTFILE
		HISTFILESIZE
		HISTIGNORE
		HISTSIZE
		HISTTIMEFORMAT
		HOME
		HOSTFILE
		IFS
		IGNOREEOF
		INPUTRC
		LANG
		LC_ALL
		LC_COLLATE
		LC_CTYPE
		LC_MESSAGES
		LC_NUMERIC
		LINES 
		MAIL
		MAILCHECK
		MAILPATH
		OPTERR
		PATH
		POSIXLY_CORRECT
		PROMPT_COMMAND
		PROMPT_DIRTRIM
		PS1
		PS2
		PS3
		PS4
		SHELL
		TIMEFORMAT
		TMOUT
		TMPDIR
		auto_resume
		histchars
	}
	
	###DEFINITIONS
	token Blank { # wird Sep
		' ' | "\t"
	}
	token ws { # So rule works properly
		<.Blank>
	}
	token Comment { # a Word begining with a '#'
		'#' (\N*) [ \n | $ ]
	}
	token Literal { # TODO Escapd Newlines are nullified
		\\ \N
	}
	token Escape {
		\\ \n			# Newline is nullified
		|| <Literal>	# All others are Literal
	}
	token Word { # Also Called 'token' in bash (according to man) Comments are words
		# Matches the chars undiliminated, so word_1<Othr_Word2 would get 'word_1'
		# We look for literals, not Escape because escape would make hellow\\\nworld be one word (when its really 2 words on one line)
		# NOT A COMMENT && 
		[  <Literal>
		|| <Quote>
		#|| <-[#]> & \S]+
		|| <Name>
		|| <-MetaChar> ]+
	}
	token Name {
		<[\_ a..zA..Z0..9]>+ # a-Z0-9 or Underscore 
	}
	token MetaChar { # A character that, when unquoted, separates words.
		'|'
		| '&' | ';' 
		| '(' | ')'
		| '<' | '>'
		| ' ' | "\t"
		| "\n" # I added this, because Word should be deliminated by newline as well.
	}
	token Control_OP {
		'||' 
		| '&' | '&&' 
		| ';' | ';;' 
		| '(' | ')' 
		| '{' | '}' 
		| '|' | '|&' 
		| "\n"
	}
	###RESERVED########
	token Reserved_Word {
		case | select | esac 
		| for | in | until | while | do | done 
		| if | elif | else | then | fi 
		| function | time 
		| '!' | '{' | '}'  '[[' ']]'
	}
	###GRAMAR##########
	token WordB {
		<Word> <.Blank>+
	}
	token BWord {
		<.Blank>+ <Word>
	}
	token Command { # An actual command
	# Command Resolve Order: Functions:Builtins:PATH
		<.ws>*
		[<Set_Var> <.ws>+]* 
		[<!before <Control_OP>[<ws>|\n|$$]> <Word> ]# Command
		[<.ws>+ <Word> ]* # Args
		[<.ws>+ <Redirects>]*
		<.ws>* <Control_OP>
	}
	token Simple_Command { # I doubt its simplicity. Single Command would be better
	# Command Resolve Order: Functions:Builtins:PATH
		<.ws>*
		[<Set_Var> <.ws>+]* 
		[<!before <Control_OP>[<ws>|\n|$$]> <Word> ]# Command
		[<.ws>+ <Word> ]* # Args
		[<.ws>+ <Redirects>]*
		<.ws>* <Control_OP>
	}
	token Pipeline { # '|' = cmd1out -> cmd2in; '|&' =  cmd1outerr -> cmd2in
		<Simple_Command> [ '|&' | '|' ]?
	}
	token List { # One line worth of commands
		[<Pipeline> [ \; | \& | '&&' | '||' | "\n"] ]*
		<Pipeline> [ \; | \& | "\n" ]?
		# TODO terminated by ';' '&' \n
		# NOTE && || have equal preced, ';' '&' are lower, 
		# NOTE List should probably be broken down to 'Sets', 
		# which I define as a list of interdependet commands.
		# made of pipleines and'&&' '||'. Sets are seperated by ';' and '&'
	}
	token Block {	# Any number of commands which are parsable
		<TOP> # FIXME TOP eats or ContClose's, wich is problematic since we dont backtrack...
	}
	token ContClose { [ [';' | "\n"] || <after [';' | "\n" ]>] [<.Blank>|\n]* }
	token Compound_Command {
		<.ws>* [
		  '(' <Block> ')'
		| '{' <Block> <?ContClose><ContClose>?  '}'
		| '((' <Arithmic_Expression> '))'
		# Word splitting and pathname expansion are not performed on the words between the [[ and ]]; tilde expansion is.
		# can be combined by (<expr>) !<expr> &&<expr> ||<expr>
		| '[[' <Conditional_Expression> ']]'
		#| 
		| for <Name> in <Word>+ <ContClose>
			do <Block> <ContClose>
			done
		| for ((<Arithmic_Expression>? <ContClose> <Arithmic_Expression>? <ContClose> <Arithmic_Expression>?)) <ContClose>
			do <Block> <ContClose>
			done
		| select <Name> in <Word> <ContClose>
			do <Block> <ContClose>
			done
		| case <Word> in [
			<Pattern> [ '|' <Pattern>]* ')'
				<Block>
				';;'
			]*
		| if <List> <ContClose>
			then <Block> <ContClose> 
			[ elif <List> <ContClose>
				then <Block> <ContClose> ]*
			[else <Block> <ContClose>]?
			fi
		| while <List> <ContClose>
			do <Block> <ContClose>
			done
		| until <List> <ContClose>
			do <Block> <ContClose>
			done
		]
	}
	token Coprocess {
		...# TODO coproc
	}
	token Function {
		<Name> \s* '()' \s+ <Compound_Command> \s* <Redirects>?
		| function \s+ <Name> \s* '()'? \s+ <Compound_Command> \s* <Redirects>?
	}
	# Comment Token { Word bebining with # } , unless interactive with interactive comments disabled
	token Quote {
		<Escape>
		|<Sing_Quote>
		|<Double_Quote>
	}
	token Sing_Quote {
		\$\' <-[\']>  \' # TODO ANSI C backslash-escape
		| \' <-[\']>* \'
	}
	token Double_Quote {
		\" [
			# NOTE Moarvm FAILED to do LongestTokenMatching with '|'. It matched 
			# '\' via | <-[\"]> and then checked <Escape> with the '\' alreay matched (yielding Escape useless)
			# It should check both from the SAME POSITION. (wonder if this error is due to implicit threading, in which case)
			# $/.pos is probably a reference instead of a copy.
			<Escape> 
			|| <-[\"]>
		]*
		\"
	}
	###PARAMETERS######
	token Parameter {
		. {Wrn "NYI <<{$/}>>"} & '' # a char with no legth (should fail, mostly..)
	}
	token Value {
		<Word> 
		|<Expansion>
	}
	token Value {
		'(' <Word>* ')'
		|<Word>
		|<Word>|
	}
	token Set_Var { # BASHNAME Variable_Assign
		<Name> '=' <Value>?
	}
	token Special_Parameter {
		'*'
		| '@'
		| '#'
		| '?'
		| '-'
		| '$'
		| '!'
		| '0'
		| '_'
	}
token Array_Assighn {
		<Name> '=' (<Values>)
		<Name> '[' <Subscript> ']' '=' <Value>
		# Values == [[<subscript>=]<Value>]*
	}
	token Array_Get {
		'${' <Name> '[' <Subscript> ']}'
		| '${' <Name> '[@]}'
		| '${' <Name> '[*]}'
		| '${#' <Name> '[' <Subscript> ']}'
	}
	###EXPANSION#######
	token Expansion {
		[ <Brace_Expansion>
		|| <Tilde_Expansion>
		|| <Parameter>
		|| <Variable>
		|| <Arithmetic_Expansion>
		|| <Command_Substitution> ]
	}
	token Brace_Expansion {
		<Preamble>? '{' [<String> ',']+ <String> '}' <Postscript>?  # needs a string list of 2 or more
		| <Preamble>? '{' <String> '..' <String>  ['..' <Int> ]? '}' <Postscript>?  # needs a string list of 2 or more
	}
	token Tidle_Expansion {
		'~' <LoginName>
		'~' '+'
		'~' '-'
		'~' '-' <Int>
		'~' '+'? <Int>
	}
	token Parameter_Expansion {
		'${'#{TODO Par Expan} '}'
		|'${' <Name> [
				':-' <Word>
				|':=' <Word>
				|':?' <Word>
				|':+' <Word>
				|':' <offset>
				|':' <offset> ':' <length>
			]
		'}'
		| '${' '!' <Name_prefix> ['*'|'@'] '}'	# List of varnames begining with name_prefix
		| '${' '!' <Name> ['*'|'@'] '}'			# List of keys in Array
		| '${' '#' <Name> '}'			# Array Length
		| '${' <Name> '#' <Word> '}'
		| '${' <Name> '##' <Word> '}'
		| '${' <Name> '%' <Word> '}'
		| '${' <Name> '%%' <Word> '}'
		| '${' <Name> '/' <Pattern> '/' <String> '}'
		| '${' <Name> '^' <Pattern> '}'
		| '${' <Name> '^^' <Pattern> '}'
		| '${' <Name> ',' <Pattern> '}'
		| '${' <Name> ',,' <Pattern> '}'
	}
	token Command_Substitution { # Deletes trailing newlines from output
		'$(' <Block> ')' # TODO Easy nesting
		\` <List> \` # TODO Literal? (may work already)
	}
	token Arithmetic_Expansion {
		'$(('
			<Arithmetic_Expression>
		'))'
	}
	token Process_Substitution {
		'<(' <List> ')'
		| '>(' <List> ')'
	}
#	token Word_Splitting {
#		# TODO
#	}
#	token Pathname_Expansion {
#		# TODO
#	}
#	token Quote_Removal {
#		# TODO
#	}#	###REDIRECTION#####
	###REDIRECTION#####
	token Redirects {
		<Redirect_Input>	
		|<Redirect_Output>	
		|<Redirect_Output_Append>	
		|<Redirect_StandOut>	
		|<Redirect_StandOut_Append>	
	}
	token Redirect_Input {
		\d* '<' <Word>
	}
	token Redirect_Output {
		\d* ['>' | '>|' ] <Word>
	}
	token Redirect_Output_Append {
		\d* '>>' <Word>
	}
	token Redirect_StandOut {
		['&>' | '>&' ] <Word>
	}
	token Redirect_StandOut_Append {
		'&>>' <Word>
	}
	token HEREDOC {
		'<<' '-'? <Word>
			<HereDocument>
		<deliminator>
	}
	token HERESTRING {
		'<<<' <Word>
	}
=begin comment
	# TODO FileDiscriptors
	###ALIASES#########
	token Alias {
		# TODO alias
	}
	token UnAlias {
		# TODO unalias
	}
	###FUNCTIONS#######
	###ARITHMETIC EVALUATION###
	# TODO
	###CONDITIONAL EXPRESSIONS###
	# TODO
	###SIMPLE COMMAND EXPANSION###
	# TODO
	###COMMAND EXECUTION###
	# TODO
	###COMMAND EXECUTION ENVIRONMENT###
	# TODO
	###ENVIRONMENT###
	# TODO
	###EXIT STATUS###
	# TODO
	###SIGNALS###
	# TODO
	###JOB CONTROL###
	# TODO
	###PROMPTING###
	# TODO
	###READLINE###
	# TODO
	###HISTORY###
	# TODO
	###HISTORY EXPANSION###
	# TODO
	###SHELL BUILTIN COMMANDS###
	# TODO
	###RESTRICTED SHELL###
	# TODO
=end comment
	###BUILTINS########
#	token # alias function declare unset set source . shift unalias
#	token # while for until
	###END BUILTINS####
=begin comment
	token Escape { # FIXME Escaped whitspaces(including newlines) should be ignored, not taken literaly. (May need to be implimented elsewear).
		\\
		[	  a alarm
			| n "\n"
			| r "\r"
			| t "\t"
			| v "\t"
			| ' ' '' # nullify
			| "\n" '' # nullify
			| "\t" '' # nullify
			| \d{3} return octle
		]
	}
	token Exec { # FIXME? Match unclosed quotes to EOF?
		# FIXME Escaped Closure for <">. ie " \" " should work as expected ( '\' stays the same ). Try [ <Literal> || <-[\"]> ]*
		  \` <-[\`]>* \` # backtics
		  | '$((' autovar math '))'
		  | '$(' BASHING ')'
		  | '(' SUBSHELL ')'
		  | '{' FUNCTION '}'
		  | '$' <Quote> # Eval it
	}
	token Var { # FIXME % is not a var, but a Non-clasic CronJob format. CronVar should probably handle things like mail(no) after \&. 
		<Word> '=' <Word>
		|( \$ <Word>)
		|( '${' <Word> '}')
		|( '${' <Word> '[' <Word> ']}')
	}
=end comment
	token TOP {
		[ [\n|\t|' ']* [ <Comment> 
		|| <Set_Var>
		|| <Compound_Command>
		|| <Function>
		|| <List>
		]]+
		#|| <Unparse> ]]+

	}
}
class Bash::Actions::Eval {
	method Assighnment {	
	}
	method Command {
	}
	method Pipe {	
	}
	method List {
	}
	method Literal {
	}
	method Quote {
	}
	method QuoteEscape {
	}
	method QuoteSingle {
	}
	method QuoteDouble {
	}
	
	method TOP($/) {
		my @CronJobs = (for ($<CronJob>.list) { .made });
		make @CronJobs;
	}
}

class Bash {
	has Bool $.Resolve = False;
	has $.ResolveDepth = Inf;
	method Check ($File) {
		my $tree = Bash::Grammar.parse($File.IO.lines.join("\n"));
		say $tree;
	}
}
my Bash $bsh;
$bsh.Check('/home/beck/.bash_completion.d/mpc');

class Bash::Tracer {
	has Bool $.Resolve = False;
	has $.ResolveDepth = Inf;
	has $.ExpandConstants = Inf;
	has $.ExpandParameter = Inf;
	has $.ExpandVariables = Inf;
	has Bool $.EvalCommands = False;
	has Bool $.ImportSources = False;
	has Bool $.ImportEval = False;
	has Bool $.InitEnv = True;
	has Bool $.ExpandQuotes = True;
	has Bool $.ResolveReadLine = False;
	has Bool $.EvalHereDoc = True;
	has Bool $.Aliases = True;
	has Bool $.Arithmitic = True;
	has Bool $.Conditions = True;
}
