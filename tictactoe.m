%Clear Console and Variables
clc
clear 
close all

%Initialize SimpleGameEngine
game = simpleGameEngine('sprites.png',20,20,4, [27,117,208]);

%-----------Welcome Screen------------

%Initialize Matrix of the Board (Sprite ID's)
Board = drawBoard(10,20,1);
Board(3,:) = [linspace(1,1,6),24,6,13,4,16,14,6,28,linspace(1,1,6)];                          %Welcome!
Board(6,:) = [linspace(1,1,3),4,13,10,4,12,1,21,16,1,17,13,2,26,28,linspace(1,1,3)];          %Click to Play!


%Draw Initial Scene onto Board
drawScene(game, Board);
title("Welcome!");


%Wait for mouse Input
getMouseInput(game);

%-----------Dice Roll to Determine who goes first---------------------%

players_turn = 1; % player always goes first

%-----------Play Game-------------

while true

    [winner] = startGame(game, players_turn);
    
    %Congratulate whoever wins
    if(winner == 1)
        title("You Won!");
        xlabel("Click to play again!")
    elseif (winner == -1)
        title("You Lost!");
        xlabel("Click to play again!")
    else
        title("It's a Tie!");
        xlabel("Click to play again!")
    end
    getMouseInput(game);
    title("");
    xlabel("");

end

%------------Functions------------------
function [winner] = startGame(game, players_turn)
    game.zoom = 10;
    game.background_color = [255,255,255];
    
    %Initialize Board Matrix
    Board = drawBoard(3,3,66);
    
    %Draw Game scene
    drawScene(game, Board);
    
    %Init Variables
    game_running = 1;
    O = 65; %Player
    X = 64; %AI
    
    %Run the Game
    while game_running
        
        if (players_turn) %Player's Turn
            title("Your Turn!");
            [r,c] = getMouseInput(game);
               
            while(~isSpotOpen(r,c,Board))
                 [r,c] = getMouseInput(game);
            end
            
            Board(r,c) = O;
            players_turn = 0; %Switch turns
        else %AI Turn
            
            title("Opponent's Turn...");
            [r,c] = makeAIMove(Board);
            pause(1);
            Board(r,c) = X;
    
            players_turn = 1; %Switch turns
        end                                                                                                                                                                         
        
        drawScene(game, Board); %Append results to UI
        
        
        %Check if a match was made
        [winner, location] = isWinner(Board);
        if(~isnan(winner))
            game_running = false;
            drawWinningLines(game, Board, location)
        end
    end
end

function [winner,location] = isWinner(board)
    board = switchBoards(board);
    winner = NaN; %No winner
    location(3,2) = 0; %3x2 matrix of spaces where match was made
    
    if (isempty(find(board == 0, 1))) 
        winner = 0;
        location = 0;
    end
    for i=1:3 
        % Check rows using max() and min() instead of range()
        if ((max(board(i,:)) - min(board(i,:))) == 0 && board(i,1) ~= 0)
            winner = board(i,1);
            location = [i,1;i,2;i,3 ];
        end
        % Check columns using max() and min() instead of range()
        if ((max(board(:,i)) - min(board(:,i))) == 0 && board(1,i) ~= 0)
            winner = board(1,i);
            location = [1,i;2,i;3,i];
        end
    end
    %Check diagonals
    downright(3) =0;
    downleft(3) =0;
    for i=1:3
        downright(i) = board(i,i);
        downleft(i) = board(i,4-i);
    end
    % Check diagonals using max() and min() instead of range()
    if ((max(downright) - min(downright)) == 0 && downright(1) ~= 0)
        winner = board(1,1);
        location = [1,1;2,2;3,3];
        
    elseif((max(downleft) - min(downleft)) == 0 && downleft(1) ~= 0)
        winner = board(1,3);
        location = [1,3;2,2;3,1];    
    end
end
%----------------------AI Recursion Functions----------------------------%
function [r,c] = makeAIMove(board)   
    bestScore = -Inf;
    move=[1,1];
    for i=1:3
        for j=1:3
            if(isSpotOpen(i,j,board)) 
                board(i,j) = 64; %Move piece to every open spot
                score = minimax(board, 0, 0); %Check score if AI moves to space (i,j)
                board(i,j) = 66; %Remove piece before moving to next
                if score > bestScore
                    bestScore = score;
                    move(1)=i;
                    move(2)=j;
                end
            end
        end
    end
    r = move(1);
    c = move(2);
end

function [returnscore] = minimax(board, depth, isMaximizing)
    [winner] = isWinner(board);
    
    if(~isnan(winner)) %Recurrsion collapses
        if (winner==-1)
            returnscore = 10; return %Win
        elseif (winner==1)
            returnscore = -10; return %Loss
        else
            returnscore = 0; return  %Tie
        end
    end
    if(isMaximizing)
        bestScore = -Inf;
        for i=1:3
            for j=1:3
                if(isSpotOpen(i,j,board)) 
                    board(i,j) = 64; %Move piece
                    score = minimax(board, depth+1, 0); 
                    board(i,j) = 66; %Remove piece
                    bestScore = max(bestScore,score);
                end
            end
        end
        returnscore = bestScore;
        
    else
        bestScore = Inf;
        for i=1:3
            for j=1:3
                if(isSpotOpen(i,j,board)) 
                    board(i,j) = 65; %Move piece
                    score = minimax(board, depth+1, 1); 
                    board(i,j) = 66; %Remove piece
                    bestScore = min(bestScore, score);
                end
            end
        end
        returnscore = bestScore;
    end
end
    
%-------------------Misc Functions------------------------------------%
function [newboard] = switchBoards(board)
    newboard(3,3) = 0;
    for i=1:3
        for j=1:3
            if board(i,j) == 66
                newboard(i,j) = 0;  %  0 = Blank
            elseif board(i,j) == 65
                newboard(i,j) = 1;  %  1 = Player
            elseif board(i,j) == 64
                newboard(i,j) = -1; % -1 = AI
            end
        end
    end
end
function [boolean] = isSpotOpen(row,column,board)
    if (row ==0 || column == 0)%If out of index
        boolean = 0;
    elseif (board(row,column) == 66 || board(row,column) == 0) 
        boolean = 1;           %Space is empty
    else          
        boolean = 0;           %Space is taken
    end
end

function [board] = drawBoard(rows,columns,value)
    board(rows, columns)=0;
    for i=1:rows
        for j=1:columns
            board(i,j) = value;
        end
    end
end
function [] = drawWinningLines(game, Board, location)
    %Draw Lines onto winning spaces
    if (location ~= 0)
        %Determine which sprite to draw
        if(max(location(:,1)) - min(location(:,1)) == 0) %Horizontal
            cross = 69;
        elseif (max(location(:,2)) - min(location(:,2)) == 0) %Vertical
            cross = 70;
        elseif (location(1,:) == [1,3])
            cross = 67;
        else
            cross = 68;
        end
        %Create topspirte sheet
        topsprites = drawBoard(3,3,1);
        for i=1:3
            topsprites(location(i,1),location(i,2)) = cross;
        end
    
        %DrawScene them onto page
        drawScene(game,Board,topsprites);
    end
end
