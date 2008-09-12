C+ NSCCVX.FOR
C  WNB 900822
C
C  Revisions:
C	WNB 921201	Text only
C	WNB 930127	Correct MDD conversion
C	WNB 930803	Change IFR_T to LIFR_T
C	WNB 930819	Always 4 polarisations
C	CMV 940518	Add IFH block
C	CMV 960624	Increase buffer, more diagnostics
C
	SUBROUTINE NSCCVX
C
C  Convert SCN file from VAX to local format
C
C  Result:
C
C	CALL NSCCVX	will convert a SCN file from VAX to local format
C
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'NSC_DEF'
	INCLUDE 'GFH_O_DEF'		!GENERAL FILE HEADER
	INCLUDE 'GFH_T_DEF'
	INCLUDE 'SGH_O_DEF'		!SUB-GROUP HEADER
	INCLUDE 'SGH_T_DEF'
	INCLUDE 'STH_O_DEF'		!SET HEADER
	INCLUDE 'STH_T_DEF'
	INCLUDE 'SCH_O_DEF'		!SCAN HEADER
	INCLUDE 'SCH_T_DEF'
	INCLUDE 'MDH_O_DEF'		!MODEL HEADER
	INCLUDE 'MDH_T_DEF'
	INCLUDE 'MDL_O_DEF'		!MODEL LINE
	INCLUDE 'MDL_T_DEF'
	INCLUDE 'IFH_O_DEF'		!IF HEADER
	INCLUDE 'IFH_T_DEF'
	INCLUDE 'FDW_O_DEF'		!TAPE BLOCKS
	INCLUDE 'FDW_T_DEF'
	INCLUDE 'FDX_O_DEF'
	INCLUDE 'FDX_T_DEF'
	INCLUDE 'OHW_O_DEF'
	INCLUDE 'OHW_T_DEF'
	INCLUDE 'SCW_O_DEF'
	INCLUDE 'SCW_T_DEF'
	INCLUDE 'SHW_O_DEF'
	INCLUDE 'SHW_T_DEF'
C
C  Parameters:
C
	INTEGER MXNCHK			!MAX. # IN CHECK LIST
	  PARAMETER (MXNCHK=20480)
C
C  Arguments:
C
C
C  Function references:
C
	LOGICAL WNFRD			!READ DATA
	LOGICAL WNFWR			!WRITE DATA
C
C  Data declarations:
C
	INTEGER CHK(0:MXNCHK-1)		!CHECK LIST
	INTEGER NCHK			!# IN LIST
	INTEGER CVT			!CONVERSION TYPE
	INTEGER*2 LIFR_T(0:1,0:1)	!IFR TRANSLATION
	  DATA LIFR_T/2,0,0,1/
	INTEGER*2 DBH_T(0:1,0:1)	!DATA TRANSLATION
	  DATA DBH_T/2,0,0,1/
	INTEGER*2 MDD_T(0:1,0:1)	!MODEL DATA
	  DATA MDD_T/14,0,0,1/
	BYTE GFH(0:GFHHDL-1)		!GENERAL FILE HEADER
	BYTE SGH(0:SGHHDL-1)		!SUB-GROUP HEADER
	  INTEGER SGHJ(0:SGHHDL/4-1)
	  EQUIVALENCE (SGH,SGHJ)
	BYTE STH(0:STHHDL-1)		!SET HEADER
	  INTEGER*2 STHI(0:STHHDL/2-1)
	  INTEGER STHJ(0:STHHDL/4-1)
	  EQUIVALENCE (STH,STHI,STHJ)
	BYTE SCH(0:SCHHDL-1)		!SCAN HEADER
	  INTEGER SCHJ(0:SCHHDL/4-1)
	  EQUIVALENCE (SCH,SCHJ)
	BYTE MDH(0:MDHHDL-1)		!MODEL HEADER
	  INTEGER MDHJ(0:MDHHDL/4-1)
	  EQUIVALENCE (MDH,MDHJ)
	BYTE IFH(0:IFHHDL-1)		!MODEL HEADER
	  INTEGER IFHJ(0:IFHHDL/4-1)
	  EQUIVALENCE (IFH,IFHJ)
	BYTE FDW(0:FDWHDL-1)		!TAPE BLOCKS
	  BYTE FDX(0:FDXHDL-1)
	  BYTE OHW(0:OHWHDL-1)
	  BYTE SCW(0:SCWHDL-1)
	  BYTE SHW(0:SHWHDL-1)
	  BYTE MDL(0:MDLHDL-1)
	  INTEGER*2 IFR(0:STHIFR-1)
	  INTEGER*2 DBUF(0:2,0:3,0:2*STHIFR-1) !DATA BUFFER
	  EQUIVALENCE (FDW,FDX,OHW,SCW,SHW,MDL,IFH,IFR,DBUF)
