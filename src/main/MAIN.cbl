       IDENTIFICATION DIVISION.
       PROGRAM-ID. MAIN.
      *----------------------------------------------------------------*
      * Main entry: stdin raw -> CALL CALCULATOR -> stdout
      *----------------------------------------------------------------*
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-LINE                     PIC X(80).
       01  WS-OUT                      PIC X(120).
       COPY DEMOMSG.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE SPACES                 TO WS-LINE
           ACCEPT WS-LINE

           MOVE SPACES                 TO DEMO-AREA
           MOVE WS-LINE                TO DEMO-RAW
           MOVE '00'                   TO DEMO-STATUS
           MOVE 'MOCK'                 TO DEMO-RESULT-X

           CALL 'CALCULATOR' USING DEMO-AREA

           MOVE SPACES                 TO WS-OUT
           STRING
               'MOCK'                  DELIMITED BY SIZE
               '|'                     DELIMITED BY SIZE
               FUNCTION TRIM(DEMO-RAW) DELIMITED BY SIZE
               '|'                     DELIMITED BY SIZE
               FUNCTION TRIM(DEMO-RESULT-X)
                                       DELIMITED BY SIZE
               '|'                     DELIMITED BY SIZE
               DEMO-STATUS             DELIMITED BY SIZE
               INTO WS-OUT
           END-STRING

           DISPLAY FUNCTION TRIM(WS-OUT)
           MOVE ZERO                   TO RETURN-CODE
           GOBACK.
       END PROGRAM MAIN.
