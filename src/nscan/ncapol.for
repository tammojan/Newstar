C+ NCAPOL.FOR
C  WNB 910421
C
C  Revisions:
C	WNB 911209	Correct ifrs selection
C	WNB 921104	Full HA range
C	HjV 930311	Change some text
C	WNB 930825	Add dipole position
C	WNB 930826	New redundant baselines
C	WNB 930901	Change to full solution
C	CMV 930907	Changed array indices to solve SHOW/COPY problem
C	JPH 940809	Left-justify mean errors in Position and Ellipticity
C			 output.
C			Correct width (was 81).
C			Reduced scan-reading output
C	JPH 940831	Improve scan-read reporting throughout
C	JPH 940926	MOD(NDONE,50) --> ...,100). Typo.
C	JPH 940927	NCAPOL: Report absence of data. Correct set name in
C			 progress reporting.
C			Improve reporting of NCAPOL results
C	JPH 941215	Init NDONE on entry of NCAPOT
C       WNB 950611	Change to WNML routines for least squares
C	JPH 960625	Narrower format for constraints output
C	JPH 960627	Suppress constraints output
C	JPH 970123	Include HA in "No valid data" report
C
C
	SUBROUTINE NCAPOL
C
C  Calculate polarisation corrections
C
C  Result:
C
C	CALL NCAPOL	will calculate the polarisation corrections
C	CALL NCAPOZ	will zero the polarisation corrections
C	CALL NCAPOS	will show the polarisation corrections
C	CALL NCAPOT	will set the polarisation corrections manually
C	CALL NCAPOE	will edit the polarisation corrections manually
C	CALL NCAPOC	will copy the polarisation corrections
C
C  PIN reference:
C
C	POL_ROTAN
C	POL_ORTHOG
C	POL_X_ELLIPS
C	POL_Y_ELLIPS
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'CBITS_DEF'
	INCLUDE 'LSQ_O_DEF'
	INCLUDE 'STH_O_DEF'			!SET HEADER
	INCLUDE 'SCH_O_DEF'			!SCAN HEADER
	INCLUDE 'NCA_DEF'
C
C  Parameters:
C
	INTEGER V_MI				!FOR IV
	  PARAMETER (V_MI=V_M+IMAG_P)
C
C  Arguments:
C
C
C  Function references:
C
	LOGICAL WNFRD				!READ DISK
	LOGICAL WNFWR				!WRITE DATA
	CHARACTER*32 WNTTSG			!MAKE SUB-GROUP NAME
	LOGICAL WNDPAR				!USER PARAMETER
	LOGICAL WNMLGA				!GET LSQ AREA
	LOGICAL NSCSTG,NSCSTL			!GET A SET
	LOGICAL NSCSIF				!READ IFR TABLE
	LOGICAL NSCSCR				!READ DATA FROM SCAN
