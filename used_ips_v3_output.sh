#!/usr/bin/env bash
set -euo pipefail

input_csv="project_subnets.csv"
no_ips_file="no_reserved_ips.txt"

# Clear previous results
> "$no_ips_file"

trim() {
  local s="${1//$'\r'/}"                 # strip CR
  s="${s#"${s%%[![:space:]]*}"}"         # ltrim
  s="${s%"${s##*[![:space:]]}"}"         # rtrim
  printf '%s' "$s"
}

while IFS=, read -r -a cols; do
  # Skip header
  first="$(trim "${cols[0]}")"
  [[ -z "$first" ]] && continue
  [[ "${first,,}" == "project" ]] && continue

  project="$first"
  echo "==== Project: $project ===="

  for ((i=1; i<${#cols[@]}; i++)); do
    subnet="$(trim "${cols[$i]}")"
    [[ -z "$subnet" ]] && continue

    output=$(gcloud compute addresses list \
      --project="$project" \
      --sort-by=subnetwork \
      --format="table(name,address,subnetwork,region,status)" \
      --filter="subnetwork~'$subnet'")

    if [[ -z "$output" ]]; then
      echo "Subnet: $subnet → No reserved IPs found"
      echo "$project,$subnet" >> "$no_ips_file"
    else
      echo "Subnet: $subnet"
      echo "$output"
    fi
  done
done < "$input_csv"

echo
echo "Subnets with no reserved IPs written to: $no_ips_file"
