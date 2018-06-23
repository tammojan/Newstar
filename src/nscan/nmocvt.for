C+ NMOCVT.FOR
C  WNB 900827
C
C  Revisions:
C	WNB 911209	Correct reference data ask
C	WNB 911227	Typo reference data
C	WNB 921104	Add J2000
C	HjV 930423	Change some text and keywords
C	WNB 930928	Add instrument
C	WNB 931005	Add better prompt
C	WNB 931008	Cater for EDIT; change CV1 call to CVS
C	WNB 931011	Make sure frequency given
C	WNB 931110	Change NMOCVS call, CVT definition
C	CMV 931220	Pass FCA of input file to WNDXLP and WNDSTA/Q
C
	SUBROUTINE NMOCVT(CVT)
C
C  Convert source list to other epoch
C
C  Result:
C
C	CALL NMOCVT( CVT_I:I)
C				Convert a source list to other epoch
C				CVT indicates convert (0) or edit (1),
C				REDIT (2), FEDIT (3)
C
C  PIN references
C
C	CONVERT_TO
C	REFERENCE_DATA
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'NMO_DEF'
	INCLUDE 'MDH_O_DEF'	!MODEL HEADER
	INCLUDE 'STH_O_DEF'	!SET HEADER
C
C  Parameters:
C
C
C  Arguments:
C
	INTEGER CVT		!CONVERT/EDIT INDICATOR
C
C  Function references:
C
	LOGICAL WNDPAR		!GET USER DATA
	LOGICAL WNDNOD		!GET A NODE
	LOGICAL WNFOP		!OPEN FILE
	LOGICAL WNDSTA		!GET SET DEFINITIOSN
	LOGICAL NSCSTG		!GET A SET HEADER
	LOGICAL NMOCVS		!CONVERT LIST
C
C  Data declarations:
C
	BYTE MDH(0:MDH__L-1)			!SOURCE HEADER
	  INTEGER MDHJ(0:MDH__L/LB_J-1)
	  REAL MDHE(0:MDH__L/LB_E-1)
	  DOUBLE PRECISION MDHD(0:MDH__L/LB_D-1)
	  EQUIVALENCE (MDH,MDHJ,MDHE,MDHD)
	BYTE LMDH(0:MDH__L-1)			!SOURCE HEADER
	  INTEGER LMDHJ(0:MDH__L/LB_J-1)
	  REAL LMDHE(0:MDH__L/LB_E-1)
	  DOUBLE PRECISION LMDHD(0:MDH__L/LB_D-1)
	  EQUIVALENCE (LMDH,LMDHJ,LMDHE,LMDHD)
	INTEGER SFCA				!TO READ SCN
	CHARACTER*80 SNOD
	CHARACTER*160 SFIL
	INTEGER SNAM(0:7)
	INTEGER STHP
	BYTE STH(0:STH__L-1)			!SET HEADER
	  INTEGER STHJ(0:STH__L/LB_J-1)
	  REAL STHE(0:STH__L/LB_E-1)
	  DOUBLE PRECISION STHD(0:STH__L/LB_D-1)
	  EQUIVALENCE (STH,STHJ,STHE,STHD)
	INTEGER RANGE(0:1)
	  DATA RANGE/0,1000000/
	DOUBLE PRECISION RA(5)			!REFERENCE DATA
	REAL PHI
	CHARACTER*24 STR
C-
C
C GET CONVERSION FORMAT
C
 10	CONTINUE
	IF (.NOT.WNDPAR('CONVERT_TO',STR,LEN(STR),J0,'""')) GOTO 900
	IF (J0.EQ.0) GOTO 900
	IF (J0.LT.0) GOTO 10				!MUST SET
	CALL WNGMVZ(MDH__L,MDH)				!MAKE GOAL
	IF (STR.EQ.'B1950') THEN			!SET TYPE
	  MDHJ(MDH_TYP_J)=2
	  MDHE(MDH_EPOCH_E)=1950.
	ELSE IF (STR.EQ.'J2000') THEN			!SET TYPE
	  MDHJ(MDH_TYP_J)=2
	  MDHE(MDH_EPOCH_E)=2000.
	ELSE IF (STR.EQ.'APPARENT') THEN
	  MDHJ(MDH_TYP_J)=1
	ELSE
	  MDHJ(MDH_TYP_J)=0
	END IF