C
C  Data declarations:
C
	CHARACTER*16 TXT			! message text
	INTEGER NDAT				! valid-data counter
	INTEGER SETNAM(0:7)			!FULL SET NAME
	INTEGER CSTNAM(0:7)			!CHECK SET NAME
	  DATA CSTNAM/8*-1/
	INTEGER*2 IFRT(0:STHIFR-1)		!INTERFEROMETER TABLE
	INTEGER IFRA(0:1,0:STHIFR-1)
	REAL ANG(0:2,0:STHIFR-1)
	REAL BASEL(0:STHIFR-1)			!BASELINE TABLE
	REAL WGT(0:STHIFR-1,0:3)		!DATA WEIGHTS XX,XY,YX,YY
	REAL DAT(0:1,0:STHIFR-1,0:3)		!DATA XX,XY,YX,YY
	  COMPLEX DATC(0:STHIFR-1,0:3)
	  EQUIVALENCE (DAT,DATC)
	COMPLEX ODATC(0:STHIFR-1,0:3)		!DATA IQUV
	INTEGER APDAT(0:STHIFR-1)		!FOUND INDICATOR
	INTEGER PTYP(0:2)			!POLARISATION WANTED
	  DATA PTYP/I_M,V_MI,U_M/
	REAL HA					!HA OF SCAN
	INTEGER NDONE				!scan counter for reporting
	COMPLEX CI				!I
	COMPLEX CCF(0:2*STHTEL-1)		!COEFFICIENTS
	INTEGER NDEG				!DEGENERACY
	INTEGER MAR				!MATRIX AREA
	REAL SOL(0:1,0:2*STHTEL-1)		!SOLUTION REAL/IMAG
	  COMPLEX CSOL(0:1,0:STHTEL-1)		!X/Y
	  REAL SSOL(0:1,0:1,0:STHTEL-1)		!Gain:Phase,X:Y,Telescopes
	  EQUIVALENCE (SOL,SSOL,CSOL)
	REAL CEQ(0:4*STHTEL-1,0:4*STHTEL-1)	!CONSTRAINT EQUATIONS GAIN/PHASE
	REAL MU,SD				!ADJUSTMENT ERROR GAIN/PHASE
	REAL ME(0:1,0:1,0:STHTEL-1)		!M.E. REAL/IMAG, X/Y
	  COMPLEX CME(0:1,0:STHTEL-1)
	  EQUIVALENCE (ME,CME)
	INTEGER STHP				!POINTER TO SET HEADER
	CHARACTER*16 TELNAM			!TEL. NAMES
	  CHARACTER*1 TELNMA(0:15)
	  EQUIVALENCE (TELNAM,TELNMA)
	  DATA TELNAM/'0123456789ABCDEF'/
	BYTE STH(0:STHHDL-1)			!SET HEADER
	  INTEGER*2 STHI(0:STHHDL/2-1)
	  INTEGER STHJ(0:STHHDL/4-1)
	  REAL STHE(0:STHHDL/4-1)
	  REAL*8 STHD(0:STHHDL/8-1)
	  EQUIVALENCE(STH,STHI,STHJ,STHE,STHD)
	BYTE SCH(0:SCHHDL-1)			!SCAN HEADER
	  INTEGER*2 SCHI(0:SCHHDL/2-1)
	  INTEGER SCHJ(0:SCHHDL/4-1)
	  REAL SCHE(0:SCHHDL/4-1)
	  REAL*8 SCHD(0:SCHHDL/8-1)
	  EQUIVALENCE(SCH,SCHI,SCHJ,SCHE,SCHD)
C-
C
C INIT
C
	IF (.NOT.WNMLGA(MAR,LSQ_T_COMPLEX,2*STHTEL)) THEN !MATRIX AREA
	   CALL WNCTXT(F_TP,'ERROR: Cannot obtain solution area')
	   GOTO 70
	END IF
C
C DO SETS - NOTE: The loop control (WNDXLN) is in the calling routine NCALIB!
C
	NDONE=0
	DO WHILE(NSCSTL(FCAOUT,SETS,STH(0),STHP,SETNAM,LPOFF)) !NEXT SET
C
C Save first sector name
C
	  IF (NDONE.EQ.0) THEN
	    DO I2=0,7
	      CSTNAM(I2)=SETNAM(I2)
	    END DO
	  ENDIF
C
C GET IFR TABLES
C
	  IF (STHI(STH_PLN_I).NE.4) THEN		!CANNOT USE
	    CALL WNCTXT(F_TP,'Sector !AS has only !UI polarisations',
	1		WNTTSG(SETNAM,0),STHI(STH_PLN_I))
	    GOTO 20					!NEXT SET
	  END IF
	  IF (.NOT.NSCSIF(FCAOUT,STH,IFRT,IFRA,ANG)) THEN !READ IFR TABLE
	    CALL WNCTXT(F_TP,'!/Error reading IFR table !AS',
	1		WNTTSG(SETNAM,0))
	    GOTO 20					!TRY NEXT SET
	  END IF
	  CALL NSCMBL(STHE(STH_RTP_E),STHJ(STH_NIFR_J),IFRT,
	1			SIFRS,BASEL)		!MAKE BASEL.
C
C DO SCANS
C
	  DO I=0,STHJ(STH_SCN_J)-1			!ALL SCANS
C
C INIT
C
	    HA=STHE(STH_HAB_E)+I*STHE(STH_HAI_E)	!HA OF SCAN
	    IF (HA.LT.HARAN(1) .OR. HA.GT.HARAN(2)) GOTO 30 !FORGET
