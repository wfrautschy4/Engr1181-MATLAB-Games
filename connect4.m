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
    xlabel("");
    [winner] = startGame(game, players_turn);
    
    if (winner == 1)
        title("You Won!");
        xlabel("Click to play again!");
    elseif (winner == -1)
        title("You Lost!");
        xlabel("Click to play again!");
    else
        title("You tied!");
        xlabel("Click to play again!");
    end

    pause(5);
    getMouseInput(game);
end


%-------------------------------Functions--------------------------------%
function [winner] = startGame(game, players_turn)
    game.zoom = 9;
    
    Board = drawBoard(6,7,61); %Draw Blank Board
    drawScene(game, Board);
    
    RED = 62; %Player
    BLACK = 63; %AI

    game_running = true;
    
    while game_running
        if (players_turn)
            title("Your Turn!");
            [~,c] = getMouseInput(game); 
                   
            while(~isColumnOpen(c,Board)) %Wait for valid move
                [c] = getMouseInput(game);
            end
    
            Board = addPieceToColumn(c, RED, Board);
    
            players_turn = 0;
        else
            title("Opponent's Turn...");
            board = normalizeBoard(Board);
            
            %Time AI on how long calculation takes
            tic
            [c, score] = search(board, 4, true); %Call minimax to find the best move
            toc

            fprintf("The bot choses to go to Col:%i with a Score of %.2f\n", c, score)
    
            pause(0.5);
            
            Board = addPieceToColumn(c, BLACK, Board);
    
            players_turn = 1;
        end
        
        drawScene(game,Board);
    
        %Check for Winner
        [winner] = checkForWinner(Board);
        
        if(~isnan(winner))
            game_running = false;
        end
    end
end
function [winner] = checkForWinner(board)
    board = normalizeBoard(board);
    winner = NaN;
    %location = 0;
    %Check if board is full
    if (isempty(find(board == 0, 1))) 
        winner = 0;
    end

    %Check Horizontal
    for r=1:6
        for w=1:4 %Wiggle in the Row
            if((max(board(r,w:w+3))- min(board(r,w:w+3))) == 0 && board(r,w) ~= 0)
                winner = board(r,w);
                %location = [r,w;r,w+1;r,w+2;r,w+3];
                return
            end
        end
    end

    %Check Vertical
    for c=1:7
        for w=1:3 %Wiggle in the Column
            if((max(board(w:w+3,c)) - min(board(w:w+3,c))) == 0 && board(w,c) ~= 0)
                winner = board(w,c);
                %location = [w,c;w+1,c;w+2,c;w+3,c];
                return
            end
        end
    end

    %Check Diagonal
    for diagLength=[4,5,6] %Diag Lengths
        diagRows = zeros(4,diagLength); %Init tempRow

        
        for diagPos=1:diagLength 
           %Left Bottom
           diagRows(1,diagPos)= board(diagPos+(6-diagLength),diagPos);
           %Left Top
           diagRows(2,diagPos)= board(diagPos,(diagPos+(7-diagLength)));
           %Right Bottom
           diagRows(3,diagPos)= board(diagPos+(6-diagLength),8-diagPos);
           %Right Top
           diagRows(4,diagPos)= board(diagPos,diagLength-diagPos+1);
        
        end
        %Check for matches in diagRows
        for r=1:4
            for w=1:(diagLength-3)
                if((max(diagRows(r,w:w+3)) - min(diagRows(r,w:w+3)))==0 && diagRows(r,w) ~= 0)
                    winner = diagRows(r,w);
                end
            end
        end
    end
end
%------------------------AI FUNCTIONS----------------------------%
function [score] = scoreRow(row,piece) % Score that should be returned for Matches

    oppPiece    = (piece*-1);
    numPieces   = length(find(row == piece));
    numoppPiece = length(find(row ==oppPiece));
    numOpen     = length(find(row == 0));

    score = 0;
    
    PRIORITY_EXTREME = 100;
    PRIORITY_HIGH = 5;
    PRIORITY_BETTER = 4;
    PRIORITY_NORMAL = 3;
    PRIORITY_LOW = 1;

    %Matches for Player
    if(numPieces == 4)
        score = score+PRIORITY_EXTREME; %Score of 100 for 4 in-a-row
    elseif (numPieces == 3 && numOpen == 1)
        score = score+PRIORITY_HIGH;  %Score of 10  for 3 in-a-row
    elseif (numPieces == 2 && numOpen ==2)
        score = score+PRIORITY_NORMAL;   %Score of 2   for 2 in-a-row
    end
    
    %Matches for opponent
    if(numoppPiece == 3 && numOpen == 1)%If making the move will give opponent the win
        score = score - PRIORITY_BETTER;
    end
