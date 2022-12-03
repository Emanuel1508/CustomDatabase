
USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS server.DA.DaPlayer: 
    {common/include/dsPlayer.i}
    //method to fetch a record from the database
    METHOD PUBLIC VOID FetchPlayer(INPUT piPlayerNum AS INTEGER, OUTPUT DATASET FOR dsPlayer):
        
        DATASET dsPlayer:EMPTY-DATASET().
     
        FOR EACH player NO-LOCK 
            WHERE player.playernum = piPlayernum:
            CREATE ttplayer.
            BUFFER-COPY player TO ttplayer.
        END.

    END METHOD.
    
    //method for submiting players to the database
    METHOD PUBLIC VOID SubmitPlayer(INPUT-OUTPUT DATASET dsPlayer):
        
        //row-created 
        FOR EACH ttplayer
            WHERE ROW-STATE(ttplayer) = ROW-CREATED:
                
            CREATE Player.
            BUFFER-COPY ttplayer EXCEPT PlayerNum TO Player.
            ASSIGN 
                Player.PlayerNum   = NEXT-VALUE(NextPlayerNum)    
                ttplayer.playernum = Player.PlayerNum    
                .
            LEAVE.
                
        END.
        
        //row-modified
        FOR EACH ttplayer
            WHERE ROW-STATE(ttplayer) = ROW-MODIFIED:
                
            FOR EACH Player EXCLUSIVE-LOCK 
                WHERE Player.PlayerNum = ttplayer.playernum:
                BUFFER-COPY ttplayer EXCEPT playernum TO Player.
            END.
        END.
        
        
        //row-deleted
        FOR EACH bttplayer
            WHERE ROW-STATE(bttplayer) = ROW-DELETED:
                
            FOR EACH Player EXCLUSIVE-LOCK
                WHERE Player.PlayerNum = bttplayer.playerNum:
                DELETE Player.
            END.
        END.
        
        DATASET dsplayer:ACCEPT-CHANGES ().
        
    END METHOD.

END CLASS.