C+ NCLFUN.FOR
C  WNB 910809
C
C  Revisions:
C
	SUBROUTINE NCLFD2(BUF,LEN)
C
C  General functions for NCLEAN programs
C
C  Result:
C
C	CALL NCLFD2( BUF_E(0:LEN-1):IO, LEN_J:I)
C				Divide BUF by 2
C	CALL NCLFCJ( CBUF_X(0:LEN-1):IO, LEN_J:I)
C				Take conjugate of CBUF
C	CALL NCLFAM( MUL_E:I, BUF0_E(0:LEN-1):I, BUF1_E(0:LEN-1):IO, LEN1_J:I)
C				Add BUF to MUL*BUF1
C	CALL NCLFSM( MUL_E:I, BUF0_E(0:LEN-1):I, BUF1_E(0:LEN-1):IO, LEN1_J:I)
C				Subtract BUF1 from MUL*BUF
C	CALL NCLFS2( MUL_E:I, MUL2_E:I, BUF1_E(0:LEN-1):I, BUF2_E(0:LEN-1):I,
C			LEN2_J:I)
C				Subtract MUL*BUF1 from MUL2*BUF
C	CALL NCLFBM( L_J:I, LEN_J:I, FDL_E:I, FDM_E:I, FDA_E:I, 
C			BUF3_E(0:LEN-1):O, SUM_E:O)
C				Fill BUF with transformed beam
C	CALL NCLF1D( BUF_E(0:LEN-1):IO, LEN_J:I)
C				Take 1/buffer
C
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
	REAL MUL				!MULTIPLIERS
	REAL MUL2
	REAL BUF(0:*)				!BUFFER TO DO
	REAL BUF0(0:*)
	REAL BUF1(0:*)
	REAL BUF2(0:*)
	REAL BUF3(0:*)
	COMPLEX CBUF(0:*)			!BUFFER TO DO
	INTEGER LEN				!BUFFER LENGTH
	INTEGER LEN1
	INTEGER LEN2
	INTEGER L				!LINE TO DO
	REAL FDL				!WIDTH L
	REAL FDM				!WIDTH M
	REAL FDA				!ROTATION ANGLE
	REAL SUM				!SUM AP
C
C  Function references:
C
C
C  Data declarations:
C
	REAL R2
C-
C
C DIVIDE BY 2
C
	DO I=0,LEN-1
	  BUF(I)=BUF(I)/2
	END DO
C
	RETURN
C
C TAKE CONJUGATE
C
	ENTRY NCLFCJ(CBUF,LEN)
C
	DO I=0,LEN-1
	  CBUF(I)=CONJG(CBUF(I))
	END DO
C
	RETURN
C
C ADD BUFFERS
C
	ENTRY NCLFAM(MUL,BUF0,BUF1,LEN1)
C
	DO I=0,LEN1-1
	  BUF1(I)=MUL*BUF1(I)+BUF0(I)
	END DO
C
	RETURN
C
C SUBTRACT BUFFERS
C
	ENTRY NCLFSM(MUL,BUF0,BUF1,LEN1)
C
	DO I=0,LEN1-1
	  BUF1(I)=BUF0(I)-MUL*BUF1(I)
	END DO
C
	RETURN
C
C SUBTRACT BUFFERS
C
	ENTRY NCLFS2(MUL,MUL2,BUF1,BUF2,LEN2)
C
	DO I=0,LEN2-1
	  BUF2(I)=MUL2*BUF1(I)-MUL*BUF2(I)
	END DO
C
	RETURN
C
C MAKE GAUSSIAN WEIGHT BUFFER
C
	ENTRY NCLFBM(L,LEN,FDL,FDM,FDA,BUF3,SUM)
C
	R0=(FLOAT(L)**2)*((FDL*COS(FDA))**2+(FDM*SIN(FDA))**2)
	R1=(FDL*SIN(FDA))**2+(FDM*COS(FDA))**2
	R2=FDL*FDL*SIN(2.*FDA)-FDM*FDM*SIN(2.*FDA)
	IF (L.EQ.0) R0=R0+LOG(2.)		!FOR HALF FFT
	I1=LEN/2
	DO I=1,I1-1
	  BUF3(I+I1)=EXP(-(R0+(FLOAT(I)**2)*R1+
	1			FLOAT(L)*FLOAT(I)*R2))
	  BUF3(I1-I)=EXP(-(R0+(FLOAT(I)**2)*R1-
	1			FLOAT(L)*FLOAT(I)*R2))
	  SUM=SUM+BUF3(I+I1)+BUF3(I1-I)
	END DO
	BUF3(I1)=EXP(-R0)
	BUF3(0)=EXP(-(R0+FLOAT(I1)*FLOAT(I1)*R1+FLOAT(L)*FLOAT(I1)*R2))
	SUM=SUM+BUF3(I1)+BUF3(0)
C
	RETURN
C
C TAKE INVERSE
C
	ENTRY NCLF1D(BUF,LEN)
C
	DO I=0,LEN-1
	  IF (BUF(I).NE.0) BUF(I)=1./BUF(I)
	END DO
C
	RETURN
C
C
	END
