#!/usr/bin/env bash


# Graphic assets
# --------------

BALL='⚪️'
MAX_BALL_SPEED=2

BRICK='▟██████████▛'
BRICK_START_LINE=3
BRICK_LINES=3

MAX_PADDLE_SPEED=4
PADDLE_SKEW_AREA=3
PADDLE_SAFE_AREA=1
INITIAL_PADDLE_TYPE=1
PADDLE_TYPES=(
  '≺{✣–=–✣}≻'
  '≺{✣–––===–––✣}≻'
  '≺{✣––<––=====––>––✣}≻'
  '–≺{✣––<⊂––==<✧>==––⊃>––✣}≻–'
)

POWERUP_CHANCE=$((32768 / 100 * 100))
POWERUP_SLOWDOWN=3
POWERUP_TYPES=(
  "grow 📟"
  "shrink 💢"
  "life ❤️"
  "shield 🛡"
)


reset-game() {
  score=0
  lives=3
  
  paddle=
  paddleType=
  set-paddle $INITIAL_PADDLE_TYPE
  paddleX=$((screenW/2 - paddleSize/2)) 
  paddleY=$((screenH-1)) 
  paddleSpeed=0 
  
  ballState=parked
  ballX=0 ballY=0
  ballSpeedX=0 ballSpeedY=0
  ballSize=${#BALL}
  park-ball
  
  powerup=
  powerupType=
  powerupSize=
  clear-powerup
  powerupX=0 powerupY=0

  bricks=()
  brickSize=${#BRICK} 
  build-bricks

  shield=
}

game-mode() {
  KEY=
  tput clear
  reset-game
  sound level
  gameSoundThread=$!
  LOOP=game-loop
}

game-loop() {
  # Clean frame
  erase "$powerupX" "$powerupY" "${powerupSize}"
  erase "$paddleX" "$paddleY" "$paddleSize"
  erase "$ballX" "$ballY" "$ballSize"


  # Paddle movement
  # ---------------
  
  case $KEY in
    'q')
      if ((paddleSpeed == 0)); then sound move; fi
      ((paddleSpeed = -MAX_PADDLE_SPEED));;
    'p')
      if ((paddleSpeed == 0)); then sound move; fi
      ((paddleSpeed = MAX_PADDLE_SPEED));;
    ' ')
      if [[ $ballState == parked ]]; then
        launch-ball
      elif ((
        (nextBallY == paddleY - 1 || ballY == paddleY) &&
        nextBallX >= paddleX - PADDLE_SAFE_AREA &&
        nextBallX <= paddleX + paddleSize + PADDLE_SAFE_AREA
      )); then 
        park-ball
      fi
  esac
  KEY=
  
  # Movement
  ((paddleX = paddleX + paddleSpeed))

  # Deceleration
  if ((paddleSpeed > 0)); then
    ((paddleSpeed -= 1))
  elif ((paddleSpeed < 0)); then
    ((paddleSpeed += 1))
  fi
  
  # Stop at screen borders
  if ((paddleX < 0)); then
    ((paddleX = 0))
  elif ((paddleX > screenW - paddleSize)); then
    ((paddleX = screenW - paddleSize))
  fi
  

  # Powerup movement
  # ----------------

  if [[ ! -z $powerup ]]; then
    if ((frame % POWERUP_SLOWDOWN == 0)); then
      ((powerupY++)); 
    fi
    if ((powerupY >= paddleY)); then
      check-powerup-conditions
      clear-powerup
    fi
  fi


  # Ball movement
  # -------------

  # Parked ball, stick to paddle
  if [[ $ballState == parked ]]; then
    ballY=$((paddleY - 1))
    ballX=$((paddleX + paddleSize / 2))

  # Ball is free-moving
  elif [[ $ballState == launched ]]; then
    # Prediction
    ((nextBallX = ballX + ballSpeedX))
    ((nextBallY = ballY + ballSpeedY))

    # Wall collision
    if ((nextBallX < 0)); then
      ((ballX = 0))
      ((ballSpeedX = -ballSpeedX))
      ((nextBallX = ballX + ballSpeedX))
      sound wall
    elif ((nextBallX >= screenW)); then
      ((ballX = screenW - 1))
      ((ballSpeedX = -ballSpeedX))
      ((nextBallX = ballX + ballSpeedX))
      sound wall
    fi

    # Ceiling collision
    if ((nextBallY == 0)); then
      ((ballSpeedY = 1)); sound wall
      ((nextBallY = ballY + ballSpeedY))
    
    # Bottom collision
    elif ((nextBallY == screenH)); then

      # Paddle collision
      if ((nextBallX >= paddleX - PADDLE_SAFE_AREA && nextBallX <= paddleX + paddleSize + PADDLE_SAFE_AREA)); then 

        # Paddle skew area
        if ((nextBallX < paddleX + PADDLE_SKEW_AREA)); then
          if ((ballSpeedX != 1)); then ((ballSpeedX -= 1)); fi
          if ((ballSpeedX <= -MAX_BALL_SPEED)); then ((ballSpeedX = -MAX_BALL_SPEED)); fi
          ((nextBallX = ballX + ballSpeedX))
        elif ((nextBallX > paddleX + paddleSize - PADDLE_SKEW_AREA)); then 
          if ((ballSpeedX != -1)); then ((ballSpeedX += 1)); fi
          if ((ballSpeedX >= MAX_BALL_SPEED)); then ((ballSpeedX = MAX_BALL_SPEED)); fi
          ((nextBallX = ballX + ballSpeedX))
        fi

        # Affect ball
        ((ballSpeedY = -1))
        ((nextBallY = ballY + ballSpeedY))
        sound paddle

      # Abyss collision
      else
        life-lost
      fi

    fi

    # Check collisions with bricks
    # if ball is inside brick line
    local lastBrick=(${bricks[-1]})
    if ((nextBallY <= lastBrick[1])); then
      for index in "${!bricks[@]}"; do
        brick=(${bricks[$index]})
        # Brick was hit
        if ((nextBallY == brick[1] && nextBallX >= brick[0] && nextBallX <= brick[0] + brickSize)); then
          # Affect score
          ((score++))
          sound brick
          # Affect ball
          ((ballSpeedY = -ballSpeedY))
          ((nextBallY = ballY + ballSpeedY))
          # Clean brick
          erase "${brick[0]}" "${brick[1]}" "$brickSize"
          unset bricks["$index"]
          # Random chance of powerup
          if [[ -z $powerup ]] && ((RANDOM <= POWERUP_CHANCE)); then
            spawn-powerup $((brick[0] + brickSize / 2)) "${brick[1]}"
          fi
        fi
      done
      check-victory-conditions
    fi

    ((ballX += ballSpeedX))
    ((ballY += ballSpeedY))
  fi

  # Score and entities
  draw 0 0 7 "Lives: $lives"
  draw-right 0 7 "Score: $score"
  draw $paddleX $paddleY 6 "$paddle"
  draw $ballX $ballY 5 "$BALL"
  if [[ ! -z $powerupType ]]; then draw $powerupX $powerupY 5 "$powerup"; fi

  render
}

