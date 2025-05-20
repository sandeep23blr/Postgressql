pipeline {
    agent any

    environment {
        DB_HOST = 'your-db-server-name.postgres.database.azure.com'
        DB_PORT = '5432'
        DB_NAME = 'your-database-name'
        DB_CRED_ID = 'pg-azure-creds' // Jenkins credential ID
    }

    stages {
        stage('Checkout SQL Files') {
            steps {
                git url: 'https://github.com/sandeep23blr/Postgressql.git', branch: 'main', credentialsId: 'git'
            }
        }

        stage('Insert Data') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "Inserting data into Azure PostgreSQL..."
                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d $DB_NAME -f insert_data.sql
                    """
                }
            }
        }

        stage('Query Data') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "Querying data from Azure PostgreSQL..."
                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d $DB_NAME -f query_data.sql > query_output.txt
                    """
                    archiveArtifacts artifacts: 'query_output.txt', fingerprint: true
                }
            }
        }
    }
}
