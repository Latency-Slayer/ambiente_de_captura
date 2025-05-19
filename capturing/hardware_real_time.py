import psutil
from datetime import datetime
import time
import requests

def collect_metrics():
    data = {
        "cpu_percent": psutil.cpu_percent(),
        "ram_percent": psutil.virtual_memory().percent,
        "disk_percent": psutil.disk_usage('/').percent,  # exemplo de uso disco
        "timestamp": datetime.now().isoformat()
    }
    return data

def send_metrics(url):
    while True:
        metrics = collect_metrics()

        payload = {
            "metrics": metrics
        }
        try:
            response = requests.post(url, json=payload)
            json_response = response.json()  # interpreta o corpo da resposta como JSON
            print("Dados enviados:", payload)
        except requests.RequestException as e:
            print("Erro ao enviar dados:", e)

        time.sleep(5) 

url = "http://localhost:8080/hardware/api/real-time"  # seu endpoint que vai receber JSON
send_metrics(url)
