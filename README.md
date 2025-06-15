# Report
For this project I have decided to complete the following requirements, here I number them to reference to them later in the implementation section of the report to showcase which implementations satisfy which features :

1. Uses memory and data structures to store the images your light show displays(**P**)
2. Contains atleast 10 images(**P**)
3. Uses scanning to display complex images
4. Never stops (**P**)
5. Using the timer interrupt(s) as an integral part of your display(**C**)
6. Using the Hardware RNG Peripheral to create a generative display. (**C**)
7. Allow using the buttons to scroll through a number of different animations (**D**)
8. Allow using the buttons to dial a particular setting of the animation. (**D**)
9. A high degree of interactivity using buttons (**HD**)


## Overview
### Key features
- LED Matrix display 
- Button input with interrupt handling 
- Use of hardware timers **(SysTick Timer,TIMER1, TIMER2)** 
- Use of random number generation 
- State dependent functionality of buttons

### Overall Approach
To create a snake game I decided to separate it into three parts. The game state stores in memory the current state the game is in, e.g the cooridnates of the snake, if the game is paused etc. The game logic would dictate the flow of the game and how the game state changes. And finally the code that translates the game state to display it on the led matrix, the **"displayer"** of the programm.

For displaying the state I decided to use a timer to quickly scan the state of the game stored in memory and display it rapidly. 

For the logic of the game, I decided to make it so that the snake wraps around the led matrix and growns when it eats a food. the food generation is random(pseudo ofcourse cause nothing is truly random).

To make the snake perpetually move I decided to use another timer to make it move in the current direction which could be changed by inputs via the buttons which are handled by the GPIOTE handler. 

Finally the game ends either if the snake reaches a score of 9 or dies by colliding with its own tail,both of which would trigger a different image, at which point the players could press button A to reset the game state back to its initial state.


## Implementation 
### Basic Game Variables (Satisfies 1 ) 
I decided that for the most part it would be better to separate the state of the game i.e the logical backbone of the programme from the code that translates this state and displays it on the led grid. For this I stored in memory the variables needed to store the state of the game such as :

| **Variable Name** | **Description** |
|-------|-------------|
| game_state | Stores if the game hasnt started, is running, or ended. **[0 : menu, 1 : in game, 2 : player won, 3 : player lost]** |
| x_coor | Stores the x cooridnate of the snake head|
| y_coor | Stores the y cooridnate of the snake head|
| snake_length | Stores the length of the snake currently(Not including the head) |
| score | Stores the current score of the player |
| tail_x | An array of length 9 which stores the x cooridnates of the tail |
| tail_y | An array of length 9 which stores the y cooridnates of the tail |
| direction | Stores the direction the snake is currently moving in **[0 : up, 1 : left, 2 : down, 3: right]** |
|food_x|Stores the x cooridnate of the food|
|food_y|Stores the y cooridnate of the food|

### Scanning to show images (Satisfies 1,2,3,4,5)
I decided to use the Systick Timer for the crux of my project, which is displaying the state of the game at any given moment. I decided to store the necessary images for different states in memory, they are described below :

| Name of display | Description |
| ----------- | ------------------- |
| led_matrix | Stores the display of the game i.e the snake and food(Is overwritten frequently during gameplay) |
| main_menu | Stores the image of an arrow pointing to the button to start the game |
| win_screen | Stores a smiley face to display once a player wins |
| lose_screen | Stores a skull face to display once a player loses |

At the start of the interrupt handler the code branches based on the state of the game to display the appropriate image.

### Timer2 to perpetually move the snake
I needed another timer to make sure the snake perpetually moves in the current direction. I used the **TIMER2** to do this.

The interrupt handler branches based on the state of the game to only move the snake if the game is in session. It calls a function **update_Snake** which updates the cooridnates of the snake by moving the head in one step in the current direction and then it updates the tail cooridinates by using iterating a number of steps based on the current snake length and copying and pasting the previous coordinates of a segment to the current coordinates of the next segment. This was made possible by the use of two placeholder variables **prev_x** and **prev_y**

### Buttons to change the snake's direction (Satisfies 7,8,9)
The GPIOTE Interrupt Handler branches based on the state of the game, if the game has not started Button A starts the game.

If the game is in session, Button A increments the direction and wraps it so the value is in **mod 4**, and button B does the same except it decrements the direction.

A third timer **TIMER1** is used to debounce the button inputs by setting a debounce flag in memory and clearing it after approximately 500 milliseconds. When set the GPIOTE Handler ignores any interrupts.

### Usage of RNG peripheral to generate food (Satisfies 6)
The RNG peripheral is used to generate food whenever a collision is detected between the head of the snake and the food. The food's coordinates are cleared and the RNG generation is started, and after waiting for the random value generation two random values are generated and wrapped so that the final numbers are in **mod 5**.

### Collision Detection System
The collision detection system for the snake head and food is simple which simply compares the x and y coordinates of food and the snake head and returns 1 if they are both equal, 0 otherwise. The speed of game is increased 10% for each food the snake consumes by updating the compare value for TIMER2.

The collision detection system for the snake head with its own tail iterates over the current length of the snake and checks if any of the segments of the tail collides with the head, similarly returns 1 if true and 0 otherwise.

## Analysis
### Usage of in memory stored values
The usage of in memory stored values could have been moved to the random access memory instead of the main memory making it faster to read and load into, however there was not enough difference to warrant a change in the late stages of programming.

### Usage of RNG 
The RNG peripheral was the best way to generate random numbers which beat using any psedo random number generation algorithm which would make the code unncessarily long. This feature also was best to use since the game requires the random generation of the food particle.

### Button functionality
The button functionality changes based on the state of the game, this allows there to be a pause screen so that the user is not immediately thrown into the game as soon as the microbit boots up. This also allows the Buttons to have multiple functions. 

The GPIOTE Interrupt Handler code could have been shorted by compiling the necessary code for handling button inputs into functions which would have made the code shorter and cleaner for the interrupt.

### Scanning to display images 
Scanning was the best option as we needed to rapidly refresh the screen to display the new changes to the state and also the game requires a constantly changing display as the snake is perpetually moving which must be conveyed to the gamer with as less of delay as possible.

The interrupt handler could have integrated both displaying state and changing state according to game logic, this would allowed us to use one less timer and free us from configuring interrupt priorities but this was tried and eventually given up upon due to time constraints.


### Future improvements
- Add score display
- Use RAM instead of memory to store game state
- Allow players to choose difficulty 
- Display animation for win and lose screens instead of static images

## Conclusions
Overall the project satisfies all the specifications required, and demonstrates a fully functional game in itself. The implementation compromised advanced features for a mediocre game structure and smooth gameplay with opportunities for future enhancements through modularization. 

