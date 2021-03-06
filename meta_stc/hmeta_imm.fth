\ $Id: hmeta_imm.fth,v 1.3 1998/11/25 21:48:57 crook Exp crook $
\ $Log: hmeta_imm.fth,v $
\ Revision 1.3  1998/11/25 21:48:57  crook
\ check-point before starting on STC modifications.
\
\ Revision 1.2  1998/09/30 23:57:15  crook
\ first working binary.
\
\ Revision 1.1  1998/09/05 12:06:36  crook
\ Initial revision
\

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
CR .( *** Immediate words for target system)
\ For hForth, these are:
\ -. ; AGAIN AHEAD IF LITERAL THEN [ ( +LOOP ." ABORT" BEGIN
\ DO DOES> ELSE LEAVE LOOP POSTPONE RECURSE REPEAT SLITERAL S" TO UNTIL
\ WHILE ['] [CHAR] \
\
\ there are 3 definitions of each of these words. For an immediate word
\ fred there is:
\ nit-fred (non-immediate target fred) in Forth wordlist
\ it-fred (immediate target fred) in Forth wordlist
\ fred (immediate target fred) in it-words
\
\ this convoluted scheme is convenient because some of the immediate words
\ want to use (eg) IF without finding the IF that is defined for the target
\ system. This can be solved by swapping the search orders around, but it's
\ clearer to have multiple names

\ In addition to this, the following words are used in the interpreter
\ and affect the compilation in the target:
\ : <wordlist control> IMMEDIATE COMPILE-ONLY VALUE CONSTANT VARIABLE ]
\ Since they must be available in the interpreter, they are all defined
\ right at the end of this file, to avoid conflict with host definitions
\ by the same name (TODO the exceptions at the moment are the : definition,
\ and the last three; which are handled as special cases in the main source
\ but must ultimately be supported to allow the supplementary files to be
\ included.
\
\ You need to understand the difference between tPOSTPONE and hPOSTPONE to
\ understand why both are used in this subsequent section of code.

\ come into here with standard compile and search order.
CR .( Check search order -> ) ORDER

BASE @ DECIMAL
ALSO its-words

: nit--. -13 THROW ;
: it--. nit--. ; hIMMEDIATE


: nit-[   0 STATE ! restore-order ; hCOMPILE-ONLY
: it-[ nit-[ ; hIMMEDIATE hCOMPILE-ONLY


\   ;           ( colon-sys -- )		 \ CORE
\		Terminate a colon definition.
\
STC_MODEL [IF]
: nit-;  restore-order
	bal 1- IF -22 THROW THEN        \ control structure mismatch
	NIP 1+ IF -22 THROW THEN        \ colon-sys type is -1
	notNONAME? IF   \ if the last definition is not created by ':'
	   linkLast 0 TO notNONAME?     \ link the word to wordlist
\ STC TODO -- don't need "EXIT" any more at the end of a definition, but
\ *do* need to provide a new STC version of it since it is a CORE word.
\ Most efficient would be immediate word that compiled inline code, but that
\ may be unattractive to code -- postpone confusions.
	THEN COLON-EXIT code,		\ add EXIT at the end of the definition
	0 TO bal nit-[  ; hCOMPILE-ONLY
[ELSE]
: nit-;  restore-order
	bal 1- IF -22 THROW THEN        \ control structure mismatch
	NIP 1+ IF -22 THROW THEN        \ colon-sys type is -1
	notNONAME? IF   \ if the last definition is not created by ':'
	   linkLast 0 TO notNONAME?     \ link the word to wordlist
	THEN tPOSTPONE EXIT     \ add EXIT at the end of the definition
	0 TO bal nit-[  ; hCOMPILE-ONLY
[THEN]

: it-; nit-; ; hCOMPILE-ONLY hIMMEDIATE


: nit-BEGIN     xhere 0 bal+            \ dest type is 0
	    ; hCOMPILE-ONLY
: it-BEGIN nit-BEGIN ; hCOMPILE-ONLY hIMMEDIATE


: nit-DO    0 rakeVar !  0		   \ ?DO-orig is 0 for DO
	    tPOSTPONE doDO xhere  bal+       \ DO-dest
	    ; hCOMPILE-ONLY
: it-DO nit-DO ; hCOMPILE-ONLY hIMMEDIATE


: nit-LOOP  tPOSTPONE doLOOP  rake ; hCOMPILE-ONLY
: it-LOOP nit-LOOP ; hCOMPILE-ONLY hIMMEDIATE


: nit-+LOOP     tPOSTPONE do+LOOP  rake ; hCOMPILE-ONLY
: it-+LOOP nit-+LOOP ; hCOMPILE-ONLY hIMMEDIATE


: nit-UNTIL IF -22 THROW THEN  \ control structure mismatch; dest type is 0
	    tPOSTPONE 0branch code, bal- ; hCOMPILE-ONLY
: it-UNTIL nit-UNTIL ; hCOMPILE-ONLY hIMMEDIATE


\ Generate a code sequence in target space that has the run-time effect
\ of putting a value on the stack. The code sequence is:
\ <dolit> <value from stack>
: nit-LITERAL
	tPOSTPONE doLIT code, ; hCOMPILE-ONLY
: it-LITERAL nit-LITERAL ; hCOMPILE-ONLY hIMMEDIATE


\ TODO try the POSTPONE definition.
\ parse the next word, and look in the target dictionary to find its xt.
\ push the xt onto the stack then generate code to emit it in the target
\ code stream
: nit-['] t' nit-LITERAL ; hCOMPILE-ONLY
: it-['] nit-['] ; hCOMPILE-ONLY hIMMEDIATE


: nit-DOES> bal 1- IF -22 THROW THEN        \ control structure mismatch
	    NIP 1+ IF -22 THROW THEN        \ colon-sys type is -1
	    tPOSTPONE pipe t['] doLIST xt, -1 ; hCOMPILE-ONLY
: it-DOES> nit-DOES> ; hCOMPILE-ONLY hIMMEDIATE

: nit-LEAVE tPOSTPONE UNLOOP tPOSTPONE branch
	    xhere rakeVar DUP @ code, ! ; hCOMPILE-ONLY
: it-LEAVE nit-LEAVE ; hCOMPILE-ONLY hIMMEDIATE


: nit-RECURSE   bal 1- 2* PICK 1+ IF -22 THROW THEN
	    \ control structure mismatch; colon-sys type is -1
	    bal 1- 2* 1+ PICK       \ xt of current definition
	    tCOMPILE, ; hCOMPILE-ONLY
: it-RECURSE nit-RECURSE ; hCOMPILE-ONLY hIMMEDIATE


: nit-IF    tPOSTPONE 0branch xhere 0 code,
	    1 bal+          \ orig type is 1
	    ; hCOMPILE-ONLY
: it-IF nit-IF ; hCOMPILE-ONLY hIMMEDIATE


: nit-THEN  1- IF -22 THROW THEN	\ control structure mismatch
				\ .. check that orig type was 1
	    xhere SWAP t! bal- ; hCOMPILE-ONLY
: it-THEN nit-THEN ; hCOMPILE-ONLY hIMMEDIATE


: nit-AHEAD tPOSTPONE branch xhere 0 code,
	1 bal+          \ orig type is 1
	; hCOMPILE-ONLY
: it-AHEAD nit-AHEAD ; hCOMPILE-ONLY hIMMEDIATE


: nit-ELSE hPOSTPONE it-AHEAD 2SWAP hPOSTPONE it-THEN ; hCOMPILE-ONLY
: it-ELSE nit-ELSE ; hCOMPILE-ONLY hIMMEDIATE


: nit-AGAIN IF -22 THROW THEN  \ control structure mismatch; dest type is 0
	tPOSTPONE branch code, bal- ; hCOMPILE-ONLY
: it-AGAIN nit-AGAIN ; hCOMPILE-ONLY hIMMEDIATE


: nit-REPEAT hPOSTPONE it-AGAIN hPOSTPONE it-THEN ; hCOMPILE-ONLY
: it-REPEAT nit-REPEAT ; hCOMPILE-ONLY hIMMEDIATE


: nit-WHILE  hPOSTPONE it-IF 2SWAP ; hCOMPILE-ONLY
: it-WHILE nit-WHILE ; hCOMPILE-ONLY hIMMEDIATE


: nit-(         [CHAR] ) PARSE 2DROP ;
: it-( nit-( ; hIMMEDIATE


\ Copy a string into target space along with the words that are needed
\ at run-time in order to print it.
: nit-SLITERAL
	DUP nit-LITERAL tPOSTPONE doS"
\ since LITERAL is immediate, tPOSTPONE LITERAL would emit LITERAL
\ so we short-circuit this process by using nit-LITERAL. Since doS" is non-imm,
\ tPOSTPONE doS" should emit doLIT doS" COMPILE,
	CHARS xhere 2DUP + ALIGNED TOxhere
	SWAP tMOVE ; hCOMPILE-ONLY


: it-SLITERAL nit-SLITERAL ; hCOMPILE-ONLY hIMMEDIATE


: nit-S" [CHAR] " PARSE nit-SLITERAL ; hCOMPILE-ONLY
: it-S" nit-S" ; hCOMPILE-ONLY hIMMEDIATE


: nit-."   nit-S" tPOSTPONE TYPE ; hCOMPILE-ONLY
: it-." nit-." ; hCOMPILE-ONLY hIMMEDIATE


\ search target dictionary for name and examine the code that makes up
\ the definition to make sure that it is a VALUE.
STC_MODEL [IF] \ TODO temporary HACK to make it pass
: nit-TO    t' ?call 
DROP -1
DUP IF          \ should be call-doVALUE
		t['] doVALUE =         \ verify VALUE marker
DROP -1
	  	IF t@ STATE @
\ STC todo -- tPOSTPONE needs to emit a BL rather than an xt
\ .. should already be OK, provided that tCOMPILE, works properly
		     IF tPOSTPONE doTO code, EXIT THEN
		     t! EXIT
		THEN
            THEN -32 THROW ; \ invalid name argument (e.g. TO xxx)
[ELSE] \ DTC
: nit-TO    t' ?call DUP IF          \ should be call-doVALUE
		t['] doVALUE =         \ verify VALUE marker
	  	IF t@ STATE @
		     IF tPOSTPONE doTO code, EXIT THEN
		     t! EXIT
		THEN
            THEN -32 THROW ; \ invalid name argument (e.g. TO xxx)
[THEN]
: it-TO nit-TO ; hIMMEDIATE


\ parse the next word and push the character code for its first character
\ onto the stack, then emit the character code in the code stream
: nit-[CHAR]    CHAR nit-LITERAL ; hCOMPILE-ONLY
: it-[CHAR] nit-[CHAR] ; hCOMPILE-ONLY hIMMEDIATE


\ " force the compilation of a word that would normally be executed"
\ " postpone the compile action of the word"
\ parse the next word in the input stream and look for it in the target
\ dictionary. It needs to be found, since a forward reference cannot save
\ us. When found, determine whether it is immediate or non-immediate and
\ based on this knowledge, emit the code sequence that will have the run-time
\ effect of executing the word.
: nit-POSTPONE
  (') 0< IF \ search the wordlists in the target image
	\ non-immediate word. Make the target definition spit out the XT by
	\ generating this code in the target code space:
	\ <dolit> <xt> <compile,>
	t['] doLIT tCOMPILE, tCOMPILE,
	t['] COMPILE,   \ non-IMMEDIATE
  THEN
  \ IMMEDIATE word - just spit out the XT in the target code space
  tCOMPILE,
  ; hCOMPILE-ONLY       \ IMMEDIATE
: it-POSTPONE nit-POSTPONE ; hCOMPILE-ONLY hIMMEDIATE

\ TODO that looks dodgy.. (maybe OK now..)
: nit-ABORT"  nit-S" tPOSTPONE ROT nit-IF tPOSTPONE abort"msg
  tPOSTPONE 2! -2 nit-LITERAL tPOSTPONE THROW nit-ELSE
  tPOSTPONE 2DROP nit-THEN ;  hCOMPILE-ONLY
: it-ABORT" nit-ABORT" ; hCOMPILE-ONLY hIMMEDIATE

: nit-\ SOURCE >IN ! DROP ;
: it-\ nit-\ ; hIMMEDIATE

\ take a number off the stack and create an immediate word whose action is to
\ parse the input buffer and extract a number. The word D# n has the same
\ effect as [ n ] LITERAL - which is normally redundant, but is needed when
\ using the interpreter to target compile.
: N#	CREATE , hIMMEDIATE DOES>
	BASE @ >R @ BASE ! \ change BASE to value in defined word's para field
	0 0 \ >NUMBER accumulates a DOUBLE
	PARSE-WORD 
	\ handle the possibility of -ve numbers..
	OVER C@ [CHAR] - = DUP >R
	IF
	  1 - SWAP CHAR+ SWAP \ skip leading - but remember we had it
	THEN
	>NUMBER
	IF
	  \ one or more characters were unconverted
	  SOURCE TYPE ABORT" -- unable to convert the number"
	THEN
	2DROP \ string address and the high part of the double number
	\ (assumed to be 0..)
	R> IF NEGATE THEN R> BASE !
	nit-LITERAL ;

PREVIOUS \ back to standard

\ immediate words for the target definitions - go into a special wordlist.
ALSO it-words DEFINITIONS PREVIOUS
ALSO its-words

: -. nit--. ; hIMMEDIATE
: [ nit-[ ; hIMMEDIATE hCOMPILE-ONLY
\ : ; nit-; ; hCOMPILE-ONLY hIMMEDIATE \ may not want this yet
: BEGIN nit-BEGIN ; hCOMPILE-ONLY hIMMEDIATE
: DO nit-DO ; hCOMPILE-ONLY hIMMEDIATE
: LOOP nit-LOOP ; hCOMPILE-ONLY hIMMEDIATE
: +LOOP nit-+LOOP ; hCOMPILE-ONLY hIMMEDIATE
: UNTIL nit-UNTIL ; hCOMPILE-ONLY hIMMEDIATE
: DOES> nit-DOES> ; hCOMPILE-ONLY hIMMEDIATE
: LEAVE nit-LEAVE ; hCOMPILE-ONLY hIMMEDIATE
: RECURSE nit-RECURSE ; hCOMPILE-ONLY hIMMEDIATE
: IF nit-IF ; hCOMPILE-ONLY hIMMEDIATE
: THEN nit-THEN ; hCOMPILE-ONLY hIMMEDIATE
: AHEAD nit-AHEAD ; hCOMPILE-ONLY hIMMEDIATE
: ELSE nit-ELSE ; hCOMPILE-ONLY hIMMEDIATE
: AGAIN nit-AGAIN ; hCOMPILE-ONLY hIMMEDIATE
: REPEAT nit-REPEAT ; hCOMPILE-ONLY hIMMEDIATE
: WHILE nit-WHILE ; hCOMPILE-ONLY hIMMEDIATE
: LITERAL nit-LITERAL ; hCOMPILE-ONLY hIMMEDIATE
: ( nit-( ; hIMMEDIATE
: SLITERAL nit-SLITERAL ; hCOMPILE-ONLY hIMMEDIATE
: S" nit-S" ; hCOMPILE-ONLY hIMMEDIATE
: ." nit-." ; hCOMPILE-ONLY hIMMEDIATE
: ['] nit-['] ; hCOMPILE-ONLY hIMMEDIATE
: TO nit-TO ; hIMMEDIATE
: [CHAR] nit-[CHAR] ; hCOMPILE-ONLY hIMMEDIATE
: POSTPONE nit-POSTPONE ; hCOMPILE-ONLY hIMMEDIATE
: ABORT" nit-ABORT" ; hCOMPILE-ONLY hIMMEDIATE
: \ nit-\ ; hIMMEDIATE
16 N# H#
10 N# D#


PREVIOUS DEFINITIONS \ back to FORTH
CR .( Check search order -> ) ORDER
CR .( *** End of hmeta_imm.fth)
BASE !
