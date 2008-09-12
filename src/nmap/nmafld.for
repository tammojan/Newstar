C+ NMAFLD.FOR
C  WNB 930929
C
C  Revisions:
C	JPH 950125	Report file name for all open failures
C	AXC 010709      Linux port - HOLO string
C
	SUBROUTINE NMAFLD(TYP)
C
C  Load/unload maps
C
C  Result:
C
C	CALL NMAFLD ( TYP_J:I)		Load foreign maps:
C					TYP=RHO		Holog loading
C					TYP=WMP		Standard WMP loading
C					TYP=UNL		Standard unloading
C
C
C  PIN references:
C
C	FILENAME
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'GFH_O_DEF'		!FILE HEADER
	INCLUDE 'SGH_O_DEF'		!SUB-GROUP HEADER
	INCLUDE 'MPH_O_DEF'		!MAP HEADER
	INCLUDE 'SMP_O_DEF'		!R-SERIES MAP FORMAT
	INCLUDE 'SMP_T_DEF'		!R-SERIES MAP TRANSLATION
	INCLUDE 'NMA_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
	INTEGER TYP			!TYPE OF OPERATION
C
C  Function references:
C
	LOGICAL WNFOP			!OPEN FILE
	LOGICAL WNFWR			!WRITE DISK
	LOGICAL WNFRD			!READ DISK
	INTEGER WNFEOF			!FILE POINTER
	LOGICAL WNDLNF,WNDLNG,WNDLNK	!LINK MAPS
	LOGICAL WNDPAR			!GET USER DATA
	CHARACTER*32 WNTTSG		!MAP NAME
	LOGICAL NMASTG			!GET MAP
C
C  Data declarations:
C
	INTEGER FCA(0:1)		!FILE AREAS
	LOGICAL FIRST			!FIRST NEW
	CHARACTER*32 TXT		!TEXT DATA
	INTEGER SNAM(0:7)		!SET NAME
	INTEGER MPHP			!MAP HEADER POINTER
	BYTE MPH(0:MPH__L-1)		!MAP HEADER
	  INTEGER*2 MPHI(0:MPH__L/LB_I-1)
	  INTEGER MPHJ(0:MPH__L/LB_J-1)
	  REAL MPHE(0:MPH__L/LB_E-1)
	  DOUBLE PRECISION MPHD(0:MPH__L/LB_D-1)
	  EQUIVALENCE (MPH,MPHI,MPHJ,MPHE,MPHD)
	BYTE SMP(0:SMP__L-1)		!RMAP HEADER
	  INTEGER*2 SMPI(0:SMP__L/LB_I-1)
	  INTEGER SMPJ(0:SMP__L/LB_J-1)
	  REAL SMPE(0:SMP__L/LB_E-1)
	  DOUBLE PRECISION SMPD(0:SMP__L/LB_D-1)
	  EQUIVALENCE (SMP,SMPI,SMPJ,SMPE,SMPD)
	REAL DAT(0:8191)		!MAP LINE
	INTEGER*2 PLC(0:1,0:7)		!POL. CODES
	  DATA PLC/'XX',0,'XY',1,'YX',2,'YY',3,
	1		'I ',0,'Q ',2,'U ',2,'V ',3/
	INTEGER TPC(0:1,0:7)		!TYPE CODES
	  DATA TPC/'MAP ',0,'AP  ',1,'COVE',2,'REAL',3,
	1		'IMAG',4,'AMPL',5,'PHAS',6,'HOLO',7/
	INTEGER TIDAT(4)		!DATA TRANSLATION
	  DATA TIDAT /4,0,0,1/
C-
C
C INIT
C
	IF (TYP.EQ.FID_UNL) THEN		!UNLOAD
	  IF (.NOT.WNFOP(FCA(1),FILIN(1),'R')) THEN
	    CALL WNCTXT(F_TP,'1 Cannot open input file !AS', FILIN(1))
	    GOTO 800				!READY
	  END IF
	ELSE					!LOAD
	  IF (.NOT.WNFOP(FCA(1),FILIN(2),'U')) THEN
	    CALL WNCTXT(F_TP,'1 Cannot open output file !AS', FILIN(2))
	    GOTO 800				!READY
	  END IF
	  IF (.NOT.WNDLNG(GFH_LINKG_1,0,SGH_GROUPN_1,FCA(1),
	1		SGPH(0),SGNR(0))) THEN	!CREATE JOB LEVEL
 30	    CONTINUE
	    CALL WNCTXT(F_TP,'Error creating sub-group')
	    CALL WNGEX				!STOP
	  END IF
	END IF
