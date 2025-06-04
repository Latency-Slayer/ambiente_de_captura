import psutil
from datetime import datetime
import time
import requests
import os
import dotenv

dotenv.load_dotenv()


def collect_data():
    for p in psutil.process_iter():
        try:
            if p.name() in ["System Idle Process", "System"]:
                continue
            p.cpu_percent(interval=None)
        except:
            continue

    cpu_percent_total = psutil.cpu_percent(interval=None)
    ram_percent_total = psutil.virtual_memory().percent
    disk_percent = psutil.disk_usage('/').percent

    cpu_count = psutil.cpu_count(logical=True)
    
    process_list = []
    for p in psutil.process_iter():
        try:
            if p.name() in ["System Idle Process", "System"]:
                continue

            dict_processos = {
                "name": p.name(),
                "pid": p.pid,
                "status": p.status(),
                "cpu_percent": round(p.cpu_percent(interval=None) / cpu_count , 2),
                "ram_percent": round(p.memory_percent(), 2)
            }
            process_list.append(dict_processos)
        except:
            continue


    timestamp = datetime.now().isoformat()

    metrics = {
        "cpu_percent": cpu_percent_total,
        "ram_percent": ram_percent_total,
        "disk_percent": disk_percent,
        "timestamp": timestamp
    }

    process = {
        "process_data": process_list,
        "timestamp": timestamp,
    }

    return metrics, process

def send_data():
    base_url_metrics = f"http://{os.environ["WEB_DATA_VIZ_URL"]}/hardware/api/real-time"
    base_url_process = f"http://{os.environ["WEB_DATA_VIZ_URL"]}/process/api/real-time"

    while True:
        metrics, process = collect_data()

        try:
            response_metrics = requests.post(base_url_metrics, json={"metrics": metrics, "motherboardId": motherboardId})
            response_process = requests.post(base_url_process, json={"process": process, "motherboardId": motherboardId})

        except requests.RequestException as e:
            print("Erro ao enviar dados:", e)

        time.sleep(5)