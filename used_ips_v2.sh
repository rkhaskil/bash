#!/usr/bin/env bash
set -euo pipefail

input_csv="project_subnets.csv"

while IFS=, read -r -a cols; do
  # Skip header row
  [[ "${cols[0]}" == "project" ]] && continue

  project="${cols[0]}"
  subnets=("${cols[@]:1}")   # everything after the first column

  # Drop any empty subnet values
  subs=()
  for s in "${subnets[@]}"; do
    [[ -n "$s" ]] && subs+=("$s")
  done

  # Build regex like (subnet1|subnet2|subnet3)
  regex="$(printf "%s|" "${subs[@]}")"
  regex="(${regex%|})"

  echo "==== Project: $project | Subnets: ${subs[*]} ===="

  # Run gcloud and capture output
  output=$(gcloud compute addresses list \
    --project="$project" \
    --sort-by=subnetwork \
    --format="table(name,address,subnetwork,region,status)" \
    --filter="subnetwork~'$regex'")

  if [[ -z "$output" ]]; then
    echo "No reserved IPs found"
  else
    echo "$output"
  fi
done < "$input_csv"