C
C GET FILE
C
 10	CONTINUE
	IF (TYP.EQ.FID_UNL) THEN		!UNLOAD
	  IF (.NOT.WNDPAR('FILENAME',FILIN(2),LEN(FILIN(2)),J0,
	1		'""')) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 810	!READY
	    GOTO 10				!RETRY
	  END IF
	ELSE					!LOAD
	  IF (.NOT.WNDPAR('FILENAME',FILIN(1),LEN(FILIN(1)),J0,
	1		'""')) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 810	!READY
	    GOTO 10				!RETRY
	  END IF
	  IF (.NOT.WNDLNG(SGPH(0)+SGH_LINKG_1,0,SGH_GROUPN_1,
	1		FCA(1),SGPH(1),SGNR(1))) GOTO 30 !CREATE FIELD
	END IF
	IF (J0.EQ.0) GOTO 810			!READY
	IF (J0.LT.0) GOTO 10			!RETRY
	IF (TYP.EQ.FID_UNL) THEN		!UNLOAD
	  IF (.NOT.WNFOP(FCA(0),FILIN(2),'W')) THEN
	    CALL WNCTXT(F_TP,'2 Cannot open output file !AS',
	1		FILIN(2))
	    GOTO 810
	  END IF
	ELSE					!LOAD
	  IF (.NOT.WNFOP(FCA(0),FILIN(1),'R')) THEN
	    CALL WNCTXT(F_TP,'2 Cannot open input file !AS',
	1		FILIN(1))
	    GOTO 810
	  END IF
	END IF
C
C UNLOAD
C
	IF (TYP.EQ.FID_UNL) THEN
	  J0=0					!OUTPUT POINTER
	  DO WHILE (NMASTG(FCA(1),SETS(0,0,1),MPH,MPHP,SNAM)) !GET A SET
	    IF (.NOT.WNFWR(FCA(0),MPH__L,MPH,J0)) THEN !WRITE HEADER
 20	      CONTINUE
	      CALL WNCTXT(F_TP,'Error writing !AS',FILIN(2))
	      GOTO 820
	    END IF
	    J0=J0+MPH__L			!OUTPUT POINTER
	    J1=MPHJ(MPH_MDP_J)			!INPUT POINTER
	    DO I=0,MPHJ(MPH_NDEC_J)-1		!ALL LINES
	      IF (.NOT.WNFRD(FCA(1),MPHJ(MPH_NRA_J)*LB_E,DAT,J1)) THEN
		CALL WNCTXT(F_TP,'Error reading set !AS',
	1		WNTTSG(SNAM,0))
		GOTO 820
	      END IF
	      J1=J1+MPHJ(MPH_NRA_J)*LB_E	!INPUT POINTER
	      IF (.NOT.WNFWR(FCA(0),MPHJ(MPH_NRA_J)*LB_E,DAT,J0))
	1			GOTO 20		!WRITE DATA
	      J0=J0+MPHJ(MPH_NRA_J)*LB_E	!OUTPUT POINTER
	    END DO
	    CALL WNCTXT(F_TP,'Map !AS(!AD) unloaded to !AS',
	1		WNTTSG(SNAM,0),MPH(MPH_FNM_1),
	1		MPH_FNM_N,FILIN(2))
	  END DO
	  GOTO 820				!READY
