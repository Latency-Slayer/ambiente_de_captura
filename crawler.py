import time
from datetime import datetime

import requests
import platform
import subprocess
import csv
import psutil


def init():
    print("Consultando dados cadastrais do servidor...")
    motherboard_id = get_motherboard_id()

    try:
        server_data = requests.get(f"http://44.223.112.30/server/get/components?motherboardID={motherboard_id}").json()
    except Exception:
        print("Servidor não cadastrado, execute o script de cadastro primeiro.")
        exit()

    print(f"Tag_name: \033[1;36m{server_data['server']["tag_name"]}\033[0m \n")

    print("Iniciando captura de dados...")

    csv_header = []
    csv_data = []

    process_json = []

    # Criando cabeçalho do CSV
    for component in server_data["components"]:
        if platform.system() == "Windows" and component["type"] == "cpu" and component["metric"] == "celsius":
            continue

        csv_header.append(
            f"{component["type"]}_{component["tag_name"].strip().replace(" ", "-")}_{component["metric"]}")

    csv_header.append("quantity_connections")
    csv_header.append("download")
    csv_header.append("upload")
    csv_header.append("timestamp")

    date = datetime.now().strftime("%d-%m-%Y%H-%M-%S")

    create_csv(csv_header, f"data_{date}.csv")

    count = 0

    while True:
        csv_line = []

        for component in server_data["components"]:
            if component["type"] == "cpu":
                cpu_metric = component["metric"]

                if cpu_metric == "%":
                    cpu_percent = psutil.cpu_percent()
                    csv_line.append(cpu_percent)
                elif cpu_metric == "celsius":
                    if platform.system() != "Windows":
                        cpu_temperature = psutil.sensors_temperatures()
                        csv_line.append(cpu_temperature)

            if component["type"] == "ram":
                ram_metric = component["metric"]

                if ram_metric == "%":
                    ram_percent = psutil.virtual_memory().percent
                    csv_line.append(ram_percent)
                elif ram_metric == "GB":
                    ram_use = psutil.virtual_memory().total / 1024 ** 3
                    csv_line.append(ram_use)

            if component["type"] == "storage":
                storage_metric = component["metric"]
                partition = component["tag_name"]

                if storage_metric == "%":
                    disk_percent = psutil.disk_usage(partition).percent
                    csv_line.append(disk_percent)
                elif storage_metric == "GB":
                    disk_use = psutil.disk_usage(partition).total / 1024 ** 3
                    csv_line.append(disk_use)

        qtd_connections = get_qtd_connections(int(server_data["server"]["port"]))
        csv_line.append(qtd_connections)

        download = psutil.net_io_counters().bytes_recv / (1024 ** 2)
        upload = psutil.net_io_counters().bytes_sent / (1024 ** 2)

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        csv_line.append(download)
        csv_line.append(upload)
        csv_line.append(timestamp)

        csv_data.append(csv_line)


        count += 1
        print(f"{count} - Nova linha adicionada ao CSV: ", csv_line, "\n")

        if len(csv_data) == 5:
            with open(f"data_{date}.csv", mode="a", newline="", encoding="utf-8") as file:
                writer = csv.writer(file, delimiter=";", quoting=csv.QUOTE_NONNUMERIC)
                writer.writerows(csv_data)
                file.flush()

                csv_data.clear()


            upload_csv(motherboard_id, server_data["server"]["registration_number"], server_data["server"]["legal_name"], date)
            date = datetime.now().strftime("%d-%m-%Y%H-%M-%S")

            create_csv(csv_header, f"data_{date}.csv")


        process_json.append(captura_processos())

        if len(process_json) == 5:
            upload_process_json(motherboard_id, server_data["server"]["registration_number"],
                                server_data["server"]["legal_name"], process_json)
            process_json.clear()

        time.sleep(3)


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


def get_qtd_connections(port):
    quant = 0

    connections = psutil.net_connections()
    
    for conn in connections:
        if conn.laddr:
            if conn.laddr.port == port:
                if conn.status == 'ESTABLISHED':
                    quant += 1


    return quant



def create_csv(csv_header, csv_name):
    with open(csv_name, mode="w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file, delimiter=";", quoting=csv.QUOTE_NONNUMERIC)
        writer.writerow(csv_header)
        file.flush()

def upload_csv(motherboard_id, registration_number, legal_name, date):
    try:
        requests.post("http://44.223.112.30:5000/s3/raw/upload", files={"file": open(f"data_{date}.csv", "rb")},
                                 data={"motherboard_uuid": motherboard_id, "registration_number": registration_number, "legal_name": legal_name})

        print("CSV enviado com sucesso! \n")
    except requests.exceptions.ConnectionError as e:
        print(f"Error: {e}")
        exit()


def upload_process_json(motherboard_id, registration_number, legal_name, process_json):
    try:
        requests.post("http://44.223.112.30:5000/s3/raw/process/upload",
                                 json={"motherboard_uuid": motherboard_id, "registration_number": registration_number, "legal_name": legal_name,
                                       "process_json": process_json})

        print("Lista de processos enviada com sucesso! \n")
    except requests.exceptions.ConnectionError as e:
        print(f"Error: {e}")
        exit()



def captura_processos():
    processos = psutil.process_iter()

    dict_processos = {
        "process_data" : [],
        "datetime": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    for p in processos:
        try:
            dict_processos["process_data"].append(
                dict({
                    "name": p.name(),
                    "pid": p.pid or None,
                    "status": p.status() or None,
                    "cpu_percent": p.cpu_percent(),
                    "memory_percent": p.memory_percent(),
                    "memory_gb": p.memory_info().vms / 1024 ** 3,
                })
            )
        except:
            continue

    return dict_processos

init()


