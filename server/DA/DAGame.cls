USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS server.DA.DAGame: 
    {common/include/dsGame.i}
    //method to fetch a game record from the database
    METHOD PUBLIC VOID FetchGame(INPUT piPlayerNum AS INTEGER, OUTPUT DATASET dsGame):
        DATASET dsgame:EMPTY-DATASET ().
        FOR EACH Game NO-LOCK 
            WHERE Game.PlayerNum = piPlayerNum:

            CREATE ttgame.
            BUFFER-COPY Game TO ttgame.

        END.
        
    END METHOD.
    //method to submit game records into the database
    METHOD PUBLIC VOID SubmitGame(INPUT-OUTPUT DATASET dsGame):
        
        //row-created
        FOR EACH ttgame NO-LOCK
            WHERE ROW-STATE(ttgame) = ROW-CREATED:
            
            CREATE Game.
            BUFFER-COPY ttgame EXCEPT GameNum TO Game.
            
            ASSIGN 
            Game.GameNum = NEXT-VALUE(NextGameNum)
            ttgame.GameNum = Game.GameNum.
            
        END.
           
        //row-modified
        FOR EACH ttgame NO-LOCK
            WHERE ROW-STATE(ttgame) = ROW-MODIFIED:
                
            FOR EACH game EXCLUSIVE-LOCK 
                WHERE Game.GameNum = ttgame.gamenum:
                BUFFER-COPY ttgame EXCEPT gamenum TO Game.
                
            END.
        END.
    
    //row-deleted
        FOR EACH bttgame NO-LOCK
            WHERE ROW-STATE(bttgame) = ROW-DELETED.
    
            FOR EACH Game EXCLUSIVE-LOCK
                WHERE Game.GameNum = bttgame.gamenum:
                DELETE Game.
            END.
        END.
        
        DATASET dsgame:ACCEPT-CHANGES ().
        
    END METHOD.
    

END CLASS.