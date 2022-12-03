//server interface
BLOCK-LEVEL ON ERROR UNDO, THROW.

USING server.BL.BEPlayer FROM PROPATH.
USING server.BL.BEGame FROM PROPATH.

{common/include/dsPlayer.i}
{common/include/dsGame.i}




PROCEDURE FetchPlayerAndGame:
    DEFINE INPUT PARAMETER piPlayerNum AS INTEGER NO-UNDO.
    DEFINE OUTPUT PARAMETER DATASET FOR dsPlayer.
    DEFINE OUTPUT PARAMETER DATASET FOR dsGame.
    
    DEFINE VARIABLE bePlayer AS BEPlayer NO-UNDO.
    DEFINE VARIABLE beGame   AS BEGame   NO-UNDO.
    
    bePlayer = NEW BEPlayer().
    beGame = NEW BEGame().
    
    bePlayer:FetchPlayer(INPUT piPlayerNum, OUTPUT DATASET dsPlayer BY-REFERENCE).
    beGame:FetchGame(INPUT piPlayerNum, OUTPUT DATASET dsGame BY-REFERENCE).

    FINALLY:
        DELETE OBJECT bePlayer NO-ERROR.
        DELETE OBJECT beGame NO-ERROR.
    END.
        
END PROCEDURE.


PROCEDURE SubmitPlayerAndGame:
    DEFINE INPUT-OUTPUT PARAMETER DATASET FOR dsPlayer.
    DEFINE INPUT-OUTPUT PARAMETER DATASET FOR dsGame.
    
  
    DEFINE VARIABLE iPlayerNum AS INTEGER  NO-UNDO. 
    DEFINE VARIABLE bePlayer   AS BEPlayer NO-UNDO.
    DEFINE VARIABLE beGame     AS BEGame   NO-UNDO.
    DEFINE VARIABLE iNum       AS INTEGER  NO-UNDO.
    
    bePlayer = NEW BEPlayer().
    beGame = NEW BEGame().
    
    DO TRANSACTION:
        bePlayer:SubmitPlayer(INPUT-OUTPUT DATASET dsplayer BY-REFERENCE).
    
        FIND LAST ttplayer NO-LOCK NO-ERROR.
        IF AVAILABLE(ttplayer) THEN
      
            iNum = ttplayer.PlayerNum.
        
        FOR EACH ttgame NO-LOCK.
            ttgame.PlayerNum = iNum.

        END.

        beGame:SubmitGame(INPUT-OUTPUT DATASET dsGame BY-REFERENCE).

    END.
    
    CATCH e AS Progress.Lang.Error :
        MESSAGE e:GetMessage(1)
            VIEW-AS ALERT-BOX. 
    END CATCH.
    
    FINALLY:
        DELETE OBJECT bePlayer NO-ERROR.
        DELETE OBJECT beGame NO-ERROR.
    END.    
    
END PROCEDURE.