C
C GET DATA
C
	    IF (.NOT.NSCSCR(FCAOUT,STH,IFRT,I,CORAP,CORDAP,
	1			SCH,WGT,DAT)) THEN	!READ SCAN DATA
	      CALL WNCTXT(F_TP,'!7$EAF7.2 Error reading scan data',HA)
	      GOTO 20					!TRY NEXT SET
	    END IF
	    DO I1=0,STHJ(STH_NIFR_J)-1			!ALL IFRS
	      APDAT(I1)=1				!ASSUME PRESENT
	    END DO
	    CALL NMOCXX(STHJ,SCHE,ANG,WGT,APDAT,DATC,ODATC,3,PTYP) !MAKE I,IV,U
	    NDAT=0
	    DO I1=0,STHJ(STH_NIFR_J)-1			!ALL IFRS
	      IF (APDAT(I1).NE.0 .AND.
	1		BASEL(I1).GE.0) THEN		!PRESENT, SELECTED
	        IF (ABS(ODATC(I1,0)).GT.0) THEN		!I OK
		  NDAT=NDAT+1
	 	  DO I2=0,2*STHTEL-1			!COEFF.
		    CCF(I2)=0
		  END DO
		  CCF(2*IFRA(0,I1))=CMPLX(1.,-1.)	!DXW
		  CCF(2*IFRA(1,I1)+1)=CMPLX(-1.,-1.)	!DYE
cc		  CALL WNMLMN(MAR,LSQ_C_REAL,CCF,1.,
cc	1		(DATC(I1,1)+ODATC(I1,2))/ODATC(I1,0)) !XY+U
		  CALL WNMLMN(MAR,LSQ_C_REAL,CCF,1.,
	1		(DATC(I1,1))/ODATC(I1,0))	!XY
		  CCF(2*IFRA(0,I1))=0			!DXW
		  CCF(2*IFRA(1,I1)+1)=0			!DYE
		  CCF(2*IFRA(0,I1)+1)=CMPLX(1.,-1.)	!DYW
		  CCF(2*IFRA(1,I1))=CMPLX(-1.,-1.)	!DXE
cc		  CALL WNMLMN(MAR,LSQ_C_REAL,CCF,1.,
cc	1		(DATC(I1,2)-ODATC(I1,2))/ODATC(I1,0)) !YX-U
		  CALL WNMLMN(MAR,LSQ_C_REAL,CCF,1.,
	1		(DATC(I1,2))/ODATC(I1,0))	!YX
		END IF
	      END IF
	    END DO
	    IF (NDAT.EQ.0) THEN
	      CALL WNCTXT(F_TP,'!AS  !7$EAF7.2: No valid data in scan',
	1		WNTTSG(SETNAM,0),SCHE(SCH_HA_E))
	    ELSE
	      NDONE=NDONE+1
	    ENDIF
C
C NEXT SCAN
C
 30	    CONTINUE
	    IF (MOD(NDONE,100) .EQ.0)
	1      CALL WNCTXT(F_T,'Now in sector !AS: !UJ valid scans read',
	1	WNTTSG(SETNAM,0), NDONE)
 	  END DO					!END SCANS
C
C NEXT SEctor
C
 20	  CONTINUE
	END DO						!END SETS
C
C MAKE SOLUTION
C
	CALL WNMLID(MAR)				!FIX MISSING TEL.
	CALL WNMLTR(MAR,NDEG)				!DECOMP + RANK
	CALL WNMLSN(MAR,CSOL,MU,SD)			!GET SOLUTION
	CALL WNMLGC(MAR,J,CEQ)				!GET CONSTRAINTS
	CALL WNMLME(MAR,CME)				!GET M.E.
CC	CALL WNCTXT(F_P,'!/(X,Y) constraints:')
CC	DO I1=0,J-1					!SHOW CONSTRAINTS
CC	  CALL WNCTXT(F_P,'!79$5Q1!5C!3$#E7.0',
CC	1		4*STHTEL,CEQ(0,I1))
CC	END DO
C
C SAVE SOLUTION
C
	DO WHILE(NSCSTL(FCAOUT,SETS,STH(0),STHP,SETNAM,LPOFF)) !NEXT SET
	  DO I=0,1					!GAIN/PHASE
	    DO I1=0,STHTEL-1				!TEL.
	      DO I2=0,1					!X,Y
		IF (IAND(CORAP,256).EQ.0) THEN		!NOT APPLIED BEFORE
		  STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2)=
	1		SSOL(I,I2,I1)/PI2		!SAVE CORRECTIONS
		ELSE					!ADD CORRECTIONS
		  STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2)=
	1		STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2)+
	1		SSOL(I,I2,I1)/PI2		!SAVE CORRECTIONS
		END IF
	      END DO
	    END DO
	  END DO
	  IF (.NOT.WNFWR(FCAOUT,STHHDL,STH,STHP)) THEN	!WRITE CORRECTIONS
	    CALL WNCTXT(F_TP,'Error saving corrections in set !AS',
	1		WNTTSG(SETNAM,0))
	  END IF
	END DO						!END SET
