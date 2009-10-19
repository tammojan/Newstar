C+ NCARCS.FOR
C  WNB 910131
C
C  Revisions:
C	WNB 910812	Add ALIGN
C	WNB 910930	Narrower check
C	WNB 911024	Running noise
C	WNB 930504	Make proper complex solution
C	WNB 930628	Typo for ALIGN part
C       WNB 950613	New LSQ routines
C       WNB 950614	Change non-linear LSQ
C       WNB 950621	Organisational changes
C       WNB 950628	Second order error correction
C       WNB 950718	Typo for some machines
C	WNB 980701	Add for new MIFR calculations
C	CMV 030116	Acommodated for unsorted IFR table
C       WNB 070814      Change in inconsistency calculations
C       WNB 091019      Change back to old (pre-070814)
C
	LOGICAL FUNCTION NCARCS(MAR,NIFR,IFR,BASEL,NDEG,
	1			IRED,WGT,AWGT,CDAT,AMP,PHAS,CMOD,CWGT,
	1			CSOL,SOL,MU,ME)
C
C  Calculate redundancy complex solution
C
C  Result:
C
C	NCARCS_L = NCARCS( MAR_J:I, NIFR_J:I, 
C				IFR_I(0:*):I, BASEL_E(0:*):I, NDEG_J:IO,
C				IRED_J(0:NIFR-1):I, WGT_E(0:*,0:*):I,
C				AWGT_E(0:8,0:1):I, CDAT_X(0:*,0:1):I
C				AMP_E(0:*,0:*):I, PHAS_E(0:*,0:*):I,
C				CMOD_X(0:*,0:1):I, CWGT_E(0:*):I,
C				CSOL_E(0:*,0:1,0:1):I,SOL_E(0:*,0:1,0:1):O,
C				MU_E:O, ME_E:O)
C					Calculate the redundancy complex solution
C					in SOL, with adjustment error MU and
C					mean errors ME using CSOL as approximate
C					solution.
C					WGT/AWGT is the weight, AMP/PHAS/CDAT
C					the data. IRED specifies the
C					redundant baselines.
C					CMOD is the model with sqrt(weights)
C					CWGT.
C					MAR is the solution area for the
C					telescopes, using NIFR interferometers
C					and a degeneracy of NDEG.
C					IFR are the interferometer
C					specifications.
C	NCASCS_L = NCASCS( ...)
C					Selfcal solution
C	NCAACS_L = NCAACS( ..., NUK_J(0:1):I, ALEQ_E(0:*,0:*,0:1):I)
C					Use model for aligning NUK parameters
C					with constraint ALEQ
C
C	NCARCE_L = NCARCE( MAR_J:I, NIFR_J:I, 
C				IFR_I(0:*):I, BASEL_E(0:*):I, NDEG_J:IO,
C				IRED_J(0:NIFR-1):I, WGT_E(0:*,0:1):I,
C				AWGT_E(0:*,0:1):I, CDAT_X(0:*,0:1):I,
C				AMP_E(0:*,0:1):I, PHAS_E(0:*,0:1):I,
C				CMOD_X(0:*,0:1):I, CWGT_E(0:*):I,
C				CSOL_E(0:*,0:1,0:1):I,SOL_E(0:*,0:1,0:1):I,
C				MU_E:I, ME_E:I, ARMS_E(0:2):I,
C				JAV_J(0:*,0:*,0:1):IO, EAV_E(0:*,0:*,0:1):IO,
C				DAV_D(0:*,0:*,0:1):IO)
C					Calculate all errors in the average
C					arrays JAV, EAV and DAV.
C					ARMS is the average amplitude of scan
C	NCARCC_L = NCARCC( ...)
C					Correct errors back
C	NCASCE_L = NCASCE( ...)
C					Calculate selfcal errors
C	NCASCC_L = NCASCC( ...)
C					Correct selfcal errors back
C	NCAACE_L = NCAACE( ...)
C					Calculate align errors
C	NCAACC_L = NCAACC( ...)
C					Correct align errors back
C
C				JAV, EAV, DAV contain:
C					*,*,0		gain
C					*,*,1		phase
C					0,0		noise per scan
C					1,0		inconsistency per scan
C					2,0		total noise
C					3,0		overall running noise
C					4,0		max. deviation in scan
C					5,0		total average noise
C					6,0		total average incons.
C					7,0		total average ampl.
C					*,1		inconsistency per ifr
C					*,2		average rms per ifr
C					*,3		gain per telescope
C!980701				*,4		weighted incons per ifr
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'LSQ_O_DEF'
	INCLUDE 'STH_O_DEF'			!SET HEADER
