C INTERFACE FOR CALL KERNEL FUNCTION IN C
      SUBROUTINE KFUN(X, Y, X0, Y0, BH, KER, Z)
      DOUBLE PRECISION X, Y, X0, Y0, BH, Z
      INTEGER KER
      Z=F(X, Y, X0, Y0, BH, KER)
      RETURN
      END
C     
      FUNCTION F(X, Y, X0, Y0, BH, KER)
C     double precision  PI25DT 
      parameter        (PI25DT = 3.141592653589793238462643d0) 
C      REAL*8 X, Y, X0, Y0, BH
      DOUBLE PRECISION X, Y, X0, Y0, BH
      INTEGER KER
      ZZ=((X-X0)*(X-X0)+(Y-Y0)*(Y-Y0))/(BH*BH)
C   KERNELS-- 1-GAUSSIAN, 2-QUADRATIC (Epanechnikov), 3-QUARTIC
C   coefficients: 1/(2*pi); 2/pi; 3/pi;  
      IF (KER.EQ.1) THEN 
         F = EXP(-ZZ/2.0)/(2.0*PI25DT*BH*BH)
      ELSE IF(ZZ.GE.1.E0) THEN
         F = 0.
      ELSE IF (KER.EQ.2) THEN 
         F = 2.0*(1.0-ZZ)/(PI25DT*BH*BH)
      ELSE
         F = 3.0*(1.0-ZZ)*(1.0-ZZ)/(PI25DT*BH*BH)
      END IF
      RETURN
      END
C
C     NCALLS MUST BE INITIALIZED TO 0 BEFORE THE FIRST CALL
      SUBROUTINE CUBTRI(T, EPS, MCALLS, ANS, ERR, NCALLS, W, NW,        CUB   10
     * X0, Y0, BH, IER, KER)
C
C      EXTERNAL F
      INTEGER IER, MCALLS, NCALLS, NW, KER
      DOUBLE PRECISION ALFA, ANS, ANSKP, AREA, EPS, ERR, ERRMAX, H, Q1, 
     * Q2, R1, R2, X0, Y0, BH, D(2,4), S(4), T(2,3), VEC(2,3), W(6,NW),
     * X(2)
C       ACTUAL DIMENSION OF W IS (6,NW/6)
C
      DOUBLE PRECISION TANS, TERR, DZERO
      COMMON /CUBSTA/ TANS, TERR
C       THIS COMMON IS REQUIRED TO PRESERVE TANS AND TERR BETWEEN CALLS
C       AND TO SAVE VARIABLES IN FUNCTION RNDERR
      DATA NFE /19/, S(1), S(2), S(3), S(4) /3*1E0,-1E0/, D(1,1),
     * D(2,1) /0.0,0.0/, D(1,2), D(2,2) /0.0,1.0/, D(1,3), D(2,3)
     * /1.0,0.0/, D(1,4), D(2,4) /1.0,1.0/
C       NFE IS THE NUMBER OF FUNCTION EVALUATIONS PER CALL TO CUBRUL.
      DATA ZERO /0.E0/, ONE /1.E0/, DZERO /0.D0/, POINT5 /.5E0/
C
C      CALCULATE DIRECTION VECTORS, AREA AND MAXIMUM NUMBER
C      OF SUBDIVISIONS THAT MAY BE PERFORMED
      DO 20 I=1,2
        VEC(I,3) = T(I,3)
        DO 10 J=1,2
          VEC(I,J) = T(I,J) - T(I,3)
   10   CONTINUE
   20 CONTINUE
      MAXC = (MCALLS/NFE+3)/4
      IER = 1
      MAXK = MIN0(MAXC,(NW/6+2)/3)
      IF (MAXC.GT.MAXK) IER = 2
      AREA = ABS(VEC(1,1)*VEC(2,2)-VEC(1,2)*VEC(2,1))*POINT5
      K = (NCALLS/NFE+3)/4
      MW = 3*(K-1) + 1
      IF (NCALLS.GT.0) GO TO 30
C
C       TEST FOR TRIVIAL CASES
      TANS = DZERO
      TERR = DZERO
      IF (AREA.EQ.ZERO) GO TO 90
      IF (MCALLS.LT.NFE) GO TO 100
      IF (NW.LT.6) GO TO 110
C
C       INITIALIZE DATA LIST
      K = 1
      MW = 1
      W(1,1) = ZERO
      W(2,1) = ZERO
      W(3,1) = ONE
      CALL CUBRUL(VEC, W(1,1), X0, Y0, BH, KER)
      TANS = W(5,1)
      TERR = W(6,1)
      NCALLS = NFE
C
C       TEST TERMINATION CRITERIA
   30 ANS = TANS
      ERR = TERR
      IF (ERR.LT.MAX(ONE,ABS(ANS))*EPS) GO TO 90
      IF (K.EQ.MAXK) GO TO 120
