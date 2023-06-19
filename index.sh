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
    4) echo "Nâng version" && get_bump_version_option && break ;;
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

create_tag() {
  TAG_NAME=$1
  {
    git tag -a $TAG_NAME -m "New release for $TAG_NAME" &&
      git push origin $TAG_NAME
  } || {
    git tag -d $TAG_NAME
  }
  echo $TAG_NAME
}

init_version_tag() {
  PREFIX=''
  if [ "${1}" ]; then
    PREFIX="$1/"
  fi
  create_tag "${PREFIX}development/v1.0.1+0"
  create_tag "${PREFIX}staging/v1.0.1+0"
  create_tag "${PREFIX}production/v1.0.0+0"
}

delete_tag() {
  git tag -d "$1"
  git push --delete origin "$1"
}

check_tag_format() {
  git fetch
  TAG_SOURCE=$(git describe --tags)
  REGEX_MATCH_TAGS_BUILD="(development|staging|production)\/((v|\.|\+)[0-9]*){4}"
  if [ "${PREFIX}" ]; then
    REGEX_MATCH_TAGS_BUILD="^.*${PREFIX}\/${REGEX_MATCH_TAGS_BUILD}$"
  else
    REGEX_MATCH_TAGS_BUILD="^.*${REGEX_MATCH_TAGS_BUILD}$"
  fi
  if [[ "$TAG_SOURCE" =~ $REGEX_MATCH_TAGS_BUILD ]]; then
    echo "INFO: Tag name '$TAG_SOURCE' is the right format tag name for building the new version."
  else
    exit "ERROR: Tag name '$TAG_SOURCE' is NOT the right format tag name for building the new version."
  fi
}

remove_all_tag() {
  git fetch
  git push origin --delete $(git tag -l)
  git tag -d $(git tag -l)
}

split_version() {
  TAG_NAME=$1
  VERSION_TYPE=$2 # full, all, major, minor, patche, increment_patche, build, increment_build, increment_major, increment_minor, increment_patche
  VERSION_NAME_PATH=($(grep -oE '[a-z,0-9,-.+]*' <<<"$TAG_NAME"))
  ARRAY_SIZE=${#VERSION_NAME_PATH[@]}
  VERSION=${VERSION_NAME_PATH[$((ARRAY_SIZE - 1))]}
  ENVIRONMENT=${VERSION_NAME_PATH[$((ARRAY_SIZE - 2))]}
  VERSION_ARRAY=($(grep -oE '[0-9]*' <<<"$VERSION"))
  MAJOR=${VERSION_ARRAY[0]}
  MINOR=${VERSION_ARRAY[1]}
  PATCHE=${VERSION_ARRAY[2]}
  BUILD_NUMBER=${VERSION_ARRAY[3]}
  case $VERSION_TYPE in
  all)
    echo ${VERSION}
    ;;
  full)
    echo "$MAJOR.$MINOR.$PATCHE"
    ;;
  # increment_patche)
  #   PATCHE_WILL_BUILD=$((PATCHE + 1))
  #   echo "$MAJOR.$MINOR.${PATCHE_WILL_BUILD}"
  #   ;;
  major)
    echo $MAJOR
    ;;
  minor)
    echo $MINOR
    ;;
  patche)
    echo $PATCHE
    ;;
  build)
    echo $BUILD_NUMBER
    ;;
  increment_build)
    echo $BUILD_NUMBER + 1 | bc
    ;;
  environment)
    echo ${ENVIRONMENT}
    ;;
  increment_major)
    echo "${VERSION_NAME_PATH}/${ENVIRONMENT}/v$((MAJOR+1)).$MINOR.$PATCHE+$BUILD_NUMBER"
    ;;
  increment_minor)
    echo "${VERSION_NAME_PATH}/${ENVIRONMENT}/v$MAJOR.$((MINOR+1)).0+$BUILD_NUMBER"
    ;;
  increment_patche)
    echo "${VERSION_NAME_PATH}/${ENVIRONMENT}/v$MAJOR.$MINOR.$((PATCHE+1))+$BUILD_NUMBER"
    ;;
  esac
}

increment_build_number() {
  TAG_LIST=$(git tag | wc -l)
  if [ $TAG_LIST -eq 0 ]; then
    exit "Vui lòng tạo tag trong repository của bạn"
  fi
  STAGE=$2
  if [[ ! "$STAGE" ]]; then
    exit "Missing STAGE environment"
  fi
  PREFIX=''
  if [[ "$1" ]]; then
    PREFIX="$1/"
  fi
  PRO_TAG=$(git tag --sort=-version:refname -l "${PREFIX}production/*" | head -n 1)
  NEW_TAG=''

  if [[ "$STAGE" == "production" ]]; then
    PRO_TAG_FULL=$(split_version $PRO_TAG full)
    PRO_BUILD_NUMBER=$(split_version $PRO_TAG build)
    PRO_BUILD_NUMBER_INCREMENT=$((PRO_BUILD_NUMBER + 1))
    NEW_TAG="${PREFIX}production/v${PRO_TAG_FULL}+${PRO_BUILD_NUMBER_INCREMENT}"
  else
    STAGE_TAG=$(git tag --sort=-version:refname -l "${PREFIX}${STAGE}/*" | head -n 1)
    STAGE_TAG_FULL=$(split_version $PRO_TAG full)
    STAGE_TAG_LATEST=$(git tag --sort=-version:refname -l "${PREFIX}${STAGE}/v${STAGE_TAG_FULL}+*" | head -n 1)
    STAGE_BUILD_NUMBER=1
    if [[ $STAGE_TAG_LATEST ]]; then
      STAGE_BUILD_NUMBER=$(split_version $STAGE_TAG_LATEST increment_build)
    fi
    NEW_TAG="${PREFIX}${STAGE}/v${STAGE_TAG_FULL}+${STAGE_BUILD_NUMBER}"
  fi
  create_tag $NEW_TAG
}
