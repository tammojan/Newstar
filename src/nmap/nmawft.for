C+ NMAWFT.FOR
C  WNB 910403
C
C  Revisions:
C	WNB 920818	Longer header
C	WNB 920828	Correct label count
C	WNB 921119	Add real format; cube
C	WNB 930118	Correct FMXMN(0)
C	WNB 930224	Typo (FRQ0) for FMXMN; close wrong place
C	WNB 930304	Make cube output contiguous
C	JPH 950117	NMAWFH becomes a function, quit if .FALSE. returned
C			 (This is a backtracking mechanism.) - Make FITS header
C			 before opening output, so latter is skipped in case of
C			 backtrack.
C			Find free label if wildcard specified. 
C			 (Up to now, * was equivalent to 1.)
C	HjV 970408	Ask COMMENT only for first CUBE
C
C
	SUBROUTINE NMAWFT(TP)
C
C  Write maps in FITS format
C
C
C  Result:
C
C	CALL NMAWFT( TP_J:I)	Write FITS header with type TP (16 or 32)
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'NMA_DEF'
	INCLUDE 'MPH_O_DEF'		!MAP HEADER
C
C  Parameters:
C
	INTEGER FBFLEN,FHDLEN		!FITS BUFFER LENGTH, HEADER LENGTH
	  PARAMETER (FBFLEN=2880)
	  PARAMETER (FHDLEN=2*FBFLEN)
C
C  Arguments:
C
	INTEGER TP			!# OF BITS (16 OR 32) PER DATA POINT
C
C  Function references:
C
	LOGICAL WNFMOU			!MOUNT TAPE
	LOGICAL WNFOP,WNFOPF		!OPEN FILE
	LOGICAL WNFWR			!WRITE DATA
	LOGICAL WNFRD			!READ DATA
	INTEGER WNFTLB			!CURRENT TAPE LABEL
	CHARACTER*32 WNTTSG		!MAP SET NAME
	INTEGER WNCALN			!STRING LENGTH
	LOGICAL NMASTG			!GET MAP SET
	LOGICAL NMAWFH			!make fits header
C
C  Data declarations:
C
	CHARACTER*160 OFILE		!FILE NAME
	INTEGER MPHP			!MAP HEADER POINTER
	BYTE MPH(0:MPHHDL-1)		!MAP HEADER
	  INTEGER*2 MPHI(0:MPHHDL/2-1)
	  INTEGER MPHJ(0:MPHHDL/4-1)
	  REAL MPHE(0:MPHHDL/4-1)
	  DOUBLE PRECISION MPHD(0:MPHHDL/8-1)
	  EQUIVALENCE (MPH,MPHI,MPHJ,MPHE,MPHD)
	CHARACTER*(FHDLEN) FBUF		!FITS BUFFER
	  BYTE LFBUF(0:FHDLEN-1)
	  INTEGER*2 IFBUF(0:FHDLEN/2-1)
	  INTEGER JFBUF(0:FHDLEN/4-1)
	  REAL EFBUF(0:FHDLEN/4-1)
	  EQUIVALENCE (FBUF,LFBUF,IFBUF,JFBUF,EFBUF)
	REAL INBUF(0:16383)		!MAP LINE BUFFER
	INTEGER JI1,JI2			!COUNTS
	REAL SCAL			!DATA SCALE
	INTEGER*2 ITRB(0:3)		!DATA TRANSLATION I
	  DATA ITRB/2,1440,0,1/
	INTEGER*2 JTRB(0:3)		!DATA TRANSLATION J
	  DATA JTRB/3,720,0,1/
	INTEGER*2 ETRB(0:3)		!DATA TRANSLATION E
	  DATA ETRB/4,720,0,1/
	LOGICAL FMAP,FLINE		!FIRST MAP, LINE POSSIBLE
	REAL CMAX,CMIN			!CURRENT MAX/MIN
	DOUBLE PRECISION CBW,ABW	!CURRENT, AVERAGE BANDWIDTH
	DOUBLE PRECISION CDF		!CURRENT CHANNEL INCREMENT
	INTEGER CSZ(0:1)		!CURRENT SIZES
	DOUBLE PRECISION CCRD(0:1)	!CURRENT COORDINATES
	INTEGER CNF,CNM			!MAP COUNT
	DOUBLE PRECISION FMXMN(0:1)	!CURRENT MAX/MIN FREQ.
	DOUBLE PRECISION CFRQ		!CURRENT FREQ.
