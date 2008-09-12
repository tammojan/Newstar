C+ NGCTRP.FOR
C  WNB 920902
C
C  Revisions:
C	WNB 921104	Full HA range
C	HjV 930423	Change name of some Keywords
C	WNB 930628	Add POL and BLN in output
C	WNB 930630	Some small typos; add TRHA, TRHAI, TRFB, TRFI, FRHACV
C	WNB 930630	Better HA and frequency calculation
C	WNB 930826	New HA range
C	CMV 931210	Add 'NGF_LOOPS' argument to WNDXLP
C	CMV 931220	Pass FCA of input file to WNDXLP and WNDSTA/Q
C	CMV 940805	No action for TRTYP=2 on input plot
C	JPH 940818	NGF_LOOPD before NGF_SETS as in other Newstar programs
C
C
	SUBROUTINE NGCTRP
C
C  Make transposed files
C
C  Result:
C
C	CALL NGCTRP			Make transposed (freq. channel <> HA)
C					plots
C
C
C  Pin references:
C
C	NGF_SETS	Plots to use
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'GFH_O_DEF'		!GENERAL FILE HEADER
	INCLUDE 'SGH_O_DEF'		!SUB-GROUP HEADER
	INCLUDE 'NGF_O_DEF'		!PLOT HEADER
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
	LOGICAL WNDPAR			!GET USER DATA
	LOGICAL WNDLNG,WNDLNK,WNDLNF	!LINK SETS
	LOGICAL WNDSTA			!GET SETS
	LOGICAL WNDXLP			!GET LOOPS
	LOGICAL WNDXLN			!NEXT LOOP
	LOGICAL WNFRD			!READ DISK
	LOGICAL WNFWR			!WRITE DISK
	INTEGER WNFEOF			!EOF POINTER
	LOGICAL WNGGVA			!GET MEMORY
	CHARACTER*32 WNTTSG		!SET NAME
	LOGICAL NGCSTG,NGCSTL		!GET PLOT
	LOGICAL NSCHAS			!GET HA RANGE
C
C  Data declarations:
C
	INTEGER NPLOT			!# OF PLOTS TO USE
	INTEGER PLOTS(MXNCHN,2)		!PLOTS TO USE
	INTEGER SNAM(0:7,MXNCHN)	!PLOT NAME
	REAL HASRA(0:1)			!HA RANGE
	INTEGER NGFHP			!HEADER POINTER
	CHARACTER*(NGF_TYP_N) HSTR,HSTR1
	INTEGER NPTS			!LENGTH SINGLE PLOT
	REAL HA,HAE			!START,END HA OUTPUT PLOT
	REAL HAINC			!HA INCREMENT OUTPUT PLOT
	REAL CHA			!HA CURRENT POINT
	REAL CUT			!UT CURRENT POINT
	REAL FRQ,BDW,FRQI,TRHA		!CURRENT FREQUENCY DATA
	INTEGER BDN,FRQIN
	INTEGER CRANGE(0:1)		!MIN. MAX. CHANNEL
	INTEGER TRTYP			!CURRENT TRANSPOSE TYPE
	INTEGER BUFL,BUFL1		!LENGTH DATA BUFFER
	INTEGER BUFAD,BUFAD1		!ADDRESS DATA BUFFER
	BYTE NGF(0:NGFHDL-1,0:MXNCHN)	!PLOT HEADERS
	  INTEGER*2 NGFI(0:NGFHDL/2-1,0:MXNCHN)
	  INTEGER NGFJ(0:NGFHDL/4-1,0:MXNCHN)
	  REAL NGFE(0:NGFHDL/4-1,0:MXNCHN)
	  EQUIVALENCE (NGF,NGFI,NGFJ,NGFE)
	COMPLEX C2
C-
C
C INIT
C
	DO I=0,7				!SET CURRENT JOB
	  SETS(I,1)=-1
	END DO
	SETS(0,0)=1
	SETS(0,1)=SGNR(0)
	CALL WNDSTR(FCAOUT,SETS)		!RESET SEARCH
	IF (NGCSTG(FCAOUT,SETS,NGF(0,0),
	1		NGFHP,SNAM(0,0))) THEN	!ONE PRESENT
	  IF (.NOT.WNDLNG(GFH_LINKG_1,0,SGH_GROUPN_1,FCAOUT,
	1		SGPH(0),SGNR(0))) GOTO 51 !CREATE JOB SET
	END IF
