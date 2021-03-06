C+ NCARMD.FOR
C  WNB 900312
C
C  Revisions:
C	WNB 910808	Include ifrs deletion
C
	LOGICAL FUNCTION NCARMD(NIFR,IFR,POL,WI,DAT,SIFRS,
	1			WGTMIN,WGT,AWGT,CDAT,
	1			AMP,PHAS,ARMS)
C
C  Get redundancy scan data
C
C  Result:
C
C	NCARMD_L = NCARMD( NIFR_J:I, IFR_I(0:*):I, POL_J:I, WI_E(0:*,0:3):I,
C				DAT_E(0:1,0:*,0:3):I,
C				SIFRS_B(0:*,0:*):I, WGTMIN_E:I,
C				WGT_E(0:*):O, AWGT_E(0:*):O,
C				CDAT_X(0:*):O, AMP_E(0:*):O, PHAS_E(0:*):O,
C				ARMS_E(0:2):O)
C					Get data for redundancy calculations,
C					using the data in DAT, the interferom.
C					selection in SIFRS, and the weights WI.
C					Output is the normalised weight WGT,
C					the normalised amplitude weight AWGT,
C					the complex data CDAT, the amplitude
C					AMP, and the phase PHAS.
C					ARMS give amplitude statistics.
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'STH_O_DEF'		!SET HEADER
C
C  Parameters:
C
C
C  Arguments:
C
	INTEGER NIFR			!# OF INTERFEROMETERS
	INTEGER*2 IFR(0:*)		!INTERFEROMETER TABLE
	INTEGER POL			!POLARISATION TO DO (0,1,2,3)
	REAL WI(0:STHIFR-1,0:3)		!WEIGHT OF DATA
	REAL DAT(0:1,0:STHIFR-1,0:3)	!COS/SIN DATA
	BYTE SIFRS(0:STHTEL-1,0:STHTEL-1) !IFR SELECTION
	REAL WGTMIN			!MINIMUM ACCEPTABLE WEIGHT
	REAL WGT(0:*)			!NORMALISED DATA WEIGHT
	REAL AWGT(0:*)			!NORMALISED AMPLITUDE WEIGHTED WEIGHT
	COMPLEX CDAT(0:*)		!COMPLEX DATA POINTS
	REAL AMP(0:*)			!AMPLITUDES
	REAL PHAS(0:*)			!PHASES
	REAL ARMS(0:2)			!AVERAGE AMPLITUDE DATA
C
C  Function references:
C
C
C  Data declarations:
C
	INTEGER N			!COUNT IFRS WITH DATA
C-
C
C INIT
C
	NCARMD=.TRUE.					!ASSUME OK
C
C GET WEIGHTS
C
	ARMS(0)=0					!MAX. AMPL.
	ARMS(1)=0					!AVER. AMPL
	D0=0						!RMS
	R0=0						!MAX. WEIGHT
	R1=0
	N=0						!COUNT
	DO I=0,NIFR-1					!ALL IFRS
	  WGT(I)=0					!ASSUME ZERO WEIGHT
	  AWGT(I)=0
	  IF (WI(I,POL).GT.0 .AND.			!DATA PRESENT
	1	SIFRS(IFR(I)/256,MOD(IFR(I),256)).NE.0) THEN !IFR SELECTED
	    AMP(I)=ABS(CMPLX(DAT(0,I,POL),DAT(1,I,POL))) !AMPL
	    IF (AMP(I).GT.0) THEN
	      PHAS(I)=ATAN2(DAT(1,I,POL),DAT(0,I,POL))	!PHASE
	      CDAT(I)=CMPLX(DAT(0,I,POL),DAT(1,I,POL))	!COMPLEX
	      WGT(I)=SQRT(WI(I,POL))			!WEIGHT
	      AWGT(I)=WGT(I)*AMP(I)
	      R0=MAX(R0,WGT(I))				!GET MAXIMA
	      R1=MAX(R1,AWGT(I))
	      ARMS(0)=MAX(ARMS(0),AMP(I))
	      ARMS(1)=ARMS(1)+AMP(I)			!AVERAGE
	      D0=D0+AMP(I)*AMP(I)			!RMS
	      N=N+1					!COUNT
	    END IF
	  END IF
	END DO
C
C CHECK DATA PRESENCE
C
 10	CONTINUE
	IF (ARMS(0).EQ.0) THEN				!NO DATA
	  NCARMD=.FALSE.
	  RETURN
	END IF
C
C NORMALISE WEIGHT
C
	DO I=0,NIFR-1
	  IF (WGT(I).GT.0) THEN
	    WGT(I)=(WGT(I)/R0)**2
	    AWGT(I)=AWGT(I)/R1
	    IF (AWGT(I).LT.WGTMIN) THEN			!FORGET POINT
	      WGT(I)=0
	      AWGT(I)=0
	      N=N-1					!CORRECT AVERAGES
	      ARMS(1)=ARMS(1)-AMP(I)
	      D0=D0-AMP(I)*AMP(I)
	    ELSE
	      AWGT(I)=AWGT(I)**2
	    END IF
	  END IF
	END DO
C
C CALCULATE AMPL. STATISTICS
C
	IF (N.LE.0) THEN				!NO DATA LEFT
	  ARMS(0)=0
	  GOTO 10
	END IF
	ARMS(1)=ARMS(1)/N				!AVER. AMPL
	ARMS(2)=SQRT(ABS(D0-ARMS(1)*ARMS(1)*N)/N)	!RMS
C
	RETURN						!READY
C
C
	END