C-
C
C INIT
C
	NCHK=0					!ZERO CHECK LIST
C
C GENERAL FILE HEADER
C
	IF (.NOT.WNFRD(FCAOUT,GFHHDL,GFH,0)) THEN !READ GENERAL FILE HEADER
 10	  CONTINUE
	  CALL WNCTXT(F_TP,'!/I/O error on SCN file')
	  GOTO 900				!READY
	END IF
	IF (GFH(GFH_DATTP_B).EQ.0) GFH(GFH_DATTP_B)=1 !ASSUME VAX INPUT
	IF (GFH(GFH_DATTP_B).EQ.PRGDAT) THEN
	  CALL WNCTXT(F_TP,'!/Data already converted')
	  GOTO 800
	END IF
	CVT=GFH(GFH_DATTP_B)			!INPUT TYPE
	CALL WNTTTL(GFHHDL,GFH,GFH_T,CVT)	!CONVERT
	GFH(GFH_DATTP_B)=PRGDAT			!SET CURRENT DATA TYPE
	IF (.NOT.WNFWR(FCAOUT,GFHHDL,GFH,0)) THEN
	   CALL WNCTXT(F_TP,'Write header')
	   GOTO 10		!REWRITE HEADER
	END IF
C
C GROUP HEADERS
C
	J=1					!LEVEL 1
	J1=GFH_LINKG_1				!CURRENT GROUP
	J2=GFH_LINKG_1				!CURRENT LINK HEAD
 22	CONTINUE
	IF (.NOT.WNFRD(FCAOUT,SGHHDL,SGH,J1)) then
	   CALL WNCTXT(F_TP,'Read group header !UJ',j1)
	   GOTO 10		!READ CURRENT
	END IF
 20	CONTINUE
	IF (SGHJ(SGH_LINK_J).EQ.J2) THEN	!END OF LIST
	  J=J-1					!DECREASE LEVEL
	  IF (J.EQ.0) GOTO 21			!READY
	  J1=SGHJ(SGH_HEADH_J)-SGH_LINKG_1+SGH_LINK_1 !LOWER HEADER ADDR.
	  IF (.NOT.WNFRD(FCAOUT,SGHHDL,SGH,J1)) then
	     CALL WNCTXT(F_TP,'Read subgroup !UJ !UJ',J,j1)
	     GOTO 10		!READ IT
	  END IF
	  J2=SGHJ(SGH_HEADH_J)			!NEW LINK HEAD
	  GOTO 20				!CONTINUE
	END IF
	J1=SGHJ(SGH_LINK_J)			!NEXT ENTRY
	IF (.NOT.WNFRD(FCAOUT,SGHHDL,SGH,J1)) then
	   CALL WNCTXT(F_TP,'Read subgroup !UJ',J1)
	   GOTO 10		!READ IT
	END IF
	CALL WNTTTL(SGHHDL,SGH,SGH_T,CVT)	!CONVERT IT
	IF (.NOT.WNFWR(FCAOUT,SGHHDL,SGH,J1)) GOTO 10 !WRITE IT
	IF (SGHJ(SGH_DATAP_J).EQ.0) THEN	!MORE LEVELS
	  IF (SGHJ(SGH_LINKG_J).EQ.J1+SGH_LINKG_1) GOTO 20 !NO NEXT LEVEL
	  J=J+1					!NEXT LEVEL
	  IF (J.GT.8) then
	     CALL WNCTXT(F_TP,'Too many levels !UJ !UJ',j,j1)
	     GOTO 10		!TOO MANY LEVELS
	  END IF
	  J2=J1+SGH_LINKG_1			!NEW HEADER PTR
	  J1=J2					!NEXT CURRENT
	  GOTO 22				!CONTINUE
	END IF
	GOTO 20					!MORE
 21	CONTINUE
C
C DO SETS
C
	IF (.NOT.WNFRD(FCAOUT,2*LB_J,STH,
	1		GFH_LINK_1)) then
	   CALL WNCTXT(F_TP,'Read set header start')
	   GOTO 10		!READ SET HEADER START
	END IF
30	CONTINUE
	J=STHJ(STH_LINK_J)			!NEXT IN LIST
	IF (J.EQ.GFH_LINK_1) GOTO 800		!ALL DONE
	IF (.NOT.WNFRD(FCAOUT,STHHDL,STH,J)) then
	   CALL WNCTXT(F_TP,'Read set header !UJ',j)
	   GOTO 10		!READ SET HEADER
	END IF
	CALL WNTTTL(STHHDL,STH,STH_T,CVT)	!CONVERT IT
	IF (.NOT.WNFWR(FCAOUT,STHHDL,STH,J)) then
	   CALL WNCTXT(F_TP,'Write set header !UJ',j)
	   GOTO 10		!WRITE SET HEADER
	END IF