C
C  Entry points:
C
	LOGICAL NCASCS				!SELFCAL SOLUTION
	LOGICAL NCAACS				!ALIGN SOLUTION
	LOGICAL NCARCE,NCARCC			!CALCULATE ERRORS
	LOGICAL NCASCE,NCASCC			!CALCULATE SELFCAL ERRORS
	LOGICAL NCAACE,NCAACC			!CALCULATE ALIGN ERRORS
C
C  Parameters:
C
C
C  Arguments:
C
	INTEGER MAR				!SOLUTION AREA POINTERS
	INTEGER NIFR				!TOTAL # OF INTERFEROMETERS
	INTEGER*2 IFR(0:*)			!INTERFEROMETER TELESCOPES
	INTEGER NDEG				!DEGENERACY LEVEL (OUT)
						!LOOP COUNT (IN)
	REAL BASEL(0:*)				!BASELINES
	INTEGER IRED(0:*)			!REDUNDANCY INDICATOR
	REAL WGT(0:STHIFR-1,0:*)		!DATA WEIGHT X,Y
	REAL AWGT(0:STHIFR-1,0:*)		!AMPL. WEIGHTED WEIGHT X,Y
	COMPLEX CDAT(0:STHIFR-1,0:*)		!DATA COMPLEX X,Y
	REAL AMP(0:STHIFR-1,0:*)		!DATA AMPLITUDE X,Y
	REAL PHAS(0:STHIFR-1,0:*)		!DATA PHASE X,Y
	COMPLEX CMOD(0:STHIFR-1,0:*)		!MODEL COMPLEX X,Y
	REAL CWGT(0:*)				!MODEL WEIGHT**0.5
	REAL SOL(0:STHTEL-1,0:1,0:1)		!SOLUTION X,Y G,P
	REAL CSOL(0:STHTEL-1,0:1,0:1)		!CONTINUITY SOLUTION G,P X,Y
	REAL MU					!ADJUSTMENT ERROR
	REAL ME					!MEAN ERRORS SOLUTION
	INTEGER NUK(0:1)			!# OF CONSTRAINTS
	REAL ALEQ(0:STHTEL-1,0:STHTEL-1,0:1)	!CONSTRAINT EQUATIONS G,P
	REAL ARMS(0:2)				!AVERAGE AMPL.
	INTEGER JAV(0:STHIFR-1,0:4,0:1)		!COUNT FOR AVERAGES
	REAL EAV(0:STHIFR-1,0:4,0:1)		!SUM FOR AVERAGES
	REAL*8 DAV(0:STHIFR-1,0:4,0:1)		!SUM FOR RMS
C
C  Function references:
C
C
C  Data declarations:
C
	COMPLEX CCF(0:2*STHTEL-1)		!COEFFICIENTS FOR SOLUTION
	INTEGER TW1,TE1				!TELESCOPES
	INTEGER TW2,TE2
	REAL W2,W22				!WEIGHTS
	REAL W4,W24
	REAL R2                                 !980701
	COMPLEX CC1,CC2
	COMPLEX CELES(0:STHIFR-1)		!CELESTIAL DATA
	REAL WCELES(0:STHIFR-1)
	COMPLEX CLSOL(0:STHTEL-1)		!LOCAL SOLUTION
	REAL LSOL(0:STHTEL-1,0:1)		!LOCAL ALIGN SOLUTION
	INTEGER NR				!RANK SOLUTION
	INTEGER NU				!# OF UNKNOWNS
	LOGICAL DOSC				!SELFCAL OPTION
	LOGICAL DOAL				!ALIGN OPTION
	REAL MMAX				!MODEL MAX
	COMPLEX C0,C1,C2                        !ADD C2 - WNB070814
	REAL R3                                 !ADD  WNB070814
C-
C
C INIT
C
	NCARCS=.TRUE.					!ASSUME OK
	NU=STHTEL					!# OF UNKNOWNS
	DOSC=.FALSE.					!NOT SELFCAL
	DOAL=.FALSE.					!NOT ALIGN
	GOTO 20