C
C LOAD
C
	ELSE
	  J1=0					!INPUT POINTER
 41	  CONTINUE
	  IF (TYP.EQ.FID_WMP) THEN
	    IF (.NOT.WNFRD(FCA(0),MPH__L,MPH,J1)) GOTO 40 !READ HEADER
	    J1=J1+MPH__L			!INPUT POINTER
	  ELSE					!HOLOG
	    IF (.NOT.WNFRD(FCA(0),SMP__L,SMP,J1)) GOTO 40 !READ HEADER
	    J1=J1+SMP__L			!INPUT POINTER
	    CALL WNTTIL(SMP__L,SMP,SMP_T)	!TRANSLATE
	    CALL WNGMVZ(MPH__L,MPH)		!MAKE NEW HEADER
	    CALL WNGMV(MPH_FNM_N,SMP(SMP_FNM_1),MPH(MPH_FNM_1))
	    MPHE(MPH_EPO_E)=SMPE(SMP_EPO_E)
	    MPHD(MPH_RA_D)=SMPD(SMP_RA_D)
	    MPHD(MPH_DEC_D)=SMPD(SMP_DEC_D)
	    MPHD(MPH_FRQ_D)=SMPD(SMP_FRQ_D)
	    MPHD(MPH_BDW_D)=SMPD(SMP_BDW_D)
	    MPHD(MPH_RAO_D)=SMPD(SMP_RAO_D)
	    MPHD(MPH_DECO_D)=SMPD(SMP_DCO_D)
	    MPHD(MPH_FRQO_D)=SMPD(SMP_FRO_D)
	    MPHI(MPH_ODY_I)=SMPI(SMP_ODY_I)
	    MPHI(MPH_OYR_I)=SMPI(SMP_OYR_I)
	    MPHI(MPH_PCD_I)=SMPI(SMP_PCD_I)
	    MPHD(MPH_SRA_D)=SMPD(SMP_SRA_D)
	    MPHD(MPH_SDEC_D)=SMPD(SMP_SDC_D)
	    MPHD(MPH_SFRQ_D)=SMPD(SMP_SFR_D)
	    MPHJ(MPH_NRA_J)=SMPI(SMP_NRA_I)
	    MPHJ(MPH_NDEC_J)=SMPI(SMP_NDC_I)
	    MPHJ(MPH_NFRQ_J)=SMPI(SMP_NFR_I)
	    MPHJ(MPH_ZRA_J)=SMPI(SMP_ZRA_I)
	    MPHJ(MPH_ZDEC_J)=SMPI(SMP_ZDC_I)
	    MPHJ(MPH_ZFRQ_J)=SMPI(SMP_ZFR_I)
	    MPHJ(MPH_MXR_J)=SMPI(SMP_MXR_I)
	    MPHJ(MPH_MXD_J)=SMPI(SMP_MXD_I)
	    MPHJ(MPH_MXF_J)=SMPI(SMP_MXF_I)
	    MPHJ(MPH_MNR_J)=SMPI(SMP_MNR_I)
	    MPHJ(MPH_MND_J)=SMPI(SMP_MND_I)
	    MPHE(MPH_MAX_E)=SMPE(SMP_MAX_E)
	    MPHE(MPH_MIN_E)=SMPE(SMP_MIN_E)
	    MPHD(MPH_SHR_D)=SMPD(SMP_SHR_D)
	    MPHD(MPH_SHD_D)=SMPD(SMP_SHD_D)
	    MPHD(MPH_SHF_D)=SMPD(SMP_SHF_D)
	    MPHD(MPH_SUM_D)=SMPD(SMP_SUM_D)
	    MPHE(MPH_UNI_E)=SMPE(SMP_UNI_E)
	    CALL WNGMV(MPH_UCM_N,SMP(SMP_UCM_1),MPH(MPH_UCM_1))
	    MPHJ(MPH_NPT_J)=SMPJ(SMP_NPT_J)
	    MPHJ(MPH_NBL_J)=SMPI(SMP_NBS_I)
	    MPHJ(MPH_NST_J)=SMPI(SMP_NST_I)
	    MPH(MPH_TYP_1)=ICHAR('H')
	    MPH(MPH_TYP_1+1)=ICHAR('O')
	    MPH(MPH_TYP_1+2)=ICHAR('L')
	    MPH(MPH_TYP_1+3)=ICHAR('O')
	    CALL WNGMV(MPH_POL_N,SMP(SMP_POL_1),MPH(MPH_POL_1))
	    DO I=0,7
	      MPHI(MPH_CD_I+I)=SMPI(SMP_CD_I+I)
	    END DO
	    MPHI(MPH_EPT_I)=SMPI(SMP_EPT_I)
	    MPHE(MPH_OEP_E)=SMPE(SMP_OEP_E)
	    MPHE(MPH_NOS_E)=SMPE(SMP_NOS_E)
	    MPHE(MPH_FRA_E)=SMPE(SMP_FRA_E)
	    MPHE(MPH_FDEC_E)=SMPE(SMP_FDC_E)
	    MPHE(MPH_FFRQ_E)=SMPE(SMP_FFR_E)
	    CALL WNGMV(MPH_TEL_N,SMP(SMP_TEL_1),MPH(MPH_TEL_1))
	    MPHJ(MPH_FSR_J)=SMPI(SMP_FSR_I)
	    MPHJ(MPH_FSD_J)=SMPI(SMP_FSD_I)
	  END IF
	  MPHI(MPH_LEN_I)=MPH__L		!LENGTH
	  MPHI(MPH_VER_I)=MPH__V		!VERSION
	  MPHI(MPH_DCD_I)=5			!REAL VALUES
	  J0=WNFEOF(FCA(1))			!OUTPUT POINTER
	  MPHJ(MPH_MDP_J)=J0+MPH__L		!DATA POINTER
	  IF (.NOT.WNFWR(FCA(1),MPH__L,MPH,
	1		J0)) GOTO 20 		!WRITE HEADER
	  J0=J0+MPH__L
	  TIDAT(2)=MPHJ(MPH_NRA_J)		!LENGTH LINE
	  DO I=0,MPHJ(MPH_NDEC_J)-1		!ALL LINES
	    IF (.NOT.WNFRD(FCA(0),MPHJ(MPH_NRA_J)*LB_E,DAT,J1)) THEN
	      CALL WNCTXT(F_TP,'Error reading !AS',
	1		FILIN(1))
	      GOTO 820
	    END IF
	    J1=J1+MPHJ(MPH_NRA_J)*LB_E		!INPUT POINTER
	    IF (TYP.EQ.FID_RHO) THEN		!TRANSLATE
	      CALL WNTTIL(MPHJ(MPH_NRA_J)*LB_E,DAT,TIDAT) !TRANSLATE
	    END IF
	    IF (.NOT.WNFWR(FCA(1),MPHJ(MPH_NRA_J)*LB_E,DAT,J0))
	1		GOTO 20			!WRITE DATA
	    J0=J0+MPHJ(MPH_NRA_J)*LB_E		!OUTPUT POINTER
	  END DO
	  IF (.NOT.WNDLNG(SGPH(1)+SGH_LINKG_1,0,SGH_GROUPN_1,
	1		FCA(1),SGPH(2),SGNR(2))) GOTO 30 !CREATE CHANNEL
	  I1=0					!POL. CODE
	  DO I=0,7
	    IF (MPHI(MPH_POL_1/LB_I).EQ.PLC(0,I)) I1=PLC(1,I)
	  END DO
	  IF (.NOT.WNDLNF(SGPH(2)+SGH_LINKG_1,I1,SGH_GROUPN_1,
	1		FCA(1),SGPH(3),SGNR(3))) GOTO 30 !CREATE CHANNEL
	  I1=0					!TYPE CODE
	  DO I=0,7
	    IF (MPHJ(MPH_TYP_1/LB_J).EQ.TPC(0,I)) I1=TPC(1,I)
	  END DO
	  IF (.NOT.WNDLNF(SGPH(3)+SGH_LINKG_1,I1,SGH_GROUPN_1,
	1		FCA(1),SGPH(4),SGNR(4))) GOTO 30 !CREATE CHANNEL
	  IF (.NOT.WNDLNK(GFH_LINK_1,MPHJ(MPH_MDP_J)-MPH__L,
	1		MPH_SETN_1,FCA(1))) GOTO 30 !LINK MAP
	  IF (.NOT.WNDLNG(SGPH(4)+SGH_LINKG_1,
	1		MPHJ(MPH_MDP_J)-MPH__L,SGH_GROUPN_1,
	1		FCA(1),SGPH(5),SGNR(5))) GOTO 30 !CREATE CHANNEL
	  SGNR(6)=-1
	  CALL WNCTXT(F_TP,'Map !AS(!AD) loaded from !AS',
	1		WNTTSG(SGNR,0),MPH(MPH_FNM_1),
	1		MPH_FNM_N,FILIN(1))
	  IF (TYP.EQ.FID_WMP) GOTO 41		!READ MORE MAPS
 40	  CONTINUE
	  CALL WNFCL(FCA(0))			!CLOSE INPUT FILE
	  GOTO 10				!NEXT FILE
	END IF
C
C READY
C
 820	CONTINUE
	CALL WNFCL(FCA(0))			!CLOSE INPUT FILE
 810	CONTINUE
	CALL WNFCL(FCA(1))			!CLOSE OUTPUT FILE
 800	CONTINUE
C
	RETURN
C
C
	END