C
C SHOW SOLUTION
C
	CALL WNCTXT(F_TP,'Sectors !AS-!AS: !UJ valid scans',
	1	WNTTSG(CSTNAM,0),WNTTSG(SETNAM,0),NDONE)
	CALL WNCTXT(F_TP,
	1	'Incremental corrections, being added to existing ones!/'//
	1	'Tel.!14C\Pos. angle!43C\Ellipticity!65C\Rotatn Orthog.!/'//
	1	'!10C\X(%)!25C\Y(%)!40C\X(%)!55C\Y(%)!67C\(deg)   (deg)')	
	DO I=0,STHTEL-1					!ALL TELESCOPES
	  CALL WNCTXT(F_TP,'!AS  !7$E7.2(!-4$E4.2)  !7$E7.2(!-4$E4.2)'//
	1		'  !7$E7.2(!-4$E4.2)  !7$E7.2(!-4$E4.2)'//
	1		'  !7$E7.2 !7$E7.2',
	1		TELNMA(I),
	1		100.*SSOL(0,0,I),100.*ME(0,0,I),
	1		100.*SSOL(0,1,I),100.*ME(0,1,I),
	1		100.*SSOL(1,0,I),100.*ME(1,0,I),
	1		100.*SSOL(1,1,I),100.*ME(1,1,I),
	1		(SSOL(0,0,I)+SSOL(0,1,I))*180./PI2,
	1		(SSOL(0,1,I)-SSOL(0,0,I))*360./PI2)
	END DO
	CALL WNCTXT(F_TP,' ')
C
C READY
C
	CALL WNMLFA(MAR)				!FREE MATRICES
C
 40	CONTINUE
	RETURN						!READY
C
C ZERO CORRECTIONS
C
	ENTRY NCAPOZ
C
C ZERO SOLUTION
C
	CALL WNCTXT(F_TP,' ')
	NDONE=0
	DO WHILE(NSCSTG(FCAOUT,SETS,STH(0),STHP,SETNAM)) !NEXT SET
	  DO I=0,1					!GAIN/PHASE
	    DO I1=0,STHTEL-1				!TEL.
	      DO I2=0,1					!X,Y
		STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2)=0
	      END DO
	    END DO
	  END DO
	  IF (.NOT.WNFWR(FCAOUT,STHHDL,STH,STHP)) THEN	!WRITE CORRECTIONS
	    CALL WNCTXT(F_TP,'Error zeroing corrections in sector !AS',
	1		WNTTSG(SETNAM,0))
	  END IF
	  NDONE=NDONE+1
	  IF (MOD(NDONE,100).EQ.0)
	1	CALL WNCTXT(F_T,'!AS: !UJ sectors done',
	1	WNTTSG(SETNAM,0),NDONE)
	END DO						!END SET
C
	CALL WNCTXT(F_TP,'!UJ sectors processed',NDONE)
	RETURN
C
C SHOW CORRECTIONS
C
	ENTRY NCAPOS
C
C GET CORRECTIONS
C
	DO WHILE(NSCSTG(FCAOUT,SETS,STH(0),STHP,SETNAM)) !NEXT SET
	  CALL WNCTXT(F_TP,'!/\Sector: !AS',
	1		WNTTSG(SETNAM,0))
	  DO I=0,1					!GAIN/PHASE
	    DO I1=0,STHTEL-1				!TEL.
	      DO I2=0,1					!X,Y
C CMV930907 Use SSOL in stead of sol
		SSOL(I,I2,I1)=				!GET CORRECTIONS
	1		STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2)*PI2
	      END DO
	    END DO
	  END DO
