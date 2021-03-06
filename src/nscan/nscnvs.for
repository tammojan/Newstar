C+ NSCNVS.FOR
C  WNB 900907
C
C  Revisions:
C	WNB 920825	Scale phi
C	WNB 920828	Correct MJD for aborted obs. in Wbork
C	WNB 920831	Make XX..YY data from Stokes Linobs output
C	WNB 921221	Add Parallactic angle
C	HjV 930311	Change some text
C	WNB 930607	New weights: STH version 2 to 3
C	HJV 930618	Symbolic names for mask bits in CBITS_O_DEF
C	CMV 930730	Corrected Stokes dipole conversion 
C	WNB 930817	Change to CBITS_DEF
C	WNB 930819	Dipole codes; version 3 to 4
C	WNB 930819	Split off NSCNOP with non-version part
C	WNB 931008	Add MINST
C
	SUBROUTINE NSCNVS
C
C  Convert SCN file to newest format
C
C  Result:
C
C	CALL NSCNVS	will convert a SCN file to newest version
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'NSC_DEF'
	INCLUDE 'CBITS_DEF'
	INCLUDE 'GFH_O_DEF'		!GENERAL FILE HEADER
	INCLUDE 'SGH_O_DEF'		!SUB-GROUP HEADER
	INCLUDE 'STH_O_DEF'		!SET HEADER
	INCLUDE 'SCH_O_DEF'		!SCAN HEADER
	INCLUDE 'MDH_O_DEF'		!MODEL HEADER
	INCLUDE 'FDW_O_DEF'		!TAPE BLOCKS
	INCLUDE 'FDX_O_DEF'
	INCLUDE 'OHW_O_DEF'
	INCLUDE 'SCW_O_DEF'
	INCLUDE 'SHW_O_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
C
C  Function references:
C
	LOGICAL WNFRD			!READ DATA
	LOGICAL WNFWR			!WRITE DATA
	INTEGER WNFEOF			!GET FILE POINTER
	CHARACTER*32 WNTTSG		!PRINT SET NAME
	LOGICAL NSCSTH			!GET A SET WITH NO VERSION CHECK
	LOGICAL NSCSCH			!READ SCAN HEADER
	LOGICAL NSCSCW			!WRITE SCAN HEADER
	LOGICAL NMORDX			!READ MODEL FROM SCAN FILE
C
C  Data declarations:
C
	INTEGER SET(0:7,0:1)		!ALL SETS
	INTEGER STHP			!SET HEADER POINTER
	INTEGER SNAM(0:7)		!SET NAME
	INTEGER TNAM(0:7)		!TEST NAME
	LOGICAL PNAM			!PRINT ASKED
	REAL UV0(0:3)			!U,V DATA
	REAL TF(0:1)			!BAND/TIME SMEARING
	INTEGER MINST			!INSTRUMENT
	DOUBLE PRECISION FRQ0		!BASIC FREQUENCY
	REAL LM0(0:1)			!L,M OFFSET
        INTEGER*2 IFR(0:STHIFR-1)       !IFR LIST
        COMPLEX CMOD(0:3,0:STHIFR-1)    !MODEL
	INTEGER*2 LDAT(0:2,0:4*STHIFR-1) !DATA BUFFER
	BYTE STH(0:STH__L-1)		!SET HEADER
	  INTEGER*2 STHI(0:STH__L/LB_I-1)
	  INTEGER STHJ(0:STH__L/LB_J-1)
	  REAL STHE(0:STH__L/LB_E-1)
	  DOUBLE PRECISION STHD(0:STH__L/LB_D-1)
	  EQUIVALENCE (STH,STHI,STHJ,STHE,STHD)
	BYTE SCH(0:SCH__L-1)		!SCAN HEADER
	  INTEGER SCHJ(0:SCH__L/LB_J-1)
	  REAL SCHE(0:SCH__L/LB_E-1)
	  EQUIVALENCE (SCH,SCHJ,SCHE)
	BYTE OHW(0:OHW__L-1)		!OH BLOCK
	  INTEGER*2 OHWI(0:OHW__L/LB_I-1)
	  INTEGER OHWJ(0:OHW__L/LB_J-1)
	  REAL OHWE(0:OHW__L/LB_E-1)
	  DOUBLE PRECISION OHWD(0:OHW__L/LB_D-1)
	  EQUIVALENCE (OHW,OHWI,OHWJ,OHWE,OHWD)
	BYTE SCW(0:SCW__L-1)		!SC BLOCK
	  INTEGER*2 SCWI(0:SCW__L/LB_I-1)
	  INTEGER SCWJ(0:SCW__L/LB_J-1)
	  REAL SCWE(0:SCW__L/LB_E-1)
	  DOUBLE PRECISION SCWD(0:SCW__L/LB_D-1)
	  EQUIVALENCE (SCW,SCWI,SCWJ,SCWE,SCWD)
	BYTE SGH(0:SGH__L-1)		!SUB-GROUP HEADER
	  INTEGER*2 SGHI(0:SGH__L/LB_I-1)
	  INTEGER SGHJ(0:SGH__L/LB_J-1)
	  REAL SGHE(0:SGH__L/LB_E-1)
	  EQUIVALENCE (SGH,SGHI,SGHJ,SGHE)
	BYTE MDH(0:MDH__L-1)		!MODEL HEADER
	  INTEGER MDHJ(0:MDH__L/LB_J-1)
	  REAL MDHE(0:MDH__L/LB_E-1)
	  DOUBLE PRECISION MDHD(0:MDH__L/LB_D-1)
	  EQUIVALENCE (MDH,MDHJ,MDHE,MDHD)
