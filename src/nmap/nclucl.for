C+ NCLUCL.FOR
C  WNB 920103
C
C  Revisions:
C	JPH 940224	Comments. - Fix final deallocation of BUFPTR (was JNDC,
C			must be JNRA).
C       HjV 950529	Multiply map with DATAFAC (data factor)
C	CMV 950616	Account for DATAFAC in map limits, noise and comment
C
C
	SUBROUTINE NCLUCL(STSRC,NDSRC,FTMP,FBEM,FOUT,FIN,
	1		MDH,MDPT,MPHP,MPH,APH)
C
C  Clean map using transformed beam
C
C  Result:
C	CALL NCLUCL ( STSRC_J:I, NDSRC_J:I, FTMP_J:I, FBEM_J:I,
C			FOUT_J:I, FIN_J:I, MDH_B(*), MDPT_J:I,
C			MPHP_J:I, MPH_B(*):IO, APH_B(*):I)
C				Clean sources STSRC until NDSRC using
C				the beam in file FBEM from the map with header
C				MPH at MPHP. MDH is the model header, MDPT
C				the input data pointer. FOUT and FIN describe
C				the input/output files.
C	The "beam" in file FBEM is the transposed Fourier transform of the 
C  antenna pattern, made by NCLUVT.
C 
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'MPH_O_DEF'	!MAP HEADER
	INCLUDE 'NCL_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
	INTEGER STSRC		!START SOURCE #
	INTEGER NDSRC		!END SOURCE #
	INTEGER FTMP		!TEMP. FILE
	INTEGER FBEM		!BEAM FILE
	INTEGER FOUT		!RESIDUAL FILE
	INTEGER FIN		!MAP/RESIDUAL FILE
	BYTE MDH(0:*)		!MODEL HEADER
	INTEGER MDPT		!INPUT DATA POINTER
	INTEGER MPHP		!MAP HEADER POINTER
	BYTE MPH(0:*)		!MAP HEADER
	BYTE APH(0:*)		!BEAM HEADER
C
C  Function references:
C
	LOGICAL WNFRD		!READ DISK
	LOGICAL WNFWR		!WRITE DISK
	LOGICAL WNGGVA		!GET VIRTUAL MEMORY
	INTEGER WNMEJC		!CEIL(X)
	INTEGER WNGGJ		!GET J VALUE
	REAL WNGGE		!GET E VALUE
C
C  Data declarations:
C
	CHARACTER CBUF*(MPH_UCM_N)	!NAME FOR CALCULATED OUTPUT MAP
	INTEGER VLEN,VAD,XAD	!LENGTH, ADDRESS BEAM BUF
	INTEGER JV		!BEAM DISK PTR
	INTEGER MLEN,MAD	!LENGTH, ADDRESS MAP BUF
	INTEGER JM,JMI		!MAP DISK PTR
	INTEGER WLEN,WAD(2)	!FFT WEIGHT BUFFER
	INTEGER BUFPTR		!TRANSPOSE BUFFER
	INTEGER FTBUF		!FFT BUFFER
	INTEGER LSIZE		!LENGTH TRANSPOSE STAGE
	INTEGER LSIZ8
	INTEGER LSTEP		!TRANSPOSE DISK STEP
	REAL RMAX,RMIN		!MAX/MIN VALUES
	INTEGER RMXR,RMXD,RMNR,RMND !POS. MAX/MIN
	REAL RSUM		!SUM RESTORE AP
	INTEGER JC		!AREA CNT
	INTEGER JNRA,JNDC
	INTEGER JJ2,JJ3,II1
	REAL RR1
C-
C
C GET BUFFERS
C
	JNDC=WNGGJ(APH(MPH_NDEC_1))
	JNRA=WNGGJ(APH(MPH_NRA_1))
	VLEN=LB_E*JNDC				!LENGTH BEAM BUF, 1 line (Note
						! that beam is transposed!)
	JS=WNGGVA(VLEN,VAD)			!GET 2 BEAM BUFFERS
	IF (JS) JS=WNGGVA(VLEN,XAD)
	MLEN=2*VLEN				!LENGTH MAP BUF
	IF (JS) JS=WNGGVA(MLEN,MAD)		!GET MAP/source LINE BUFFERS
	WLEN=2*VLEN/2				!LENGTH FFT BUF
	IF (JS) JS=WNGGVA(WLEN,WAD(1))		!GET FFT cos/sin BUFFERS
	IF (JS) JS=WNGGVA(WLEN,WAD(2))
	IF (.NOT.JS) THEN
	  CALL WNCTXT(F_TP,'Cannot obtain clean buffers')
	  CALL WNGEX				!STOP
	END IF