C-
C
C INIT
C
C
C GET INFO MAPS
C
	FMAP=.TRUE.				!FIRST MAP
	FLINE=.TRUE.				!ASSUME LINE POSSIBLE
	CNF=0					!NO MAPS SEEN
	CDF=0					!FREQ. INCREMENT
	DO WHILE(NMASTG(FCAOUT,SETS,MPH,MPHP,SGNR)) !READ MAPS
	  IF (FMAP) THEN
	    FMAP=.FALSE.			!NOT FIRST
	    CMAX=MPHE(MPH_MAX_E)		!CURRENT MAX/MIN
	    CMIN=MPHE(MPH_MIN_E)
	    CBW=MPHD(MPH_BDW_D)			!BANDWIDTH
	    CSZ(0)=MPHJ(MPH_NRA_J)		!SIZE
	    CSZ(1)=MPHJ(MPH_NDEC_J)
	    CCRD(0)=MPHD(MPH_RA_D)		!RA/DEC
	    CCRD(1)=MPHD(MPH_DEC_D)
	    CNF=1				!# OF MAPS
	    ABW=CBW				!AVERAGE BANDWIDTH
	    FMXMN(0)=MPHD(MPH_FRQV_D)		!FREQ.
	    FMXMN(1)=MPHD(MPH_FRQV_D)
	    CFRQ=MPHD(MPH_FRQV_D)
	  ELSE
	    CMAX=MAX(CMAX,MPHE(MPH_MAX_E))
	    CMIN=MIN(CMIN,MPHE(MPH_MIN_E))
	    IF (ABS(CBW-MPHD(MPH_BDW_D)).GT.1E-3*CBW) FLINE=.FALSE. !NO LINE
	    IF (CSZ(0)-MPHJ(MPH_NRA_J).NE.0) FLINE=.FALSE.
	    IF (CSZ(1)-MPHJ(MPH_NDEC_J).NE.0) FLINE=.FALSE.
	    IF (ABS(CCRD(0)-MPHD(MPH_RA_D)).GT.1E-5) FLINE=.FALSE.
	    IF (ABS(CCRD(1)-MPHD(MPH_DEC_D)).GT.1E-5) FLINE=.FALSE.
	    ABW=ABW+MPHD(MPH_BDW_D)		!AVERAGE BANDWIDTH
	    IF (CNF.EQ.1) THEN			!2ND MAP
	      CDF=MPHD(MPH_FRQV_D)-CFRQ		!FREQ. INTERVAL
	    ELSE
	      IF (ABS(MPHD(MPH_FRQV_D)-CFRQ-CDF).GT.1E-2*ABS(CDF))
	1		FLINE=.FALSE.		!CANNOT DO LINE
	    END IF
	    CFRQ=MPHD(MPH_FRQV_D)
	    FMXMN(0)=MAX(FMXMN(0),MPHD(MPH_FRQV_D))
	    FMXMN(1)=MIN(FMXMN(1),MPHD(MPH_FRQV_D))
	    CNF=CNF+1				!COUNT MAPS
	  END IF
	END DO
	IF (CNF.GT.0) ABW=ABW/CNF		!AVERAGE BANDWIDTH
	IF (POLT(0,0).EQ.1 .AND. .NOT.FLINE) THEN !CUBIC ASKED, BUT NOT TO DO
	  CALL WNCTXT(F_TP,'Cubic asked, but maps do not conform')
	  POLT(0,0)=0				!SET NO CUBIC
	END IF
	IF (POLT(0,0).EQ.0) THEN		!NO CUBE
	  CNM=1					!SIMULTANEOUS MAPS
	ELSE
	  CNM=CNF
	END IF
	IF (CDF.LT.0) THEN			!REVERSE ORDER FREQ.
	  D0=FMXMN(0)
	  FMXMN(0)=FMXMN(1)
	  FMXMN(1)=D0
	END IF