C
C SELFCAL SOLUTION
C
	ENTRY NCASCS(MAR,NIFR,IFR,BASEL,NDEG,
	1			IRED,WGT,AWGT,CDAT,AMP,PHAS,CMOD,CWGT,
	1			CSOL,SOL,MU,ME)
C
	NCASCS=.TRUE.					!ASSUME OK
	NU=STHTEL					!# OF UNKNOWNS
	DOSC=.TRUE.					!SELFCAL
	DOAL=.FALSE.					!NOT ALIGN
	GOTO 21
C
C ALIGN SOLUTION
C
	ENTRY NCAACS(MAR,NIFR,IFR,BASEL,NDEG,
	1			IRED,WGT,AWGT,CDAT,AMP,PHAS,CMOD,CWGT,
	1			CSOL,SOL,MU,ME,NUK,ALEQ)
C
	NCAACS=.TRUE.					!ASSUME OK
	NU=MAX(NUK(0),NUK(1))				!# OF UNKNOWNS
	DOSC=.FALSE.					!NOT SELFCAL
	DOAL=.TRUE.					!ALIGN
	GOTO 21
C
C INIT
C
 21	CONTINUE
	MMAX=ABS(CMOD(0,0))				!WEIGHT SCALING
	DO I=1,NIFR-1
	   MMAX=MAX(MMAX,ABS(CMOD(I,0)))
	END DO
	MMAX=MAX(MMAX,1.)				!MAKE SURE		
 20	CONTINUE
C
C ZERO SOLUTION MATRIX
C
	CALL WNMLIA(MAR,LSQ_I_ALL) 			!FULL AREA
	ME=1. 	 	 	 	 	 	!START LOOP
	DO I=0,STHTEL-1					!START SOLUTION
	   IF (DOAL) THEN
	      CLSOL(I)=0
	   ELSE
	      CLSOL(I)=CMPLX(1.,0.)
	   END IF
	END DO
C
C LOOP
C
	DO WHILE((ME.GT.0 .OR. ME.LT.-0.001) .AND. NCARCS
	1    .AND. NDEG.GE.0)
	   NDEG=NDEG-1					!LOOP COUNT
