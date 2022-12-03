USING Progress.Lang.*.
USING server.DA.DaPlayer FROM PROPATH.
USING server.BL.BEGame FROM PROPATH.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS server.BL.BEPlayer: 
    {common/include/dsPlayer.i}
    {common/include/dsGame.i}
    
    DEFINE VARIABLE cOutputMessage AS CHARACTER NO-UNDO.
    
    DEFINE PROPERTY beGame AS BEGame
        GET:
            IF NOT VALID-OBJECT(beGame) THEN
                beGame = NEW BEGame().
        END GET.
        SET.
    
    DEFINE PROPERTY daPlayer AS DAPlayer
        GET:
            IF NOT VALID-OBJECT(daPlayer) THEN
                daPlayer = NEW DAPlayer().
        
            RETURN daPlayer. 
        END GET.
        SET.
        
    METHOD PUBLIC VOID FetchPlayer(INPUT piPlayerNum AS INTEGER, OUTPUT DATASET FOR dsPlayer):
        daPlayer:FetchPlayer(INPUT piPlayerNum, OUTPUT dataset dsPlayer).
    END METHOD.
    
    METHOD PUBLIC VOID SubmitPlayer(INPUT-OUTPUT DATASET FOR dsPlayer):
        cOutputMessage = ValidateRecords(INPUT-OUTPUT DATASET dsplayer).
            
        IF cOutputMessage <> "" THEN 
            UNDO, THROW NEW AppError(cOutputMessage, 1).
            
        daPlayer:SubmitPlayer(INPUT-OUTPUT DATASET dsPlayer BY-REFERENCE).                     
        
        
    END METHOD.
    