C
C FILL cos/sin buffers: WAD(1) with cos/sin, WAD with cos/-sin
C (NOTE: Unnecessary duplication of sin/cos calculations)
C
	DO I=0,JNDC/2-1
	  CALL WNGMV(LB_E,COS(I*PI2/JNDC),A_B(WAD(1)-A_OB+2*LB_E*I))
	  CALL WNGMV(LB_E,SIN(I*PI2/JNDC),A_B(WAD(1)-A_OB+LB_E+2*LB_E*I))
	  CALL WNGMV(LB_E,COS(I*PI2/JNDC),A_B(WAD(2)-A_OB+2*LB_E*I))
	  CALL WNGMV(LB_E,-SIN(I*PI2/JNDC),A_B(WAD(2)-A_OB+LB_E+2*LB_E*I))
	END DO
C
C DO ALL BEAM columns
C
	JV=0					!BEAM PTR
	JJ2=LB_E*JNDC
	JM=0					!TMP OUTPUT PTR
	RSUM=0					!RESTORE AP SUM
	DO I=0,JNRA/2				!ALL BEAM columns
	  JJ3=2*LB_E*JNDC
	  CALL WNGMVZ(JJ3,A_B(MAD-A_OB))	!CLEAR MAP column buffer
	  IF (FBEM.NE.0) THEN
	    IF (.NOT.WNFRD(FBEM,JJ2,
	1	A_B(VAD-A_OB),JV)) THEN 	!READ transformed-beam column
	      CALL WNCTXT(F_TP,'Read error transformed beam')
	      CALL WNGEX			!STOP
	    END IF
	  ELSE
	    CALL NCLFBM(I,JNDC,RESDL,RESDM,
	1	RESDAN,A_B(VAD-A_OB),RSUM) 	!FILL RESTORE BEAM
	  END IF
	  JV=JV+JJ2				!NEXT BEAM-column PTR
	  CALL NCLUC1(STSRC,NDSRC,I,A_B(MAD-A_OB),A_B(VAD-A_OB),
	1	A_B(WAD(1)-A_OB),
	1	A_B(WAD(2)-A_OB),
	1	MDH,MPH,APH,A_B(XAD-A_OB)) 	!create column of source 
C						! transform
	  IF (.NOT.WNFWR(FTMP,2*JJ2,
	1	A_B(MAD-A_OB),JM)) THEN 	!WRITE source column to TMP file
	    CALL WNCTXT(F_TP,'Write error source map')
	    CALL WNGEX				!STOP
	  END IF
	  JM=JM+2*JJ2				!NEXT MAP PTR
	END DO
C
C CLEAR BUFFERS
C
	CALL WNGFVA(VLEN,VAD)			!BEAM BUFFERS
	CALL WNGFVA(VLEN,XAD)
	CALL WNGFVA(MLEN,MAD)			!MAP LINE BUFFERS
	CALL WNGFVA(WLEN,WAD(1))		!FFT WEIGHT BUFFERS
	CALL WNGFVA(WLEN,WAD(2))
C
C Transform the sources back from UV to map plane and subtract them
C
C GET BUFFERS
C
	LSIZE=MIN(WNMEJC(MEMSIZ/(REAL(LB_X)*(JNRA/2+1))),JNDC) 	!LENGTH STAGE
	LSIZ8=LB_X*LSIZE
	JS=WNGGVA(LSIZ8*(JNRA/2+1),BUFPTR)	!TRANSPOSE BUFfer
	J=LB_X*JNRA				!FFT BUFFER
	IF (JS) JS=WNGGVA(J,FTBUF)
	IF (JS) JS=WNGGVA(J,MAD)		!MAP INPUT BUFfer
	IF (JS) JS=WNGGVA(J/2,WAD(1))		!FFT WEIGHT BUFfer
	IF (.NOT.JS) THEN
	  CALL WNCTXT(F_TP,'Cannot obtain map clean buffers')
	  CALL WNGEX				!STOP
	END IF
	DO I=0,JNRA/2-1				!FILL cos/sin BUFfer
	  CALL WNGMV(LB_E,COS(I*PI2/JNRA),
	1	A_B(WAD(1)-A_OB+LB_X*I))
	  CALL WNGMV(LB_E,-SIN(I*PI2/JNRA),
	1	A_B(WAD(1)-A_OB+LB_E+LB_X*I))
	END DO
	LSTEP=LB_X*JNDC				!DISK INPUT STEP