C
C       FIND TRIANGLE WITH LARGEST ERROR
      ERRMAX = ZERO
      DO 40 I=1,MW
        IF (W(6,I).LE.ERRMAX) GO TO 40
        ERRMAX = W(6,I)
        J = I
   40 CONTINUE
C
C       SUBDIVIDE TRIANGLE INTO FOUR SUBTRIANGLES AND UPDATE DATA LIST
      DO 50 I=1,2
        X(I) = W(I,J)
   50 CONTINUE
      H = W(3,J)*POINT5
      IF (RNDERR(X(1),H,X(1),H).NE.ZERO) GO TO 130
      IF (RNDERR(X(2),H,X(2),H).NE.ZERO) GO TO 130
      ANSKP = SNGL(TANS)
      TANS = TANS - DBLE(W(5,J))
      TERR = TERR - DBLE(W(6,J))
      R1 = W(4,J)
      R2 = W(5,J)
      JKP = J
      Q1 = ZERO
      Q2 = ZERO
      DO 70 I=1,4
        DO 60 L=1,2
          W(L,J) = X(L) + H*D(L,I)
   60   CONTINUE
        W(3,J) = H*S(I)
        CALL CUBRUL(VEC, W(1,J), X0, Y0, BH, KER)
        Q2 = Q2 + W(5,J)
        Q1 = Q1 + W(4,J)
        J = MW + I
   70 CONTINUE
      ALFA = 1E15
      IF (Q2.NE.R2) ALFA = ABS((Q1-R1)/(Q2-R2)-ONE)
      J = JKP
      DO 80 I=1,4
        W(6,J) = W(6,J)/ALFA
        TANS = TANS + W(5,J)
        TERR = TERR + W(6,J)
        J = MW + I
   80 CONTINUE
      MW = MW + 3
      NCALLS = NCALLS + 4*NFE
      K = K + 1
C
C       IF ANSWER IS UNCHANGED, IT CANNOT BE IMPROVED
      IF (ANSKP.EQ.SNGL(TANS)) GO TO 150
C
C       REMOVE THIS IF STATEMENT TO DISABLE ROUNDING ERROR TEST
      IF (K.GT.3 .AND. ABS(Q2-R2).GT.ABS(Q1-R1)) GO TO 140
      GO TO 30
C
C       EXITS FROM SUBROUTINE
   90 IER = 0
      GO TO 120
  100 IER = 1
      GO TO 120
  110 IER = 2
  120 ANS = TANS
      ERR = TERR
      RETURN
  130 IER = 3
      GO TO 120
  140 IER = 4
      GO TO 120
  150 IER = 5
      GO TO 120
      END
C
      FUNCTION RNDERR(X, A, Y, B)                                       RND   10
C       THIS FUNCTION COMPUTES THE ROUNDING ERROR COMMITTED WHEN THE
C       SUM X+A IS FORMED.  IN THE CALLING PROGRAM, Y MUST BE THE SAME
C       AS X AND B MUST BE THE SAME AS A.  THEY ARE DECLARED AS
C       DISTINCT VARIABLES IN THIS FUNCTION, AND THE INTERMEDIATE
C       VARIABLES S AND T ARE PUT INTO COMMON, IN ORDER TO DEFEND
C       AGAINST THE WELL-MEANING ACTIONS OF SOME OFFICIOUS OPTIMIZING
C       FORTRAN COMPILERS.
      COMMON /CUBATB/ S, T
      REAL*8 X, A, Y, B
      S = X + A
      T = S - Y
      RNDERR = T - B
      RETURN
      END
C
      SUBROUTINE CUBRUL(VEC, P, X0, Y0, BH, KER)                             CUB   10
C
      INTEGER KER
      DOUBLE PRECISION A1, A2, S, SN, DZERO, DONE, DTHREE, DSIX
      DOUBLE PRECISION X0, Y0, BH, AREA, ORIGIN(2), P(6), TVEC(2,3), 
     * VEC(2,3), W(5,6), X, Y
C
      DATA NQUAD /6/, W(1,1), W(2,1), W(3,1) /3*.33333333333333333333333
     * 33E0/, W(4,1), W(5,1) /.225E0,.3786109120031468330830822E-1/,
     * W(1,2), W(2,2), W(3,2) /.7974269853530873223980253E0,2*
     * .1012865073234563388009874E0/, W(4,2), W(5,2)
     * /.3778175416344814577870518E0,.1128612762395489164329420E0/,
     * W(1,3), W(2,3), W(3,3) /.5971587178976982045911758E-1,2*
     * .4701420641051150897704412E0/, W(4,3), W(5,3)
     * /.3971824583655185422129482E0,.2350720567323520126663380E0/
      DATA W(1,4), W(2,4), W(3,4) /.5357953464498992646629509E0,2*
     * .2321023267750503676685246E0/, W(4,4), W(5,4)
     * /0.E0,.3488144389708976891842461E0/, W(1,5), W(2,5), W(3,5)
     * /.9410382782311208665596304E0,2*.2948086088443956672018481E-1/,
     * W(4,5), W(5,5) /0.E0,.4033280212549620569433320E-1/, W(1,6),
     * W(2,6), W(3,6) /.7384168123405100656112906E0,
     * .2321023267750503676685246E0,.2948086088443956672018481E-1/,
     * W(4,6), W(5,6) /0.E0,.2250583347313904927138324E0/