C
C GET MAP
C
	FMAP=.TRUE.				!FIRST MAP
	J4=0					!OUTPUT POINT COUNT
 50	CONTINUE
	IF (.NOT.NMASTG(FCAOUT,SETS,MPH,MPHP,SGNR)) GOTO 810 !NO MORE MAPS
C
C Make FITS header in core. 
C  NMAWFH prompts for user comments, returns .FALSE. if user requests backtrack
C
	IF (FMAP) THEN				! skip if CUBE
	  IF (POLT(0,0).EQ.1) THEN		!CUBE
	    MPHE(MPH_MAX_E)=CMAX		!CURRENT MAX/MIN
	    MPHE(MPH_MIN_E)=CMIN
	  END IF
	  IF (.NOT.NMAWFH(FBUF,TP,CWGVAL,OLABEL-1,
	1	MPH,MPHI,MPHJ,MPHE,MPHD,CNM,CNF,FMXMN,ABW,
	1	SCAL)) GOTO 800			! GET HEADER
C
C For wildcard (OLABEL<0) find the first non-existent label. Open output
C	
	  IF (OUNIT.EQ.'D') THEN
	    IF (OLABEL.LE.0) THEN
	      OLABEL=-1
	      DO WHILE (OLABEL.LT.0)
	        CALL WNCTXS(OFILE,'!AS\.!6$ZJ',FILIN,-OLABEL) !MAKE FILE NAME
	        IF (WNFOP(FCATAP,OFILE(1:WNCALN(OFILE)),'R')) THEN
		  OLABEL=OLABEL-1
		ELSE
		  GOTO 30
	        ENDIF
	      ENDDO
	    ENDIF
 30	    CONTINUE
	    OLABEL=-OLABEL
C
	    CALL WNCTXS(OFILE,'!AS\.!6$ZJ',FILIN,ABS(OLABEL)) !MAKE FILE NAME
!!	    OLABEL=OLABEL+1			!COUNT LABELS
	    IF (.NOT.WNFOP(FCATAP,OFILE(1:WNCALN(OFILE)),'W')) THEN
	      CALL WNCTXT(F_TP,'Cannot open output file !AS',OFILE)
	      GOTO 800
	    END IF
	  ELSE
	    IF (OLABEL.LE.0) THEN			!AT END OF TAPE
	      IF (.NOT.WNFOPF(FCATAP,' ','W',0,FBFLEN,80,0)) THEN
 51	        CONTINUE
	        CALL WNCTXT(F_TP,'Cannot open output tape')
	        GOTO 800
	      END IF
	      OLABEL=WNFTLB(FCATAP)		!LABEL
	    ELSE
	      IF (.NOT.WNFOPF(FCATAP,' ','W',0,FBFLEN,
	1			80,OLABEL)) GOTO 51 !OPEN TAPE
	    END IF
	    CALL WNCTXS(OFILE,'!6$ZJ',OLABEL)	!LABEL NAME
	    OLABEL=OLABEL+1			!NEXT LABEL
	  END IF
	  CALL WNCTXT(F_TP,'Writing !AS to file/label !AS',
	1		WNTTSG(SGNR,0),OFILE)
C
C WRITE HEADER DATA
C
	  J2=0					!OUTPUT POINTER
	  DO I=0,FHDLEN-1,FBFLEN
	    IF (.NOT.WNFWR(FCATAP,FBFLEN,LFBUF(I),J2)) THEN !WRITE FITS HEADER
 52	      CONTINUE
	      CALL WNCTXT(F_TP,'Error writing FITS data')
	      GOTO 800
	    END IF
	    J2=J2+FBFLEN
	  END DO
	  IF (POLT(0,0).EQ.1 .AND. CNF.GT.1) FMAP=.FALSE. !WRITE CUBE
	ENDIF