C
C DO ALL LINES in "stages" of LSIZE lines
C
	RMAX=-1E36				!START MAX/MIN SEARCH
	RMIN=1E36
	D0=4D0/JNRA/JNDC			!NORMALISATION
	IF (FBEM.EQ.0) D0=1D0/RSUM
	CALL WNMHS8(MPHAD,+1,
	1	MAX(ABS(WNGGE(MPH(MPH_MAX_1))*DATAFAC),
	1	ABS(WNGGE(MPH(MPH_MIN_1))*DATAFAC))) !initialise MAP HISTO AREA
	JM=WNGGJ(MPH(MPH_MDP_1))		!MAP OUTPUT PTR
	JMI=MDPT				!MAP INPUT POINTER
	JJ2=LB_E*JNRA
	DO I2=0,JNDC-1,LSIZE			!DO STAGES
	  J0=MIN(LSIZE,JNDC-I2)			!LENGTH TO DO IN STAGE
C
C Inverse transform for stage
C
	  DO J=0,JNRA/2				!READ A STAGE
	    JS=WNFRD(FTMP,LB_X*J0,
	1	A_B(BUFPTR-A_OB+J*LSIZ8),
	1	J*LSTEP+LB_X*I2)
	  END DO
	  DO J1=0,J0-1				!ALL LINES IN STAGE
	    I5=I2+J1-JNDC/2			!POSition in DECLINATION
	    DO J=0,JNRA/2
	      CALL WNGMV(LB_X,
	1	A_B(BUFPTR-A_OB+J*LSIZ8+LB_X*J1),
	1	A_B(FTBUF-A_OB+LB_X*J))		!TRANSPOSE
	    END DO
	    J2=LB_X*(JNRA/2-1)			!ZERO LENGTH
	    CALL WNGMVZ(J2,
	1	A_B(FTBUF-A_OB+LB_X*(JNRA/2+1)))!clear upper half of BUF
	    CALL WNMFTC(JNRA,A_B(FTBUF-A_OB),
	1	A_B(WAD(1)-A_OB)) 		!FFT in FTBUF
	    CALL WNMFCS(JNRA,A_B(FTBUF-A_OB))	!SWAP HALVES
	    CALL WNMFCR(JNRA,A_B(FTBUF-A_OB))	!MAKE REAL
C
C Combine map with sources in FTBUF and write to residuals file FOUT
C
	    IF (.NOT.WNFRD(FIN,JJ2,
	1	A_B(MAD-A_OB),JMI)) THEN 	!READ MAP
	      CALL WNCTXT(F_TP,'Read error map')
	      CALL WNGEX			!STOP
	    END IF
	    DO I=0,JNRA-1
	       A_E(MAD/LB_E-A_OE+I)=A_E(MAD/LB_E-A_OE+I)*DATAFAC
	    END DO
	    IF (FBEM.NE.0) THEN
	      RR1=D0
	      CALL NCLFAM(RR1,A_B(MAD-A_OB),	!ADD SOURCES:
	1	A_B(FTBUF-A_OB),JNRA) 		! FTBUF = MAD + RR1*FTBUF
	    ELSE				!SUBTRACT SOURCES
	      RR1=D0
	      IF (.NOT.RONMDL) THEN		!NOT RESTORE ONLY
	        CALL NCLFSM(RR1,A_B(MAD-A_OB),	!subtract: 
	1		A_B(FTBUF-A_OB),JNRA)	! FTBUF = MAD - RR1*FTBUF
	      ELSE
	        CALL NCLFS2(RR1,CLFAC,		!
	1	A_B(MAD-A_OB),			! FTBUF = CLFAC*FTBUF - RR1*MAD
	1	A_B(FTBUF-A_OB),JNRA)
	      END IF
	    END IF
	    IF (.NOT.WNFWR(FOUT,JJ2,A_B(FTBUF-A_OB),JM)) THEN !WRITE RESIDUAL
	      CALL WNCTXT(F_TP,'Write error residual file')
	      CALL WNGEX			!STOP
	    END IF

	    JM=JM+LB_E*JNRA			!NEXT MAP IN/OUT PTR
	    JMI=JMI+LB_E*JNRA			! for next line
