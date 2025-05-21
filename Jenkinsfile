pipeline {
    agent any

    environment {
        DB_HOST = 'testpostgrestest.postgres.database.azure.com'
        DB_PORT = '5432'
        DB_NAME = 'postgres'
        DB_CRED_ID = 'pg-azure-creds'
        CSV_FILE = 'data.csv'
        TABLE_NAME = 'csv_data'
        LOCAL_CSV_PATH = 'workspace_data.csv'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/sandeep23blr/Postgressql.git', branch: 'main', credentialsId: 'git'
            }
        }

        stage('Prepare Table and Upload Data') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "Creating table if not exists..."

                        echo "CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
                            id SERIAL PRIMARY KEY,
                            name TEXT,
                            email TEXT
                        );" > create_table.sql

                        echo "Running SQL to create table..."
                        PGSSLMODE=require PGPASSWORD=\$PASSWORD psql -h $DB_HOST -p $DB_PORT -U \$USERNAME -d $DB_NAME -f create_table.sql

                        echo "Preparing CSV for copy..."
                        cp ${CSV_FILE} ${LOCAL_CSV_PATH}

                        echo "Inserting data from CSV into table..."
                        PGSSLMODE=require PGPASSWORD=\$PASSWORD psql -h $DB_HOST -p $DB_PORT -U \$USERNAME -d $DB_NAME -c "\\COPY ${TABLE_NAME}(name,email) FROM '${LOCAL_CSV_PATH}' CSV HEADER;"
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed. Please check the logs above for details."
        }
        success {
            echo "Data successfully uploaded to Azure PostgreSQL!"
        }
    }
}