C
C MAKE MATRIX
C
	   I1=0					!TEST REDUNDANT BASELINE
	   DO I=0,NIFR-1			!ALL IFRS
	     IF (.NOT.DOAL .AND. IRED(I).GT.0) THEN !REDUNDANT
		IF (IRED(I).GT.I1) THEN 	!NEXT SET
		  IF (WGT(I,0).NE.0) THEN 	!CAN USE AS BASE
		    I1=IRED(I) 		!NEW TEST VALUE
		    I4=I
		    TE1=IFR(I)/256 		!TELESCOPES
		    TW1=MOD(IFR(I),256)
		    W2=AWGT(I,0) 		!SAVE WEIGHT
		    CC1=CDAT(I,0)* 		!CORRECTED DATA
	1	       EXP(CMPLX(-CSOL(TW1,0,0)-CSOL(TE1,0,0),
	1	       -CSOL(TW1,1,0)+CSOL(TE1,1,0)))
		    IF (DOSC) THEN 		!SELFCAL
		       W4=WGT(I,0)*(CWGT(I)**2) !MODEL WEIGHT
		       W24=(ABS(CMOD(I,0))/MMAX)**2
		       IF (W24.NE.0) THEN
			 CC2=CC1/CMOD(I,0)
			 DO I2=0,2*NU-1 	!ZERO COEFFICIENTS
			   CCF(I2)=0
			 END DO
			 CCF(2*TW1)=CONJG(CLSOL(TE1))
			 CCF(2*TE1+1)=CLSOL(TW1)
			 CALL WNMLMN(MAR,LSQ_C_CCOMPLEX,CCF,W4*W24,
	1			CC2-CLSOL(TW1)*CONJG(CLSOL(TE1)))
		       END IF
		    END IF
	            DO I3=I+1,NIFR-1				!FIND OTHERS 
		      IF (IRED(I3).EQ.I1.AND.WGT(I3,0).GT.0) THEN 	!SHOULD INCLUDE
		        TE2=IFR(I3)/256 		!TELESCOPES
		        TW2=MOD(IFR(I3),256)
		        W22=AWGT(I3,0) 		!WEIGHT
		        CC2=CDAT(I3,0)* 		!CORRECTED DATA
	1		    EXP(CMPLX(-CSOL(TW2,0,0)-CSOL(TE2,0,0),
	1		    -CSOL(TW2,1,0)+CSOL(TE2,1,0)))
		        IF (W2.NE.0) THEN
			  CC2=CC2/CC1
			  DO I2=0,2*NU-1
			     CCF(I2)=0 		!ZERO COEFFICIENTS
			  END DO
			  C0=CONJG(CLSOL(TE2))*CLSOL(TW2)/
	1		       (CONJG(CLSOL(TE1))*CLSOL(TW1))
			  CCF(2*TW1)=-C0/CLSOL(TW1)
			  CCF(2*TE1+1)=-C0/CONJG(CLSOL(TE1))
			  CCF(2*TW2)=C0/CLSOL(TW2)
			  CCF(2*TE2+1)=C0/CONJG(CLSOL(TE2))
			  CALL WNMLMN(MAR,LSQ_C_CCOMPLEX,CCF,W2*W22,
	1		       CC2-C0)
		        END IF
		      END IF
		    END DO
		  END IF
		END IF
	      ELSE IF (DOSC .AND. WGT(I,0).GT.0) THEN !SELFCAL
		 W22=WGT(I,0)*(CWGT(I)**2)	!WEIGHTS
		 W24=(ABS(CMOD(I,0))/MMAX)**2
		 TE2=IFR(I)/256			!TELESCOPES
		 TW2=MOD(IFR(I),256)
		 CC2=CDAT(I,0)*			!CORRECTED DATA
	1	      EXP(CMPLX(-CSOL(TW2,0,0)-CSOL(TE2,0,0),
	1	      -CSOL(TW2,1,0)+CSOL(TE2,1,0)))
		 IF (W24.NE.0) THEN
		    CC2=CC2/CMOD(I,0)
		    DO I2=0,2*NU-1
		       CCF(I2)=0 		!ZERO COEFFICIENTS
		    END DO
		    CCF(2*TW2)=CONJG(CLSOL(TE2))
		    CCF(2*TE2+1)=CLSOL(TW2)
		    CALL WNMLMN(MAR,LSQ_C_CCOMPLEX,CCF,W22*W24,
	1		 CC2-CLSOL(TW2)*CONJG(CLSOL(TE2)))
		 END IF
	      ELSE IF (DOAL .AND. WGT(I,0).GT.0) THEN !ALIGN
		 W22=WGT(I,0)*(CWGT(I)**2)	!WEIGHTS
		 W24=(ABS(CMOD(I,0))/MMAX)**2
		 TE2=IFR(I)/256			!TELESCOPES
		 TW2=MOD(IFR(I),256)
		 CC2=CDAT(I,0)*			!CORRECTED DATA
	1	      EXP(CMPLX(-CSOL(TW2,0,0)-CSOL(TE2,0,0),
	1	      -CSOL(TW2,1,0)+CSOL(TE2,1,0)))
		 IF (W24.NE.0) THEN		!CAN DO
		    CC2=CC2/CMOD(I,0)
		    DO I2=0,2*NU-1 		!ZERO COEEFICIENTS
		       CCF(I2)=0
		    END DO
		    DO I2=0,NUK(0)-1
		       CCF(2*I2)=(ALEQ(TW2,I2,0)+ALEQ(TE2,I2,0))
		    END DO
		    DO I2=0,NUK(1)-1
		       CCF(2*I2+1)=ALEQ(TW2,I2,1)-ALEQ(TE2,I2,1)
		    END DO
		    C0=1
		    DO I2=0,NU-1
		       C1=EXP(CMPLX(0.,REAL(CCF(2*I2+1))*AIMAG(CLSOL(I2))))
		       C0=C0*(1+REAL(CLSOL(I2))*CCF(2*I2))*C1
		    END DO
		    DO I2=0,NU-1
		       CCF(2*I2)=CCF(2*I2)*C0/(1+REAL(CLSOL(I2))*CCF(2*I2))
		       CCF(2*I2+1)=CCF(2*I2+1)*C0
		    END DO
		    CALL WNMLMN(MAR,LSQ_C_DCOMPLEX,CCF,W22*W24,
	1		 CC2-C0)	    
		 END IF
	      END IF
	   END DO
