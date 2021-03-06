!+ NFL.DSC
!  WNB 930618
!
!  Revisions:
!
%REVISION=WNB=930803="Remove .INCLUDE"
%REVISION=WNB=930618="Original version"
!
!	Layout of overall include file (NFL.DEF)
!
%COMMENT="NFL.DEF is an INCLUDE file for the NFLAG program"
%COMMENT=" "
!
%VERSION=1
%SYSTEM=1
%USER=WNB
%%DATE
%%NAME
%LOCAL=MXNSET=64				!MAX. # OF SETS
%LOCAL=MXNIFR=120				!MAX. # OF INTERFEROMETERS
!-
.DEFINE
  .PARAMETER
	MXNSET	J	/MXNSET/		!MAX. # OF SETS
	MXNIFR	J	/MXNIFR/		!MAX. # OF INTERFEROMETERS
  .DATA
!
!  Local variables:
!
  .COMMON
	OPTION	C24				!PROGRAM OPTION
	OPT=OPTION C3
	NODIN	C80				!INPUT NODE
	IFILE	C80				!INPUT FILE NAME
	FCAIN	J				!INPUT FCA
	SETS	J(0:7,0:MXNSET)			!SETS TO DO
.END
