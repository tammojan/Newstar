C+ NMOMUI.FOR
C  WNB 900903
C
C  Revisions:
C	WNB 911007	Add instrum. pol.
C	WNB 911023	Suppress instrum. pol. question
C	WNB 921202	Add NMOMUJ
C	CMV 930917	Disable INSPOL (not yet properly implemented)
C	WNB 931006	Text
C	WNB 931008	Add BEAM
C	CMV 931102	Changed default to NOBEAM
C	CMV 931122	INPOL enabled for a while  ***** Need to set back
C	CMV 000210	Changed default back to BEAM (request AGB)
C
	SUBROUTINE NMOMUI
C
C  Get model action for scan files
C
C  Result:
C
C	CALL NMOMUI		will get the action wanted on model/scan files
C	CALL NMOMUJ( UACT_J:I)	UACT specifies action
C
C  PIN references
C
C	MODEL_ACTION
C	INPOL*_*
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'NMO_DEF'
C
C  Entries:
C
C
C  Parameters:
C
C
C  Arguments:
C
	INTEGER UACT				!ACTION
C
C  Function references:
C
	LOGICAL WNDPAR				!GET USER DATA
C
C  Data declarations:
C
	CHARACTER*24 STR(5)			!REPLY
	CHARACTER*1 INPC(0:2)			!FOR INSTRUM. POL.
	  DATA INPC/'Q','U','V'/
	CHARACTER*6 INPF(0:6)
	  DATA INPF/'100','400','1000','2000','4000','10000','100000'/
	REAL LOCF(0:6)
	  DATA LOCF/100,400,1000,2000,4000,10000,1000000/
C-
 10	CONTINUE
	MODACT=NMO_USE+NMO_MER+NMO_SAV+NMO_BAN+NMO_TIM !DEFAULT:
C						    USE,MERGE,SAVE,BAND,TIME
	IF (.NOT.WNDPAR('MODEL_ACTION',STR,5*LEN(STR(1)),J0,
	1		'MERGE,BAND,TIME,NOINPOL,BEAM')) THEN
	  GOTO 10				!MUST SPECIFY
	END IF
	IF (J0.EQ.-1) THEN			!*
	  STR(1)='MERGE'
	  STR(2)='BAND'
	  STR(3)='TIME'
	  STR(4)='NOINPOL'
	  STR(5)='BEAM'
	ELSE IF (J0.LT.4) THEN
	  GOTO 10				!MUST SPECIFY
	END IF
	IF (STR(1)(1:3).EQ.'MER') THEN		!SCAN SAVE TYPE
	  MODACT=IOR(NMO_USE+NMO_MER+NMO_SAV,
	1		IAND(NOT(NMO_USAGE),MODACT))
	ELSE IF (STR(1)(1:3).EQ.'ADD') THEN
	  MODACT=IOR(NMO_USE+NMO_ADD+NMO_SAV,
	1		IAND(NOT(NMO_USAGE),MODACT))
	ELSE IF (STR(1)(1:3).EQ.'NEW') THEN
	  MODACT=IOR(NMO_SAV,IAND(NOT(NMO_USAGE),MODACT))
	ELSE IF (STR(1)(1:3).EQ.'TEM') THEN
	  MODACT=IOR(0,IAND(NOT(NMO_USAGE),MODACT))
	ELSE IF (STR(1)(1:3).EQ.'INC') THEN
	  MODACT=IOR(NMO_USE,IAND(NOT(NMO_USAGE),MODACT))
	ELSE
	  GOTO 10
	END IF
	IF (STR(2)(1:3).EQ.'BAN') THEN		!BAND SMEARING
	  MODACT=IOR(NMO_BAN,IAND(NOT(NMO_BAN),MODACT))
	ELSE IF (STR(2)(1:3).EQ.'NOB') THEN
	  MODACT=IOR(0,IAND(NOT(NMO_BAN),MODACT))
	END IF
	IF (STR(3)(1:3).EQ.'TIM') THEN		!TIME SMEARING
	  MODACT=IOR(NMO_TIM,IAND(NOT(NMO_TIM),MODACT))
	ELSE IF (STR(3)(1:3).EQ.'NOT') THEN
	  MODACT=IOR(0,IAND(NOT(NMO_TIM),MODACT))
	END IF
	IF (STR(4)(1:3).EQ.'INP') THEN		!INSTRUM. POL.
C	  CALL WNCTXT(F_TP,'Not yet implemented...')
C	  MODACT=IOR(0,IAND(NOT(NMO_IPO),MODACT)) !NOINP
	  CALL WNCTXT(F_TP,'Good luck, there you go...')
	  MODACT=IOR(NMO_IPO,IAND(NOT(NMO_IPO),MODACT))	!INPOL
	ELSE IF (STR(4)(1:3).EQ.'NOI') THEN
	  MODACT=IOR(0,IAND(NOT(NMO_IPO),MODACT))
	END IF
	IF (STR(5)(1:3).EQ.'BEA') THEN		!BEAM CORRECTION
	  MODACT=IOR(NMO_BEA,IAND(NOT(NMO_BEA),MODACT))
	ELSE IF (STR(5)(1:3).EQ.'NOB') THEN
	  MODACT=IOR(0,IAND(NOT(NMO_BEA),MODACT))
	END IF
	GOTO 100
C
C NMOMUJ
C
	ENTRY NMOMUJ(UACT)
C
	MODACT=UACT				!SET ACTION WANTED
	GOTO 100
C
C INSTRUMENTAL POLARISATION
C
 100	CONTINUE
	IF (IAND(MODACT,NMO_IPO).NE.0 .AND. INPOLF(0).EQ.0) THEN !STILL TO DO
	 DO I=0,2				!Q,U,V
	  DO I1=0,6				!FREQUENCIES
 20	    CONTINUE
	    IF (.NOT.WNDPAR('INPOL'//INPC(I)//'_'//INPF(I1),INPOL(0,I,I1),
	1		10*LB_E,J0)) THEN
	      GOTO 20
	    END IF
	    IF (J0.NE.10) GOTO 20		!MUST SPECIFY EXACTLY
	    INPOLF(I1)=LOCF(I1)			!SET FREQUENCY
	  END DO
	 END DO
	END IF
C
	RETURN
C
C
	END