C       
C       INVERT/SOLVE NORMAL EQUATIONS
C       
	   CALL WNMLNR(MAR,NR,CLSOL,MU,ME)	!LU DECOMP. + RANK + SOLVE
	   DO I=0,NU-1				!CHECK SOLUTION
	      IF (DOAL) THEN
		 IF (ABS(1+CLSOL(I)).GT.1E-6) THEN
		    C0=1+CLSOL(I)
		    IF (ABS(C0).GT.5) THEN
		       NCARCS=.FALSE.
		    END IF
		 ELSE
		    NCARCS=.FALSE.
		 END IF
	      ELSE IF (ABS(CLSOL(I)).GT.1E-6) THEN !MAKE PROPER UNITS
		 C0=LOG(CLSOL(I))
		 IF (ABS(C0).GT.10) THEN 	!CHECK FUNNY
		    NCARCS=.FALSE.
		 END IF
	      ELSE
		 NCARCS=.FALSE.
	      END IF
	   END DO
	END DO
	IF (NCARCS) THEN
	   DO I=0,NU-1				!SET SOLUTION
	      IF (.NOT.DOAL) THEN
		 C0=LOG(CLSOL(I))
	      ELSE
		 C0=LOG(1+CLSOL(I))
	      END IF
	      SOL(I,0,0)=REAL(C0)
	      SOL(I,0,1)=AIMAG(C0)
	   END DO
	   IF (DOAL) THEN 			!MAKE ALIGN SOLUTION
	      DO I2=0,1				!COS/SIN
		 DO I=0,NUK(I2)-1
		    LSOL(I,I2)=SOL(I,0,I2) 	!SAVE SOLUTION
		 END DO
	      END DO
	      DO I=0,STHTEL-1			!SET ALIGN SOLUTION
		 DO I2=0,1			!COS/SIN
		    SOL(I,0,I2)=0
		    DO I1=0,NUK(I2)-1
		       SOL(I,0,I2)=SOL(I,0,I2)+ALEQ(I,I1,I2)*LSOL(I1,I2)
		    END DO
		 END DO
	      END DO
	   END IF
	END IF						!NON-LINEAR LOOP
C
	RETURN						!READY
C
C ERROR CALCULATION
C
	ENTRY NCARCE(MAR,NIFR,IFR,BASEL,NDEG,
	1			IRED,WGT,AWGT,CDAT,AMP,PHAS,CMOD,CWGT,
	1			CSOL,SOL,MU,ME,
	1			ARMS,JAV,EAV,DAV)
C
	NCARCE=.TRUE.					!ASSUME OK
	J0=1						!ADD ERRORS
	DOSC=.FALSE.					!NO SELFCAL
	DOAL=.FALSE.					!NO ALIGN
	GOTO 10
C
C ERROR CORRECTION
C
	ENTRY NCARCC(MAR,NIFR,IFR,BASEL,NDEG,
	1			IRED,WGT,AWGT,CDAT,AMP,PHAS,CMOD,CWGT,
	1			CSOL,SOL,MU,ME,
	1			ARMS,JAV,EAV,DAV)
C
	NCARCC=.TRUE.					!ASSUME OK
	J0=-1						!SUBTRACT ERROR
	DOSC=.FALSE.					!NO SELFCAL
	DOAL=.FALSE.					!NO ALIGN
	GOTO 10
C
C SELFCAL ERROR CALCULATION
C
	ENTRY NCASCE(MAR,NIFR,IFR,BASEL,NDEG,
	1			IRED,WGT,AWGT,CDAT,AMP,PHAS,CMOD,CWGT,
	1			CSOL,SOL,MU,ME,
	1			ARMS,JAV,EAV,DAV)
C
	NCASCE=.TRUE.					!ASSUME OK
	J0=1						!ADD ERRORS
	DOSC=.TRUE.					!SELFCAL
	DOAL=.FALSE.					!NOT ALIGN
	GOTO 10
C
C SELFCAL ERROR CORRECTION
C
	ENTRY NCASCC(MAR,NIFR,IFR,BASEL,NDEG,
	1			IRED,WGT,AWGT,CDAT,AMP,PHAS,CMOD,CWGT,
	1			CSOL,SOL,MU,ME,
	1			ARMS,JAV,EAV,DAV)
C
	NCASCC=.TRUE.					!ASSUME OK
	J0=-1						!SUBTRACT ERROR
	DOSC=.TRUE.					!SELFCAL
	DOAL=.FALSE.					!NOT ALIGN
	GOTO 10
