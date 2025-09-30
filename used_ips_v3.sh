#!/usr/bin/env bash
set -euo pipefail

input_csv="project_subnets.csv"

trim() {
  local s="${1//$'\r'/}"                 # strip CR
  s="${s#"${s%%[![:space:]]*}"}"         # ltrim
  s="${s%"${s##*[![:space:]]}"}"         # rtrim
  printf '%s' "$s"
}

while IFS=, read -r -a cols; do
  # Skip header (tolerate spaces/case)
  first="$(trim "${cols[0]}")"
  [[ -z "$first" ]] && continue
  [[ "${first,,}" == "project" ]] && continue

  project="$first"
  echo "==== Project: $project ===="

  # Iterate every remaining column as a subnet name
  for ((i=1; i<${#cols[@]}; i++)); do
    subnet="$(trim "${cols[$i]}")"
    [[ -z "$subnet" ]] && continue

    # Query this subnet only
    output=$(gcloud compute addresses list \
      --project="$project" \
      --sort-by=subnetwork \
      --format="table(name,address,subnetwork,region,status)" \
      --filter="subnetwork~'$subnet'")

    if [[ -z "$output" ]]; then
      echo "Subnet: $subnet → No reserved IPs found"
    else
      echo "Subnet: $subnet"
      echo "$output"
    fi
  done
done < "$input_csv"
