C+ WNTIAN.FOR
C  WNB 930501
C
C  Revisions:
C
	LOGICAL FUNCTION WNTIAN(TLIN,PT,NAM,NENT,IENTRY,FENTRY)
C
C  Analyse a name (.) line
C
C  Result:
C
C	WNTIAN_L = WNTIAN( TLIN_C*:I, PT_J:IO, NAM_C*:O, NENT_J:I,
C			IENTRY_J(0:*):IO, FENTRY_J(0:*):IO)
C				Analyse a line given in TLIN at PT for
C				. statement. NAM returns the . name found
C				and data in IENTRY and FENTRY structure.
C				NENT is the current line number
C
C  Include files:
C
	INCLUDE 'WNG_DEF'
	INCLUDE 'WNT_O_DEF'
	INCLUDE 'WNT_DEF'
C
C  Parameters:
C
C
C  Arguments:
C
	CHARACTER*(*) TLIN		!LINE TO DO
	INTEGER PT			!POINTER INTO LINE
	CHARACTER*(*) NAM		!% NAME FOUND
	INTEGER NENT			!CURRENT LINE NUMBER
	INTEGER IENTRY(0:*)		!LINE STRUCTURE
	INTEGER FENTRY(0:*)		!DATA FORMAT STRUCTURE
C
C  Function references:
C
	LOGICAL WNCASC,WNCATC		!TEST CHARACTER GIVEN
	LOGICAL WNCAFN			!GET NAME
	INTEGER WNCAFU			!MINIMAX FIT
	INTEGER WNTIBR			!READ ENTRY
	INTEGER WNTIBW			!WRITE ENTRY
	LOGICAL WNTIVG			!GET VALUE
	LOGICAL WNTIVP			!SET VALUE
C
C  Data declarations:
C
	CHARACTER*(MXLNAM) LNAM,LNAM1,LNAM2,LNAM3 !LOCAL NAME
	INTEGER LENTRY(0:WNTIHDL/LB_J-1) !LINE DESCRIPTOR
	BYTE LFENTB(0:WNTFHDL-1)	!FORMAT DESCRIPTOR
	  INTEGER LFENTJ(0:WNTFHDL/LB_J-1)
	  EQUIVALENCE (LFENTB,LFENTJ)
C-
C
C INIT
C
	WNTIAN=.TRUE.				!ASSUME OK
	NAM=' '					!FOR ERROR MESSAGES
C
C . NAME
C
	CALL WNCASB(TLIN,PT)			!SKIP BLANK
	IF (WNCATC(TLIN,PT,'=')) THEN		!SAME AS .OFFSET
	  I=PN_OFF
	ELSE
	  IF (.NOT.WNCAFN(TLIN,PT,NAM)) GOTO 900 !GET .  NAME
	  I=WNCAFU(NAM,PN__TXT)			!TEST NAME
	END IF
C
C .COMMON END
C
	IF (CBTP.EQ.BT_COM) THEN		!COULD BE END COMMON
	  IF (I.EQ.PN_PAR .OR. I.EQ.PN_DAT .OR. I.EQ.PN_COM .OR.
	1		(I.EQ.PN_END .AND. CATP.EQ.AT_DEF)) THEN !END COMMON
	    DO I1=XFDES_J(WNTB_CNT_J)-1,0,-1	!FIND START COMMON
	      I2=WNTIBR(XFDES,LFENTB,I1)	!READ ENTRY
	      IF (LFENTJ(WNTF_BTYP_J).EQ.BT_DCM) THEN !FOUND
	        LFENTJ(WNTF_TLEN_J)=COFF	!SET LENGTH
	        I2=WNTIBW(XFDES,LFENTB,I1)	!REWRITE ENTRY
	        GOTO 10				!OK
	      END IF
	    END DO
 10	    CONTINUE
	  END IF
	END IF