C
      DATA DZERO /0.D0/, DONE /1.D0/, DTHREE /3.D0/, DSIX /6.D0/,
     * POINT5 /.5E0/
C
C       SCALE BASE VECTORS AND OBTAIN AREA
      DO 20 I=1,2
        ORIGIN(I) = VEC(I,3) + P(1)*VEC(I,1) + P(2)*VEC(I,2)
        DO 10 J=1,2
          TVEC(I,J) = P(3)*VEC(I,J)
   10   CONTINUE
   20 CONTINUE
      AREA = POINT5*ABS(TVEC(1,1)*TVEC(2,2)-TVEC(1,2)*TVEC(2,1))
      A1 = DZERO
      A2 = DZERO
C
C       COMPUTE ESTIMATES FOR INTEGRAL AND ERROR
      DO 40 K=1,NQUAD
        X = ORIGIN(1) + W(1,K)*TVEC(1,1) + W(2,K)*TVEC(1,2)
        Y = ORIGIN(2) + W(1,K)*TVEC(2,1) + W(2,K)*TVEC(2,2)
        S = DBLE(F(X,Y,X0,Y0,BH,KER))
        SN = DONE
        IF (W(1,K).EQ.W(2,K)) GO TO 30
        X = ORIGIN(1) + W(2,K)*TVEC(1,1) + W(1,K)*TVEC(1,2)
        Y = ORIGIN(2) + W(2,K)*TVEC(2,1) + W(1,K)*TVEC(2,2)
        S = S + DBLE(F(X,Y,X0,Y0,BH,KER))
        X = ORIGIN(1) + W(2,K)*TVEC(1,1) + W(3,K)*TVEC(1,2)
        Y = ORIGIN(2) + W(2,K)*TVEC(2,1) + W(3,K)*TVEC(2,2)
        S = S + DBLE(F(X,Y,X0,Y0,BH,KER))
        SN = DTHREE
        IF (W(2,K).EQ.W(3,K)) GO TO 30
        X = ORIGIN(1) + W(1,K)*TVEC(1,1) + W(3,K)*TVEC(1,2)
        Y = ORIGIN(2) + W(1,K)*TVEC(2,1) + W(3,K)*TVEC(2,2)
        S = S + DBLE(F(X,Y,X0,Y0,BH,KER))
        X = ORIGIN(1) + W(3,K)*TVEC(1,1) + W(1,K)*TVEC(1,2)
        Y = ORIGIN(2) + W(3,K)*TVEC(2,1) + W(1,K)*TVEC(2,2)
        S = S + DBLE(F(X,Y,X0,Y0,BH,KER))
        X = ORIGIN(1) + W(3,K)*TVEC(1,1) + W(2,K)*TVEC(1,2)
        Y = ORIGIN(2) + W(3,K)*TVEC(2,1) + W(2,K)*TVEC(2,2)
        S = S + DBLE(F(X,Y,X0,Y0,BH,KER))
        SN = DSIX
   30   S = S/SN
        A1 = A1 + W(4,K)*S
        A2 = A2 + W(5,K)*S
   40 CONTINUE
      P(4) = SNGL(A1)*AREA
      P(5) = SNGL(A2)*AREA
      P(6) = ABS(P(5)-P(4))
      RETURN
      END
C
C     EXTRACT TRIANGLE INDEX FROM THE OUTPUT OF DELDIR
      SUBROUTINE EXTRACT(EDGE_INDX, EDGE_N,
     * TRI_INDX, TRI_N)
      INTEGER EDGE_N, TRI_N
      INTEGER EDGE_INDX(EDGE_N, 2), TRI_INDX(TRI_N, 3)
      INTEGER N_POSI/1/
      DO 10, I = 1, EDGE_N-2
         DO 20, J = I+1, EDGE_N-1
            IF (EDGE_INDX(I,2).EQ.EDGE_INDX(J,2)) THEN
               DO 30, K = J+1, EDGE_N
                  IF ( (EDGE_INDX(K,1).EQ.EDGE_INDX(J,1)) .AND. 
     *                 (EDGE_INDX(K,2).EQ.EDGE_INDX(I,1)) ) THEN
                     TRI_INDX(N_POSI,1)=EDGE_INDX(K,1)
                     TRI_INDX(N_POSI,2)=EDGE_INDX(K,2)
                     TRI_INDX(N_POSI,3)=EDGE_INDX(J,2)
                     N_POSI=N_POSI+1
                  END IF
 30            CONTINUE
            END IF
 20      CONTINUE
 10   CONTINUE
      RETURN
      END
C
