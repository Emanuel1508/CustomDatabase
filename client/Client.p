BLOCK-LEVEL ON ERROR UNDO, THROW.
{common/include/dsplayer.i}
{common/include/dsgame.i}

DEFINE VARIABLE hProc AS HANDLE NO-UNDO.

RUN server/SI/SIPlayerAndGame.p PERSISTENT SET hProc.

DATASET dsplayer:EMPTY-DATASET ().
DATASET dsgame:EMPTY-DATASET ().

TEMP-TABLE ttplayer:TRACKING-CHANGES = TRUE.
TEMP-TABLE ttgame:TRACKING-CHANGES = TRUE.


/*FOR EACH ttgame NO-LOCK.*/
/*    DISPLAY ttgame.     */
/*END.                    */

RUN CreateRecords(INPUT-OUTPUT DATASET dsplayer, INPUT-OUTPUT DATASET dsgame).

//RUN FetchUpdateAndDelete(1, OUTPUT DATASET dsplayer BY-REFERENCE, OUTPUT DATASET dsgame BY-REFERENCE).



TEMP-TABLE ttplayer:TRACKING-CHANGES = FALSE.
TEMP-TABLE ttgame:TRACKING-CHANGES = FALSE.


DO TRANSACTION:
    RUN submitPlayerAndGame IN hProc(INPUT-OUTPUT DATASET dsplayer BY-REFERENCE, INPUT-OUTPUT DATASET dsgame BY-REFERENCE).
END.

FOR EACH Player NO-LOCK.
    DISPLAY Player.
END.

FOR EACH Game NO-LOCK.
    DISPLAY Game.
END.

PROCEDURE CreateRecords:
    DEFINE INPUT-OUTPUT PARAMETER DATASET FOR dsplayer.
    DEFINE INPUT-OUTPUT PARAMETER DATASET FOR dsgame.

    CREATE ttPlayer.
    ASSIGN
        ttPlayer.PlayerAge      = 21
        ttPlayer.PlayerRank     = "Gold"
        ttPlayer.PlayerRating   = 70
        ttPlayer.playerUsername = 'Grubby'
        .
    
    CREATE ttgame.
    ASSIGN
        ttgame.GameLength  = 35
        ttgame.GameResult  = "Victory"
        ttgame.PlayerScore = 89
        .

    CREATE ttgame.
    ASSIGN
        ttgame.GameLength  = 25
        ttgame.GameResult  = "Defeat"
        ttgame.PlayerScore = 19
        .
        

END PROCEDURE.

PROCEDURE FetchUpdateAndDelete:
    DEFINE INPUT PARAMETER iPlayerNum AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER DATASET FOR dsplayer.
    DEFINE OUTPUT PARAMETER DATASET FOR dsgame.
    
    RUN FetchPlayerAndGame IN hProc(INPUT iPlayerNum, OUTPUT DATASET dsplayer, OUTPUT DATASET dsgame).
 
    FOR EACH ttplayer NO-LOCK:
        DISPLAY ttplayer.
    END.
    
    FOR EACH ttplayer EXCLUSIVE-LOCK:
        ttplayer.PlayerUsername = "Grubby".
    END.
    
/*    FOR EACH ttplayer EXCLUSIVE-LOCK:*/
/*        DELETE ttplayer.             */
/*    END.                             */
    
    
END PROCEDURE.


