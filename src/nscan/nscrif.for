C+ NSCRIF.FOR
C  WNB 930901
C
C  Revisions:
C
	LOGICAL FUNCTION NSCRIF(FCA,STHJ,IFRJ,IFRE)
C
C  Read interferometer information for a set
C
C  Result:
C
C	NSCRIF_L = NSCRIF( FCA_J:I, STHJ_J(0:*):I,
C			IFRJ_J(0:2,0:*):O, IFRE_E(0:2,0:*):O)
C				Read the interferometer table belonging to
C				set with set header STH from file FCA into
C				the interferometer tables IFRJ and IFRE.
C				IFRJ:
C				0 (IFJ_WT):	W telescope
C				1 (IFJ_WT):	E telescope
C				2 (IFJ_IFR):	Interferometer (256*E+W)
C				IFRE:
C				0 (IFE_ANG):	W X-dipole angle (N->E, circles)
C				1 (IFE_SB):	sin(E X-dipole - W X-dipole)
C				2 (IFE_CB):	cos(same)
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'CBITS_DEF'
	INCLUDE 'STH_O_DEF'		!SET HEADER
C
C  Parameters:
C
C
C  Arguments:
C
	INTEGER FCA			!FILE CONTROL AREA
	INTEGER STHJ(0:*)		!CURRENT SET HEADER
	INTEGER IFRJ(IFJ_WT:IFJ_IFR,0:*) !INTERFEROMETER TABLE
	INTEGER IFRE(IFE_ANG:IFE_CB,0:*)
C
C  Function references:
C
	LOGICAL WNFRD			!READ DATA
C
C  Data declarations:
C
	INTEGER*2 IFRT(0:STHIFR-1)	!LOCAL INTERFEROMETER TABLE
C-
C
C INIT
C
	NSCRIF=.TRUE.					!ASSUME OK
C
C READ
C
	IF (.NOT.WNFRD(FCA,LB_I*STHJ(STH_NIFR_J),IFRT, 	!READ TABLE
	1		STHJ(STH_IFRP_J))) THEN
	  NSCRIF=.FALSE.				!ERROR READING TABLE
	  GOTO 800
	END IF
C
C MAKE IFRJ
C
	DO I=0,STHJ(STH_NIFR_J)-1			!MAKE ARRAY
	  IFRJ(IFJ_WT,I)=MOD(IFRT(I),256)		!WEST TEL.
	  IFRJ(IFJ_ET,I)=IFRT(I)/256			!EAST TEL.
	END DO
C
C MAKE IFRE
C
	DO I=0,STHJ(STH_NIFR_J)-1
	  IFRE(IFE_ANG,I)=IAND(3,ISHFT(STHJ(STH_DIPC_J),
	1		-2*IFRJ(IFJ_WT,I)))/8.		!ANGLE W TELESCOPE
	  R0=IAND(3,ISHFT(STHJ(STH_DIPC_J),
	1		-2*IFRJ(IFJ_ET,I)))/8.-IFRE(IFE_ANG,I) !DIFF. E TEL.
	  IFRE(IFE_SB,I)=SIN(R0*PI2)			!ITS SINE
	  IFRE(IFE_CB,I)=COS(R0*PI2)			!AND COSINE
	END DO
C
C READY
C
 800	CONTINUE
C
	RETURN
C
C
	END
