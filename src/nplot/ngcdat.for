C+ NGCDAT.FOR
C  WNB 920819
C
C  Revisions:
C	HjV 930423	Change name of some keywords
C	WNB 930824	Change interferometer/telescope select
C	WNB 930825	Change pol. selection
C	CMV 931220	Pass FCA of input file to WNDXLP and WNDSTA/Q
C       HjV 940428      Add plotting of IF data
C	JPH 940822	Remove subgroup creation. (Is done by action routines)
C			Open SCN file read-only
C
C
	SUBROUTINE NGCDAT
C
C  Get NGCALC program parameters
C
C  Result:
C
C	CALL NGCDAT	will ask and set all program parameters
C
C  PIN references:
C
C	ACTION
C	NGF_NODE
C	SCN_SETS	Sets to do
C	EXTRACT_TYPE	Type of data
C       IF_MODE
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'GFH_O_DEF'		!GENERAL FILE HEADER
	INCLUDE 'SGH_O_DEF'		!SUB-GROUP HEADER
	INCLUDE 'STH_O_DEF'
	INCLUDE 'NGC_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
C
C  Function references:
C
	LOGICAL WNDPAR			!GET DWARF PARAMETER
	LOGICAL WNDSTA			!GET SETS TO DO
	LOGICAL WNDNOD			!GET NODE NAME
	LOGICAL WNDLNG			!LINK SUB-GROUP
	LOGICAL WNFOP			!OPEN FILE
	LOGICAL NSCSTG			!FIND A SET
	LOGICAL NSCIF1			!SELECT INTERFEROMETERS
	LOGICAL NSCTL1			!SELECT TELESCOPES
	LOGICAL NSCPLS			!SELECT POLARISATION
C
C  Data declarations:
C
	INTEGER SETNAM(0:7)		!SET NAME
	INTEGER STHP			!SET POINTER
	BYTE STH(0:STH__L-1)		!SET HEADER
	  INTEGER STHJ(0:STH__L/LB_J-1)
	  EQUIVALENCE (STH,STHJ)
C-
C
C GET DATA NODE
C
 10	CONTINUE
	IF (FCAOUT.EQ.0) THEN			!NO NODE PRESENT
	  IF (.NOT.WNDNOD('NGF_NODE',NODOUT,'NGF',
	1		'U',NODOUT,FILOUT)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) THEN
	      OPT='QUIT'			!ASSUME END
	      GOTO 100
	    END IF
	    GOTO 10				!REPEAT
	  ELSE IF (E_C.EQ.DWC_NULLVALUE) THEN
	    GOTO 10				!RETRY
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN
	    GOTO 10				!MUST SPECIFY
	  END IF
	  IF (.NOT.WNFOP(FCAOUT,FILOUT,'U')) THEN !OUTPUT NGF FILE
	    GOTO 10				!RETRY
	  END IF
	END IF
C
C GET ACTION
C
 20	CONTINUE
	IF (.NOT.WNDPAR('ACTION',OPTION,LEN(OPTION),J0,'QUIT')) THEN
	  OPTION='QUIT'				!ASSUME END
	ELSE IF (J0.LE.0) THEN
	  OPTION='QUIT'				!ASSUME END
	END IF
C
C EXTRACT
C
	IF (OPT.EQ.'EXT') THEN
 110	  CONTINUE
	  IF (.NOT.WNDNOD('SCN_NODE',NODIN,'SCN','R',NODIN,FILIN)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 20	!FORGET
	    GOTO 110				!RETRY
	  ELSE IF (E_C.EQ.DWC_NULLVALUE) THEN
	    GOTO 20				!FORGET
	  ELSE IF (E_C.EQ.DWC_WILDCARD) THEN
	    GOTO 110				!MUST SPECIFY
	  END IF
	  IF (.NOT.WNFOP(FCAIN,FILIN,'R')) GOTO 110 !OPEN INPUT
C
C GET SETS
C
 111	  CONTINUE
	  IF (.NOT.WNDSTA('SCN_SETS',MXNSET,SETS(0,0),FCAIN)) THEN !GET SETS TO DO
 116	    CONTINUE
	    CALL WNFCL(FCAIN)
	    GOTO 110
	  END IF
	  IF (.NOT.NSCSTG(FCAIN,SETS,STH,STHP,SETNAM)) GOTO 116 !FIND A SET
	  CALL WNDSTR(FCAIN,SETS)		!RESET SET SEARCH
C
C GET POLARISATION
C
 112	  CONTINUE
	  IF (.NOT.NSCPLS(0,SPOL)) GOTO 116	!GET POL. TO DO
C
C CORRECTIONS
C
	  CALL NSCSAD(CORAP,CORDAP)		!GET CORRECTIONS WANTED
C
C EXTRACT TYPE
C
 113	  CONTINUE
	  IF (.NOT.WNDPAR('EXTRACT_TYPE',SOPT,LEN(SOPT),
	1		J0,'QUIT')) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 112	!RETRY POL.
	    GOTO 113
	  END IF
	  IF (J0.EQ.0) GOTO 112			!RETRY POL
	  IF (J0.LT.0) GOTO 113			!MUST SPECIFY
	  IF (SOPT.EQ.'QUIT') GOTO 111
	  IF_MODE=' '
          IF (SOPT.EQ.'IFDATA') THEN                !Get IF Option
            IF (.NOT.WNDPAR('IF_MODE',IF_MODE,LEN(IF_MODE),J0,
	1	  'TSYS')) THEN
              GOTO 20                           !RETRY OPTION
            ELSE IF (J0.LE.0) THEN
              IF_MODE='TSYS'
            END IF
	    SOPT='T'
          END IF
	  IF (SOPT(1:1).EQ.'T') THEN
 114	    CONTINUE
	    IF(.NOT.NSCTL1(1,STELS,STHJ)) GOTO 113 !SELECT TELESCOPES
	  ELSE
	    IF (.NOT.NSCIF1(4,SIFR,STHJ)) GOTO 113 !GET IFRS TO DO
	  END IF
	END IF
C
C READY
C
 100	CONTINUE
C
	RETURN
C
C
	END
