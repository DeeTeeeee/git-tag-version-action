source src/version.sh && source src/tag.sh
get_stage_prompt() {
  title="Chon moi truong build:"
  prompt="Lua chon:"
  options=("Development" "Staging" "Production" "Bump Version")

  echo "$title"
  PS3="$prompt "
  STAGE=""
  select opt in "${options[@]}" "Thoat"; do
    case "$REPLY" in
    1) echo "Lua chon build $opt" && STAGE="development" && break ;;
    2) echo "Lua chon build $opt" && STAGE="staging" && break ;;
    3) echo "Lua chon build $opt" && STAGE="production" && break ;;
    4) echo "Nâng version" && get_version_option && break ;;
    $((${#options[@]} + 1)))
      echo "Goodbye!"
      exit 0
      ;;
    *)
      echo "Sai lua chon. chon lai."
      continue
      ;;
    esac
  done
}

get_bump_version_option() {
  PREFIX='merchant/'
  if [[ "$1" ]]; then
    PREFIX="$1/"
  fi
  PRO_TAG=$(git tag --sort=-version:refname -l "${PREFIX}production/*" | head -n 1)
  title="Version của app hiện tại: $PRO_TAG"
  options=("Major Version" "Minor Version" "Patche")
  NEW_VERSION=''

  echo "$title"
  echo "Lựa chọn để nâng version"
  select opt in "${options[@]}" "Thoat"; do
    case "$REPLY" in
    1) echo "Lua chon build $opt" && NEW_VERSION=$(split_version $PRO_TAG increment_major) && break ;;
    2) echo "Lua chon build $opt" && NEW_VERSION=$(split_version $PRO_TAG increment_minor) && break ;;
    3) echo "Lua chon build $opt" && NEW_VERSION=$(split_version $PRO_TAG increment_patche) && break ;;
    $((${#options[@]} + 1)))
      echo "Goodbye!"
      exit 0
      ;;
    *)
      echo "Sai lua chon. chon lai."
      continue
      ;;
    esac
  done
  create_tag $NEW_VERSION
}