C
C POINTED BLOCKS
C
	LIFR_T(1,0)=LB_I*STHJ(STH_NIFR_J)	!LENGTH TRANSLATION
	IF (STHJ(STH_IFRP_J).NE.0)
	1	CALL NSCCV1(FCAOUT,CVT,
	1		LB_I*STHJ(STH_NIFR_J),
	1		STHJ(STH_IFRP_J),IFR,
	1		MXNCHK,NCHK,CHK,LIFR_T)	!IFR'S
	IF (STHJ(STH_FDP_J).NE.0)
	1	CALL NSCCV1(FCAOUT,CVT,FDWHDL,
	1		STHJ(STH_FDP_J),FDW,
	1		MXNCHK,NCHK,CHK,FDW_T)	!FD
	IF (STHJ(STH_FDP_J).NE.0)
	1	CALL NSCCV1(FCAOUT,CVT,STHJ(STH_NFD_J)-FDWHDL,
	1		STHJ(STH_FDP_J)+FDWHDL,FDX,
	1		MXNCHK,NCHK,CHK,FDX_T)	!FDX
	IF (STHJ(STH_OHP_J).NE.0)
	1	CALL NSCCV1(FCAOUT,CVT,STHJ(STH_NOH_J),
	1		STHJ(STH_OHP_J),OHW,
	1		MXNCHK,NCHK,CHK,OHW_T)	!OH
	IF (STHJ(STH_SCP_J).NE.0)
	1	CALL NSCCV1(FCAOUT,CVT,STHJ(STH_NSC_J),
	1		STHJ(STH_SCP_J),SCW,
	1		MXNCHK,NCHK,CHK,SCW_T)	!SC
	IF (STHJ(STH_SHP_J).NE.0)
	1	CALL NSCCV1(FCAOUT,CVT,STHJ(STH_NSH_J),
	1		STHJ(STH_SHP_J),SHW,
	1		MXNCHK,NCHK,CHK,SHW_T)	!SH
C
	IF (STHJ(STH_IFHP_J).NE.0) THEN		!IF DATA
	   I=NCHK				!SAVE CURRENT CHECK
	   CALL NSCCV1(FCAOUT,CVT,IFHHDL,
	1		STHJ(STH_IFHP_J),IFH,
	1		MXNCHK,NCHK,CHK,IFH_T)	!IFH
	   IF (NCHK.NE.I) THEN			!WAS NEW BLOCK, DO DATA
	     J=STHJ(STH_IFHP_J)+IFHHDL		!DATA POINTER
	     I1=4*STHTEL*LB_I			!DATA LENGTH
	     DBH_T(1,0)=I1			!TRANSLATION LENGTH
	     DO I=1,IFHJ(IFH_NTP_J)+IFHJ(IFH_NIF_J)
	        IF (.NOT.WNFRD(FCAOUT,I1,DBUF,J)) then
		   CALL WNCTXT(F_TP,'Read data !UJ',J)
		   GOTO 10	!READ DATA
		END IF
	        CALL WNTTTL(I1,DBUF,DBH_T,CVT)	!CONVERT
	        IF (.NOT.WNFWR(FCAOUT,I1,DBUF,J)) then
		   CALL WNCTXT(F_TP,'Write data !UJ',J)
		   GOTO 10	!WRITE DATA
		END IF
	        J=J+I1				!NEXT SCAN
	     END DO
	   END IF
	END IF