C-
C
C INIT
C
	DO I=0,7				!SET SET *.*.*.*.*.*.*
	  DO I1=0,1
	    SET(I,I1)=0
	  END DO
	END DO
	SET(0,0)=1				!1 LINE
	DO I=0,7
	  SET(I,1)=-1				!*
	  TNAM(I)=-1				!TEST PRINT NAME
	END DO
C
C DO ALL SETS
C
	DO WHILE (NSCSTH(FCAOUT,SET,STH,STHP,SNAM))	!GET SET
	  PNAM=.FALSE.					!ASSUME NO PRINT
	  DO I=0,3
	    IF (TNAM(I).NE.SNAM(I)) PNAM=.TRUE.		!PRINT
	  END DO
	  DO I=0,3
	    TNAM(I)=SNAM(I)				!NEW TEST SET
	  END DO
C
C GET OH, SC AND IFR
C
	  IF (STHJ(STH_OHP_J).NE.0) THEN
	    IF (.NOT.WNFRD(FCAOUT,STHJ(STH_NOH_J),OHW,
	1		STHJ(STH_OHP_J))) GOTO 10	!READ OH
	  END IF
	  IF  (STHJ(STH_SCP_J).NE.0) THEN
	    IF (.NOT.WNFRD(FCAOUT,STHJ(STH_NSC_J),SCW,
	1		STHJ(STH_SCP_J))) GOTO 10	!READ SC
	  END IF
	  IF (.NOT.WNFRD(FCAOUT,LB_I*STHJ(STH_NIFR_J),IFR,
	1		STHJ(STH_IFRP_J))) GOTO 10	!READ IFRS
C
C MAKE FROM VERSION 1
C
	  IF (STHI(STH_VER_I).EQ.1) THEN		!STILL VERSION 1
	    J=WNFEOF(FCAOUT)				!NEW SET HEADER POINTER
	    STHI(STH_LEN_I)=STH__L			!NEW LENGTH
	    STHI(STH_VER_I)=MIN(2,STHHDV)		!NEW VERSION (2)
	    CALL WNGMV(68,STH(340),STHE(STH_REDNS_E))	!SHIFT DATA
	    CALL WNGMVZ(STH__L-STH_POLC_1,STHE(STH_POLC_E)) !CLEAR REMAINDER
	    J1=STHJ(STH_LINK_J+0)			!NEXT SET POINTER
	    J2=STHJ(STH_LINK_J+1)			!PREVIOUS SET POINTER
	    STHP=J					!NEW HEADER POINTER
	    IF (.NOT.WNFWR(FCAOUT,STH__L,STH(0),STHP)) GOTO 10 !REWRITE HEADER
	    IF (.NOT.WNFWR(FCAOUT,LB_J,STHP,J2)) GOTO 10 !LINK NEW
	    IF (.NOT.WNFWR(FCAOUT,LB_J,STHP,J1+4)) GOTO 10
	    IF (.NOT.WNFRD(FCAOUT,SGH__L,SGH(0),SET(3,0))) GOTO 10 !READ SGH
	    SGHJ(SGH_DATAP_J)=STHP			!SET DATA POINTER
	    IF (.NOT.WNFWR(FCAOUT,SGH__L,SGH(0),SET(3,0))) GOTO 10 !WRITE SGH
	    IF (PNAM) CALL WNCTXT(F_TP,
	1		'Sector(s) !AS converted from version 1',
	1		WNTTSG(TNAM,0))
	  END IF					!VERSION 1