C
C GET PLOTS
C
 10	CONTINUE
 12	CONTINUE
	IF (.NOT.WNDXLP('NGF_LOOPS',FCAOUT)) THEN
	  IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 10	!SETS AGAIN
	END IF
	IF (.NOT.WNDSTA('NGF_SETS',MXNSET,SETS,FCAOUT)) GOTO 900 !PLOTS TO USE
	IF (SETS(0,0).EQ.0) GOTO 900
	CALL WNDXLI(LPOFF)			!INIT LOOPING
C
C GET RANGE
C
	IF (.NOT.NSCHAS(1,HASRA)) GOTO 10	!GET HA RANGE
	HASRA(0)=HASRA(0)*360.			!MAKE DEGREES
	HASRA(1)=HASRA(1)*360.
C
C GET PLOTS
C
 30	CONTINUE
	IF (.NOT.WNDXLN(LPOFF)) GOTO 10		!NO MORE LOOPS
	NPLOT=0					!CNT PLOTS
	DO WHILE(NGCSTL(FCAOUT,SETS,NGF(0,NPLOT+1),
	1		NGFHP,SNAM(0,NPLOT+1),LPOFF)) !GET PLOT
	  IF (NPLOT.LT.MXNCHN-1) THEN
	    NPLOT=NPLOT+1			!COUNT
	    PLOTS(NPLOT,2)=NGFHP		!SAVE HEADER POINTER
	    PLOTS(NPLOT,1)=NPLOT		!A NUMBER
	    CALL WNDSTI(FCAOUT,SNAM(0,NPLOT))	!PROPER NAME
	  END IF
	END DO
	IF (NPLOT.LE.0) GOTO 30			!NEXT LOOP
C
C SET LENGTHS PLOTS
C
	NPTS=NGFJ(NGF_SCN_J,1)			!INIT VALUES
	HA=NGFE(NGF_HAB_E,1)*360.
	HAINC=NGFE(NGF_HAI_E,1)*360.
	HAE=NGFE(NGF_HAB_E,1)*360.+(NPTS-1)*HAINC
	CRANGE(0)=SNAM(2,1)
	CRANGE(1)=SNAM(2,1)
C
	TRTYP=NGFJ(NGF_TRTYP_J,1)
	IF (TRTYP.NE.0.AND.TRTYP.NE.1) THEN
	   CALL WNCTXT(F_TP,
	1	'!/Cannot transpose plots with transpose type !UJ',
	1	TRTYP)
	   GOTO 30				!NEXT LOOP
	END IF
C
	FRQ=NGFE(NGF_FRQ_E,1)
	BDW=NGFE(NGF_BDW_E,1)
	BDN=SNAM(2,1)
	FRQI=0
	FRQIN=0
	TRHA=NGFE(NGF_TRHA_E,1)
C
	DO I=2,NPLOT
	  NPTS=MAX(NPTS,NGFJ(NGF_SCN_J,I))
	  HA=MIN(HA,NGFE(NGF_HAB_E,I)*360.)
	  HAINC=MIN(HAINC,NGFE(NGF_HAI_E,I)*360.)
	  HAE=MAX(HAE,NGFE(NGF_HAB_E,I)*360.+(NGFJ(NGF_SCN_J,I)-1)*
	1		NGFE(NGF_HAI_E,I)*360.)
	  CRANGE(0)=MIN(CRANGE(0),SNAM(2,I))
	  CRANGE(1)=MAX(CRANGE(1),SNAM(2,I))
	  IF (CRANGE(0).EQ.SNAM(2,I)) TRHA=NGFE(NGF_TRHA_E,I) !LOWEST HA
	  IF (SNAM(2,I).NE.BDN) THEN		!FREQ. DIFFERENCE
	    FRQI=FRQI+(NGFE(NGF_FRQ_E,I)-FRQ)/(SNAM(2,I)-BDN)
	    FRQIN=FRQIN+1
	  END IF
	  IF (TRTYP.NE.NGFJ(NGF_TRTYP_J,I)) THEN
	    CALL WNCTXT(F_TP,'!/Cannot transpose different types')
	    GOTO 30				!NEXT LOOP
	  END IF
	END DO
C
	NPTS=MAX(NPTS,NINT((HAE-HA)/HAINC)+1)
	IF (FRQIN.EQ.0) THEN
	  FRQI=BDW
	ELSE
	  FRQI=FRQI/FRQIN			!AVERAGE FREQ. STEP
	END IF
C
	BUFL=LB_X*(NPLOT+1)*NPTS		!GET DATA BUFFER
	IF (.NOT.WNGGVA(BUFL,BUFAD)) THEN
 22	  CONTINUE
	  CALL WNCTXT(F_TP,'!/Cannot get plotdata buffer')
	  GOTO 900
	END IF
	BUFAD=(BUFAD-A_OB)/LB_X
