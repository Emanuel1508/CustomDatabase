USING Progress.Lang.*.
USING server.DA.DAGame FROM PROPATH.
USING server.BL.BEPlayer FROM PROPATH.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS server.BL.BEGame: 
    {common/include/dsGame.i}
    {common/include/dsPlayer.i}
    
    DEFINE VARIABLE cFinalMessage AS CHARACTER NO-UNDO.
    
    DEFINE PROPERTY bePlayer AS BEPlayer NO-UNDO
        GET:
            IF NOT VALID-OBJECT(bePlayer) THEN
                bePlayer = NEW BEPlayer().
        
            RETURN bePlayer.
        
        END GET.    
        SET.
    
    DEFINE PROPERTY daGame AS DAGame NO-UNDO
        GET:
            IF NOT VALID-OBJECT(daGame) THEN
                daGame = NEW DAGame().
            
            RETURN daGame.
        END GET.
        SET.
        
    METHOD PUBLIC VOID FetchGame(INPUT piPlayerNum AS INTEGER, OUTPUT DATASET FOR dsGame):
        daGame:FetchGame(INPUT piPlayerNum, OUTPUT DATASET dsGame BY-REFERENCE).
    END METHOD.      
    
    
    //method to submit the game records if they pass the validations
    METHOD PUBLIC VOID SubmitGame(INPUT-OUTPUT DATASET dsGame):
        cFinalMessage = "".
        cFinalMessage = ValidateRecords(INPUT-OUTPUT DATASET dsgame). //calling the validation function
            
        IF cFinalMessage <> "" THEN //if there are error messages throw an apperror
            UNDO, THROW NEW AppError(cFinalMessage, 1).
            

        daGame:SubmitGame(INPUT-OUTPUT DATASET dsgame BY-REFERENCE).
        
        
    END METHOD.
    
    //method to validate the game records
    METHOD PUBLIC CHARACTER ValidateRecords(INPUT-OUTPUT DATASET FOR dsgame): 
        DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
        //row-created validations
        FOR EACH ttgame NO-LOCK
            WHERE ROW-STATE(ttgame) = ROW-CREATED:

            beplayer:FetchPlayer(INPUT ttgame.playernum, OUTPUT dataset dsPlayer BY-REFERENCE). //looking if a player with a certain playernum exists

             
            IF NOT CAN-FIND(LAST ttplayer WHERE ttplayer.playernum = ttgame.playernum) THEN
                cFinalMessage = cFinalMessage + substitute("The player (&1) that you're trying to register the game for, doesn't exist in the database", ttgame.playernum) + chr(10).
                
            cFinalMessage = cFinalMessage + ValidateGameLength(INPUT ttgame.GameLength).
            cFinalMessage = cFinalMessage + ValidatePlayerScore(INPUT ttgame.PlayerScore).
            cFinalMessage = cFinalMessage + ValidateGameResult(INPUT ttgame.GameResult).
        END.
        
        //row-modified validations
        FOR EACH ttgame NO-LOCK
            WHERE ROW-STATE(ttgame) = ROW-MODIFIED:
                
            FIND FIRST bttgame NO-LOCK WHERE
                ROWID(bttgame) = BUFFER ttgame:BEFORE-ROWID NO-ERROR.
                
            IF AVAILABLE bttgame THEN            
            DO :                
                cFinalMessage = cFinalMessage + ValidateGameLength(INPUT ttgame.GameLength).
                cFinalMessage = cFinalMessage + ValidatePlayerScore(INPUT ttgame.PlayerScore).
                cFinalMessage = cFinalMessage + ValidateGameResult(INPUT ttgame.GameResult).
            END. 
        END.
        
        RETURN cFinalMessage.
            
    END METHOD.
    
    //validation methods
    METHOD PUBLIC CHARACTER ValidateGameLength(INPUT iLength AS INTEGER):
        DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
        cMessage = "".
  
        IF iLength < 25 THEN
            cMessage = cMessage + substitute("All games have at least a duration of 25 minutes, this one can't be &1 minutes long", iLength) + chr(10).
    
        IF iLength > 45 THEN 
            cMessage = cMessage + substitute("The game time limit is 45 minutes, the value &1 is not valid", iLength) + chr(10).
            
        RETURN cMessage.
        
    END METHOD.
   
   //playerscore
    METHOD PUBLIC CHARACTER ValidatePlayerScore(INPUT iScore AS INTEGER):
        DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
        cMessage = "".
        
        IF iScore < 0 THEN
            cMessage = cMessage + substitute("The score can't be negative, the value: &1 is invalid", iScore).

        RETURN cMessage.
    END METHOD.
    
    //gameresults
    METHOD PUBLIC CHARACTER ValidateGameResult(INPUT cResult AS CHARACTER):
        DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
        cMessage = "".
        
        IF cResult <> "Victory" AND cResult <> "Defeat" AND cResult <> "Draw" THEN
            cMessage = cMessage + substitute("The game can only be won/lost or tied, value &1 is not valid", cResult).
        
        RETURN cMessage.
    END METHOD.
  

//destructor
    DESTRUCTOR BEGame():
        DELETE OBJECT daGame NO-ERROR.
        DELETE OBJECT bePlayer NO-ERROR.
    END.
END CLASS.