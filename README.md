KenKenSolver
============

A KenKen solver written in Ruby. KenKen is a Sudoku-like puzzle with some math added. In addition to having a square grid where each row and column must have every digit exactly once, there are blocks (or cages) that have a number and a mathematical operator associated with them. After applying the operator to the number in the block (cage), the number associated with the block should be obtained. There are no numbers filled in to get you started (unlike Sudoku).

A sample 5x5 grid with plus, minus, divide and multipy operators is -  

<p>
<pre>
 _____________________________ 
|  11+      |  19+            |
|_____      |_____ _____      |  
|  15+|                 |     |  
|     |_____ _____ _____|     |  
|                 |   1 |     |  
|_____ _____      |_____|_____|  
| 240*|   4 |     |   5 |   3%| 
|     |_____|_____|_____|     |  
|                       |     |  
|_______________________|_____|
</pre>
</p>
The input to the problem is a description of the grid in text file with comma seperated values. Each cell is represented by a block number that it is part of, the number associated with the block and the operator associated with the block. The first cell would thus be 1,11,+ (assuming the first block is called block 1).
The full description of the grid may be -  
2,11,+,2,11,+,3,19,+,3,19,+,3,19,+  
4,15,+,2,11,+,2,11,+,2,11,+,3,19,+  
4,15,+,4,15,+,4,15,+,5,1, ,3,19,+  
6,240,\*,7,4, ,4,15,+,1,5, ,8,3,%  
6,240,\*,6,240,\*,6,240,\*,6,240,\*,8,3,%  

The program accepts multiple of these grid descriptions in a 'input' directory and writes the solution to console and 'results' directory.

Algorithm uses iterations with probabilities used to determine the most likely number for a given cell. It is fairly efficient for grids upto 7x7 but can take a lot of time to solve some of the hard 8x8 and 9x9 grids.
