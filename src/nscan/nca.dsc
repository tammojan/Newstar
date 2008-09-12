!+ NCA.DSC
!  WNB 900306
!
!  Revisions:
!
%REVISION=JPH=970403="Add USIGN"
%REVISION=JPH=960802="Shorten OPTION, insert DOWNWT"
%REVISION=JPH=951124="Comments"
%REVISION=WNB=950614="Add DOMIFR"
%REVISION=HjV=95-6-9="Add CIFRS"
%REVISION=CMV=940503="Add CEQUAL"
%REVISION=CMV=940429="Add IFRCOR
%REVISION=CMV=940331="Add TELS"
%REVISION=WNB=931126="Add XOSOL"
%REVISION=JPH=930825="Comments. - COR_ parameters"
%REVISION=JPH=930825="Comments. - COR_ parameters"
%REVISION=WNB=930803="Remove .INCLUDE; use NSTAR.DSF"
%REVISION=WNB=921120="Change units HAINT"
%REVISION=WNB=910812="Add ALIGN"
%REVISION=WNB=910612="Add loops"
%REVISION=WNB=900306="Original version"
!
!	Layout of overall include file (NCA.DEF)
!
%COMMENT="NCA.DEF is an INCLUDE file for the NCALIB program"
%COMMENT=" "
!
%VERSION=1
%SYSTEM=1
%USER=WNB
%%DATE
%%NAME
!
! Get number of telescopes
!
%INCLUDE=NSTAR_DSF
!
%LOCAL=MXNSET=64				!SETS per job
%LOCAL=NIFR=NSTAR_TEL*(NSTAR_TEL+1)/2		!# INTERFEROMETERS
!-
.DEFINE
  .PARAMETER
	MXNSET	J	/MXNSET/		!MAX. SETS PER GO
!enumerate correction types for NCASTY		!MAX. SETS PER GO
	COR_FRQ		J	 /1/
	COR_DX		J	 /2/
	COR_DY		J	 /3/
	COR_DZ		J	 /4/
	COR_POLE	J	 /5/
	COR_MUL		J	/16/
!and for NCASTX etc
	COR_EXT		J	 /6/
	COR_REF		J	 /7/
	COR_CLK		J	 /8/
	COR_FAR		J	 /9/
	COR_IRF		J	/10/
	COR_AIFR	J	/11/
	COR_MIFR	J	/12/
  .DATA
!
!  Local variables:
!
  .COMMON
	OPTION	C20				!PROGRAM OPTION
	OPT=OPTION C3
	DOWNWT	R				! weight reduction factor
	SETS	J(0:7,0:MXNSET)			!SETS TO DO
	FCAOUT	J				!OUTPUT FCB
	FILOUT	C160				!FILE NAME
	NODOUT	C80				!NODE NAME
	SETINP	J(0:7,0:MXNSET)			!SETS TO DO
	FCAINP	J				!OUTPUT FCB
	FILINP	C160				!FILE NAME
	NODINP	C80				!NODE NAME
	RS1	J				!ALIGNMENT
	HARAN	E(2)				!HA RANGE
	HAINT	E				!INTEGRATION TIME
	BASDEV	E				!BASELINE DEVIATION
	WGTMIN	E				!MIN. WEIGHT
	XYSOL	L(0:1)				!X/Y SOLUTION
	APSOL	L(0:1)				!AMPL/PHASE SOLUTION
	XSOLVE	L				!COMPLEX SOLUTION
	CSOLVE	L				!CONTINUITY IN SOLUTION
	DOALG	L				!DO ALIGN/SELFCAL
	DOSCAL	L				!DO SELFCAL
	FORFRE	L(0:1)				!FORCE ALIGN FREEDOMS
	XOSOL	L				!SOLVE ONLY COMPLEX
	RES1	L
	FREGPH	J(0:NSTAR_TEL-1,0:1)		!GAIN/PHASE FREEDOM
	FORPER	E(0:13)				!PHASE START
	RIN	E(3)				!CHECK VALUES
	SHLV	J(0:4)				!PRINT LEVELS
!
	JAV	J(0:NIFR-1,0:4,0:1,0:1)		!COUNTS FOR NOISE AVERAGES
	EAV	E(0:NIFR-1,0:4,0:1,0:1)		!NOISE AVERAGES
 	DAV	D(0:NIFR-1,0:4,0:1,0:1)		!NOISE AVERAGES RMS
						! see NCARPS for details on the
						!  use of these arrays
!
	SIFRS	B(0:NSTAR_TEL-1,0:NSTAR_TEL-1)	!SELECTED INTERFEROMETERS
	SPOL	J				!SELECTED POLARISATIONS
	NSRC	J(0:2)				!SOURCES TO USE
	MWGT	J				!MODEL WEIGHT TYPE
	MWGTD	E(0:2)				!MODEL WEIGHT DATA
	CORAP	J				!CORRECTIONS TO APPLY
	CORDAP	J				!CORRECTIONS TO DE-APPLY
	CORZE	J				!CORRECTIONS TO ZERO
	CFREF	E(0:2)				!REFRACTION COEFFICIENTSS in
						!the formula
						!  N = C0 +C1*FRQ +C2*FRQ**2 
						!   (with 0FRQ in GHz)
						!also used as buffer for value
						! of STH_SHFT, STH_CLK, 
						! STH_IREF
	CFEXT	E(0:2)				!EXTINCTION COEFFICIENTS 
						!  (same)
	PCGAN	E(0:NSTAR_TEL-1,0:1)		!GAIN CORRECTIONS GIVEN
	PCPHS	E(0:NSTAR_TEL-1,0:1)		!PHASE CORRECTIONS GIVEN
	LFLDS	J(0:1)				!LOOP FIELDS
	LCHANS	J(0:1)				!LOOP CHANNELS
	LPOFF	J(0:7)				!LOOP OFFSETS
	TELS    B(0:NSTAR_TEL-1)		!TELESCOPES SELECTED
	IFRCOR	X(0:NIFR-1,0:3)			!IFR CORRECTIONS (XX,XY,YX,YY)
	CEQUAL  J                               !Copy cal's with equal length
	CIFRS	B(0:NSTAR_TEL-1,0:NSTAR_TEL-1)	!Selected correction IFRS
%ALIGN
	DOMIFR	L				!Indicate MIFR asked
	USIGN	E				!Stokes-U sign: 0 or PI for U
						!	<0 or >0
.END