C
	BUFL1=LB_X*(CRANGE(1)-CRANGE(0)+1)	!COUNT BUFFER
	IF (.NOT.WNGGVA(BUFL1,BUFAD1)) THEN
	  CALL WNGFVA(BUFL,BUFAD*LB_X+A_OB)
	  GOTO 22
	END IF
	BUFAD1=(BUFAD1-A_OB)/LB_X
	CALL WNGMVZ(BUFL,A_X(BUFAD))		!ZERO BUFFERS
	DO I=0,CRANGE(1)-CRANGE(0)		!SET DELETED
	  A_X(BUFAD1+I)=CMPLX(NGCDLC,NGCDLC)
	END DO
C
C READ PLOT DATA
C
	DO I=1,NPLOT				!READ ALL DATA
	  IF (.NOT.WNFRD(FCAOUT,LB_X*NGFJ(NGF_SCN_J,I),
	1		A_X(BUFAD+I*NPTS),NGFJ(NGF_DPT_J,I))) THEN
21 	    CONTINUE
	    CALL WNCTXT(F_TP,'!/Error reading plot file #!UJ',
	1		IAND(PLOTS(I,1),NOT(NGCSDL)))
	    GOTO 10				!RETRY EXPRESSION
	  END IF
	END DO
C
C BUILD TRANSPOSED PLOTS
C
	DO I1=0,NPTS-1				!ALL DATA
	 CHA=HA+I1*HAINC			!CURRENT HA
	 IF (CHA.GE.HASRA(0) .AND. CHA.LE.HASRA(1)) THEN !SELECTED
	  CUT=360.*((CHA/360.-NGFE(NGF_HAB_E,1))*0.99727+
	1			NGFE(NGF_UTB_E,1)) !CURRENT UT
	  DO I=1,NPLOT				!ALL SETS
	    R1=(CHA/360.-NGFE(NGF_HAB_E,I))/NGFE(NGF_HAI_E,I) !OFFSET
	    I2=NINT(R1)
	    I3=SNAM(2,I)-CRANGE(0)		!PLOT #
	    IF (I2.LT.0 .OR. I2.GE. NGFJ(NGF_SCN_J,I)) THEN
	      A_X(BUFAD1+I3)=CMPLX(NGCDLC,NGCDLC)
	    ELSE
	      A_X(BUFAD1+I3)=A_X(BUFAD+I*NPTS+I2) !DATA
	    END IF
	  END DO
