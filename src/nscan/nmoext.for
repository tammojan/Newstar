C+ NMOEXT.FOR
C  WNB 900827
C
C  Revisions:
C	WNB 920403	Correct for symmetric extended sources
C
	SUBROUTINE NMOEXF(IMDLE)
C
C  Convert from/to external format
C
C  Result:
C
C	CALL NMOEXF( IMDLE_E(0:*))	convert IMDLE source to internal format
C	CALL NMOEXT( IMDLE_E(0:*))	convert IMDLE source to external format
C
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'MDL_O_DEF'			!MODEL LINE
C
C  Entries:
C
C
C  Parameters:
C
C
C  Arguments:
C
	REAL IMDLE(0:*)				!MODEL LINE
C
C  Function references:
C
	INTEGER WNGARA				!GET ADDRESS
C
C  Data declarations:
C
	BYTE TP					!TYPE
	REAL R2,R3
C-
C
C EXF
C
	IF (IMDLE(MDL_Q_E).EQ.0 .AND. IMDLE(MDL_U_E).EQ.0 .AND.
	1		IMDLE(MDL_V_E).EQ.0) THEN
	  TP=2						!SET NO POL.
	ELSE
	  TP=0						!SET POL.
	END IF
	IF (ABS(IMDLE(MDL_EXT_E))+ABS(IMDLE(MDL_EXT_E+1)).GT.0) THEN !EXTENDED
	  R0=COS(IMDLE(MDL_EXT_E+2)/DEG)		!P.A.
	  R1=-SIN(IMDLE(MDL_EXT_E+2)/DEG)
	  R2=(.5*IMDLE(MDL_EXT_E)/3600./DEG)**2
	  R3=(.5*IMDLE(MDL_EXT_E+1)/3600./DEG)**2
	  IMDLE(MDL_EXT_E+0)=R2*R1*R1+R3*R0*R0		!INTERNAL FORMAT
	  IMDLE(MDL_EXT_E+1)=R2*R0*R0+R3*R1*R1
	  IMDLE(MDL_EXT_E+2)=2*(R2-R3)*R0*R1
	  TP=TP+1					!SET EXTENDED
	ELSE
	  IMDLE(MDL_EXT_E+2)=0				!P.A.
	END IF
	IMDLE(MDL_L_E)=IMDLE(MDL_L_E)/3600./DEG		!MAKE RADIANS
	IMDLE(MDL_M_E)=IMDLE(MDL_M_E)/3600./DEG
	IMDLE(MDL_Q_E)=IMDLE(MDL_Q_E)/100.		!MAKE FRACTION
	IMDLE(MDL_U_E)=IMDLE(MDL_U_E)/100.
	IMDLE(MDL_V_E)=IMDLE(MDL_V_E)/100.
	A_B(WNGARA(IMDLE(0))+MDL_BITS_B-A_OB)=TP	!SET TYPE
C
	RETURN
C
C EXT
C
	ENTRY NMOEXT(IMDLE)
C
	IF (IMDLE(MDL_EXT_E+2).EQ.0 .AND.		!EXTENDED
	1		(ABS(IMDLE(MDL_EXT_E+1))+
	1		ABS(IMDLE(MDL_EXT_E)).EQ.0)) THEN
	  R0=0
	  R1=0
	  R2=0
	ELSE
	  IF (IMDLE(MDL_EXT_E+2).EQ.0 .AND.
	1		(IMDLE(MDL_EXT_E+1)-IMDLE(MDL_EXT_E)).EQ.0) THEN !SYMM.
	    R0=0
	  ELSE
	    R0=.5*DEG*ATAN2(-IMDLE(MDL_EXT_E+2),
	1		IMDLE(MDL_EXT_E+1)-IMDLE(MDL_EXT_E)) !P.A.
	  END IF
	  R1=SQRT(IMDLE(MDL_EXT_E+2)**2+
	1		(IMDLE(MDL_EXT_E)-IMDLE(MDL_EXT_E+1))**2)
	  R2=IMDLE(MDL_EXT_E)+IMDLE(MDL_EXT_E+1)
	END IF
	IMDLE(MDL_EXT_E+0)=2*SQRT(ABS((R2+R1)/2))*3600.*DEG !DL
	IMDLE(MDL_EXT_E+1)=2*SQRT(ABS((R2-R1)/2))*3600.*DEG !DM
	IMDLE(MDL_EXT_E+2)=R0				!P.A.
	IMDLE(MDL_L_E)=IMDLE(MDL_L_E)*3600.*DEG		!MAKE ARCSEC
	IMDLE(MDL_M_E)=IMDLE(MDL_M_E)*3600.*DEG
	IMDLE(MDL_Q_E)=IMDLE(MDL_Q_E)*100.		!MAKE %
	IMDLE(MDL_U_E)=IMDLE(MDL_U_E)*100.
	IMDLE(MDL_V_E)=IMDLE(MDL_V_E)*100.
C
C
	END
