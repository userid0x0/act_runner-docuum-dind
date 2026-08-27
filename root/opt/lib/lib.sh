
die () {
  local msg red nc
  msg="${1}"
  red="\e[31m"
  nc="\e[0m"

  echo -e "[${red}fatal${nc}] ${msg}" >&2
  exit 1
}

info() {
  local msg purple nc
  msg="${1}"
  purple="\e[35m"
  nc="\e[0m"

  echo -e "[${purple}info${nc}] ${msg}"
}


########################################
# Get variables from
#     environment variables,
#     secret file in environment variables,
#     secret file in .env file,
#     environment variables in .env file.
# Arguments:
#     variable name
#     index (optional)
# Outputs:
#     variable value
########################################
get_env() {
  local var_name="$1"
  local index="$2"
  local value
  postfixes=()
  if [ -z "${index}" ]; then
    postfixes+=""
  else
    postfixes+="_${index}"
    [ "${index}" != 0 ] || postfixes+=""
  fi
  

  for postfix in "${postfixes[@]}"; do
    local VAR
    local VAR_FILE
    local VAR_DOTENV
    local VAR_DOTENV_FILE
    VAR="${var_name}${postfix}"
    VAR_FILE="${var_name}_FILE${postfix}"
    VAR_DOTENV="DOTENV_${var_name}${postfix}"
    VAR_DOTENV_FILE="DOTENV_${var_name}_FILE${postfix}"
    value=""
    if [[ -n "${!VAR:-}" ]]; then
      value="${!VAR}"
    elif [[ -n "${!VAR_FILE:-}" ]]; then
      value="$(cat "${!VAR_FILE}")"
    elif [[ -n "${!VAR_DOTENV_FILE:-}" ]]; then
      value="$(cat "${!VAR_DOTENV_FILE}")"
    elif [[ -n "${!VAR_DOTENV:-}" ]]; then
      value="${!VAR_DOTENV}"
    fi
    if [ -n "${value}" ]; then
      echo "${value}"
      return 0
    fi
  done
  return 0
}

# count the number of instances to register
get_gitea_runner_instance_count () {
  local i
  i=0
  while true; do
    [ -n "$(get_env "GITEA_RUNNER_REGISTRATION_TOKEN" ${i})" ] || break
    i=$(( i + 1 ))
  done
  echo "${i}"
}
