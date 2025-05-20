pipeline {
    agent any

    environment {
        DB_HOST = 'testpostgrestest.postgres.database.azure.com'
        DB_PORT = '5432'
        DB_NAME = 'testpostgrestest' // Connects to default db first
        DB_USER = 'postgres@testpostgrestest' // Fully qualified Azure username
        DB_CRED_ID = 'pg-azure-creds' // Jenkins credential with username/password
    }

    stages {
        stage('Install PostgreSQL Client') {
            steps {
                sh '''
                    apt-get update
                    apt-get install -y postgresql-client
                '''
            }
        }

        stage('Create Database') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "Creating sampledb..."
                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d $DB_NAME -c "CREATE DATABASE sampledb;"
                    """
                }
            }
        }

        stage('Insert Data') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "Inserting data..."
                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d sampledb -f insert_data.sql
                    """
                }
            }
        }

        stage('Query Data') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "Querying data..."
                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d sampledb -f query_data.sql > query_output.txt
                    """
                    archiveArtifacts artifacts: 'query_output.txt', fingerprint: true
                }
            }
        }
    }
}