C
C MAKE FROM VERSION 2
C
	  IF (STHI(STH_VER_I).EQ.2) THEN		!STILL VERSION 2
	    STHI(STH_VER_I)=MIN(3,STHHDV)		!NEW VERSION
	    DO I=0,STHJ(STH_SCN_J)-1			!ALL SCANS
	      IF (.NOT.NSCSCH(FCAOUT,STH,0,I,0,0,SCH)) GOTO 10 !READ SCAN HEAD
	      IF (.NOT.WNFRD(FCAOUT,STHJ(STH_SCNL_J)-SCH__L,
	1		LDAT,STHJ(STH_SCNP_J)+
	1			STHJ(STH_SCNL_J)*I+SCH__L)) GOTO 10 !READ SCAN
	      IF (IAND(SCHJ(SCH_BITS_J),1).EQ.0) THEN	!NOT DELETED
		SCHJ(SCH_BITS_J)=0
	      ELSE
		SCHJ(SCH_BITS_J)=FL_OLD			!DELETED
	      END IF
	      IF (.NOT.NSCSCW(FCAOUT,STH,0,I,0,0,SCH)) GOTO 10 !WRITE HEADER
	      DO I1=0,STHJ(STH_NIFR_J)-1		!ALL IFRS
		DO I2=0,STHI(STH_PLN_I)-1		!ALL POL.
		  I3=ABS(LDAT(0,4*I1+I2))		!OLD WEIGHT/FLAG
		  IF (LDAT(0,4*I1+I2).LT.0) THEN	!FLAGGED DATA
		    LDAT(0,4*I1+I2)=MIN(I3,255)+FL_OLD	!SET NEW WEIGHT/FLAG
		  ELSE
		    LDAT(0,4*I1+I2)=MIN(I3,255)		!SET NEW WEIGHT
		  END IF
		END DO
	      END DO
	      IF (.NOT.WNFWR(FCAOUT,STHJ(STH_SCNL_J)-SCH__L,
	1		LDAT,STHJ(STH_SCNP_J)+
	1			STHJ(STH_SCNL_J)*I+SCH__L)) GOTO 10 !WRITE DATA
	    END DO
	    IF (PNAM) CALL WNCTXT(F_TP,
	1		'Sector(s) !AS converted from version 2',
	1		WNTTSG(TNAM,0))
	  END IF					!VERSION 2
C
C MAKE FROM VERSION 3
C
	  IF (STHI(STH_VER_I).EQ.3) THEN		!STILL VERSION 3
	    STHI(STH_VER_I)=MIN(4,STHHDV)		!NEW VERSION
	    IF (STHJ(STH_OHP_J).NE.0 .AND.
	1		STHJ(STH_NOH_J).GT.OHW_POLC_1) THEN
	      STHJ(STH_DIPC_J)=0			!SET DIPOLE CODE
	      I1=OHWI(OHW_POLC_I)
	      DO I=0,STHTEL-1
		IF (I.LT.10) THEN                     !WEST TEL.
		  STHJ(STH_DIPC_J)=STHJ(STH_DIPC_J)+ISHFT(I1/4,2*I)
	   	ELSE                                  !EAST TEL
		  STHJ(STH_DIPC_J)=STHJ(STH_DIPC_J)+ISHFT(MOD(I1,4),2*I)
		END IF
	      END DO
	    ELSE
	      STHJ(STH_DIPC_J)='0aaaaaaa'X		!ASSUME PARALLEL
	    END IF
	    IF (STHI(STH_PLN_I).NE.4 .AND.
	1		STHJ(STH_MDL_J).NE.0 .AND.
	1		STHJ(STH_MDD_J).NE.0) THEN	!MODEL PRESENT
	      IF (NMORDX(FCAOUT,STHJ(STH_MDL_J),6)) THEN !READ MODEL
	        IF (.NOT.WNFRD(FCAOUT,MDH__L,MDH,STHJ(STH_MDL_J)))
	1			GOTO 10			!READ MODEL HEADER
	        CALL NMOMUJ(IOR(8,IAND(NOT(255),MDHJ(MDH_ACT_J)))) !SET ACTION
		CALL NMOMST(MDHJ(MDH_TYP_J),MDHD(MDH_RA_D),
	1		MDHD(MDH_DEC_D),STH,LM0,FRQ0,TF,MINST) !GET SOME DATA
		DO I=0,STHJ(STH_SCN_J)-1		!ALL SCANS
	          IF (.NOT.NSCSCH(FCAOUT,STH,0,I,0,0,SCH)) GOTO 10 !READ HEAD
		  CALL NMOMUV(MDHJ(MDH_TYP_J),MDHD(MDH_RA_D),
	1		MDHD(MDH_DEC_D),STH,SCH,UV0)	!GET DATA
		  CALL NMOMUC(6,UV0,LM0,FRQ0,STHE(STH_RTP_E),
	1		4,STHJ(STH_NIFR_J),IFR,TF,MINST,CMOD) !GET MODEL
		  IF (.NOT.WNFWR(FCAOUT,4*STHJ(STH_NIFR_J)*LB_X,
	1		CMOD,STHJ(STH_MDD_J)+4*STHJ(STH_NIFR_J)*LB_X))
	1			GOTO 10			!SAVE MODEL
		END DO					!SCANS
	      END IF					!MODEL READ
	    END IF					!MODEL PRESENT
	    IF (PNAM) CALL WNCTXT(F_TP,
	1		'Sector(s) !AS converted from version 3',
	1		WNTTSG(TNAM,0))
	  END IF					!VERSION 3
C
C WRITE NEW HEADER
C
	  IF (.NOT.WNFWR(FCAOUT,STH__L,STH(0),STHP)) THEN !REWRITE SET HEADER
 10	    CONTINUE
	    CALL WNCTXT(F_TP,'!/Error rewriting Sector(s)')
	    GOTO 900
	  END IF
	END DO
C
C READY
C
 800	CONTINUE
	CALL WNFCL(FCAOUT)				!CLOSE FILE
C
	RETURN
C
C ERROR
C
 900	CONTINUE
	CALL WNFCL(FCAOUT)				!CLOSE FILE
	RETURN						!READY
C
C
	END