C
C ADD NEW POINT TO PLOT FILE
C
	  CALL WNGMVZ(NGFHDL,NGF(0,0))		!ZERO NGF
	  NGFE(NGF_MAX_E,0)=-1E20		!INIT MAX/MIN
	  NGFE(NGF_MIN_E,0)=1E20
	  DO I=0,CRANGE(1)-CRANGE(0)		!ALL POINTS
	    IF (REAL(A_X(BUFAD1+I)).NE.NGCDLC) THEN
	      C2=A_X(BUFAD1+I)
	      NGFE(NGF_MAX_E,0)=MAX(NGFE(NGF_MAX_E,0),ABS(C2)) !NEW MAX/MIN
	      NGFE(NGF_MIN_E,0)=MIN(NGFE(NGF_MIN_E,0),ABS(C2))
	    ELSE
	      NGFJ(NGF_DEL_J,0)=NGFJ(NGF_DEL_J,0)+1 !COUNT
	    END IF
	  END DO
	  NGFI(NGF_VER_I,0)=NGFHDV		!FILL PLOT HEADER	     
	  NGFI(NGF_LEN_I,0)=NGFHDL
	  CALL WNGMV(NGF_NAM_N,NGF(NGF_NAM_1,1),NGF(NGF_NAM_1,0))
	  NGFE(NGF_RA_E,0)=NGFE(NGF_RA_E,1)
	  NGFE(NGF_DEC_E,0)=NGFE(NGF_DEC_E,1)
	  NGFE(NGF_FRQ_E,0)=NGFE(NGF_FRQ_E,1)
	  NGFE(NGF_BDW_E,0)=NGFE(NGF_BDW_E,1)
	  NGFJ(NGF_TRTYP_J,0)=MOD(NGFJ(NGF_TRTYP_J,1)+1,2)
	  IF (NGFJ(NGF_TRTYP_J,0).EQ.1) THEN
	    NGFE(NGF_TRHAI_E,0)=HAINC/360.
	    NGFE(NGF_TRHA_E,0)=CHA/360.
	    NGFE(NGF_TRFB_E,0)=FRQ+(CRANGE(0)-BDN)*FRQI
	    NGFE(NGF_TRFI_E,0)=FRQI
	    NGFE(NGF_HAB_E,0)=CRANGE(0)*FRHACV/360.
	    NGFE(NGF_HAI_E,0)=FRHACV/360.
	    NGFJ(NGF_BDN_J,0)=I1
	  ELSE
	    NGFE(NGF_TRHAI_E,0)=0.
	    NGFE(NGF_TRHA_E,0)=0.
	    NGFE(NGF_TRFB_E,0)=0.
	    NGFE(NGF_TRFI_E,0)=0.
	    NGFE(NGF_HAB_E,0)=TRHA
	    NGFE(NGF_HAI_E,0)=NGFE(NGF_TRHAI_E,1)
	    NGFJ(NGF_BDN_J,0)=NINT(CHA/FRHACV)
	  END IF
	  NGFE(NGF_HAV_E,0)=NGFE(NGF_HAV_E,1)
	  NGFE(NGF_UTB_E,0)=NGFE(NGF_UTB_E,1)
	  NGFE(NGF_UTE_E,0)=NGFE(NGF_UTE_E,1)
	  NGFJ(NGF_SCN_J,0)=CRANGE(1)-CRANGE(0)+1
	  NGFJ(NGF_VNR_J,0)=NGFJ(NGF_VNR_J,1)
	  CALL WNGMV(NGF_IFR_N,NGF(NGF_IFR_1,1),NGF(NGF_IFR_1,0))
	  CALL WNGMV(NGF_POL_N,NGF(NGF_POL_1,1),NGF(NGF_POL_1,0))
	  NGFI(NGF_ODY_I,0)=NGFI(NGF_ODY_I,1)
	  NGFI(NGF_OYR_I,0)=NGFI(NGF_OYR_I,1)
	  NGFE(NGF_BLN_E,0)=NGFE(NGF_BLN_E,1)
	  HSTR1='TRANSP'
	  CALL WNCTXS(HSTR,'!AS(!AS-!AS)',
	1		HSTR1,WNTTSG(SNAM(0,1),0),WNTTSG(SNAM(0,NPLOT),0))
	  CALL WNGMFS(NGF_TYP_N,HSTR,NGF(NGF_TYP_1,0))
	  IF (.NOT.WNDLNF(SGPH(0)+SGH_LINKG_1,SNAM(1,1),
	1		SGH_GROUPN_1,FCAOUT,SGPH(1),SGNR(1))) THEN
 51	    CONTINUE
	    CALL WNCTXT(F_TP,'!/Error linking sub-group')
	    GOTO 900
	  END IF
	  IF (.NOT.WNDLNF(SGPH(1)+SGH_LINKG_1,
	1		NGFJ(NGF_BDN_J,0),
	1		SGH_GROUPN_1,FCAOUT,SGPH(2),SGNR(2))) GOTO 51
	  IF (.NOT.WNDLNF(SGPH(2)+SGH_LINKG_1,SNAM(3,1),
	1		SGH_GROUPN_1,FCAOUT,SGPH(3),SGNR(3))) GOTO 51
	  IF (.NOT.WNDLNF(SGPH(3)+SGH_LINKG_1,SNAM(4,1),
	1		SGH_GROUPN_1,FCAOUT,SGPH(4),SGNR(4))) GOTO 51
	  J=WNFEOF(FCAOUT)			!OUTPUT POINTER
	  NGFJ(NGF_DPT_J,0)=J+NGFHDL		!DATA POINTER
	  IF (.NOT.WNFWR(FCAOUT,NGFHDL,NGF,J)) GOTO 21 !WRITE HEADER
	  IF (.NOT.WNFWR(FCAOUT,LB_X*NGFJ(NGF_SCN_J,0),
	1		A_X(BUFAD1),J+NGFHDL)) GOTO 21 !DATA
	  IF (.NOT.WNDLNK(GFH_LINK_1,J,
	1		NGF_SETN_1,FCAOUT)) GOTO 51 !LINK DATA
	  IF (.NOT.WNDLNG(SGPH(4)+SGH_LINKG_1,J,
	1		SGH_GROUPN_1,FCAOUT,SGPH(5),SGNR(5))) GOTO 51 !INDEX
	 END IF
	END DO
	CALL NGCSPH(SGNR,NGF(0,0))		!SHOW NEW PLOT
	CALL WNGFVA(BUFL,BUFAD*LB_X+A_OB)	!RELEASE BUFFER
	CALL WNGFVA(BUFL1,BUFAD1*LB_X+A_OB)	!RELEASE BUFFER
C
C LOOP IF NECESSARY
C
	GOTO 30					!NEXT LOOP
C
C READY
C
 900	CONTINUE
	RETURN					!READY
C
C
	END
