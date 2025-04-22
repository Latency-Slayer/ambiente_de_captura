import time
import requests
import platform
import subprocess
import csv
import psutil


def init():
    print("Consultando dados cadastrais do servidor...")
    motherboard_id = get_motherboard_id()

    try:
        server_data = requests.get(f"http://localhost:3333/server/get/components?motherboardID={motherboard_id}").json()
    except:
        print("Servidor não cadastrado, execute o script de cadastro primeiro.")


    print(f"Tag_name: \033[1;36m{server_data['server']["tag_name"]}\033[0m \n")

    print("Iniciando captura de dados...")

    capturing = [[]]

    # Criando cabeçalho do CSV
    for component in server_data["components"]:
        if platform.system() == "Windows" and component["type"] == "cpu" and component["metric"] == "celsius":
            continue

        capturing[0].append(
            f"{component["type"]}_{component["tag_name"].strip().replace(" ", "-")}_{component["metric"]}")

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


        capturing.append(csv_line)

        with open("teste.csv", mode="w", newline="", encoding="utf-8") as file:
            writer = csv.writer(file, delimiter=";", quoting=csv.QUOTE_NONNUMERIC)
            writer.writerows(capturing)
            file.flush()
            print("Dado gravado")

        time.sleep(1)


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


init()
