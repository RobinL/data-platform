#!/usr/bin/env bash

MODE="${1}"

case ${MODE} in
  containers)
    PATH_FILTER_CONFIGURATION_FILE=".github/path-filter/containers.yml"
    SEARCH_PATTERN="*Dockerfile*"
    SKIP_FILE=".containers-path-filter-ignore"
  ;;
  terraform)
    PATH_FILTER_CONFIGURATION_FILE=".github/path-filter/terraform.yml"
    SEARCH_PATTERN=".terraform.lock.hcl"
    SKIP_FILE=".terraform-path-filter-ignore"
  ;;
  pytest)
    PATH_FILTER_CONFIGURATION_FILE=".github/path-filter/pytest.yml"
    SEARCH_PATTERN="**/*_test.py"
    SKIP_FILE=".pytest-path-filter-ignore"
  ;;
  *)
    echo "Usage: ${0} [containers|terraform|pytest]"
    exit 1
  ;;
esac

if [[ "${MODE}" == "pytest" ]]; then
  folders=$(find . -type f -wholename "${SEARCH_PATTERN}" | sed 's|/tests/.*$||g' | sort -h | uniq | cut -c 3-)
else
  folders=$(find . -type f -name "${SEARCH_PATTERN}" -exec dirname {} \; | sort -h | uniq | cut -c 3-)
fi

export folders

echo "=== Folders ==="
echo "${folders}"

echo "Generating ${PATH_FILTER_CONFIGURATION_FILE}"
cat >"${PATH_FILTER_CONFIGURATION_FILE}" <<EOL
---
# This file is auto-generated by running the below command, do not manually amend.
# bash scripts/path-filter/configuration-generator.sh ${MODE}

EOL

for folder in ${folders}; do

  if [[ -f "${folder}/${SKIP_FILE}" ]]; then
    echo "Ignoring ${folder}"
    continue
  fi

  if [[ "${MODE}" == "terraform" ]]; then
    baseName=$(echo "${folder}" | sed 's|/|-|g' | sed 's|terraform-||')
  else
    baseName=$(basename "${folder}")
  fi

  printf "${baseName}: ${folder}/**\n" >>"${PATH_FILTER_CONFIGURATION_FILE}"
done
