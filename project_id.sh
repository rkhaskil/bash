#LOOKUP PROJECT ID USING PROJECT NUMBER IN GCP AND VICE VERSA
project() {
    if [ -z "$1" ]; then
        echo "Usage: project <PROJECT_ID | PROJECT_NUMBER>"
        return 1
    fi

    # Try to detect if input is numeric (project number) or not (project ID)
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        # Input is a number → get project ID
        gcloud projects describe "$1" --format="value(projectId)"
    else
        # Input is a string → get project number
        gcloud projects describe "$1" --format="value(projectNumber)"
    fi
}
