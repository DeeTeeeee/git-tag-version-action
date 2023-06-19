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
    echo "${VERSION_NAME_PATH}/${ENVIRONMENT}/v$((MAJOR+1)).0.0+$BUILD_NUMBER"
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
