C+ NMOBMR.FOR
C  WNB 930826
C
C  Revisions:
C	WNB 930928	Change to cater for multiple instruments and beams
C	CMV 930917	Various corrections
C
	LOGICAL FUNCTION NMOBMR()
C
C  Get (de-)beam factors
C
C  Result:
C
C	NMOBMR_L = NMOBMR ()		Get beam factors from user
C
C  PIN references
C
C	BEAM_SCALE
C	BEAM_DESCR
C	BEAM-FREQ_*
C	BEAM_FACTOR_*
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'BMD_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
C
C  Function references:
C
	LOGICAL WNDPAR		!GET USER DATA
C
C  Data declarations:
C
	CHARACTER*1 BCD		!INSTRUM. CODE
C-
C
C INIT
C
	NMOBMR=.TRUE.				!ASSUME OK
	IF (BEMNIN.GE.0) RETURN			!ALREADY THERE
C
C GET VALUES
C
C BEAM SCALE
C
 10	CONTINUE
	IF (.NOT.WNDPAR('BEAM_SCALE',BEMSC,LB_E,J0,'1.')) THEN
	  BEMSC=1.				!SET DEFAULT
	END IF
	IF (J0.NE.1) BEMSC=1.			!DEFAULT
C
C BEAM DESCRIPTORS
C
	IF (.NOT.WNDPAR('BEAM_DESCR',BEMCOD,BEMNDV*BEMMIN*LB_J,J0)) THEN
 11	  CONTINUE
	  BEMNIN=-1				!SET NOTHING READ
	  NMOBMR=.FALSE.			!RETURN ERROR
C
	  RETURN
	END IF
	IF (J0.LE.0) GOTO 10			!MUST SPECIFY
	IF (MOD(J0,BEMNDV).NE.0) GOTO 11	!INCORRECT # OF CODES
	BEMNIN=J0/BEMNDV			!# OF INSTRUMENTS DEFINED
	DO I=0,BEMNIN-1				!CHECK DESCRIPTOR
	  IF (BEMCOD(0,I).LT.0 .OR.
	1		BEMCOD(0,I).GE.BEMMIN) GOTO 11 !ILLEGAL FREQ_/FACTOR_
	  IF (BEMCOD(1,I).LT.0 .OR.
	1		BEMCOD(1,I).GT.BEMMTP) GOTO 11 !ILLEGAL TYPE
	  IF (BEMCOD(2,I).LT.1 .OR.
	1		BEMCOD(2,I).GT.BEMMFC) GOTO 11 !ILL. # FACTORS/FREQ
	  IF (BEMCOD(3,I).LT.1 .OR.
	1		BEMCOD(3,I).GT.BEMMFQ) GOTO 11 !ILL. # FREQ. RANGES
	END DO
C
C FREQUENCY RANGES AND FACTORS
C
	DO I=0,BEMNIN-1				!ALL DEFINED INSTRUMENTS
	  CALL WNCTXS(BCD,'!UJ',BEMCOD(0,I))	!INSTRUM. CODE
	  IF (.NOT.WNDPAR('BEAM_FREQ_'//BCD,BEMFQ(0,I),
	1		BEMMFQ*LB_E,J0)) THEN	!GET FREQ. RANGES
	    GOTO 11
	  END IF
	  IF (J0.LE.0) GOTO 10			!MUST SPECIFY
	  IF (J0.NE.BEMCOD(3,I)) GOTO 11	!ILLEGAL # OF RANGES
	  IF (.NOT.WNDPAR('BEAM_FACTOR_'//BCD,BEMFC(0,I),
	1		BEMMFQ*BEMMFC*LB_E,J0)) THEN !GET FACTORS
	    GOTO 11
	  END IF
	  IF (J0.LE.0) GOTO 10			!MUST SPECIFY
	  IF (J0.NE.BEMCOD(2,I)*BEMCOD(3,I)) GOTO 11 !ILLEGAL # OF FACTORS
	END DO
C
	RETURN
C
C
	END
