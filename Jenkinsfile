pipeline {
    agent any

    environment {
        DB_HOST = 'testpostgrestest.postgres.database.azure.com'
        DB_PORT = '5432'
        DB_NAME = 'postgres'
        DB_CRED_ID = 'pg-azure-creds'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/sandeep23blr/Postgressql.git', branch: 'main', credentialsId: 'git'
            }
        }

        stage('Detect Data File') {
            steps {
                script {
                    def file = sh(script: "find . -type f \\( -iname '*.csv' -o -iname '*.json' -o -iname '*.xlsx' \\) | head -n 1", returnStdout: true).trim()
                    if (!file) {
                        error "No supported file (CSV, JSON, XLSX) found in repo."
                    }
                    env.DATA_FILE = file
                    def base = file.tokenize('/')[-1].split("\\.")[0].replaceAll("[^a-zA-Z0-9_]", "_").toLowerCase()
                    env.TABLE_NAME = base
                    echo "Found file: ${env.DATA_FILE}, will upload to table: ${env.TABLE_NAME}"
                }
            }
        }

        stage('Install Python Requirements') {
            steps {
                sh 'pip install pandas sqlalchemy psycopg2-binary openpyxl'
            }
        }

        stage('Upload Data to DB') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    writeFile file: 'upload.py', text: '''
import os
import pandas as pd
from sqlalchemy import create_engine, text

file_path = os.environ['DATA_FILE']
table_name = os.environ['TABLE_NAME']
db_user = os.environ['USERNAME']
db_pass = os.environ['PASSWORD']
db_name = os.environ['DB_NAME']
db_host = os.environ['DB_HOST']
db_port = os.environ['DB_PORT']

engine = create_engine(f"postgresql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}")

# Load data
ext = os.path.splitext(file_path)[-1].lower()
if ext == '.csv':
    df = pd.read_csv(file_path)
elif ext in ['.xls', '.xlsx']:
    df = pd.read_excel(file_path)
elif ext == '.json':
    df = pd.read_json(file_path)
else:
    raise Exception(f"Unsupported file type: {ext}")

# Normalize column names to match PostgreSQL constraints
df.columns = [col.strip().replace(" ", "_").replace("-", "_").lower() for col in df.columns]

# Append or create table automatically
with engine.begin() as conn:
    df.head(0).to_sql(table_name, conn, if_exists='append', index=False)
    df.to_sql(table_name, conn, if_exists='append', index=False)
    print(f"Data uploaded to table '{table_name}' successfully.")
'''
                    sh 'python3 upload.py'
                }
            }
        }

        stage('Verify Upload') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        echo "Verifying data in table ${TABLE_NAME}..."
                        PGSSLMODE=require PGPASSWORD=$PASSWORD psql -h $DB_HOST -p $DB_PORT -U $USERNAME -d $DB_NAME -c "SELECT COUNT(*) FROM ${TABLE_NAME};"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Data successfully detected, uploaded, and verified in PostgreSQL."
        }
        failure {
            echo "Pipeline failed. Please check the logs for errors."
        }
    }
}