C
	IF (STHJ(STH_MDL_J).NE.0) THEN		!MODEL 1
	  MDHJ(MDH_NSRC_J)=0			!MAKE SURE SINGLE
	  CALL NSCCV1(FCAOUT,CVT,MDHHDL,STHJ(STH_MDL_J),MDH,
	1		MXNCHK,NCHK,CHK,MDH_T)	!MODEL 1
	  J=MDHJ(MDH_MODP_J)			!MODEL POINTER
	  DO I=0,MDHJ(MDH_NSRC_J)-1		!ALL SOURCES
	    IF (.NOT.WNFRD(FCAOUT,MDLHDL,MDL,J)) then
	       CALL WNCTXT(F_TP,'Read !UJ !UJ',i,j)
	       GOTO 10		!READ SOURCE
	    END IF
	    CALL WNTTTL(MDLHDL,MDL,MDL_T,CVT)	!TRANSLATE
	    IF (.NOT.WNFWR(FCAOUT,MDLHDL,MDL,J)) then
	       CALL WNCTXT(F_TP,'Write !UJ !UJ',i,j)
	       GOTO 10		!REWRITE SOURCE
	    END IF
	    J=J+MDLHDL				!NEXT PTR
	  END DO
	END IF
	IF (STHJ(STH_MDL_J+1).NE.0) THEN	!MODEL 2
	  MDHJ(MDH_NSRC_J)=0			!MAKE SURE SINGLE
	  CALL NSCCV1(FCAOUT,CVT,MDHHDL,STHJ(STH_MDL_J+1),MDH,
	1		MXNCHK,NCHK,CHK,MDH_T)	!MODEL 1
	  J=MDHJ(MDH_MODP_J)			!MODEL POINTER
	  DO I=0,MDHJ(MDH_NSRC_J)-1		!ALL SOURCES
	    IF (.NOT.WNFRD(FCAOUT,MDLHDL,MDL,J)) GOTO 10 !READ SOURCE
	    CALL WNTTTL(MDLHDL,MDL,MDL_T,CVT)	!TRANSLATE
	    IF (.NOT.WNFWR(FCAOUT,MDLHDL,MDL,J)) GOTO 10 !REWRITE SOURCE
	    J=J+MDLHDL				!NEXT PTR
	  END DO
	END IF
	I1=4*STHJ(STH_NIFR_J)			!MODEL DATA LENGTH
	MDD_T(1,0)=I1				!TRANSLATION LENGTH
	I1=I1*LB_X				!BYTE LENGTH
	J=STHJ(STH_MDD_J)			!DATA POINTERS
	J0=STHJ(STH_MDD_J+1)
	IF (STHJ(STH_MDD_J).NE.0 .OR. STHJ(STH_MDD_J+1).NE.0) THEN !MODEL DATA
	  DO I=0,STHJ(STH_SCN_J)-1		!ALL SCANS
	    IF (STHJ(STH_MDD_J).NE.0) THEN	!MODEL 1 DATA
	      IF (.NOT.WNFRD(FCAOUT,I1,DBUF,J)) GOTO 10 !READ SOURCE SCAN
	      CALL WNTTTL(I1,DBUF,MDD_T,CVT)	!TRANSLATE
	      IF (.NOT.WNFWR(FCAOUT,I1,DBUF,J)) GOTO 10 !REWRITE
	    END IF
	    IF (STHJ(STH_MDD_J+1).NE.0) THEN	!MODEL 2 DATA
	      IF (.NOT.WNFRD(FCAOUT,I1,DBUF,J0)) GOTO 10 !READ SOURCE SCAN
	      CALL WNTTTL(I1,DBUF,MDD_T,CVT)	!TRANSLATE
	      IF (.NOT.WNFWR(FCAOUT,I1,DBUF,J0)) GOTO 10 !REWRITE
	    END IF
	    J=J+4*STHJ(STH_NIFR_J)*LB_X		!NEXT DATA POINTERS
	    J0=J0+4*STHJ(STH_NIFR_J)*LB_X
	  END DO
	END IF
C
C SCANS
C
	J=STHJ(STH_SCNP_J)			!POINTER TO SCAN
	I1=6*STHI(STH_PLN_I)*STHJ(STH_NIFR_J)	!DATA LENGTH
	DBH_T(1,0)=I1				!TRANSLATION LENGTH
	DO I=1,STHJ(STH_SCN_J)			!ALL SCANS
	  IF (.NOT.WNFRD(FCAOUT,SCHHDL,SCH,J)) GOTO 10 !SCAN HEAD
	  CALL WNTTTL(SCHHDL,SCH,SCH_T,CVT)	!CONVERT
	  IF (.NOT.WNFWR(FCAOUT,SCHHDL,SCH,J)) GOTO 10 !SCAN HEAD
	  J=J+SCHHDL				!UPDATE POINTER
	  IF (.NOT.WNFRD(FCAOUT,I1,DBUF,J)) GOTO 10 !READ DATA
	  CALL WNTTTL(I1,DBUF,DBH_T,CVT)	!CONVERT
	  IF (.NOT.WNFWR(FCAOUT,I1,DBUF,J)) GOTO 10 !WRITE DATA
	  J=J+I1				!UPDATE POINTER
	END DO					!NEXT SCAN
	GOTO 30					!NEXT SET
C
C READY
C
 800	CONTINUE
	CALL WNFCL(FCAOUT)			!CLOSE FILE
C
	RETURN
C
C ERROR
C
 900	CONTINUE
	CALL WNFCL(FCAOUT)			!CLOSE FILE
	RETURN					!READY
C
C
	END
