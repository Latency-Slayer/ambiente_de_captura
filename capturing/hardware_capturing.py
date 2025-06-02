import platform
import time
from datetime import datetime
import psutil
import csv
import requests
import os
import dotenv

dotenv.load_dotenv()

def create_csv(csv_header, csv_name):
    with open(csv_name, mode="w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file, delimiter=";", quoting=csv.QUOTE_NONNUMERIC)
        writer.writerow(csv_header)
        file.flush()

def init (server_data, motherboard_id):
    csv_header = []
    csv_data = []

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

        if len(csv_data) == 5:
            with open(f"data_{date}.csv", mode="a", newline="", encoding="utf-8") as file:
                writer = csv.writer(file, delimiter=";", quoting=csv.QUOTE_NONNUMERIC)
                writer.writerows(csv_data)
                file.flush()

                csv_data.clear()


            upload_csv(motherboard_id, server_data["server"]["registration_number"], server_data["server"]["legal_name"], date)
            date = datetime.now().strftime("%d-%m-%Y%H-%M-%S")

            create_csv(csv_header, f"data_{date}.csv")

        time.sleep(5)


def get_qtd_connections(port):
    quant = 0

    connections = psutil.net_connections()

    for conn in connections:
        if conn.laddr:
            if conn.laddr.port == port:
                if conn.status == 'ESTABLISHED':
                    quant += 1

    return quant


def upload_csv(motherboard_id, registration_number, legal_name, date):
    try:
        requests.post(f"http://{os.environ["DATA_TRANSFER_API"]}/s3/raw/upload", files={"file": open(f"data_{date}.csv", "rb")},
                                 data={"motherboard_uuid": motherboard_id, "registration_number": registration_number, "legal_name": legal_name})

        print("CSV de hardware enviado com sucesso! \n")
    except requests.exceptions.ConnectionError as e:
        print(f"Error: {e}")
        exit()


