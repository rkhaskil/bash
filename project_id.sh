#LOOKUP PROJECT ID USING PROJECT NUMBER IN GCP
project() {
    if [ -z "$1" ]; then
        echo "Usage: project <PROJECT_NUMBER>"
        return 1
    fi
    gcloud projects describe "$1" --format="value(projectId)"
}