C
C inspect line for extremes
C
	    R0=-1E36
	    R1=1E36
	    CALL WNMFMX(JNRA,A_B(FTBUF-A_OB),1D0,
	1		R0,I3,R1,I4)		!FIND MAX/MIN AND NORMALIZE
	    IF (R0.GT.RMAX) THEN
	      RMAX=R0				!NEW MAX with its L and M
	      RMXR=I3-JNRA/2
	      RMXD=I5
	    END IF
	    IF (R1.LT.RMIN) THEN		!NEW MIN with its L and M
	      RMIN=R1
	      RMNR=I4-JNRA/2
	      RMND=I5
	    END IF
C
C Make histogram of residuals in selected areas
C
	    J2=-32768				!START POINT
	    DO JC=1,NAREA			!ALL AREAS
	      IF (I5.GE.PAREA(2,JC,1) .AND. I5.LE.PAREA(3,JC,1)) THEN !LINE OK
	        J2=MAX(J2,PAREA(0,JC,1))	!START POINT
	        II1=PAREA(1,JC,1)-J2+1
		CALL WNMHS1(MPHAD,II1,
	1		A_B(FTBUF-A_OB+
	1		LB_E*(JNRA/2+J2)))
		J2=PAREA(1,JC,1)+1		!NEXT START
	      END IF
	    END DO
	  END DO				!END LINES
	END DO					!END STAGE
	CALL WNGMV(LB_E,RMAX,MPH(MPH_MAX_1))	!SAVE MAX/MIN
	CALL WNGMV(LB_E,RMIN,MPH(MPH_MIN_1))
	CALL WNGMV(LB_J,RMXR,MPH(MPH_MXR_1))
	CALL WNGMV(LB_J,RMNR,MPH(MPH_MNR_1))
	CALL WNGMV(LB_J,RMXD,MPH(MPH_MXD_1))
	CALL WNGMV(LB_J,RMND,MPH(MPH_MND_1))
	IF (FBEM.NE.0) THEN
	  CBUF='RESIDUAL'
	ELSE
          CBUF='RESTORED'
	END IF
	IF (DATAFAC.NE.1.0) 
	1	CALL WNCTXS(CBUF(9:),' (*!E5.2)',DATAFAC)
	CALL WNGMFS(MPH_UCM_N,CBUF,MPH(MPH_UCM_1))
	IF (FBEM.NE.0) THEN
	  CALL WNMHS4(MPHAD,MPH(MPH_NOS_1),0)	!SET NOISE
	ELSE IF (RONMDL) THEN			!ONLY RESTORE
	  RR1=WNGGE(MPH(MPH_NOS_1))
	  RR1=CLFAC*RR1
	  CALL WNGMV(LB_E,RR1,MPH(MPH_NOS_1))
	ELSE					!RESTORE ON RESIDUAL
	  RR1=WNGGE(MPH(MPH_NOS_1))		!USE DATAFAC
	  RR1=DATAFAC*RR1
	  CALL WNGMV(LB_E,RR1,MPH(MPH_NOS_1))
	END IF
	JS=WNFWR(FOUT,MPHHDL,MPH,MPHP)		!SET RESIDUAL HEADER
C
C release BUFFERS 
C
	CALL WNGFVA(LSIZ8*(JNRA/2+1),BUFPTR)	!TRANSPOSE BUF
	J=LB_X*JNRA				!FFT BUFFER
	CALL WNGFVA(J,FTBUF)
	CALL WNGFVA(MLEN,MAD)			!MAP INPUT BUFFER
	CALL WNGFVA(WLEN,WAD(1))			!FFT WEIGHT BUF
C
	RETURN
C
C
	END