C
C WRITE MAP DATA
C
	J3=MPHJ(MPH_MDP_J)			!INPUT DATA POINTER
	JI1=MPHJ(MPH_NRA_J)			!POINTS PER LINE
	JI2=MPHJ(MPH_NDEC_J)			!LINES
	DO I3=1,JI2				!ALL LINES
	  IF (.NOT.WNFRD(FCAOUT,LB_E*JI1,INBUF,J3)) THEN !READ A LINE
	    CALL WNCTXT(F_TP,'Error reading data')
	    GOTO 800
	  END IF
	  J3=J3+LB_E*JI1			!INPUT POINTER UPDATE
	  DO I4=0,JI1-1				!OUTPUT WORDS
	    IF (TP.EQ.16) THEN
	      IFBUF(J4/LB_I)=INBUF(I4)*SCAL	!SCALE DATA
	      J4=J4+LB_I
	    ELSE IF (TP.EQ.32) THEN		!32 BITS
	      JFBUF(J4/LB_J)=INBUF(I4)*SCAL	!SCALE DATA
	      J4=J4+LB_J
	    ELSE				!REAL
	      EFBUF(J4/LB_E)=INBUF(I4)*SCAL	!SCALE DATA
	      J4=J4+LB_E
	    END IF
	    IF (J4.GE.FBFLEN) THEN		!OUTPUT BLOCK
	      IF (TP.EQ.16) THEN		!MAKE IEEE FORMAT
	        CALL WNTTLT(FBFLEN,IFBUF,ITRB,5)
	      ELSE IF (TP.EQ.32) THEN
	        CALL WNTTLT(FBFLEN,JFBUF,JTRB,5)
	      ELSE
		CALL WNTTLT(FBFLEN,EFBUF,ETRB,5)
	      END IF
	      IF (.NOT.WNFWR(FCATAP,FBFLEN,LFBUF,J2)) GOTO 52 !WRITE FITS BLOCK
	      J2=J2+FBFLEN			!OUTPUT DISK POINTER
	      J4=0				!OUTPUT BUF POINTER
	    END IF
	  END DO
	END DO
	IF (FMAP .AND. J4.GT.0) THEN		!OUTPUT LAST FOR SINGLE MAP
	  CALL WNGMVZ(FBFLEN-J4,LFBUF(J4))	!ZERO LAST BLOCK
	  IF (TP.EQ.16) THEN			!MAKE IEEE FORMAT
	    CALL WNTTLT(FBFLEN,IFBUF,ITRB,5)
	  ELSE IF (TP.EQ.32) THEN
	    CALL WNTTLT(FBFLEN,JFBUF,JTRB,5)
	  ELSE
	    CALL WNTTLT(FBFLEN,EFBUF,ETRB,5)
	  END IF
	  IF (.NOT.WNFWR(FCATAP,FBFLEN,LFBUF,J2)) GOTO 52 !WRITE FITS BLOCK
	  J2=J2+FBFLEN				!OUTPUT DISK POINTER
	  J4=0					!OUTPUT BUF POINTER
	END IF
	GOTO 50					!NEXT MAP
C
C READY
C
 810	CONTINUE
	IF (J4.GT.0) THEN			!OUTPUT LAST FOR CUBE
	  CALL WNGMVZ(FBFLEN-J4,LFBUF(J4))	!ZERO LAST BLOCK
	  IF (TP.EQ.16) THEN			!MAKE IEEE FORMAT
	    CALL WNTTLT(FBFLEN,IFBUF,ITRB,5)
	  ELSE IF (TP.EQ.32) THEN
	    CALL WNTTLT(FBFLEN,JFBUF,JTRB,5)
	  ELSE
	    CALL WNTTLT(FBFLEN,EFBUF,ETRB,5)
	  END IF
	  IF (.NOT.WNFWR(FCATAP,FBFLEN,LFBUF,J2)) GOTO 52 !WRITE FITS BLOCK
	  J2=J2+FBFLEN				!OUTPUT DISK POINTER
	  J4=0					!OUTPUT BUF POINTER
	END IF
 800	CONTINUE
	CALL WNFCL(FCATAP)			!CLOSE OUTPUT
	CALL WNFDMO(FCATAP)			!DISMOUNT OUTPUT
	CALL WNFCL(FCAOUT)			!CLOSE INPUT
C
	RETURN
C
C
	END 