C
C ALIGN ERROR CALCULATION
C
	ENTRY NCAACE(MAR,NIFR,IFR,BASEL,NDEG,
	1			IRED,WGT,AWGT,CDAT,AMP,PHAS,CMOD,CWGT,
	1			CSOL,SOL,MU,ME,
	1			ARMS,JAV,EAV,DAV)
C
	NCAACE=.TRUE.					!ASSUME OK
	J0=1						!ADD ERRORS
	DOSC=.FALSE.					!NOT SELFCAL
	DOAL=.TRUE.					!ALIGN
	GOTO 10
C
C ALIGN ERROR CORRECTION
C
	ENTRY NCAACC(MAR,NIFR,IFR,BASEL,NDEG,
	1			IRED,WGT,AWGT,CDAT,AMP,PHAS,CMOD,CWGT,
	1			CSOL,SOL,MU,ME,
	1			ARMS,JAV,EAV,DAV)
C
	NCAACC=.TRUE.					!ASSUME OK
	J0=-1						!SUBTRACT ERROR
	DOSC=.FALSE.					!NOT SELFCAL
	DOAL=.TRUE.					!ALIGN
	GOTO 10
C
C GET CELESTIAL GAIN/PHASES
C
 10	CONTINUE
	IF (DOSC .OR. DOAL) THEN			!ALIGN/SELFCAL
	  DO I=0,NIFR-1
	    CELES(I)=CMOD(I,0)
	  END DO
	ELSE
	  DO I=0,NIFR-1					!ZERO CELESTIAL SOLUTION
	    CELES(I)=0
	    WCELES(I)=0
	  END DO
	  DO I=0,NIFR-1					!CALCULATE
	    IF (IRED(I).GT.0) THEN			!REDUNDANT
	      IF (WGT(I,0).GT.0) THEN			!CAN USE
	        I1=IRED(I)				!POINTER
	        TE1=IFR(I)/256				!TELESCOPES
	        TW1=MOD(IFR(I),256)
	        W2=AWGT(I,0)				!WEIGHT
	        CELES(I1)=CELES(I1)+W2*CDAT(I,0)*
	1		EXP(CMPLX(-CSOL(TW1,0,0)-CSOL(TE1,0,0),
	1		-CSOL(TW1,1,0)+CSOL(TE1,1,0)))	!SUM
	        WCELES(I1)=WCELES(I1)+W2		!SUM WEIGHT
	      END IF
	    END IF
	  END DO
	  DO I=0,NIFR-1					!SOLVE
	    IF (WCELES(I).GT.0) CELES(I)=CELES(I)/WCELES(I)
	  END DO
	END IF
C
C INIT
C
	DO I=0,1					!GAIN/PHASE
	  JAV(0,0,I)=0					!NOISE
	  EAV(0,0,I)=0
	  DAV(0,0,I)=0
	  JAV(1,0,I)=0					!FRACT. NOISE (INCONS.)
	  EAV(1,0,I)=0
	  DAV(1,0,I)=0
	  JAV(4,0,I)=0					!MAX. DEVIATION
	  EAV(4,0,I)=0
	  IF (JAV(2,0,I).NE.0) THEN			!TOTAL COUNT
	    EAV(3,0,I)=SQRT(EAV(2,0,I)/JAV(2,0,I))	!OVERALL RUNNING NOISE
	  ELSE
	    EAV(3,0,I)=0
	  END IF
	END DO
C
C DO FOR IFRS
C
	DO I=0,NIFR-1					!ALL IFRS
	  IF (DOSC .OR. DOAL .OR. IRED(I).GT.0) THEN	!REDUNDANT
	    IF (WGT(I,0).GT.0) THEN			!CAN USE
	      IF (DOSC .OR. DOAL) THEN			!ALIGN
	        I1=I
	      ELSE
	        I1=IRED(I)				!REDUNDANT POINTER
	      END IF
	      TE1=IFR(I)/256				!TELESCOPES
	      TW1=MOD(IFR(I),256)
