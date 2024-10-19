#!/bin/bash

# Initialize default values for the number of web and judge containers
num_web_containers=0
num_judge_containers=0

# Function to print usage
usage() {
  echo -e "Please provide the number of domserver instances to deploy.\nUsage: $0 [-w number_of_domserver_web_containers] [-j number_of_domserver_judge_containers]"
  exit 1
}

# If no flags are provided, trigger usage
if [[ $# -eq 0 ]]; then
  usage
fi

# Parse flags
while getopts "w:j:" opt; do
  case "$opt" in
    w) num_web_containers=$OPTARG ;;
    j) num_judge_containers=$OPTARG ;;
    *) usage ;; # Print usage if invalid flags are provided
  esac
done

# SQL query to check if the database has already been populated
# Check if a key table in the DOMjudge schema exists (like the `team` table)
CHECK_SCHEMA_SQL="SELECT 1 FROM information_schema.tables WHERE table_schema='$DJ_DB' AND table_name='team' LIMIT 1;"


# Run the SQL query on the MariaDB container
RESULT=$(docker exec -i mariadb mariadb -u"$DJ_DB_USER" -p"$DJ_DB_PASSWORD" -e "$CHECK_SCHEMA_SQL")

# If the query returns a result, schema is populated
if [[ "$RESULT" == *"1"* ]]; then
  echo -e "Database schema is already populated.\nSkipping running the domserver-judge-1 container."
else
  echo -e "Database schema is not populated.\nRunning domserver-judge-1 container on judge-network."
fi

docker compose -f domserver-main.yml up -d

#Setting up the domserver-web compose file 

# Start with an empty docker-compose.yml file
> domserver.yml

# Copy the static parts of the docker-compose.yml file (if any)
cat <<EOF >> domserver.yml
services:
EOF

current_web_count = docker ps --filter "name=domserver-web-" --format "{{.Names}}" | grep -c "domserver-web-"
# Loop through and create judgehost instances
for ((i = current_web_count + 1; i <= num_web_containers + current_web_count; i++))
do
  # Replace the placeholder {{ID}} with the actual number
  sed "s/{{ID}}/$i/g" domserver.template.yml >> domserver.yml
  cat <<EOF >> judgehost.yml
      - web-network
EOF
done

cat <<EOF >> domserver.yml
volumes:
EOF
# Loop through and create judgehost instances
for ((i=1; i<=NUM_JUDGEHOSTS; i++))
do  
cat <<EOF >> judgehost.yml  
  judgehost-data-$i:
    name: judgehost-data-$i
EOF
done

cat <<EOF >> judgehost.yml
volumes:
  submissions-data:
    name: domserver-submissions-data
  judgings-data:
    name: domserver-judgings-data

networks:
  mariadb-network:
    name: mariadb-network
    external: true
  judge-network:
    name: judge-network
  traefik-public:
    name: traefik-public
    external: true
EOF

# Now you can use docker-compose up to launch all instances
# docker compose -f judgehost.yml up -d
