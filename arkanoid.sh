#!/usr/bin/env bash
PLATFORM=$(uname -s)
DELAY=0.015
TTY=
KEY=

BALL='🎾'
PADDLE='<–––––––––––––>'
BRICK='[######]'

score=0
screenW=$(tput cols) screenH=$(tput lines) screenC=$((screenW*screenH))
ballSize=1 ballX=$((screenW/2-1)) ballY=$((screenH-1))
paddleSize=15 paddleX=$((screenW/2-paddleSize/2)) paddleY=$((screenH-1)) 
ballSpeedX=1 ballSpeedY=-1 paddleSpeed=0 maxPaddleSpeed=4 paddleSafeArea=4
brickSize=${#BRICK} bricks=()
framebuffer=

setup() {
  TTY=$(stty -g)
  stty raw -echo
  tput civis
  tput clear
  trap teardown EXIT
  trap loop ALRM
  generate-bricks
}

teardown() {
  trap exit ALRM
  stty "$TTY"
  tput cvvis
  tput sgr0
  sleep $DELAY
  exit
}

generate-bricks() {
  local lines=5
  local count=$((screenW / brickSize - 1))

  for y in $(seq 1 $((lines))); do
    for x in $(seq 0 $count); do
      local color=$(((RANDOM % 8) + 1))
      local x=$((x * brickSize))
      local brick="$x $y $color $BRICK"
      bricks+=("$brick")
      draw $brick
    done
  done
}

input() {
  read -rs -n1 KEY || true
}

loop() {
  erase $paddleX $paddleY $paddleSize
  erase $ballX $ballY $ballSize

  case $KEY in
    'q')
      ((paddleSpeed = -maxPaddleSpeed))
      sound move;;
    'p')
      ((paddleSpeed = maxPaddleSpeed))
      sound move;;
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
    # ((paddleSpeed = -paddleSpeed))
  elif ((paddleX > screenW - paddleSize)); then
    ((paddleX = screenW - paddleSize))
    # ((paddleSpeed = -paddleSpeed))
  fi
  
  ((nextBallX = ballX + ballSpeedX))
  ((nextBallY = ballY + ballSpeedY))

  if ((nextBallX < 0)); then
    ((ballX = 0))
    ((ballSpeedX = -ballSpeedX)); sound wall
    ((nextBallX = ballX + ballSpeedX))
  elif ((nextBallX >= screenW)); then
    ((ballX = screenW - 1))
    ((ballSpeedX = -ballSpeedX)); sound wall
    ((nextBallX = ballX + ballSpeedX))
  fi

  if ((nextBallY == 0)); then
    ((ballSpeedY = 1)); sound wall
    ((nextBallY = ballY + ballSpeedY))
  elif ((nextBallY == screenH)); then
    if ((nextBallX < paddleX - 1 || nextBallX > paddleX + paddleSize + 1)); then 
      sound gameover
      teardown
    else
      if ((nextBallX < paddleX + paddleSafeArea)); then
        ((ballSpeedX -= 1))
        if ((ballSpeedX <= -2)); then ((ballSpeedX = -2)); fi
        ((nextBallX = ballX + ballSpeedX))
      elif ((nextBallX > paddleX + paddleSize - paddleSafeArea)); then 
        ((ballSpeedX += 1))
        if ((ballSpeedX >= 2)); then ((ballSpeedX = 2)); fi
        ((nextBallX = ballX + ballSpeedX))
      fi
      ((ballSpeedY = -1))
      ((nextBallY = ballY + ballSpeedY))
      sound paddle
    fi
  fi

  if (( ${#bricks[@]} == 0 )); then
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
      ((i++))
    done
  fi

  ((ballX += ballSpeedX))
  ((ballY += ballSpeedY))

  draw 0 0 7 "Score: $score"
  draw $paddleX $paddleY 6 $PADDLE
  draw $ballX $ballY 5 $BALL

  echo -en "${framebuffer}"
  framebuffer=

  (sleep $DELAY && kill -ALRM $$) &
}

draw() {
  local x=$1
  local y=$2
  local color=$3
  local str=${*:4}
  framebuffer="${framebuffer}\e[$((y+1));$((x+1))H\e[$((color+90));m${str}\e[m"
}

erase() {
  local x=$1
  local y=$2
  local len=$3
  framebuffer="${framebuffer}\e[$((y+1));$((x+1))H$(repeat ' ' "$len")"
}

repeat() {
  local c=$1
  local n=$2
  printf "%0.s$c" $(seq 1 "$n")
}

sound() {
  local sound=$1.wav
  case $PLATFORM in
    Darwin) afplay "$sound" &;;
    Linux) paplay "$sound" &;;
    *) echo -en '\a';;
  esac
}

setup
sound start
loop

while :; do
  input
done