C
C .DEFINE
C
	IF (I.EQ.PN_DEF) THEN
	  IF (DEFSN .OR. DEP.GT.0) GOTO 900	!NOT ALLOWED
	  CALL WNCASB(TLIN,PT)
	  IF (PT.LE.LEN(TLIN)) GOTO 900		!FORMAT ERROR
	  FENTRY(WNTF_BTYP_J)=BT_DEF		!FORMAT TYPE
	  FENTRY(WNTF_DTP_J)=CATP		!SAVE PREVIOUS AREA TYPE
	  FENTRY(WNTF_ALEN_J)=CALN		!AND LINE NUMBER
	  FENTRY(WNTF_TLEN_J)=COFF		!CURRENT OFFSET
	  FENTRY(WNTF_ULEN_J)=CBTP		!CURRENT BLOCK TYPE
	  IENTRY(WNTI_FTYP_J)=FT_DEF		!SET TYPE
	  CATP=AT_DEF				!SET DEFINE TYPE
	  DEP=DEP+1				!NEW DEPTH
	  CALN=NENT				!CURRENT LINE NUMBER
	  CBTP=BT_DAT				!ASSUME DATA
	  COFF=0				!START NEW OFFSET
	  DEFSN=.TRUE.				!SET .DEFINE SEEN
C
C .STRUCTURE/BEGIN
C
	ELSE IF (I.EQ.PN_BEG .OR. I.EQ.PN_STR) THEN
	  IF (CATP.EQ.AT_BEG) GOTO 900		!NO NESTING ALLOWED
	  CALL WNCASB(TLIN,PT)			!SKIP BLANKS
	  IF (WNCASC(TLIN,PT,'=')) THEN		!NAME GIVEN
	    CALL WNCASB(TLIN,PT)		!SKIP BLANK
	    IF (.NOT.WNCAFN(TLIN,PT,LNAM)) GOTO 900 !IMPROPER NAME
	  ELSE
	    LNAM=PARM(P_NAM)
	  END IF
	  DO I1=0,XFDES_J(WNTB_CNT_J)-1		!CHECK DUPLICATE NAME
	    I2=WNTIBR(XFDES,LFENTB,I1)		!READ ENTRY
	    IF (LFENTJ(WNTF_BTYP_J).EQ.BT_BEG) THEN
	      CALL WNGMTS(WNTF_NAM_N,LFENTB(WNTF_NAM_1),LNAM1)
	      IF (LNAM.EQ.LNAM1) THEN
	        CALL WNCTXT(F_TP,'Duplicate structure name')
	        GOTO 900
	      END IF
	    END IF
	  END DO
	  FENTRY(WNTF_BTYP_J)=BT_BEG		!STRUCTURE FORMAT
	  FENTRY(WNTF_DTP_J)=CATP		!SAVE PREVIOUS AREA TYPE
	  FENTRY(WNTF_ALEN_J)=CALN		!AND LINE NUMBER
	  FENTRY(WNTF_TLEN_J)=COFF		!CURRENT OFFSET
	  FENTRY(WNTF_ULEN_J)=CBTP		!CURRENT BLOCK TYPE
	  CALL WNGMFS(WNTF_NAM_N,LNAM,FENTRY(WNTF_NAM_1/LB_J)) !SAVE NAME
	  IENTRY(WNTI_FTYP_J)=FT_BEG		!SET TYPE
	  CATP=AT_BEG				!SET BEGIN TYPE
	  DEP=DEP+1				!NEW DEPTH
	  CALN=NENT				!CURRENT LINE NUMBER
	  CBTP=BT_SDA				!ASSUME DATA
	  COFF=0				!NEW OFFSET START
	  CALEN=0				!NEW ALIGNMENT BLOCK
	  BEGSN=.TRUE.				!SET .BEGIN SEEN
