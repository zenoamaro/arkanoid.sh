#!/usr/bin/env bash

score=0
ballSize=1 ballX=$((screenW/2-1)) ballY=$((screenH-1))
paddleSize=15 paddleX=$((screenW/2-paddleSize/2)) paddleY=$((screenH-1)) 
ballSpeedX=1 ballSpeedY=-1 maxBallSpeed=2
paddleSpeed=0 maxPaddleSpeed=4
paddleSkewArea=2 paddleSafeArea=2
brickLines=3 brickLine=3 brickSize=${#BRICK} bricks=()

game-mode() {
  tput clear
  generate-bricks
  sound level
  gameSoundThread=$!
  sound start
  LOOP=game-loop
}

game-loop() {
  erase $paddleX $paddleY $paddleSize
  erase $ballX $ballY $ballSize

  case $KEY in
    'q')
      if ((paddleSpeed == 0)); then sound move; fi
      ((paddleSpeed = -maxPaddleSpeed));;
    'p')
      if ((paddleSpeed == 0)); then sound move; fi
      ((paddleSpeed = maxPaddleSpeed));;
  esac
  KEY=
  
  ((paddleX = paddleX + paddleSpeed))

  if ((paddleSpeed > 0)); then
    ((paddleSpeed -= 1))
  elif ((paddleSpeed < 0)); then
    ((paddleSpeed += 1))
  fi
  
  if ((paddleX < 0)); then
    ((paddleX = 0))
  elif ((paddleX > screenW - paddleSize)); then
    ((paddleX = screenW - paddleSize))
  fi
  
  ((nextBallX = ballX + ballSpeedX))
  ((nextBallY = ballY + ballSpeedY))

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

  if ((nextBallY == 0)); then
    ((ballSpeedY = 1)); sound wall
    ((nextBallY = ballY + ballSpeedY))
  elif ((nextBallY == screenH)); then
    if ((nextBallX < paddleX - paddleSafeArea || nextBallX > paddleX + paddleSize + paddleSafeArea)); then 
      kill-thread "$gameSoundThread"
      sound gameover
      teardown
    else
      if ((nextBallX < paddleX + paddleSkewArea)); then
        if ((ballSpeedX != 1)); then ((ballSpeedX -= 1)); fi
        if ((ballSpeedX <= -maxBallSpeed)); then ((ballSpeedX = -maxBallSpeed)); fi
        ((nextBallX = ballX + ballSpeedX))
      elif ((nextBallX > paddleX + paddleSize - paddleSkewArea)); then 
        if ((ballSpeedX != -1)); then ((ballSpeedX += 1)); fi
        if ((ballSpeedX >= maxBallSpeed)); then ((ballSpeedX = maxBallSpeed)); fi
        ((nextBallX = ballX + ballSpeedX))
      fi
      ((ballSpeedY = -1))
      ((nextBallY = ballY + ballSpeedY))
      sound paddle
    fi
  fi

  if (( ${#bricks[@]} == 0 )); then
    kill-thread "$gameSoundThread"
    sound victory
    teardown
  fi

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
  fi

  ((ballX += ballSpeedX))
  ((ballY += ballSpeedY))

  draw 0 0 7 "Score: $score"
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
