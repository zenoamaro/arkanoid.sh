#!/usr/bin/env bash

score=
lives=
ballSize=1 ballX=$((screenW/2-1)) ballY=$((screenH-1))
paddleSize=15 paddleX=$((screenW/2-paddleSize/2)) paddleY=$((screenH-1)) 
ballSpeedX=0 ballSpeedY=0 maxBallSpeed=2
paddleSpeed=0 maxPaddleSpeed=4
paddleSkewArea=3 paddleSafeArea=1
brickLines=3 brickLine=3 brickSize=${#BRICK} bricks=()
ballState=parked

game-mode() {
  KEY=
  tput clear

  score=0
  lives=3
  park-ball
  generate-bricks

  sound level
  gameSoundThread=$!
  LOOP=game-loop
}

game-loop() {
  # Clean frame
  erase $paddleX $paddleY $paddleSize
  erase $ballX $ballY $ballSize


  # Paddle movement
  # ---------------
  
  case $KEY in
    'q')
      if ((paddleSpeed == 0)); then sound move; fi
      ((paddleSpeed = -maxPaddleSpeed));;
    'p')
      if ((paddleSpeed == 0)); then sound move; fi
      ((paddleSpeed = maxPaddleSpeed));;
    ' ')
      if [[ $ballState == parked ]]; then
        launch-ball
      elif ((
        (nextBallY == paddleY - 1 || ballY == paddleY) &&
        nextBallX >= paddleX - paddleSafeArea &&
        nextBallX <= paddleX + paddleSize + paddleSafeArea
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
  

  # Ball movement
  # -------------

  # Parked ball, stick to paddle
  if [[ $ballState == parked ]]; then
    ballY=$((paddleY - 1))
    ballX=$((paddleX + paddleSize / 2))
  fi

  if [[ $ballState == launched ]]; then
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
      if ((nextBallX >= paddleX - paddleSafeArea && nextBallX <= paddleX + paddleSize + paddleSafeArea)); then 

        # Paddle skew area
        if ((nextBallX < paddleX + paddleSkewArea)); then
          if ((ballSpeedX != 1)); then ((ballSpeedX -= 1)); fi
          if ((ballSpeedX <= -maxBallSpeed)); then ((ballSpeedX = -maxBallSpeed)); fi
          ((nextBallX = ballX + ballSpeedX))
        elif ((nextBallX > paddleX + paddleSize - paddleSkewArea)); then 
          if ((ballSpeedX != -1)); then ((ballSpeedX += 1)); fi
          if ((ballSpeedX >= maxBallSpeed)); then ((ballSpeedX = maxBallSpeed)); fi
          ((nextBallX = ballX + ballSpeedX))
        fi

        # Affect ball
        ((ballSpeedY = -1))
        ((nextBallY = ballY + ballSpeedY))
        sound paddle

      # Abyss collision
      else
        sound gameover
        ((lives--))
        if check-gameover-conditions; then park-ball; fi
      fi

    fi

    # Check collisions with bricks
    # if ball is inside brick line
    local lastBrick=(${bricks[-1]})
    if ((nextBallY <= lastBrick[1])); then
      for index in "${!bricks[@]}"; do
        brick=(${bricks[$index]})
        if ((nextBallY == brick[1] && nextBallX >= brick[0] && nextBallX <= brick[0] + brickSize)); then
          ((score++))
          ((ballSpeedY = -ballSpeedY))
          ((nextBallY = ballY + ballSpeedY))
          erase "${brick[0]}" "${brick[1]}" "$brickSize"
          unset bricks["$index"]
          sound brick
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
  draw $paddleX $paddleY 6 "$PADDLE"
  draw $ballX $ballY 5 "$BALL"

  render
}

generate-bricks() {
  local count=$((screenW / brickSize - 1))
  local padding=$(( (screenW % brickSize) / 2 ))

  for y in $(seq 0 $((brickLines - 1))); do
    for x in $(seq 0 $count); do
      local color=$(((RANDOM % 8) + 1))
      local x=$((padding + x * brickSize))
      local brick="$x $((y+brickLine)) $color $BRICK"
      bricks+=("$brick")
      draw $brick
    done
  done
}

park-ball() {
  draw-centered $((screenH / 2)) 4 "PRESS <SPACE> TO LAUNCH AND CATCH"
  ballState=parked
  ballSpeedX=0
  ballSpeedY=0
}

launch-ball() {
  sound start
  ballState=launched
  ballSpeedY=-1
  ballSpeedX=1
  erase 0 $((screenH / 2)) "$screenW"
}

check-victory-conditions() {
  if (( ${#bricks[@]} == 0 )); then
    kill-thread "$gameSoundThread"
    victory-mode
    return 1
  fi
}

check-gameover-conditions() {
  if (( lives == 0 )); then
    kill-thread "$gameSoundThread"
    gameover-mode
    return 1
  fi
}