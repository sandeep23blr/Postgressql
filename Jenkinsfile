pipeline {
    agent any

    environment {
        DB_HOST = 'posttest.postgres.database.azure.com'
        DB_PORT = '5432'
        DB_NAME = 'posttest' // Will switch to sampledb inside SQL
        DB_USER = 'sandeep
        DB_CRED_ID = 'pg-azure-creds'
    }

    stages {
        stage('Install PostgreSQL Client') {
            steps {
                sh 'sudo apt-get update && sudo apt-get install -y postgresql-client'
            }
        }

        stage('Create Database') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d $DB_NAME -f create_db.sql
                    """
                }
            }
        }

        stage('Insert Data') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d sampledb -f insert_data.sql
                    """
                }
            }
        }

        stage('Query Data') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d sampledb -f query_data.sql > query_output.txt
                    """
                    archiveArtifacts artifacts: 'query_output.txt', fingerprint: true
                }
            }
        }
    }
}
