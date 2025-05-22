pipeline {
    agent any

    environment {
        DB_HOST = 'testpostgrestest.postgres.database.azure.com'
        DB_PORT = '5432'
        DB_NAME = 'postgres'
        DB_CRED_ID = 'pg-azure-creds'
    }

    stages {
        stage('Detect Latest Data File') {
            steps {
                script {
                    def file = sh(script: "find ./uploads -type f \\( -iname '*.csv' -o -iname '*.json' -o -iname '*.xlsx' \\) -printf '%T@ %p\\n' | sort -n | tail -n 1 | cut -d' ' -f2-", returnStdout: true).trim()
                    if (!file) {
                        error "No supported data file found in ./uploads directory."
                    }
                    env.DATA_FILE = file

                    def filename = file.tokenize('/').last()
                    def base = filename.split("\\.")[0].replaceAll("[^a-zA-Z0-9_]", "_").toLowerCase()
                    env.TABLE_NAME = base

                    echo "Detected latest file: ${env.DATA_FILE}"
                    echo "Target table: ${env.TABLE_NAME}"
                }
            }
        }

        stage('Upload to PostgreSQL') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    writeFile file: 'upload.py', text: '''
import os
import pandas as pd
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus

file_path = os.environ['DATA_FILE']
table_name = os.environ['TABLE_NAME']
db_user = os.environ['USERNAME']
db_pass = quote_plus(os.environ['PASSWORD'])
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
    columns_ddl = ", ".join([f"{col} TEXT" for col in df.columns])
    create_sql = f"CREATE TABLE IF NOT EXISTS {table_name} ({columns_ddl});"
    conn.execute(text(create_sql))

    df.to_sql(table_name, conn, if_exists='append', index=False)

print(f"Uploaded {len(df)} rows to table '{table_name}'")
'''
                    sh """
                        DATA_FILE="${env.DATA_FILE}" TABLE_NAME="${env.TABLE_NAME}" DB_NAME="${env.DB_NAME}" DB_HOST="${env.DB_HOST}" DB_PORT="${env.DB_PORT}" USERNAME="$USERNAME" PASSWORD="$PASSWORD" python3 upload.py
                    """
                }
            }
        }

        stage('Verify Upload') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh """
                        export PGPASSWORD="$PASSWORD"
                        echo "Verifying data count in table '${TABLE_NAME}'..."
                        psql "host=${DB_HOST} port=${DB_PORT} user=$USERNAME dbname=${DB_NAME} sslmode=require" -c "SELECT COUNT(*) FROM ${TABLE_NAME};"
                    """
                }
            }
        }

        stage('Ask for Download Filename') {
            steps {
                script {
                    env.DOWNLOAD_FILENAME = input(
                        message: "Enter the name to save the pulled data (e.g. data.csv):",
                        parameters: [
                            string(name: 'filename', defaultValue: "${env.TABLE_NAME}_downloaded.csv", description: 'Output file name')
                        ]
                    )
                }
            }
        }

        stage('Pull Data from PostgreSQL') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DB_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    writeFile file: 'pull_data.py', text: '''
import os
import pandas as pd
from sqlalchemy import create_engine
from urllib.parse import quote_plus

table_name = os.environ['TABLE_NAME']
output_file = os.environ.get('DOWNLOAD_FILENAME', f"{table_name}_downloaded.csv")

db_user = os.environ['USERNAME']
db_pass = quote_plus(os.environ['PASSWORD'])
db_name = os.environ['DB_NAME']
db_host = os.environ['DB_HOST']
db_port = os.environ['DB_PORT']

engine = create_engine(f"postgresql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}")
df = pd.read_sql(f"SELECT * FROM {table_name}", con=engine)

df.to_csv(output_file, index=False)
print(f"Downloaded {len(df)} rows from table '{table_name}' into '{output_file}'")
'''
                    sh """
                        TABLE_NAME="${env.TABLE_NAME}" DOWNLOAD_FILENAME="${env.DOWNLOAD_FILENAME}" DB_NAME="${env.DB_NAME}" DB_HOST="${env.DB_HOST}" DB_PORT="${env.DB_PORT}" USERNAME="$USERNAME" PASSWORD="$PASSWORD" python3 pull_data.py
                    """
                }
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: '*_downloaded.csv', fingerprint: true
            echo "Upload and download complete!"
        }
        failure {
            echo "Pipeline failed. Check console output for details."
        }
    }
}