//final validation method
    METHOD PUBLIC CHARACTER ValidateRecords(INPUT-OUTPUT DATASET dsplayer):
        DEFINE VARIABLE cOutputMessage AS CHARACTER NO-UNDO.
        
        //row-created
        FOR EACH ttplayer NO-LOCK
            WHERE ROW-STATE(ttplayer) = ROW-CREATED.
            cOutputMessage = cOutputMessage + ValidatePlayerUsername(INPUT ttplayer.PlayerUsername).   
            cOutputMessage = cOutputMessage + ValidatePlayerAge(INPUT ttplayer.PlayerAge).
            cOutputMessage = cOutputMessage + ValidatePlayerRanking(INPUT ttplayer.PlayerRating, INPUT ttplayer.PlayerRank).
      
        END.
        
        //row-modified
        FOR EACH ttplayer NO-LOCK
            WHERE ROW-STATE(ttplayer) = ROW-MODIFIED.
            
            FIND FIRST bttplayer NO-LOCK
                WHERE ROWID(bttplayer) = BUFFER ttplayer:BEFORE-ROWID NO-ERROR.
            
            IF AVAILABLE bttplayer THEN
            DO:            

                FIND FIRST Player NO-LOCK WHERE Player.PlayerUsername = ttplayer.PlayerUsername NO-ERROR.
                IF AVAILABLE Player THEN 
                    cOutputMessage = cOutputMessage + substitute("The username: &1 is already taken", ttplayer.PlayerUsername).
                cOutputMessage = cOutputMessage + ValidatePlayerUsername(INPUT ttplayer.PlayerUsername).   
                cOutputMessage = cOutputMessage + ValidatePlayerAge(INPUT ttplayer.PlayerAge).
                cOutputMessage = cOutputMessage + ValidatePlayerRanking(INPUT ttplayer.PlayerRating, INPUT ttplayer.PlayerRank).
            END.
        END.
            
        
        //row-deleted
        FOR EACH bttPlayer NO-LOCK 
            WHERE ROW-STATE(ttplayer) = ROW-DELETED:
            begame:FetchGame(bttplayer.playernum, OUTPUT DATASET dsGame).
            
            FIND FIRST ttgame NO-LOCK NO-ERROR. //we check if the player has games registered
            IF CAN-FIND(FIRST ttgame WHERE ttgame.playernum = ttplayer.playernum) THEN
                cOutputMessage = cOutputMessage + "The player still has game registered. He can't be deleted" + chr(10).
        
        END.
        
        RETURN cOutputMessage.
        
        
        END METHOD.
    
    //method necessary to validate the player username.
        METHOD PUBLIC CHARACTER ValidatePlayerUsername(INPUT cUserName AS CHARACTER):
            DEFINE VARIABLE cMessage           AS CHARACTER NO-UNDO.
            DEFINE VARIABLE iSpecialCharacters AS CHARACTER NO-UNDO INITIAL "! @ # $ % ^ & * ( ) _ + - = [ ] \ ; ' . , / < > ? : ' ".  
            DEFINE VARIABLE iIterator          AS INTEGER   NO-UNDO.
            DEFINE VARIABLE cCharacter         AS CHARACTER NO-UNDO.
        
            cMessage =  "".

            IF cUserName = "" THEN
            DO:
                cMessage = cMessage + "The player username can't be empty" + chr(10).
                RETURN cMessage.
            END.
        
            DO iIterator = 1 TO LENGTH(cUserName):
            
                cCharacter = SUBSTRING(cUserName, iIterator, 1).
            
                IF LOOKUP(cCharacter, iSpecialCharacters, " ") > 1 OR cCharacter = " " THEN
                    cMessage = cMessage + "The player username can't contain special characters or white spaces" + chr(10).
                
            END.

            RETURN cMessage.

        END METHOD.
    
    //method to validate the player age
        METHOD PUBLIC CHARACTER ValidatePlayerAge(INPUT iPlayerAge AS INTEGER):
            DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
            cMessage = "".
        
            IF iPlayerAge < 0 THEN
            DO:
                cMessage = cMessage + substitute("The player hasn't been born yet: &1 introduced", iPlayerAge) + chr(10).
                RETURN cMessage.
            END.
        
            IF iPlayerAge < 18 THEN
                cMessage = cMessage + substitute("The player is too young to play, he's just &1 years old", iPlayerAge) + chr(10).
        
            IF iPlayerAge > 39 THEN
                cMessage = cMessage + substitute("We don't think that a &1 years old person would be interested in this", iPlayerAge) + chr(10).
                     
            RETURN cMessage.
  
        
        END METHOD.
        
        //method to validate the player ranking
        METHOD PUBLIC CHARACTER ValidatePlayerRanking(INPUT iRating AS DECIMAL, INPUT cRankName AS CHARACTER):
            DEFINE VARIABLE cMessage AS CHARACTER NO-UNDO.
            cMessage = "".
        
            IF cRankName = "" THEN
                cMessage = cMessage + "The player must have a ranking" + chr(10).
        
            IF iRating < 0 THEN
                cMessage = cMessage + "The rating can't be a negative value" + chr(10).
        
            IF iRating < 40 AND cRankName <> "Grass" THEN
                cMessage = cMessage + "The player has under 40 rating points, he must placed in the grass division" + chr(10).
        
            IF iRating > 40 AND iRating < 60 AND cRankName <> "Silver" THEN
                cMessage = cMessage + "The player has the rating between 40 and 60, he must be placed in the silver division" + CHR(10).
        
            IF iRating > 60 AND iRating < 80 AND cRankName <> "Gold" THEN
                cMessage = cMessage + "The player has rating between 60 and 80, he must be placed in the gold division" + CHR(10).
        
            IF iRating > 80 AND cRankName <> "Platinum" THEN 
                cMessage = cMessage + "The player has more than 80 points, he must be placed in the platinum division" + CHR(10).
            
            IF iRating > 100 THEN
                cMessage = cMessage + "The player rankking can't be more than 100 points" + CHR(10).

            RETURN cMessage.
        END METHOD.
        
        
        DESTRUCTOR BEPlayer():
            DELETE OBJECT daPlayer NO-ERROR.
            DELETE OBJECT begame NO-ERROR.
        END.
    
    END CLASS.