C
C INIT SOURCE LIST
C
	CALL NMOHZD(GDES)			!CLEAR HEADER DATA
	CALL NMORDS(FCAOUT)			!READ SOURCES
	CALL NMORDM(7,-1)			!AND ADD THEM
	CALL NMOPTT(F_TP,RANGE)			!SHOW DATA
C
C GET REFERENCE DATA
C
	DO I=1,5
	  RA(I)=0				!EMPTY REFERENCE DATA
	END DO
	IF (MDHJ(MDH_TYP_J).EQ.0) THEN		!READY
	ELSE
	  IF (.NOT.WNDNOD('REF_SCN_NODE',' ','SCN','R',SNOD,SFIL))
	1		GOTO 901		!CANNOT DO
	  IF (E_C.EQ.DWC_NULLVALUE) GOTO 901	!""
	  IF (E_C.EQ.DWC_WILDCARD) THEN		!ASK SEPARATE
 11	    CONTINUE
	    IF (MDHJ(MDH_TYP_J)*GDESJ(MDH_TYP_J).NE.0 .AND.
	1		MDHJ(MDH_TYP_J).NE.GDESJ(MDH_TYP_J) .AND.
	1		CVT.EQ.0) THEN
	      CALL WNCTXT(F_TP,'To convert apparent <-> epoch a '//
	1			'reference scan is needed.')
	      CALL WNCTXT(F_TP,'Use EDIT to change without conversion')
	      GOTO 10				!RETRY
	    END IF
	    RA(1)=360.*GDESD(MDH_RA_D)		!MAKE PROMPT
	    RA(2)=360.*GDESD(MDH_DEC_D)
	    RA(3)=GDESD(MDH_FRQ_D)
	    RA(4)=0
	    RA(5)=IAND(GDESJ(MDH_BITS_J),MDHINS_M) !INSTRUMENT
	    IF (.NOT.WNDPAR('REFERENCE_DATA',RA,5*LB_D,J0,
	1		A_B(-A_OB),RA,5)) GOTO 901 !STOP
	    IF (J0.NE.5) GOTO 901
	    IF ((RA(1).EQ.RA(2) .AND. RA(1).EQ.0) .OR.
	1		RA(3).LE.0) GOTO 11
	    MDHD(MDH_RA_D)=RA(1)/360		!MAKE FRACTIONS
	    MDHD(MDH_DEC_D)=RA(2)/360
	    MDHD(MDH_FRQ_D)=RA(3)
	    PHI=RA(4)/360
	    MDHJ(MDH_BITS_J)=NINT(RA(5))	!INSTRUMENT
	  ELSE					!GET SCAN DATA
	    IF (.NOT.WNFOP(SFCA,SFIL,'R')) THEN
	      CALL WNCTXT(F_TP,'Cannot find SCN file')
	      GOTO 901
	    END IF
	    IF (.NOT.WNDSTA('REF_SCN_SET',MXNSET,SETS,SFCA)) GOTO 902
	    IF (.NOT.NSCSTG(SFCA,SETS,STH,STHP,SNAM)) THEN
	      CALL WNCTXT(F_TP,'Cannot find SCN sector')
	      GOTO 902
	    END IF
	    CALL WNFCL(SFCA)			!CLOSE SCAN
	    IF (MDHJ(MDH_TYP_J).EQ.1) THEN	!APPARENT
	      MDHD(MDH_RA_D)=STHD(STH_RA_D)
	      MDHD(MDH_DEC_D)=STHD(STH_DEC_D)
	      MDHD(MDH_FRQ_D)=STHD(STH_FRQ_D)
	      PHI=STHE(STH_PHI_E)
	      MDHJ(MDH_BITS_J)=STHJ(STH_INST_J)	!INSTRUMENT
	      LMDHD(MDH_RA_D)=STHD(STH_RAE_D)	!FOR POSSIBLE INTERIM
	      LMDHD(MDH_DEC_D)=STHD(STH_DECE_D)
	      LMDHD(MDH_FRQ_D)=STHD(STH_FRQE_D)
	    ELSE				!1950
	      MDHD(MDH_RA_D)=STHD(STH_RAE_D)
	      MDHD(MDH_DEC_D)=STHD(STH_DECE_D)
	      MDHD(MDH_FRQ_D)=STHD(STH_FRQE_D)
	      PHI=-STHE(STH_PHI_E)
	      MDHJ(MDH_BITS_J)=STHJ(STH_INST_J)	!INSTRUMENT
	      LMDHD(MDH_RA_D)=STHD(STH_RA_D)	!FOR POSSIBLE INTERIM
	      LMDHD(MDH_DEC_D)=STHD(STH_DEC_D)
	      LMDHD(MDH_FRQ_D)=STHD(STH_FRQ_D)
	    END IF
	  END IF
	END IF
