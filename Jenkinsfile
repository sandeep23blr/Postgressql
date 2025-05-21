pipeline {
    agent any

    environment {
        DB_HOST = 'testpostgrestest.postgres.database.azure.com'
        DB_PORT = '5432'
        DB_NAME = 'postgres'
        DB_CRED_ID = 'pg-azure-creds'
        VENV_PATH = '.venv'
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
                        error "No supported file found."
                    }
                    env.DATA_FILE = file
                    def base = file.tokenize('/')[-1].split("\\.")[0].replaceAll("[^a-zA-Z0-9_]", "_").toLowerCase()
                    env.TABLE_NAME = base
                    echo "Detected file: ${env.DATA_FILE}, table: ${env.TABLE_NAME}"
                }
            }
        }

        stage('Setup Python Virtual Env') {
            steps {
                sh '''
                    python3 -m venv ${VENV_PATH}
                    . ${VENV_PATH}/bin/activate
                    ${VENV_PATH}/bin/pip install --upgrade pip
                    ${VENV_PATH}/bin/pip install pandas sqlalchemy psycopg2-binary openpyxl
                '''
            }
        }

        stage('Upload Data to DB') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    writeFile file: 'upload.py', text: '''
import os
import pandas as pd
from sqlalchemy import create_engine, text
import os.path

file_path = os.environ['DATA_FILE']
table_name = os.environ['TABLE_NAME']
db_user = os.environ['USERNAME']
db_pass = os.environ['PASSWORD']
db_name = os.environ['DB_NAME']
db_host = os.environ['DB_HOST']
db_port = os.environ['DB_PORT']

ext = os.path.splitext(file_path)[-1].lower()
if ext == '.csv':
    df = pd.read_csv(file_path)
elif ext in ['.xls', '.xlsx']:
    df = pd.read_excel(file_path)
elif ext == '.json':
    df = pd.read_json(file_path)
else:
    raise Exception(f"Unsupported file type: {ext}")

df.columns = [col.strip().replace(" ", "_").replace("-", "_").lower() for col in df.columns]

engine = create_engine(f"postgresql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}")

with engine.begin() as conn:
    create_stmt = f'CREATE TABLE IF NOT EXISTS {table_name} (' + ', '.join([f'{col} TEXT' for col in df.columns]) + ')'
    conn.execute(text(create_stmt))
    df.to_sql(table_name, conn, if_exists='append', index=False)
print(f"Uploaded {len(df)} rows to table '{table_name}'")
'''
                    sh """
                        . ${env.VENV_PATH}/bin/activate
                        DATA_FILE="${env.DATA_FILE}" TABLE_NAME="${env.TABLE_NAME}" DB_NAME="${env.DB_NAME}" DB_HOST="${env.DB_HOST}" DB_PORT="${env.DB_PORT}" USERNAME="$USERNAME" PASSWORD="$PASSWORD" python upload.py
                    """
                }
            }
        }

        stage('Verify Upload') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        echo "Verifying upload..."
                        export PGPASSWORD="$PASSWORD"
                        psql "host=${env.DB_HOST} port=${env.DB_PORT} user=$USERNAME dbname=${env.DB_NAME} sslmode=require" -c "SELECT COUNT(*) FROM ${env.TABLE_NAME};"
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Data upload complete!"
        }
        failure {
            echo "Pipeline failed. Please check logs for details."
        }
    }
}
