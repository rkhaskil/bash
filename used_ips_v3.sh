#!/usr/bin/env bash
set -euo pipefail

input_csv="project_subnets.csv"

trim() {
  # strip CRLF carriage return and trim leading/trailing whitespace
  local s="${1//$'\r'/}"
  # leading
  s="${s#"${s%%[![:space:]]*}"}"
  # trailing
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

while IFS=, read -r -a cols; do
  # skip header (tolerate spaces/case)
  header="$(trim "${cols[0]}")"
  [[ "${header,,}" == "project" ]] && continue

  project="$header"
  subnets_raw=("${cols[@]:1}")

  subs=()
  for s in "${subnets_raw[@]}"; do
    t="$(trim "$s")"
    [[ -n "$t" ]] && subs+=("$t")
  done

  echo "==== Project: $project | Subnets: ${subs[*]:-<none>} ===="

  # If no subnets on this row, move on
  [[ ${#subs[@]} -eq 0 ]] && { echo "No subnets listed for $project"; continue; }

  # Build a gcloud filter like: (subnetwork~'sub1' OR subnetwork~'sub2' ...)
  # Using OR avoids some RE2 surprises and handles names cleanly.
  filter=""
  for subnet in "${subs[@]}"; do
    # match by name anywhere in the full subnetwork URL
    part="subnetwork~'$subnet'"
    if [[ -z "$filter" ]]; then
      filter="$part"
    else
      filter="$filter OR $part"
    fi
  done

  output=$(gcloud compute addresses list \
    --project="$project" \
    --sort-by=subnetwork \
    --format="table(name,address,subnetwork,region,status)" \
    --filter="($filter)")

  if [[ -z "$output" ]]; then
    echo "No reserved IPs found"
  else
    echo "$output"
  fi
done < "$input_csv"
