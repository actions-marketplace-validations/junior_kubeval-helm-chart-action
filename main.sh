#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")

main() {
    args=(--k8s-version "${INPUT_KUBERNETES_VERSION?'k8s-version' is required}")
    args+=(--charts-dir "${INPUT_CHARTS_DIR?Input 'charts_dir' is required}")

    if [[ -n "${INPUT_KUBEVAL_VERSION:-}" ]]; then
        args+=(--version "${INPUT_KUBEVAL_VERSION}")
    fi

    if [[ -n "${INPUT_K8S_VERSION:-}" ]]; then
        args+=(--k8s-version "${INPUT_K8S_VERSION}")
    fi

    "$SCRIPT_DIR/kubeval_helm_chart.sh" "${args[@]}"
}

main