set-paddle() {
  paddleType=$1
  paddle=${PADDLE_TYPES[$paddleType]}
  paddleSize=${#paddle}
}

shrink-paddle() {
  if ((paddleType > 0)); then
    set-paddle $((paddleType - 1))
  fi
}

grow-paddle() {
  if ((paddleType < ${#PADDLE_TYPES[@]} - 1)); then
    set-paddle $((paddleType + 1))
  fi
}

build-bricks() {
  local count=$((screenW / brickSize - 1))
  local padding=$(( (screenW % brickSize) / 2 ))

  for y in $(seq 0 $((BRICK_LINES - 1))); do
    for x in $(seq 0 $count); do
      local color=$(((RANDOM % 8) + 1))
      local x=$((padding + x * brickSize))
      local brick="$x $((y+BRICK_START_LINE)) $color $BRICK"
      bricks+=("$brick")
      draw $brick
    done
  done
}

park-ball() {
  draw-centered $((screenH / 2)) 4 "PRESS <SPACE> TO LAUNCH OR CATCH"
  ballState=parked
  ballSpeedX=0
  ballSpeedY=0
}

launch-ball() {
  sound start
  ballState=launched
  ballSpeedY=-1
  if ((paddleSpeed < 0)); then
    ballSpeedX=-1
  else
    ballSpeedX=1
  fi
  erase 0 $((screenH / 2)) "$screenW"
}

add-life() {
  ((lives++))
}

add-shield() {
  shield=on
}

remove-shield() {
  shield=
}

spawn-powerup() {
  local x=$1
  local y=$2
  local index=$((RANDOM % ${#POWERUP_TYPES[@]}))
  local powerupSpec=(${POWERUP_TYPES[$index]})
  powerupType=${powerupSpec[0]} powerup=${powerupSpec[1]} 
  powerupX="$x" powerupY="$y" powerupSize=${#powerup}
}

apply-powerup() {
  local type=$1
  case "$type" in
    shrink) shrink-paddle;;
    grow) grow-paddle;;
    shield) add-shield;;
    life) add-life;;
  esac
  sound powerup
}

clear-powerup() {
  powerup=
  powerupType=
}

check-powerup-conditions() {
  if ((powerupX >= paddleX - PADDLE_SAFE_AREA && powerupX <= paddleX + paddleSize + PADDLE_SAFE_AREA)); then
    apply-powerup "$powerupType"
  fi
}

check-victory-conditions() {
  if (( ${#bricks[@]} == 0 )); then
    kill-thread "$gameSoundThread"
    victory-mode
    return 1
  fi
}

life-lost() {
  sound lose
  ((lives--))
  set-paddle $INITIAL_PADDLE_TYPE
  if check-gameover-conditions; then park-ball; fi
}

check-gameover-conditions() {
  if (( lives == 0 )); then
    kill-thread "$gameSoundThread"
    gameover-mode
    return 1
  fi
}