C
C CONVERT
C
	IF (MDHJ(MDH_TYP_J)*GDESJ(MDH_TYP_J).NE.0 .AND.
	1		MDHJ(MDH_TYP_J).NE.GDESJ(MDH_TYP_J) .AND.
	1		CVT.EQ.0) THEN		!APPARENT <-> EPOCH
	  D0=MDHD(MDH_RA_D)			!SET SHIFT ONLY
	  MDHD(MDH_RA_D)=LMDHD(MDH_RA_D)
	  LMDHD(MDH_RA_D)=D0
	  D0=MDHD(MDH_DEC_D)
	  MDHD(MDH_DEC_D)=LMDHD(MDH_DEC_D)
	  LMDHD(MDH_DEC_D)=D0
	  D0=MDHD(MDH_FRQ_D)
	  MDHD(MDH_FRQ_D)=LMDHD(MDH_FRQ_D)
	  LMDHD(MDH_FRQ_D)=D0
	  LMDHJ(MDH_TYP_J)=MDHJ(MDH_TYP_J)
	  MDHJ(MDH_TYP_J)=GDESJ(MDH_TYP_J)
	  IF (.NOT.NMOCVS(GDES,MDH,PHI,CVT)) THEN !CONVERT DATA
 20	    CONTINUE
	    CALL WNCTXT(F_TP,'Error in conversion')
	    GOTO 901
	  END IF
	  MDHD(MDH_RA_D)=LMDHD(MDH_RA_D)	!SET ROTATION
	  MDHD(MDH_DEC_D)=LMDHD(MDH_DEC_D)
	  MDHD(MDH_FRQ_D)=LMDHD(MDH_FRQ_D)
	  MDHJ(MDH_TYP_J)=LMDHJ(MDH_TYP_J)
	  IF (.NOT.NMOCVS(GDES,MDH,PHI,1)) GOTO 20 !CONVERT DATA
	ELSE					!NO ROTATION CONVERSION
	  IF (.NOT.NMOCVS(GDES,MDH,PHI,CVT)) GOTO 20 !CONVERT DATA
	END IF
C
C REWRITE DATA
C
	IF (.NOT.WNFOP(FCAOUT,FILOUT,'U')) THEN
	  CALL WNCTXT(F_TP,'Cannot output data')
	  GOTO 901
	END IF
	CALL NMOWRS(FCAOUT,GDES)		!WRITE DATA BACK
C
	RETURN
C
C ERRORS
C
 902	CONTINUE
	CALL WNFCL(SFCA)
	GOTO 901
 900	CONTINUE
	CALL WNFCL(FCAOUT)
 901	CONTINUE
C
	RETURN
C
C
	END