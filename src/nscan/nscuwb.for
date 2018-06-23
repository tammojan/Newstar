C+ NSCUWB.FOR
C  WNB 910220
C
C  Revisions:
C
	LOGICAL FUNCTION NSCUWB(FCAOUT,BUF)
C
C  Write a fits card image and other info
C
C  Result:
C
C	NSCUWB_L = NSCUWB_L( FCAOUT_J:I, BUF(0:79)_B:I)
C				write buffer BUF to line in FCAOUT
C	NSCUWS_L = NSCUWS_L( FCAOUT_J:I, SBUF_C*:I)
C				write the string in SBUF to line in FCAOUT
C	NSCUWF_L = NSCUWF_L( FCAOUT_J:I)
C				fill out FITS record on FCAOUT
C	NSCUWL_L = NSCUWL_L( FCAOUT_J:I, BUF(0:*)_B:I, NBUF_J:I)
C				write NBUF bytes to FCAOUT
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
C
C  Parameters:
C
	INTEGER LRCLEN			!RECORD LENGTH FITS (CHANGE ALSO NSCUWB)
	  PARAMETER (LRCLEN=2880)
	INTEGER CDILEN			!CARD IMAGE LENGTH
	  PARAMETER (CDILEN=80)
	INTEGER NCDI			!# OF CARD IMAGES/RECORD
	  PARAMETER (NCDI=LRCLEN/CDILEN)
C
C  Arguments:
C
	INTEGER FCAOUT			!FILE POINTER
	BYTE BUF(0:*)			!BUFFER TO WRITE
	CHARACTER*(*) SBUF		!STRING TO WRITE
	INTEGER NBUF			!BUFFER LENGTH
C
C  Entry points:
C
	LOGICAL NSCUWS,NSCUWF,NSCUWL
C
C  Function references:
C
	LOGICAL WNFWRS			!WRITE SEQUENTIAL DATA
	INTEGER WNFEOF			!FILE POINTER
C
C  Data declarations:
C
	BYTE LBUF(0:CDILEN-1)		!LOCAL BUFFER
C-
C
C NSCUWB
C
	NSCUWB=.TRUE.					!ASSUME OK
	IF (.NOT.WNFWRS(FCAOUT,CDILEN,BUF(0))) THEN	!WRITE IMAGE
 10	  CONTINUE
	  NSCUWB=.FALSE.
	END IF
C
	RETURN
C
C NSCUWS
C
	ENTRY NSCUWS(FCAOUT,SBUF)
C
	NSCUWS=.TRUE.					!ASSUME OK
	CALL WNGMFS(CDILEN,SBUF,LBUF(0))		!MAKE BUFFER
	IF (.NOT.WNFWRS(FCAOUT,CDILEN,LBUF(0))) GOTO 10	!WRITE IMAGE
C
	RETURN
C
C NSCUWL
C
	ENTRY NSCUWL(FCAOUT,BUF,NBUF)
C
	NSCUWL=.TRUE.					!ASSUME OK
	IF (.NOT.WNFWRS(FCAOUT,NBUF,BUF(0))) GOTO 10	!WRITE IMAGE
C
	RETURN
C
C NSCUWF
C
	ENTRY NSCUWF(FCAOUT)
C
	NSCUWF=.TRUE.					!ASSUME OK
	J=WNFEOF(FCAOUT)				!CURRENT POINTER
	J=(((J+LRCLEN-1)/LRCLEN)*LRCLEN)-J		!BYTES TO WRITE
	CALL WNGMVZ(CDILEN,LBUF(0))			!ZERO BUFFER
	DO I=1,J/CDILEN					!WRITE FILLERS
	  IF (.NOT.WNFWRS(FCAOUT,CDILEN,LBUF(0))) GOTO 10 !WRITE IMAGE
	END DO
	IF (.NOT.WNFWRS(FCAOUT,MOD(J,CDILEN),LBUF(0))) GOTO 10 !WRITE LAST PART
C
	RETURN
C
C
	END