C+ NMAP.FOR
C  WNB 910219
C
C  Revisions:
C	WNB 910828	Add run option
C	WNB 911104	Add mosaic combine
C	WNB 920811	Add loops for Fiddle sums
C	WNB 921119	Add WRLFITS
C	WNB 930929	Add Fiddle LOAD
C	WNB 930930	Use Fiddle codes
C       HjV 940714	Add RFITS
C	JPH 950117	Return to NMADAT after most actions
C
C
	SUBROUTINE NMAP
C
C  Main routine to handle Map files
C
C  Result:
C
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'NMA_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
C
C  Function references:
C
	LOGICAL WNDXLN		!TEST LOOP
	LOGICAL WNDRUN		!TEST RUN OPTION
C
C  Data declarations:
C
	INTEGER FCADUM		!DUMMY FCA
	  DATA FCADUM/0/
C-
C
C PRELIMINARIES
C
	CALL NMAINI				!INIT PROGRAM
C
C DISTRIBUTE
C
 11	CONTINUE
	OPT=' '					!MAKE SURE NOT FIDDLE
 10	CONTINUE
	CALL NMADAT				!GET USER DATA
	IF (OPT.EQ.'MAK') THEN			!MAKE MAPS
	  IF (.NOT.WNDRUN()) CALL WNGEX		!DO NOT RUN
	  CALL NMAMAK
	  GOTO 10
	ELSE IF (OPT.EQ.'SHO') THEN		!SHOW MAP DATA
	  CALL NMAPRT
	  GOTO 10				!RETRY
	ELSE IF (OPT.EQ.'FRO') THEN		!FROM OLD FORMAT
	  CALL NMAOFR
	  GOTO 10				!RETRY
	ELSE IF (OPT.EQ.'TO_') THEN		!TO OLD FORMAT
	  IF (.NOT.WNDRUN()) CALL WNGEX		!DO NOT RUN
	  CALL NMAOTO
	ELSE IF (OPT.EQ.'RFI') THEN		!READ FITS
	  IF (.NOT.WNDRUN()) CALL WNGEX		!DO NOT RUN
	  CALL NMARFT
	  GOTO 10
	ELSE IF (OPT.EQ.'W16') THEN		!16 BITS FITS
	  IF (.NOT.WNDRUN()) CALL WNGEX		!DO NOT RUN
	  CALL NMAWFT(16)
	  GOTO 10
	ELSE IF (OPT.EQ.'W32') THEN		!32 BITS FITS
	  IF (.NOT.WNDRUN()) CALL WNGEX		!DO NOT RUN
	  CALL NMAWFT(32)
	  GOTO 10
	ELSE IF (OPT.EQ.'WRL') THEN		!32 BITS REAL FITS
	  IF (.NOT.WNDRUN()) CALL WNGEX		!DO NOT RUN
	  CALL NMAWFT(-32)
	  GOTO 10
	ELSE IF (OPT.EQ.'CVX') THEN		!CONVERT VAX TO LOCAL
	  CALL NMAXCV
	  GOTO 10				!RETRY
	ELSE IF (OPT.EQ.'NVS') THEN		!MAKE NEWEST VERSION
	  CALL NMANVS
	  GOTO 10				!RETRY
	ELSE IF (OPT.EQ.'FID') THEN		!FIDDLE
	  CALL WNDXLI(LPOFF)			!INIT LOOPS
	  CALL WNDSTR(FCADUM,SETS(0,0,1))	!RESET SET SEARCH
	  CALL WNDSTR(FCADUM,SETS(0,0,2))	!RESET SET SEARCH
	  IF (DATTYP.LE.FID_DUM) THEN		!QUIT
	    GOTO 11
	  ELSE IF (DATTYP.GE.FID_RHO) THEN	!LOAD/UNLOAD FOREIGN
	    CALL NMAFLD(DATTYP)
	  ELSE IF (DATTYP.GE.FID_MOS) THEN	!MOSAIC COMBINE
	    CALL NMAFMC(DATTYP)
	  ELSE IF (DATTYP.GE.FID_SUM .AND. DATTYP.LT.FID_EXT) THEN !SUM'S
	    DO WHILE (WNDXLN(LPOFF))		!LOOP
	      CALL NMAFID(DATTYP)		!DO FIDDLE
	    END DO
	  ELSE
	    CALL NMAFID(DATTYP)			!DO FIDDLE
	  END IF
	  GOTO 10				!RETRY
	END IF
C
	RETURN					!READY
C
C
	END