end

function [col, bestScore] = search(board, depth, isMaximizing)
    col = randi(7,1,1); %Pick random move to begin
    while (~isColumnOpen(col,board))
        col = randi(7,1,1);
    end 
    winner = checkForWinner(board);

    if (winner ==1)
        bestScore = -100000000;
        return
    elseif(winner==-1)
        bestScore = 100000000;
        return
    elseif (depth == 0)
        bestScore = scoreBoard(board, -1);                  
        return
    end

    if (isMaximizing)  
        
        bestScore = -Inf;
        for c=1:7
            if(isColumnOpen(c, board))
                board = addPieceToColumn(c,-1,board);
                [~, searchScore] = search(board, depth-1, false); 
                board = removePieceFromColumn(c,board);
                
                if(searchScore > bestScore)
                    bestScore = searchScore;
                    col = c;
                end
            end
        end
        
    else
        bestScore = Inf;
        for c=1:7
            if(isColumnOpen(c, board))
                board = addPieceToColumn(c,1,board);
                [~, searchScore] = search(board, depth-1, true);
                board = removePieceFromColumn(c,board);
    
                if (searchScore < bestScore)
                    bestScore = searchScore;
                    col = c;
                end
            end
        end
    end
end
function [score] = scoreBoard(board, piece)
    %Return higher scores for greater # of combined pieces
    score = 0;

    %Score Horizontal
    for r=1:6
        for w=1:4 %ColumnCount-3
            %Create Temp 4 Row and score by combinations
            row = board(r,w:w+3);
            score = score + scoreRow(row,piece);
        end
    end

    %Score Vertical
    for c=1:7
        for w=1:3 %RowCount-3
           col = board(w:w+3,c);
           score = score + scoreRow(col,piece);
        end
    end

    %Score Diagonal
    for diagLength=[4,5,6] %Diag Lengths
        diagRows = zeros(4,diagLength); %Init tempRow

        %This was easily the biggest pain in my ass while making this
        for diagPos=1:diagLength 
           %Left Bottom
           diagRows(1,diagPos)= board(diagPos+(6-diagLength),diagPos);
           %Left Top
           diagRows(2,diagPos)= board(diagPos,(diagPos+(7-diagLength)));
           %Right Bottom
           diagRows(3,diagPos)= board(diagPos+(6-diagLength),8-diagPos);
           %Right Top
           diagRows(4,diagPos)= board(diagPos,diagLength-diagPos+1);
        end
        
        %Check for matches in diagRows
        for r=1:4
            for w=1:(diagLength-3)
                row = diagRows(r,w:w+3);
                score = score + scoreRow(row,piece);
            end
        end
    end
end
%--------------------------Misc Functions----------------------------%
function [bool] = isColumnOpen(c, board)
    Board = normalizeBoard(board);
    column = Board(:,c);
    bool = false;
    %If top of column is open than it's valid
    if column(1) == 0 
        bool = true;
    end
end
function [board] = addPieceToColumn(c,piece,board)
    for r=6:-1:1
        if (board(r,c) == 61 || board(r,c) == 0) %If space is empty
            board(r,c) = piece; %Assign slot with lowest spot
            break;
        end  
    end
end
function [board] = removePieceFromColumn(c,board) %Only used with normalized Board
    for r=1:6
        if(board(r,c) ~= 0)
            board(r,c) = 0; %Make top piece in column disappear
            break;
        end
    end
end
function [board] = normalizeBoard(board)
    for r=1:6
        for c=1:7
            if (board(r,c) == 62)     %Player Piece
               board(r,c) = 1; 
            elseif (board(r,c) == 63) %AI Piece
                board(r,c) = -1;
            elseif (board(r,c) == 61) %Blank Space
                board(r,c) = 0;
            end
        end
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