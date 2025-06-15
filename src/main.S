.syntax unified
.global main
.include "lib/constants.s"

.type main, %function
main:
  // Configure the GPIOTE_CONFIG[0] channel for button A
  ldr r0, = GPIOTE_CONFIG0
  ldr r1, =(1 | 14 << 8 | 0 << 13 | 1 << 16)
  str r1,[r0]

  // Configure the GPIOTE_CONFIG[1] channel for button B
  ldr r0, = GPIOTE_CONFIG1
  ldr r1, =(1 | 23 << 8 | 0 << 13 | 1 << 16)
  str r1,[r0]

  // EnablevInterrupt for GPIOTE 
  ldr r0, =GPIOTE_INTENSET
  ldr r1, =0b11
  str r1, [r0]

  // Enable GPIOTE in NVIC_ISERO (id = 6)
  ldr r0,=NVIC_ISER0
  ldr r1, = (1 << 6)
  str r1, [r0]

  bl init_leds
  bl init_timer1
  bl init_timer2
  bl init_syst

  loop :
    b loop



.global GPIOTE_IRQHandler 
.type GPIOTE_IRQHandler, %function
GPIOTE_IRQHandler :
  push {r0-r6,lr}
  @ Check Button A
  ldr r0, =GPIOTE_EVENTS_IN0
  ldr r1, [r0]
  cbz r1, check_b

  @ Clear GPIOTE event immediately
  mov r2, #0
  str r2, [r0]

  // Debounce 
  ldr r0, =debounce_active
  ldr r1,[r0]
  cmp r1,#1
  beq end_intrpt

  mov r1,#1
  str r1, [r0]

  // Start timer
  ldr r0, =TIMER1_CLEAR
  mov r1, #1
  str r1,[r0]

  ldr r0,=TIMER1_COMPARE0
  ldr r1, =160000 
  str r1, [r0]

  ldr r0,=TIMER1_START
  mov r1,#1
  str r1,[r0]

  //Handler Button A
  ldr r2,=game_state
  ldr r2,[r2]
  cmp r2,#0
  beq start_game 

  cmp r2,#2
  bge restart_game

  ldr r2,=direction
  ldr r1,[r2]
  add r1,#1
  mov r0,r1
  mov r1,#4
  bl wrap_mod
  str r0,[r2]

  pop {r0-r6,lr}
  bx lr

check_b:
  ldr r0, =0x40006104         // EVENTS_IN[1]
  ldr r1, [r0]
  cbz r1, end_intrpt

  // Clear Event
  ldr r0, =GPIOTE_EVENTS_IN1
  ldr r1,=0
  str r1,[r0]

  // Debounce 
  ldr r0, =debounce_active
  ldr r1,[r0]
  cmp r1,#1
  beq end_intrpt

  mov r1,#1
  str r1, [r0]

  // Start timer
  ldr r0, =TIMER1_CLEAR
  mov r1, #1
  str r1,[r0]

  ldr r0,=TIMER1_COMPARE0
  ldr r1, =8000000
  str r1, [r0]

  ldr r0,=TIMER1_START
  mov r1,#1
  str r1,[r0]

  // Handle Button B
  ldr r2,=direction
  ldr r1,[r2]
  sub r1,#1
  mov r0,r1
  mov r1,#4
  bl wrap_mod
  str r0,[r2]

  pop {r0-r6,lr}
  bx lr

end_intrpt :
  pop {r0-r6,lr}
  bx lr
start_game :
  ldr r2,=game_state
  mov r1,#1
  str r1,[r2]

  pop {r0-r6,lr}
  bx lr
restart_game :
  ldr r2,=game_state
  mov r1,#0
  str r1,[r2]

  bl reset_game
  pop {r0-r6,lr}
  bx lr

.type init_timer1, %function
init_timer1:
  ldr r0, =TIMER1_MODE
  mov r1, #0       @ Timer mode
  str r1, [r0]

  ldr r0, =TIMER1_EVENTS_COMPARE0
  mov r1, #0
  str r1, [r0]

  ldr r0, =TIMER1_BITMODE
  mov r1, #0       @ 16-bit mode
  str r1, [r0]

  ldr r0, =TIMER1_SHORTS
  mov r1, #(1 << 0)  @ Stop on compare[0]
  str r1, [r0]

  ldr r0, =TIMER1_INTENSET
  mov r1, #(1 << 16)  @ Enable interrupt on COMPARE[0]
  str r1, [r0]

  @ Enable TIMER1 IRQ in NVIC (IRQ ID = 9)
  ldr r0, =NVIC_ISER0
  mov r1, #(1 << 9)
  str r1, [r0]
  
  bx lr

