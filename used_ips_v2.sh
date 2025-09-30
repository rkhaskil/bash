#!/usr/bin/env bash
set -euo pipefail

input_csv="project_subnets.csv"
output_file="no_reserved_ips.txt"

# Clear old results
> "$output_file"

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

  echo "==== Project: $project ===="

  for subnet in "${subs[@]}"; do
    output=$(gcloud compute addresses list \
      --project="$project" \
      --sort-by=subnetwork \
      --format="table(name,address,subnetwork,region,status)" \
      --filter="subnetwork~'$subnet'")

    if [[ -z "$output" ]]; then
      echo "Subnet: $subnet → No reserved IPs found"
      echo "$project,$subnet" >> "$output_file"
    else
      echo "Subnet: $subnet"
      echo "$output"
    fi
  done
done < "$input_csv"

echo
echo "✅ Subnets with no reserved IPs written to: $output_file"
