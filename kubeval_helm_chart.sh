#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

DEFAULT_KUBEVAL_VERSION=0.15.0
# DEFAULT_CHART_DIRS="$(git diff --find-renames --name-only "$(git rev-parse --abbrev-ref HEAD)" remotes/origin/master -- charts | grep '[cC]hart.yaml' | sed -e 's#/[Cc]hart.yaml##g')"
DEFAULT_SCHEMA_LOCATION="https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/"

show_help() {
cat << EOF
Usage: $(basename "$0") <options>
    -h, --help          Display help
    -v, --version       The kubeval version to use (default: $DEFAULT_KUBEVAL_VERSION)
    -d, --charts-dir    The charts directory (defaut: charts)
    -k, --k8s-version   kubernetes version to be validated
EOF
}

main() {
    local kubeval_version="$DEFAULT_KUBEVAL_VERSION"
    local kubernetes_version=
    # local chart_dirs=$DEFAULT_CHART_DIRS
    local charts_dir=charts
    local schema_location=$DEFAULT_SCHEMA_LOCATION
    local k8s_version=

    parse_command_line "$@"

    if [[ -z "$k8s_version" ]]; then
        echo "ERROR: '-k|--k8s-version' is required." >&2
        show_help
        exit 1
    fi

    echo 'Looking up latest tag...'
    local latest_tag
    latest_tag=$(lookup_latest_tag)

    echo "Discovering changed charts since '$latest_tag'..."
    local changed_charts=()
    readarray -t changed_charts <<< "$(lookup_changed_charts "$latest_tag")"

    if [[ -n "${changed_charts[*]}" ]]; then
        install_kubeval

        for chart in "${changed_charts[@]}"; do
            if [[ -d "$chart" ]]; then
                kubeval_chart "$chart"
            else
                echo "Chart '$chart' no longer exists in repo. Skipping it..."
            fi
        done

    else
        echo "Nothing to do. No chart changes detected."
    fi

    # popd > /dev/null
}

parse_command_line() {
    while :; do
        case "${1:-}" in
            -h|--help)
                show_help
                exit
                ;;
            -v|--version)
                if [[ -n "${2:-}" ]]; then
                    version="$2"
                    shift
                else
                    echo "ERROR: '-v|--version' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            -d|--charts-dir)
                if [[ -n "${2:-}" ]]; then
                    charts_dir="$2"
                    shift
                else
                    echo "ERROR: '-d|--charts-dir' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            -k|--k8s-version)
                if [[ -n "${2:-}" ]]; then
                    k8s_version="$2"
                    shift
                else
                    echo "ERROR: '-k|--k8s-version' cannot be empty." >&2
                    show_help
                    exit 1
                fi
                ;;
            *)
                break
                ;;
        esac

        shift
    done
}

install_kubeval() {
    echo "Installing kubeval..."

    curl -sSLo /tmp/kubeval.tar.gz https://github.com/instrumenta/kubeval/releases/download/$version/kubeval-linux-amd64.tar.gz
    tar -xzf /tmp/kubeval.tar.gz kubeval
}

lookup_latest_tag() {
    git fetch --tags > /dev/null 2>&1

    if ! git describe --tags --abbrev=0 2> /dev/null; then
        git rev-list --max-parents=0 --first-parent HEAD
    fi
}

lookup_changed_charts() {
    local commit="$1"

    local changed_files
    changed_files=$(git diff --find-renames --name-only "$commit" -- "$charts_dir")

    local fields
    if [[ "$charts_dir" == '.' ]]; then
        fields='1'
    else
        fields='1,2'
    fi

    cut -d '/' -f "$fields" <<< "$changed_files" | uniq | filter_charts
}

filter_charts() {
    while read chart; do
        [[ ! -d "$chart" ]] && continue
        local file="$chart/Chart.yaml"
        if [[ -f "$file" ]]; then
            echo $chart
        else
           echo "WARNING: $file is missing, assuming that '$chart' is not a Helm chart. Skipping." 1>&2
        fi
    done
}

kubeval_chart() {
    local chart="$1"

    echo "Validating chart '$chart'..."

    helm template --values "$chart"/ci/ci-values.yaml "$chart" | ./kubeval --strict --ignore-missing-schemas --kubernetes-version "${k8s_version#v}" --schema-location "$schema_location"
}

readarray_macos() {
  local __resultvar=$1
  declare -a __local_array
  let i=0
  while IFS=$'\n' read -r line_data; do
      __local_array[i]=${line_data}
      ((++i))
  done < $2
  if [[ "$__resultvar" ]]; then
    eval $__resultvar="'${__local_array[@]}'"
  else
    echo "${__local_array[@]}"
  fi
}

main "$@"