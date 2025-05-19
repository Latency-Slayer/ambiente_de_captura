import psutil
from datetime import datetime
import time
import requests

def collect_process():
    processos = psutil.process_iter()

    process_list = []
    for p in processos:
        try:
            dict_processos = {
                "name": p.name(),
                "pid": p.pid or None,
                "status": p.status() or None,
                "cpu_percent": p.cpu_percent(interval=None), 
                "ram_percent": p.memory_percent(),
                "ram_gb": p.memory_info().vms / 1024 ** 3,
            }
            process_list.append(dict_processos)
        except:
            continue
    
    top_cpu = sorted(process_list, key=lambda x: x["cpu_percent"], reverse=True)[:6]
        
    return {
        "process_data": top_cpu,
        "timestamp": datetime.now().isoformat()
    }

def send_process(url):
    while True:
        process = collect_process()

        payload = {
            "process": process
        }
        try:
            response = requests.post(url, json=payload)
            json_response = response.json()  # interpreta o corpo da resposta como JSON
            print("Dados enviados:", payload)
        except requests.RequestException as e:
            print("Erro ao enviar dados:", e)

        time.sleep(2) 

url = "http://localhost:8080/process/api/real-time"  # seu endpoint que vai receber JSON
send_process(url)
