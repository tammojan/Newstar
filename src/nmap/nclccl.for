C+ NCLCCL.FOR
C  WNB 920103
C
C  Revisions:
C	WNB 921216	Add Grating factor
C	WNB 931006	Text
C	JPH 940221	Comments
C
	SUBROUTINE NCLCCL(BEM,MAP,IMAP,SRC1,MDHJ,MPHD,SUMGL)
C
C  Do patch type clean cycle
C
C  Result:
C	CALL NCLCCL( BEM_E(-*:*,0:*):I, MAP_E(2,0:*):I, IMAP_I(4,0:*):I,
C			SRC1_J:I, MDHJ_J(*):IO, MPHD_D(*):I, SUMGL_E:IO)
C				Clean a patch using beam area BEM and map
C				area MAP,IMAP starting at source SRC1 in
C				model header MDHJ. SUMGL gives the maximum
C				contribution outside beam patch
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'MPH_O_DEF'	!MAP HEADER
	INCLUDE 'MDH_O_DEF'	!MODEL HEADER
	INCLUDE 'MDL_O_DEF'	!MODEL LINE
	INCLUDE 'NCL_DEF'	
C
C  Parameters:
C
C
C  Arguments:
C
	REAL BEM(-BEMPAT:BEMPAT,0:BEMPAT) !BEAM
	REAL MAP(2,0:*)			!MAP
	INTEGER*2 IMAP(4,0:*)		!MAP
	INTEGER SRC1			!FIRST SOURCE IN CYCLE
	INTEGER MDHJ(0:*)		!MODEL HEADER
	DOUBLE PRECISION MPHD(0:*)	!MAP HEADER
	REAL SUMGL			!GRATING POSSIBLE CONTRIBUTION
C
C  Function references:
C
C
C  Data declarations:
C
	INTEGER RG(0:1)			!SOURCE RANGE
	BYTE MDL (0:MDLHDL-1)		!MODEL LINE
	  INTEGER MDLJ(0:MDLHDL/4-1)
	  REAL MDLE(0:MDLHDL/4-1)
	  EQUIVALENCE (MDL,MDLJ,MDLE)
C-
C
C ADD SOURCE to model list
C
	R0=CLFAC*MAP(2,CURPMX)			!NEW AMPL
	R1=ABS(CLBXLM*R0)*GRFAC			!MAX. CORRECTION OUTSIDE PATCH
	SUMGL=SUMGL+R1				!POSSIBLE MAX. OUTSIDE CONTRIB.
	IF (MDHJ(MDH_NSRC_J).LT.SRCLIM) THEN	!CAN ADD MORE
	  CALL WNGMVZ(MDLHDL,MDL)		!EMPTY SOURCE
	  MDLE(MDL_I_E)=R0			!AMPL
	  MDLE(MDL_L_E)=DPI2*(MPHD(MPH_SRA_D)*
	1		IMAP(1,CURPMX)+MPHD(MPH_SHR_D)) !L
	  MDLE(MDL_M_E)=DPI2*(MPHD(MPH_SDEC_D)*
	1			IMAP(2,CURPMX)+MPHD(MPH_SHD_D)) !M
	  MDLJ(MDL_ID_J)=3001+MDHJ(MDH_NSRC_J)	!ID
	  MDL(MDL_TP_B)=MDLCLN_M		!CLEAN COMPONENT
	  CALL WNGMV(MDLHDL,MDL,A_B(MDHJ(MDH_MODP_J)-A_OB+
	1		MDHJ(MDH_NSRC_J)*MDLHDL)) !SAVE SOURCE
	  MDHJ(MDH_NSRC_J)=MDHJ(MDH_NSRC_J)+1	!CNT SRC
C
C.. output source component to terminal and/or log
C
	  I1=0					!PRINT CODE
	  IF (CMPLOG(1).NE.0) THEN
	    IF (MOD(MDHJ(MDH_NSRC_J)-SRC1,CMPLOG(1)).EQ.0) I1=I1+F_T
	  END IF
	  IF (CMPLOG(2).NE.0) THEN
	    IF (MOD(MDHJ(MDH_NSRC_J)-SRC1,CMPLOG(2)).EQ.0) I1=I1+F_P
	  END IF
	  IF (I1.NE.0) THEN
	    RG(0)=MDHJ(MDH_NSRC_J)		!SOURCE RANGE
	    RG(1)=RG(0)
	    CALL NMOPRM(I1,RG,MDL)		!PRINT SOURCE
	  END IF
	END IF
C
C CLEAN
C
	CURMAX=-1E20				!NEW MAX
	I4=IMAP(1,CURPMX)			!OLD MAX L
	I5=IMAP(2,CURPMX)			!M
	DO J=0,MAPPAT-1				!ALL MAP POINTS
	  I1=IMAP(1,J)-I4			!OFFSET L
	  I2=IMAP(2,J)-I5			!OFFSET M
	  IF (ABS(I1).LE.BEMPAT .AND. ABS(I2).LE.BEMPAT) THEN !DO CLEAN
	    IF (I2.LT.0) THEN			!TAKE SYMMETRIC
	      MAP(2,J)=MAP(2,J)-R0*BEM(-I1,-I2)	!DO CLEAN
	    ELSE
	      MAP(2,J)=MAP(2,J)-R0*BEM(I1,I2)	!DO CLEAN OF POINT
	    END IF
	  END IF
	  IF (CURMAX.LT.ABS(MAP(2,J))) THEN	!NEW MAX
	    CURMAX=ABS(MAP(2,J))
	    CURPMX=J
	  END IF
	END DO
C
	RETURN
C
C
	END