.type init_timer2, %function 
init_timer2 :
  ldr r0, =TIMER2_MODE
  mov r1, #0       @ Timer mode
  str r1, [r0]

  ldr r0, =TIMER2_COMPARE0
  ldr r1, =3200 
  str r1, [r0]

  ldr r0, =TIMER2_BITMODE
  mov r1, #0       @ 16-bit mode
  str r1, [r0]

  ldr r0, =TIMER2_SHORTS
  mov r1, #0  @ Dont stop on compare[0]
  str r1, [r0]

  ldr r0, =TIMER2_INTENSET
  mov r1, #(1 << 16)  @ Enable interrupt on COMPARE[0]
  str r1, [r0]

  @ Enable TIMER1 IRQ in NVIC (IRQ ID = 10)
  ldr r0, =NVIC_ISER0
  mov r1, #(1 << 10)
  str r1, [r0]

  ldr r0, =TIMER2_CLEAR
  mov r1,#1
  str r1,[r0]

  ldr r0, =TIMER2_BASE
  mov r1, #10        @ example prescaler value
  str r1, [r0, #0x510]

  ldr r0, =TIMER2_START
  mov r1,#1
  str r1,[r0]
  
  bx lr


.global TIMER1_IRQHandler
.type TIMER1_IRQHandler, %function 
TIMER1_IRQHandler:
  push {r0-r6,lr}
  // Clear Event
  ldr r0, =TIMER1_EVENTS_COMPARE0
  mov r1, #0
  str r1, [r0]

  // Clear debound flag
  ldr r0, =debounce_active
  str r1,[r0]

  pop {r0-r6,lr}
  bx lr

.type init_syst, %function 
init_syst :
  push {r0-r3}

  ldr r1,=SYST_RVR
  ldr r0,=160000
  str r0,[r1]
  
  ldr r1,=SYST_CVR
  mov r0,#0
  str r0,[r1]

  ldr r0, =(1 << 2 | 1 << 1 | 1 )
  ldr r1,=SYST_CSR
  str r0,[r1]

  ldr r0, =SHPR3
  mov r1,#0
  str r1,[r0]

  pop {r0-r3}
  bx lr

.global SysTick_Handler
.type SysTick_Handler, %function 
SysTick_Handler :
  b refresh_led_display


.global TIMER2_IRQHandler
.type TIMER2_IRQHandler, %function
TIMER2_IRQHandler:
  push {r0-r6, lr}

  @ Clear Event
  ldr r0, =TIMER2_EVENTS_COMPARE0
  mov r1,#0
  str r1, [r0]

  @ Restart Timer
  ldr r0, =TIMER2_CLEAR
  mov r1, #1
  str r1, [r0]

  ldr r0, =TIMER2_START
  mov r1, #1
  str r1, [r0]

  @ Snake movement logic here
  bl update_Snake

return_from_tick :
  bl head_tail_collisions
  cmp r0,#1
  beq game_over

  ldr r0,=score
  ldr r0,[r0]
  cmp r0,#9
  bge game_win

end_tick:
  bl set_led_matrix
  pop {r0-r6,lr}
  bx lr

game_over:
  ldr r0,=game_state
  mov r1,#3
  str r1,[r0]
  b end_tick

game_win:
  ldr r0,=game_state
  mov r1,#2
  str r1,[r0]
  b end_tick

.type generate_Food, %function
generate_Food :
  push {r0-r6,lr}
  ldr r5,=food_x
  ldr r5,[r5]
  ldr r6,=food_y
  ldr r6,[r6]
  
  mov r1,#5
  bl random_mod5
  bl wrap_mod
  mov r3,r0

  bl random_mod5
  bl wrap_mod
  mov r4,r0

  cmp r3,r5
  bne done_food_check

  cmp r4,r6
  bne done_food_check

  b generate_Food

done_food_check :
  ldr r5,=food_x
  str r3,[r5]
  ldr r6,=food_y
  str r4,[r6]
  pop {r0-r6,lr}
  bx lr


.type set_led_matrix, %function 
set_led_matrix: 
  push {r0-r12,lr}
  ldr r0,=led_matrix
  mov r1,#0
  mov r2,#0
clear_loop :
  mov r3,#4
  str r1,[r0]
  add r2,#1
  add r0,r3
  cmp r2,#5
  blt clear_loop

  ldr r3,=x_coor
  ldr r4,[r3]
  ldr r3,=y_coor
  ldr r5,[r3]

  ldr r3,=food_x
  ldr r6,[r3]
  ldr r3,=food_y
  ldr r7,[r3]

  mov r8,#4
  sub r8,r8,r4

  mov r9,r5

  ldr r0,=led_matrix
  ldr r10,[r0,r8,lsl #2]
  mov r11,#1
  lsl r11,r11,r9
  orr r10,r10,r11
  str r10,[r0,r8,lsl #2]

  mov r8,#4
  sub r8,r8,r6

  mov r9,r7

  ldr r10,[r0,r8,lsl #2]
  mov r11,#1
  lsl r11,r11,r9
  orr r10,r10,r11
  str r10,[r0,r8,lsl #2]

  @Draw the tail 
  ldr r10,=snake_length
  ldr r10,[r10]

  ldr r1,=tail_x
  ldr r2,=tail_y

  mov r3,#0

draw_tail_loop :
  cmp r3,r10
  bge draw_done

  mov r7,r3
  sub r7,r7,#1
  mov r4,#4
  mul r5,r3,r4

  ldr r6,[r1,r5]
  ldr r7,[r2,r5]

  mov r8,#4
  sub r8,r8,r6
  mov r9,r7

  ldr r0,=led_matrix
  ldr r11,[r0,r8,lsl #2]
  mov r12,#1
  lsl r12,r12,r9
  orr r11,r11,r12
  str r11,[r0,r8,lsl #2]

  add r3,r3,#1
  b draw_tail_loop

draw_done :
  pop {r0-r12,lr}
  bx lr 


.type check_collisions, %function
check_collisions:
  push {r1-r3, lr}

  ldr r0, =x_coor
  ldr r1, [r0]       @ r1 = snake_x

  ldr r0, =food_x
  ldr r2, [r0]       @ r2 = food_x

  cmp r1, r2
  bne no_collision   @ if snake_x != food_x, no collision

  ldr r0, =y_coor
  ldr r1, [r0]       @ r1 = snake_y

  ldr r0, =food_y
  ldr r2, [r0]       @ r2 = food_y

  cmp r1, r2
  bne no_collision   @ if snake_y != food_y, no collision

  mov r0, #1         @ collision detected: return 1
  b done

no_collision:
  mov r0, #0         @ no collision: return 0

done:
  pop {r1-r3, lr}
  bx lr


@Returns r0 : 1 if there is a collision of the snake head with its tail 0 otherwise
.type head_tail_collisions,%function 
head_tail_collisions:
  push {r1-r6,lr}
  mov r0,#0
  mov r4,#0
  ldr r1,=snake_length
  ldr r1,[r1]
  cmp r1,#2
  ble end_head_tail_detection
  lsl r1,r1,#2

  ldr r2,=tail_x
  ldr r3,=tail_y

  ldr r5,=x_coor
  ldr r5,[r5]

  ldr r6,=y_coor
  ldr r6,[r6]

head_tail_detection_loop:
  cmp r4,r1
  bge end_head_tail_detection

  ldr r7,[r2,r4]
  cmp r7,r5
  bne no_head_tail_collision

  ldr r8,[r3,r4]
  cmp r8,r6
  beq head_tail_collision

no_head_tail_collision:
  add r4,r4,#4
  cmp r4,#36
  mov r0,#0
  beq end_head_tail_detection
  b head_tail_detection_loop

head_tail_collision :
  mov r0,#1
end_head_tail_detection :
  pop {r1-r6,lr}
  bx lr


@ ========================== Function to update snake ====================================================
.type update_Snake, %function
update_Snake:
  ldr r1,=x_coor
  ldr r1,[r1]
  ldr r2,=prev_x
  str r1,[r2]

  ldr r1,=y_coor
  ldr r1,[r1]
  ldr r2,=prev_y
  str r1,[r2]

  ldr r0, =direction
  ldr r0, [r0]

  cmp r0, #0
  beq move_up
  cmp r0, #1
  beq move_left
  cmp r0, #2
  beq move_down
  cmp r0, #3
  beq move_right

  b return_from_tick

move_up:
  ldr r6, =y_coor
  ldr r3, [r6]
  add r3, r3, #1
  str r3, [r6]
  b finish_move
move_down:
  ldr r6, =y_coor
  ldr r3, [r6]
  sub r3, r3, #1
  str r3, [r6]
  b finish_move
move_left:
  ldr r5, =x_coor
  ldr r3, [r5]
  sub r3, r3, #1
  str r3, [r5]
  b finish_move
move_right:
  ldr r5, =x_coor
  ldr r3, [r5]
  add r3, r3, #1
  str r3, [r5]
  b finish_move

finish_move:
  ldr r5, =x_coor
  ldr r5, [r5]
  mov r0, r5
  mov r1, #5
  bl wrap_mod
  ldr r5, =x_coor
  str r0, [r5]

  ldr r6, =y_coor
  ldr r6, [r6]
  mov r0, r6
  mov r1, #5
  bl wrap_mod
  ldr r6, =y_coor
  str r0, [r6]

  @ Move the snake tail
  ldr r0, =snake_length
  ldr r0, [r0]

  bl move_snake_tail

  bl check_collisions
  cmp r0,#0
  beq return_from_tick

  bl generate_Food
  ldr r1,=score
  ldr r2,[r1]
  add r2,#1
  str r2,[r1]

  ldr r1,=snake_length
  ldr r2,[r1]
  add r2,#1
  str r2,[r1]

  ldr r0,=TIMER1_COMPARE0
  ldr r1,[r0]

  mov r2,r1
  mov r3,#10
  mul r2,r1,r3
  mov r3,#100
  udiv r2,r2,r3

  subs r1,r1,r2
  str r1,[r0]
  b return_from_tick

@ ============ End function ===============================================================================

.type move_snake_tail, %function
move_snake_tail:
  push {r0-r12,lr}
  ldr r12,=snake_length
  ldr r12,[r12]
  cmp r12,#0
  beq end_snake_tail_move
  add r12,r12,#1
  mov r0,#0
move_snake_tail_loop :
  cmp r0,r12
  beq end_snake_tail_move

  ldr r3,=tail_x
  ldr r4,=tail_y

  mov r1,r0
  mov r2,#4
  mul r2,r2,r1

  add r3,r3,r2
  add r4,r4,r2

  ldr r5,[r3] @The current x coor of this element
  ldr r6,[r4] @The current y coor of this element

  ldr r7,=prev_x
  ldr r8,=prev_y

  ldr r2,[r7]
  str r2,[r3]

  ldr r2,[r8]
  str r2,[r4]

  str r5,[r7]
  str r6,[r8]

  add r0,#1
  b move_snake_tail_loop
end_snake_tail_move :
  pop {r0-r12,lr}
  bx lr


@Params r0 : Stores the value of r0 to game_state
.type set_game_state, %function
set_game_state :
  push {r1}
  ldr r1,=game_state
  str r0,[r1]
  pop {r1}
  bx lr

@ Resets all the game variables
.type reset_game, %function
reset_game :
  push {r0-r6,lr}
  ldr r0,=direction
  mov r1,#1
  str r1,[r0]

  ldr r0,=game_state
  mov r1,#0
  str r1,[r0]  

  ldr r0,=score
  mov r1,#0
  str r1,[r0]  


  ldr r0,=snake_length
  mov r1,#0
  str r1,[r0]

  ldr r0,=x_coor
  mov r1,#2
  str r1,[r0]

  ldr r0,=y_coor
  mov r1,#2
  str r1,[r0]

  ldr r0,=food_x
  mov r1,#0
  str r1,[r0]

  ldr r0,=food_y
  mov r1,#0
  str r1,[r0]

  bl init_syst

  pop {r0-r6,lr}
  bx lr

.type refresh_led_display, %function
refresh_led_display :
  push {r0-r6, lr}

  ldr r0, =current_column
  ldr r1, [r0]                @ r1 = current column index (0..4)

  @ Turn off all columns first (send 0 to all columns)
  mov r0, #0
  bl write_column_pins

  ldr r5,=game_state
  ldr r5,[r5]

  cmp r5,#0
  beq set_main_menu

  cmp r5,#1
  beq set_snake

  cmp r5,#2
  beq set_win_screen

  cmp r5,#3
  beq set_lose_screen

set_main_menu :
  ldr r2,=main_menu
  b continue 

set_win_screen :
  ldr r2,=win_screen
  b continue

set_lose_screen:
  ldr r2,=lose_screen
  b continue

set_snake:
  ldr r2,=led_matrix
  b continue

continue :
  mov r3,#4
  mul r4,r1,r3
  add r2,r2,r4   
  ldr r3, [r2]           

  @ In your system, row bitmask 1 = high, 0 = low
  mov r0, r3
  bl write_row_pins           @ sets the rows for this column

  @ Prepare column bitmask: only the current column is ON (bit=1), others 0
  mov r0, #1
  lsl r0, r0, r1             @ shift bit to current column index (0..4)

  bl write_column_pins       @ sets the column pins (inverts internally)

  @ Increment current_column = (current_column + 1) % 5
  add r1, r1, #1
  cmp r1, #5
  bne no_wrap
  mov r1, #0
no_wrap:
  ldr r0,=current_column
  str r1, [r0]           @ store updated current_column
  pop {r0-r6, lr}
  bx lr


.data 
direction: .word 1
debounce_active: .word 0
x_coor: .word 2
y_coor: .word 2
food_x: .word 0
food_y: .word 0
score: .word 0
led_matrix: .word 0,0,0,0,0
current_column: .word 0
game_state: .word 0  @ 0:Start menu,1:Game playing, 2: Game end(Win), 3:Game end(Lose)
tail_x: .space 9*4
tail_y: .space 9*4
prev_x: .word 0
prev_y: .word 0
win_screen: .word 0b00010,0b01001,0b00001,0b01001,0b00010
lose_screen: .word 0b01100,0b10111,0b11111,0b10111,0b01100
main_menu: .word 0b00100,0b01110,0b10101,0b00100,0b00100
snake_length: .word 0

