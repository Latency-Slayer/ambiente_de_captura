import psutil
from datetime import datetime
import time
import requests
import subprocess
import platform

def get_motherboard_id():
    so = platform.system()

    try:
        windows_sh = ["powershell", "-Command", "Get-WmiObject Win32_BaseBoard "
                                                "| Select-Object -ExpandProperty SerialNumber"]
        linux_sh = "sudo dmidecode -s system-uuid"

        sh = windows_sh if so == "Windows" else linux_sh

        motherboard_uuid = subprocess.check_output(sh, shell=True).decode().strip()

    except subprocess.SubprocessError:
        exit("\033[1;31m❌ Erro ao coletar UUID da placa-mãe.\033[0m")

    print(f"📎 UUID da Placa-mãe: \033[1;36m{motherboard_uuid}\033[0m")
    return motherboard_uuid

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

def send_data(url_metrics, url_process, motherboardId):

    while True:
        metrics, process = collect_data()

        try:
            response_metrics = requests.post(url_metrics, json={"metrics": metrics, "motherboardId": motherboardId})
            response_process = requests.post(url_process, json={"process": process, "motherboardId": motherboardId})

            print("Dados enviados - Metrics:", metrics)
            print("Dados enviados - Process:", process)
        except requests.RequestException as e:
            print("Erro ao enviar dados:", e)

        time.sleep(5)

base_url_metrics = "http://localhost:80/hardware/api/real-time" 
base_url_process = "http://localhost:80/process/api/real-time" 

send_data(base_url_metrics, base_url_process, get_motherboard_id())