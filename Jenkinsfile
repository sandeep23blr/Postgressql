pipeline {
    agent any

    environment {
        DB_HOST = 'testpostgrestest.postgres.database.azure.com'
        DB_PORT = '5432'
        DB_NAME = 'testpostgrestest'
        DB_CRED_ID = 'pg-azure-creds' // Jenkins credential ID
        CSV_FILE = 'data.csv' // CSV file pushed to GitHub
        TABLE_NAME = 'csv_data'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/sandeep23blr/Postgressql.git', branch: 'main', credentialsId: 'git'
            }
        }

        stage('Insert CSV into Database') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "Creating table if not exists..."
                        echo "CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
                            id SERIAL PRIMARY KEY,
                            name TEXT,
                            email TEXT
                        );" > create_table.sql

                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d $DB_NAME -f create_table.sql

                        echo "Copying CSV data into table..."
                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d $DB_NAME -c "\\COPY ${TABLE_NAME}(name,email) FROM '${CSV_FILE}' CSV HEADER;"
                    """
                }
            }
        }
    }
}
