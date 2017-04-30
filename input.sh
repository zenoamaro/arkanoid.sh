KEY=

start-input-handler() {
  while :; do
    read -rs -n1 KEY || true
    if [[ -z $KEY ]]; then KEY=' '; fi
  done
}