C
C SHOW SOLUTION
C
	  CALL WNCTXT(F_TP,'!/       Position      '//
	1		'    Ellipticity   '//
	1		' Rotation Orthog.!/'//
	1		'      X(%)     Y(%)  '//
	1		'   X(%)     Y(%)  '//
	1		'  (deg)    (deg)!/')		!HEADING
	  DO I=0,STHTEL-1				!ALL TELESCOPES
	    CALL WNCTXT(F_TP,'!AS  !7$E7.2  !7$E7.2'//
	1		'  !7$E7.2  !7$E7.2'//
	1		'  !7$E7.2  !7$E7.2',
	1		TELNMA(I),
	1		100.*SSOL(0,0,I),
	1		100.*SSOL(0,1,I),
	1		100.*SSOL(1,0,I),
	1		100.*SSOL(1,1,I),
	1		(SSOL(0,0,I)+SSOL(0,1,I))*180./PI2,
	1		(SSOL(0,1,I)-SSOL(0,0,I))*360./PI2)
	  END DO
	END DO						!END SETS
	CALL WNCTXT(F_TP,' ')
C
	RETURN
C
C SET CORRECTIONS
C
	ENTRY NCAPOT
C
C GET VALUES
C
C
C	Here we assume the SSOL array is dimensioned 
C	  SSOL(0:STHTEL-1,X:Y,GAIN:PHASE)
C
C	This is not the case and might give errors if array bound
C	checking would be done
C
	NDONE=0
41	CONTINUE
	DO I1=0,STHTEL-1				!MAKE ZERO
	  SSOL(I1,0,0)=0
	END DO
	IF (.NOT.WNDPAR('POL_ROTAN',SSOL(0,0,0),STHTEL*LB_E,J0,
	1		A_B(-A_OB),SSOL(0,0,0),STHTEL)) THEN
	  IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 40		!STOP
	  GOTO 41					!RETRY
	END IF
	IF (J0.LE.0) THEN				!SET ZERO
	  DO I1=0,STHTEL-1
	    SSOL(I1,0,0)=0
	  END DO
	END IF
42	CONTINUE
	DO I1=0,STHTEL-1				!MAKE ZERO
	  SSOL(I1,1,0)=0
	END DO
	IF (.NOT.WNDPAR('POL_ORTHOG',SSOL(0,1,0),STHTEL*LB_E,J0,
	1		A_B(-A_OB),SSOL(0,1,0),STHTEL)) THEN
	  IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 41		!STOP
	  GOTO 42					!RETRY
	END IF
	IF (J0.LE.0) THEN				!SET ZERO
	  DO I1=0,STHTEL-1
	    SSOL(I1,1,0)=0
	  END DO
	END IF
43	CONTINUE
	DO I1=0,STHTEL-1				!MAKE ZERO
	  SSOL(I1,0,1)=0
	END DO
	IF (.NOT.WNDPAR('POL_X_ELLIPS',SSOL(0,0,1),STHTEL*LB_E,J0,
	1		A_B(-A_OB),SSOL(0,0,1),STHTEL)) THEN
	  IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 42		!STOP
	  GOTO 43					!RETRY
	END IF
	IF (J0.LE.0) THEN				!SET ZERO
	  DO I1=0,STHTEL-1
	    SSOL(I1,0,1)=0
	  END DO
	END IF
44	CONTINUE
	DO I1=0,STHTEL-1				!MAKE ZERO
	  SSOL(I1,1,1)=0
	END DO
	IF (.NOT.WNDPAR('POL_Y_ELLIPS',SSOL(0,1,1),STHTEL*LB_E,J0,
	1		A_B(-A_OB),SSOL(0,1,1),STHTEL)) THEN
	  IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 43		!STOP
	  GOTO 44					!RETRY
	END IF
	IF (J0.LE.0) THEN				!SET ZERO
	  DO I1=0,STHTEL-1
	    SSOL(I1,1,1)=0
	  END DO
	END IF
C
C MAKE PROPER FORMAT
C
	DO I1=0,STHTEL-1				!TEL.
	  DO I2=0,1					!X,Y
	    SSOL(I1,I2,1)=SSOL(I1,I2,1)/100		!ELLIPTICITY
	  END DO
	  R0=(SSOL(I1,0,0)*PI2/180-SSOL(I1,1,0)*PI2/360)/2 !POS. X
	  SSOL(I1,1,0)=(SSOL(I1,0,0)*PI2/180+SSOL(I1,1,0)*PI2/360)/2 !POS. Y
	  SSOL(I1,0,0)=R0				!POS. X
	END DO