C
C .END
C
	ELSE IF (I.EQ.PN_END) THEN
	  CALL WNCASB(TLIN,PT)
	  IF (PT.LE.LEN(TLIN)) GOTO 900		!FORMAT ERROR
	  DEP=DEP-1
	  IF (DEP.LT.0) THEN
	    CALL WNCTXT(F_TP,'Fatal -- Illegal depth')
	    GOTO 900
	  END IF
	  IF (CATP.EQ.AT_BEG) THEN
	    FENTRY(WNTF_BTYP_J)=BT_EBG		!END FORMAT TYPE
	  ELSE IF (CATP.EQ.AT_DEF) THEN
	    FENTRY(WNTF_BTYP_J)=BT_EDF		!END FORMAT TYPE
	  ELSE
	    CALL WNCTXT(F_TP,'Fatal -- Illegal END statement')
	    GOTO 900
	  END IF
	  FENTRY(WNTF_DTP_J)=CATP		!SAVE BEGIN AREA
	  FENTRY(WNTF_ALEN_J)=CALN
	  IENTRY(WNTI_FTYP_J)=FT_END		!SET TYPE
	  I2=WNTIBR(IBDES,LENTRY,CALN)		!READ PREVIOUS AREA DEFINITION
	  I2=WNTIBR(XFDES,LFENTB,LENTRY(WNTI_PFOR_J)) !READ FORMAT
	  CATP=LFENTJ(WNTF_DTP_J)		!TYPE PREVIOUS DEFINITION
	  CBTP=LFENTJ(WNTF_ULEN_J)		!TYPE PREVIOUS BLOCK
	  CALN=LFENTJ(WNTF_ALEN_J)		!LINE PRE-PREVIOUS DEFINITION
	  I1=COFF				!CURRENT OFFSET
	  COFF=LFENTJ(WNTF_TLEN_J)		!OLD OFFSET
	  LFENTJ(WNTF_TLEN_J)=I1		!SAVE LENGTH STRUCTURE
	  IF (FENTRY(WNTF_DTP_J).EQ.AT_BEG) THEN !SAVE BLOCK ALIGNMENT
	    LFENTJ(WNTF_ALEN_J)=CALEN
	    CALL WNCTXS(LNAM2,'!AD__L',
	1		LFENTB(WNTF_NAM_1),WNTF_NAM_N) !MAKE VARIABLES
	    CALL WNCTXS(LNAM3,'!UJ',LFENTJ(WNTF_TLEN_J))
	    J=1
	    JS=WNTIVP(LNAM3,J,LNAM2,.FALSE.)
	    CALL WNCTXS(LNAM2,'!AD__V',
	1		LFENTB(WNTF_NAM_1),WNTF_NAM_N) !MAKE VARIABLES
	    J=1
	    JS=WNTIVP(PARM(P_VER),J,LNAM2,.FALSE.)
	    CALL WNCTXS(LNAM2,'!AD__S',
	1		LFENTB(WNTF_NAM_1),WNTF_NAM_N) !MAKE VARIABLES
	    J=1
	    JS=WNTIVP(PARM(P_SYS),J,LNAM2,.FALSE.)
	  END IF
	  I2=WNTIBW(XFDES,LFENTB,I2)		!REWRITE STRUCTURE FORMAT
