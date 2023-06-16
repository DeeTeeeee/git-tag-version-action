get_stage_prompt() {
  title="Chon moi truong build:"
  prompt="Lua chon:"
  options=("Development" "Staging" "Production" "Increment App Version")

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

get_version_option() {
  PREFIX='merchant/'
  if [[ "$1" ]]; then
    PREFIX="$1/"
  fi
  PRO_TAG=$(git tag --sort=-version:refname -l "${PREFIX}production/*" | head -n 1)
  title="Version của app hiện tại: $PRO_TAG"
  options=("Major Version" "Minor Version" "Patches")

  echo "$title"
  echo "Lựa chọn để nâng version"
  select opt in "${options[@]}" "Thoat"; do
    case "$REPLY" in
    1) echo "Lua chon build $opt" && bump_version "Major" $PRO_TAG && break ;;
    2) echo "Lua chon build $opt" && bump_version "Minor" $PRO_TAG && break ;;
    3) echo "Lua chon build $opt" && bump_version "Patches" $PRO_TAG && break ;;
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

bump_version() {
  NEW_VERSION=''
  VERSION_NAME_PATH=($(grep -oE '[a-z,0-9,-.+]*' <<<"$2"))
  ARRAY_SIZE=${#VERSION_NAME_PATH[@]}
  VERSION=${VERSION_NAME_PATH[$((ARRAY_SIZE - 1))]}
  ENVIRONMENT=${VERSION_NAME_PATH[$((ARRAY_SIZE - 2))]}
  VERSION_ARRAY=($(grep -oE '[0-9]*' <<<"$VERSION"))
  case $1 in
  Major)
    NEW_VERSION="${VERSION_NAME_PATH}/${ENVIRONMENT}/v$((VERSION_ARRAY[0]+1)).${VERSION_ARRAY[1]}.${VERSION_ARRAY[2]}+${VERSION_ARRAY[3]}"
    ;;
  Minor)
    NEW_VERSION="${VERSION_NAME_PATH}/${ENVIRONMENT}/v${VERSION_ARRAY[0]}.$((VERSION_ARRAY[1]+1)).0+${VERSION_ARRAY[3]}"
    ;;
  Patches)
    NEW_VERSION="${VERSION_NAME_PATH}/${ENVIRONMENT}/v${VERSION_ARRAY[0]}.${VERSION_ARRAY[1]}.$((VERSION_ARRAY[2]+1))+${VERSION_ARRAY[3]}"
    ;;
  esac
  create_tag $NEW_VERSION
}