C
C SAVE SOLUTION
C
	CALL WNCTXT(F_TP,' ')
	DO WHILE(NSCSTG(FCAOUT,SETS,STH(0),STHP,SETNAM)) !NEXT SET
	  DO I=0,1					!GAIN/PHASE
	    DO I1=0,STHTEL-1				!TEL.
	      DO I2=0,1					!X,Y
		STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2)=
	1			SSOL(I1,I2,I)/PI2	!SET
	      END DO
	    END DO
	  END DO
	  IF (.NOT.WNFWR(FCAOUT,STHHDL,STH,STHP)) THEN	!WRITE CORRECTIONS
	    CALL WNCTXT(F_TP,'Error setting corrections in set !AS',
	1		WNTTSG(SETNAM,0))
	  END IF
	  NDONE=NDONE+1
	  IF (MOD(NDONE,100).EQ.0)
	1	CALL WNCTXT(F_T,'!AS: !UJ sectors done',
	1	WNTTSG(SETNAM,0),NDONE)
	END DO						!END SET
C
 70	CONTINUE
	CALL WNCTXT(F_TP,'!UJ sectors processed',NDONE)
	RETURN
C
C EDIT  CORRECTIONS
C
	ENTRY NCAPOE
C
C GET SOLUTION
C
C
C	Again assume SSOL(0:STHTEL-1,X:Y,GAIN:PHASE)
C
	CALL WNCTXT(F_TP,' ')
	NDONE=0
	DO WHILE(NSCSTG(FCAOUT,SETS,STH(0),STHP,SETNAM)) !NEXT SET
	  DO I=0,1					!GAIN/PHASE
	    DO I1=0,STHTEL-1				!TEL.
	      DO I2=0,1					!X,Y
		SSOL(I1,I2,I)=PI2*
	1		STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2) !GET CORRECTIONS
	      END DO
	    END DO
	  END DO
C
C MAKE EXTERNAL FORMAT
C
	  DO I1=0,STHTEL-1				!TEL.
	    DO I2=0,1					!X,Y
	      SSOL(I1,I2,1)=100*SSOL(I1,I2,1)		!ELLIPTICITY
	    END DO
	    R0=(SSOL(I1,0,0)+SSOL(I1,1,0))*180./PI2
	    SSOL(I1,1,0)=(SSOL(I1,1,0)-SSOL(I1,0,0))*360./PI2 !ORTHOG.
	    SSOL(I1,0,0)=R0				!ROTAT. ANGLE
	  END DO