C
C ERROR
C
	      C1=CDAT(I,0)*EXP(CMPLX(-CSOL(TW1,0,0)-CSOL(TE1,0,0),
	1		-CSOL(TW1,1,0)+CSOL(TE1,1,0))) 	!CORRECTED DATA
	      C0=C1-CELES(I1) 				!ERROR
	      IF (ABS(CELES(I1)).NE.0) THEN
		C2=C0/CELES(I1)                         !070814
	      ELSE
		C2=0
	      END IF
	      IF (ABS(C1).NE.0) THEN			!FRACT. ERROR
		C1=2.-CELES(I1)/C1
		IF (ABS(C1).NE.0) THEN
		  C1=LOG(C1)
		ELSE
		  C1=-10
		END IF
	      ELSE
		C1=0
	      END IF
	      R2=AMP(I,0)                               !980701
	      DO I2=0,1					!GAIN/PHASE
		IF (I2.EQ.0) THEN			!GAIN
		  R1=REAL(C0)
		  R0=REAL(C1)
		  R3=REAL(C2)                           !070814
		ELSE					!PHASE
		  R1=AIMAG(C0)
		  R0=AIMAG(C1)
		  R3=AIMAG(C2)                           !070814
		END IF
C
C EXTREME
C
	        IF (ABS(R0).GT.ABS(EAV(4,0,I2))) THEN	!MAX. DEVIATION
	  	  EAV(4,0,I2)=R0
		  JAV(4,0,I2)=TW1*16+TE1		!WHERE
	        END IF
C
C NOISE
C
	        JAV(0,0,I2)=JAV(0,0,I2)+J0		!COUNT
	        EAV(0,0,I2)=EAV(0,0,I2)+J0*(R1**2)	!NOISE
	        JAV(1,0,I2)=JAV(1,0,I2)+J0		!INCONSISTENCY
	        EAV(1,0,I2)=EAV(1,0,I2)+J0*(R0**2)
	        JAV(5,0,I2)=JAV(5,0,I2)+J0		!AVG NOISE
	        EAV(5,0,I2)=EAV(5,0,I2)+J0*R1
	        JAV(6,0,I2)=JAV(6,0,I2)+J0		!AVG INCONSISTENCY
	        EAV(6,0,I2)=EAV(6,0,I2)+J0*R0
	        JAV(2,0,I2)=JAV(2,0,I2)+J0		!AVG RMS
	        EAV(2,0,I2)=EAV(2,0,I2)+J0*(R1**2)
	        JAV(I,1,I2)=JAV(I,1,I2)+J0		!IFR AVG NOISE
	        DAV(I,1,I2)=DAV(I,1,I2)+J0*R1
	        EAV(I,1,I2)=EAV(I,1,I2)+J0*R0		!FRACT. NOISE
	        JAV(I,2,I2)=JAV(I,2,I2)+J0		!IFR AVG RMS
	        DAV(I,2,I2)=DAV(I,2,I2)+J0*(R1**2)
		EAV(I,4,I2)=EAV(I,4,I2)+J0*R0*R2*R2     !980701 070814 091019
	        DAV(I,4,I2)=DAV(I,4,I2)+J0*R2*R2        !980701
	      END DO
	    END IF
	  END IF
	END DO
C
C NOISES AND TEL. PHASES
C
	DO I2=0,1					!GAIN/PHASE
	  IF (JAV(0,0,I2).GT.0) THEN			!AVERAGE POSSIBLE
	    EAV(0,0,I2)=SQRT(EAV(0,0,I2)/JAV(0,0,I2))	!NOISE
	    EAV(1,0,I2)=SQRT(EAV(1,0,I2)/JAV(1,0,I2))	!INCONSISTENCY
	    DO I=0,STHTEL-1				!PER TELESCOPE
	      JAV(I,3,I2)=JAV(I,3,I2)+J0		!COUNT
	      EAV(I,3,I2)=EAV(I,3,I2)+J0*CSOL(I,I2,0)	!AVERAGE CORRECTION
	      DAV(I,3,I2)=DAV(I,3,I2)+J0*CSOL(I,I2,0)*CSOL(I,I2,0) !PHASE RMS
	    END DO
	  END IF
	END DO
C
C AVERAGE AMPLITUDE
C
	JAV(7,0,0)=JAV(7,0,0)+J0			!AVERAGE AMPLITUDE
	EAV(7,0,0)=EAV(7,0,0)+J0*DBLE(ARMS(1))		!SUM
	DAV(7,0,0)=DAV(7,0,0)+J0*(DBLE(ARMS(1))**2)	!RMS
C
	RETURN
C
C
	END




