C
C .PARAMETER/DATA/COMMON
C
	ELSE IF (I.EQ.PN_PAR) THEN
	  CBTP=BT_PAR
	  PARSN=.TRUE.				!SET .PARAMETER SEEN
	ELSE IF (I.EQ.PN_DAT) THEN
	  IF (DEP.LE.0) GOTO 900
	  IF (CATP.EQ.AT_BEG) THEN
	    CBTP=BT_SDA
	  ELSE
	    CBTP=BT_DAT
	  END IF
	ELSE IF (I.EQ.PN_COM) THEN
	  IF (DEP.LE.0 .OR. CATP.NE.AT_DEF) GOTO 900 !NOT ALLOWED
	  CALL WNCASB(TLIN,PT)			!SKIP BLANKS
	  IF (WNCASC(TLIN,PT,'=')) THEN		!NAME GIVEN
	    CALL WNCASB(TLIN,PT)		!SKIP BLANK
	    IF (.NOT.WNCAFN(TLIN,PT,LNAM)) GOTO 900 !IMPROPER NAME
	  ELSE
	    LNAM=PARM(P_NAM)
	  END IF
	  DO I1=0,XFDES_J(WNTB_CNT_J)-1		!CHECK DUPLICATE NAME
	    I2=WNTIBR(XFDES,LFENTB,I1)		!READ ENTRY
	    IF (LFENTJ(WNTF_BTYP_J).EQ.BT_DCM) THEN
	      CALL WNGMTS(WNTF_NAM_N,LFENTB(WNTF_NAM_1),LNAM1)
	      IF (LNAM.EQ.LNAM1) THEN
	        CALL WNCTXT(F_TP,'Duplicate common name')
	        GOTO 900
	      END IF
	    END IF
	  END DO
	  FENTRY(WNTF_BTYP_J)=BT_DCM		!DEFINE COMMON FORMAT
	  CALL WNGMFS(WNTF_NAM_N,LNAM,FENTRY(WNTF_NAM_1/LB_J)) !SAVE NAME
	  IENTRY(WNTI_FTYP_J)=FT_DCM		!SET TYPE
	  COFF=0				!RESTART OFFSETS
	  CBTP=BT_COM
C
C .OFFSET
C
	ELSE IF (I.EQ.PN_OFF) THEN
	  IF (DEP.LE.0 .OR. CBTP.EQ.BT_PAR .OR.
	1	CBTP.EQ.BT_DAT) GOTO 900	!NOT ALLOWED
	  CALL WNCASB(TLIN,PT)			!SKIP BLANKS
	  IF (.NOT.WNCASC(TLIN,PT,'=')) GOTO 900
	  IF (.NOT.WNTIVG(TLIN,PT,JS,I1,LNAM)) GOTO 900 !GET VALUE
	  IF (.NOT.JS) GOTO 900			!NOT VALUE
	  CALL WNCASB(TLIN,PT)			!SKIP BLANKS
	  IF (PT.LE.LEN(TLIN)) GOTO 900		!FORMAT ERROR
	  IF (I1.LT.COFF) THEN			!CANNOT DO
	    CALL WNCTXT(F_TP,'Illegal offset (before current position)')
	    GOTO 900
	  END IF
	  CALL WNTIA1(I1-COFF)			!MAKE DUMMY ENTRY
C
C .ALIGN
C
	ELSE IF (I.EQ.PN_ALI) THEN
	  IF (DEP.LE.0 .OR. CBTP.EQ.BT_PAR .OR.
	1	CBTP.EQ.BT_DAT) GOTO 900	!NOT ALLOWED
	  CALL WNCASB(TLIN,PT)			!SKIP BLANKS
	  IF (.NOT.WNCASC(TLIN,PT,'=')) GOTO 900
	  IF (.NOT.WNTIVG(TLIN,PT,JS,I1,LNAM)) GOTO 900 !GET VALUE
	  IF (.NOT.JS) GOTO 900			!NOT VALUE
	  CALL WNCASB(TLIN,PT)			!SKIP BLANKS
	  IF (PT.LE.LEN(TLIN)) GOTO 900		!FORMAT ERROR
	  IF (I1.LE.0) GOTO 900			!CANNOT ALIGN ON 0
	  I1=((COFF+I1-1)/I1)*I1		!ALIGNED OFFSET
	  CALL WNTIA1(I1-COFF)			!MAKE DUMMY ENTRY
C
C .MAP
C
	ELSE IF (I.EQ.PN_MAP) THEN
	  CALL WNCTXT(F_TP,'.MAP not yet implemented')
	  GOTO 900
C
C .UNION
C
	ELSE IF (I.EQ.PN_UNI) THEN
	  CALL WNCTXT(F_TP,'.UNION not yet implemented')
	  GOTO 900
C
C END .
C
	ELSE
	  GOTO 900				!UNKNOWN
	END IF
C
C FINISH
C
 800	CONTINUE
C
	RETURN
C
C ERROR
C
 900	CONTINUE
	WNTIAN=.FALSE.
	GOTO 800
C
C
	END
