C+ NSCTLS.FOR
C  WNB 930824
C
C  Revisions:
C	JPH 940902	Adapt to WNCXPL format, use WNCXPL where possible
C			Call WNDPOHC
C
C
	LOGICAL FUNCTION NSCTLS(TYP,TELS)
C
C  Select/de-select telescopes
C
C  Result:
C	NSCTLS_L = NSCTLS ( TYP_J:I, TELS_B(0:*):IO)
C				Include (.true.) or exclude (.false.)
C				telescopes in TELS. TYP can be:
C				0  use as given (show first)
C				1  pre-select all
C				4  pre-select none
C				TYP can be TYP+100 to suppress asking.
C				TYP can be TYP+200 to suppress asking and 
C				initial message
C				Assume WSRT telescopes. .FALSE. if
C				input error or # given (check E_C)
C	NSCTL1_L = NSCTL1 ( TYP_J:I, TELS_B(0:*)*:IO, STHJ_J(0:*):I)
C				As TLS, but check for instrument used
C
C  Pin references:
C
C	SELECT_TELS
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'STH_O_DEF'		!SET HEADER
C
C  Entry points:
C
	LOGICAL NSCTL1
C
C  Parameters:
C
	INTEGER MAXDEF			!MAXIMUM ENTRIES PIN ENTRY
	  PARAMETER (MAXDEF=20)
C
C  Arguments:
C
	INTEGER TYP			!SELECTION TYPE
	BYTE TELS(0:STHTEL-1)		!SELECTION TEL TABLE
	INTEGER STHJ(0:*)		!SET HEADER
C
C  Function references:
C
	LOGICAL WNDPAR				!GET USER DATA
C
C  Data declarations:
C
	CHARACTER*(STHTEL+8) TEL		!TELESCOPE NAMES
	  DATA TEL/'0123456789ABCD*FMYZPTU'/
	INTEGER IS(STHTEL+8)			!START VALUES
	  DATA IS/0,1,2,3,4,5,6,7,8,9,10,11,12,13,
	1			00,0,10,10,12,1,08,0/
	INTEGER IE(STHTEL+8)			!END VALUES
	  DATA IE/0,1,2,3,4,5,6,7,8,9,10,11,12,13,
	1			13,9,13,11,13,0,13,7/
C		  0 1 2 3 4 5 6 7 8 9  A  B  C  D
C				 * F  M  Y  Z P  T U
	LOGICAL LP				!PRINT INDICATOR
	LOGICAL ADD				!INCLUDE/EXCLUDE
	INTEGER INSTR				!INSTRUMENT (0=WSRT, 1=ATCA)
	CHARACTER*4 RD(MAXDEF)			!INPUT
	CHARACTER*(STHTEL) IFTXT		!LIST
C-
C
C NSCTLS
C
	INSTR=0					!ASSUME WSRT
	GOTO 100
C
C NSCTL1
C
	ENTRY NSCTL1(TYP,TELS,STHJ)
C
	INSTR=STHJ(STH_INST_J)			!GET INSTRUMENT
	GOTO 100
C
C INIT
C
 100	CONTINUE
	A_J(0)=1				! inhibit reset of dynamic 
						!  prompt strings
	NSCTLS=.TRUE.				!ASSUME OK
	LP=.FALSE.				!ASSUME NO PRINT
	IF (MOD(TYP,100).EQ.1) THEN		!PRE-SELECT ALL
	  IF (TYP.LT.200)
	1	CALL WNCTXT(F_TP,'!4C\All telescopes pre-selected')
	  DO I1=0,STHTEL-1
	    IF (INSTR.EQ.1 .AND. I1.LT.8) THEN
	      TELS(I1)=.FALSE.
	    ELSE
	      TELS(I1)=.TRUE.
	    END IF
	  END DO
	ELSE IF (MOD(TYP,100).EQ.4) THEN	!NONE
	  IF (TYP.LT.200)
	1	CALL WNCTXT(F_TP,'!4C\No telescopes pre-selected')
	  DO I1=0,STHTEL-1
	    TELS(I1)=.FALSE.
	  END DO
	ELSE					!START WITH GIVEN
	  LP=.TRUE.				!PRINT FIRST
	END IF
C
C GET USER DATA
C
 10	CONTINUE
	IF (LP) THEN				!PRINT TELS
	  IFTXT=' '
	  DO I2=1,STHTEL
	    IF (TELS(I2-1)) THEN		!SELECT
	      IFTXT(I2:I2)=TEL(I2:I2)
	    ELSE				!DESELECT
	      IFTXT(I2:I2)='.'
	    END IF
	  END DO
	  CALL WNCTXT(F_T,'!4C\Telescopes selected: !#$AS',STHTEL,IFTXT)
	END IF
C
 11	CONTINUE
	IF (TYP.GE.100) GOTO 20			!READY
	IF (.NOT.WNDPAR('SELECT_TELS',RD,MAXDEF*4,J0,'""')) THEN !GET INFO
	  IF (E_C.EQ.DWC_ENDOFLOOP) THEN
	    NSCTLS=.FALSE.			!SHOW END
	    GOTO 20				!READY
	  END IF
	  GOTO 11				!REPEAT
	ELSE IF (J0.EQ.0) THEN
	  GOTO 20				!READY
	ELSE IF (J0.LT.0) THEN			!ASSUME +*
	  IF (INSTR.EQ.1) THEN			!ATCA
	    RD(1)='+T'
	  ELSE
	    RD(1)='+*'
	  END IF
	  J0=1
	END IF
C
	DO I=1,J0
	  ADD=.TRUE.				!ASSUME INCLUDE
	  I1=1					!CHARACTER PTR
 31	  CONTINUE
	  IF (I1.GT.4) GOTO 30			!EMPTY
	  IF (RD(I)(I1:I1).EQ.' ') THEN
	    I1=I1+1				!SKIP SPACE
	    GOTO 31
	  ELSE IF (RD(I)(I1:I1).EQ.'+') THEN
	    I1=I1+1				!SKIP +
	    GOTO 31
	  ELSE IF (RD(I)(I1:I1).EQ.'-') THEN
	    I1=I1+1
	    ADD=.NOT.ADD			!EXCLUDE
	    GOTO 31
	  ELSE
	    I2=INDEX(TEL,RD(I)(I1:I1))		!GET TELESCOPE
	    IF (I2.EQ.0) GOTO 30		!UNKNOWN
	    I1=I1+1
	    DO I4=IS(I2),IE(I2)			!DO FOR SPECIFIED TEL.
	      TELS(I4)=ADD
	    END DO
	  END IF
 30	  CONTINUE
	END DO
	LP=.TRUE.
	GOTO 10					!MORE
C
 20	CONTINUE
	CALL WNDPOHC
C
	RETURN
C
C
	END
