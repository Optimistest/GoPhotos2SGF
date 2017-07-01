# GoPhotos2SGF
Matlab code to extract a game record (SGF) from a series of photos of the board game Go. Finds the most likely legal sequence of moves.  Code to accompany the paper "Making Real Games Virtual: Tracking Board Game Pieces" ICPR 2008 by Scher, Crabb, and Davis at UCSC.

Apologies, I wrote this code 10 years ago for a class project, it's definitely research code, meaning it worked just well enough to write the paper, every element of it can be easily improved, and it's poorly commented and uses global variables :(  I don't have a copy of Matlab now, so I don't even know if this runs on modern Matlab. The repository that used to host this disappeared.

If this code is somehow useful to anyone in any way, please be my guest, you have my permission.  It would be great to hear from you about it at sscher@soe.ucsc.edu
-Steve Scher

The main script to run is GoAnalyzeImages5.m
  - Looks through a specified folder for photos of a go game

  - Finds the go board in the first photo:
    * detecting lines with MyLineDetector4.m
    * finding an appropriate set of lines with GuessSpacingRansac.m
    * saving calibration information into a file Lfull.mat
    * shows the photo with the identified grid with GoWarpBoard.m

  - Pre-processing each photo
    * converts to HSV colorspace
    * warps the board area to a square with GoWarpBoard.m
    * runs a pixelwise median-filter on the time-dimension with medianHSV to remove obscuring hands and shadows

  - For each photo (time), for each intersection on the board, assign probabilities between [empty, black stone, white stone] using GoDetectStonesSVM2.m
    * make pixelwise prediction probabilities pEmpty, pBlack, pWhite with an SVM
    * Make a mask of pixels to ignore. Ignore pixels more than a stone-radius away from any intersection.
    * Loop, greedily finding the most-confident stone detected on the board
      + For each intersection, find the pixels within a circle slightly smaller than a stone, and find the probability of a black stone and a white stone as the 90th-percentile highest probability among those pixels.
      + Find the most-likely stone: choose the intersection with the highest 90th-percentile probability, either black or white.
      + Find the center of the stone: of the pixels in a circle around that intersection, find the highest-probability pixel.
      + Add to the mask of pixels to ignore: an area slightly larger than a stone around the detected stone. This helps avoid spuriously detecting the same stone twice.
    * saves the probabilities in probs.mat
    * shows a video of the photos and detection probabilities

  - Find the most likely legal sequence with ChooseNextMoveAstar2.m
    * To deal with limited memory, loop to find the jth best move, considering photos j to j+N
    * ChooseNextMoveAstar2 uses the standard A* algorithm
    * The A* admissible heuristic ScoreEstimate gives a conservative estimate for unexplored nodes by ignoring limitations on legal move sequences, and considering independently, for each photo, for each intersection, the most-likely state of that intersection (black stone, white stone, empty) according to the SVM stone detector.
    * maintain a global queue QueueOfNodes of unfinished nodes (with move histories less than the full length of the sequence) for possible expansion, and keep track of the best full-length sequence found so far BestFinishedNode
      + each node represents a possible move sequence for the first "depth" timesteps of the N time steps we'll consider
      + the score for this node is the actual score of the actual board states chosen, plus the heuristic ScoreEstimate for the later unexamined moves. Lower is better.
      + each nodes keeps track of the board state including which player's turn it is and a list of dead stones waiting to be removed, the score, move history, and a Zobrist hash for quickly checking transpositions.
      + start with a node for the empty board

    * In the main loop, call subfunction ExpandNode on the node with the best score. This is the node containing the subsequence whose continuation is most likely to be the optimal full sequence. Stop the loop when the unfinished node with the best score isn't as good as the best finished node. This will eventually find the full-length move sequence with the best score, and eventually the best unfinished node (and therefore all other possible unfinished nodes) will be seen to have no possible continuations that could be better, and the algorithm will return.
      + Score this node
      + Find legal continuation moves, and add them as nodes to the queue with subfunction InsertNode
        # don't insert transpositions (getting to the same board state via different sequences) with worse scores
        # if the move history is the full-length of the sequence we're looking for, don't insert it if its score is worse than the BestFinishedNode score
        # GoCheckDeadStonesCausedBy this move and add them to the list of dead stones to be removed
      + "legal" continuations are:
        # a repetition of the current board state for an additional time step
        # if there are dead stones waiting to be removed from the board after an earlier capture, the only "legal moves" considered are to remove one of the dead stones.
        # otherwise, placing a stone of the correct color for the player whose turn it is, on any empty intersection such that the group of stones to which the new stone belongs either (1) has a liberty or (2) captures stones.  Found  with GoFindLegalMoves
        # at the beginning of the game, placing handicap stones is allowed.