C
C EDIT
C
51	  CONTINUE
	  IF (.NOT.WNDPAR('POL_ROTAN',SSOL(0,0,0),STHTEL*LB_E,J0,
	1		A_B(-A_OB),SSOL(0,0,0),STHTEL)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 50		!STOP
	    GOTO 51					!RETRY
	  END IF
	  IF (J0.EQ.0) THEN				!SET ZERO
	    DO I1=0,STHTEL-1
	      SSOL(I1,0,0)=0
	    END DO
	  END IF
52	  CONTINUE
	  IF (.NOT.WNDPAR('POL_ORTHOG',SSOL(0,1,0),STHTEL*LB_E,J0,
	1		A_B(-A_OB),SSOL(0,1,0),STHTEL)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 51		!STOP
	    GOTO 52					!RETRY
	  END IF
	  IF (J0.EQ.0) THEN				!SET ZERO
	    DO I1=0,STHTEL-1
	      SSOL(I1,1,0)=0
	    END DO
	  END IF
53	  CONTINUE
	  IF (.NOT.WNDPAR('POL_X_ELLIPS',SSOL(0,0,1),STHTEL*LB_E,J0,
	1		A_B(-A_OB),SSOL(0,0,1),STHTEL)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 52		!STOP
	    GOTO 53					!RETRY
	  END IF
	  IF (J0.EQ.0) THEN				!SET ZERO
	    DO I1=0,STHTEL-1
	      SSOL(I1,0,1)=0
	    END DO
	  END IF
54	  CONTINUE
	  IF (.NOT.WNDPAR('POL_Y_ELLIPS',SSOL(0,1,1),STHTEL*LB_E,J0,
	1		A_B(-A_OB),SSOL(0,1,1),STHTEL)) THEN
	    IF (E_C.EQ.DWC_ENDOFLOOP) GOTO 53		!STOP
	    GOTO 54					!RETRY
	  END IF
	  IF (J0.EQ.0) THEN				!SET ZERO
	    DO I1=0,STHTEL-1
	      SSOL(I1,1,1)=0
	    END DO
	  END IF
C
C MAKE PROPER FORMAT
C
	  DO I1=0,STHTEL-1				!TEL.
	    DO I2=0,1					!X,Y
	      SSOL(I1,I2,1)=SSOL(I1,I2,1)/100		!ELLIPTICITY
	    END DO
	    R0=(SSOL(I1,0,0)*PI2/180-SSOL(I1,1,0)*PI2/360)/2 !POS. X
	    SSOL(I1,1,0)=(SSOL(I1,0,0)*PI2/180+SSOL(I1,1,0)*PI2/360)/2 !POS. Y
	    SSOL(I1,0,0)=R0				!POS. X
	  END DO
C
C SET NEW CORRECTIONS
C
	  DO I=0,1					!GAIN/PHASE
	    DO I1=0,STHTEL-1				!TEL.
	      DO I2=0,1					!X,Y
		STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2)=
	1			SSOL(I1,I2,I)/PI2	!SET
	      END DO
	    END DO
	  END DO
	  IF (.NOT.WNFWR(FCAOUT,STHHDL,STH,STHP)) THEN	!WRITE CORRECTIONS
	    CALL WNCTXT(F_TP,'Error setting corrections in set !AS',
	1		WNTTSG(SETNAM,0))
	  END IF
	  NDONE=NDONE+1
	  IF (MOD(NDONE,100).EQ.0)
	1	CALL WNCTXT(F_T,'Now at output sector !AS: !UJ sectors done',
	1	WNTTSG(SETNAM,0),NDONE)
	END DO						!END SET
C
 50	CONTINUE
	CALL WNCTXT(F_TP,'Total of !UJ sectors processed',NDONE)
	RETURN
C
C COPY CORRECTIONS
C
	ENTRY NCAPOC
C
C GET DATA
C
	IF (.NOT.NSCSTL(FCAINP,SETINP,STH(0),STHP,CSTNAM,LPOFF)) THEN
	  CALL WNCTXT(F_TP,'No input set can be found')
	  GOTO 60					!READY
	END IF
C
C FORMAT IT
C
	DO I=0,1					!GAIN/PHASE
	  DO I1=0,STHTEL-1				!TEL.
	    DO I2=0,1					!X,Y
C CMV930907 Please use proper SSOL here...
C	      SSOL(I1,I2,I)=PI2*
	      SSOL(I,I2,I1)=PI2*
	1		STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2) !GET CORRECTIONS
	    END DO
	  END DO
	END DO
C
C SAVE THEM
C
CC	CALL WNCTXT(F_TP,' ')
	NDONE=0
	DO WHILE(NSCSTL(FCAOUT,SETS,STH(0),STHP,SETNAM,LPOFF)) !NEXT output sctr
C
C SET NEW CORRECTIONS
C
	  DO I=0,1					!GAIN/PHASE
	    DO I1=0,STHTEL-1				!TEL.
	      DO I2=0,1					!X,Y
C CMV930907 Also proper SSOL
		STHE(STH_POLC_E+I+2*I1+2*STHTEL*I2)=
	1			SSOL(I,I2,I1)/PI2	!SET
	      END DO
	    END DO
	  END DO
	  IF (.NOT.WNFWR(FCAOUT,STHHDL,STH,STHP)) THEN	!WRITE CORRECTIONS
	    CALL WNCTXT(F_TP,'Error setting corrections in sector !AS',
	1		WNTTSG(SETNAM,0))
	  END IF
	  NDONE=NDONE+1
	  IF (MOD(NDONE,100).EQ.0)
	1	CALL WNCTXT(F_T,'Input sector !AS, !UJ output sectors done',
	1	WNTTSG(CSTNAM,0),NDONE)
	END DO						!END SET
C
	CALL WNCTXT(F_TP,'Input sector !AS copied to !UJ output sectors',
	1	WNTTSG(CSTNAM,0),NDONE)
 60	CONTINUE
	RETURN
C
C
	END
