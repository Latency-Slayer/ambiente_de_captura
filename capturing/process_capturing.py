import psutil
from datetime import datetime
import requests

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

def upload_process_json(motherboard_id, registration_number, legal_name, process_json):
    try:
        requests.post("http://44.223.112.30:5000/s3/raw/process/upload",
                                 json={"motherboard_uuid": motherboard_id, "registration_number": registration_number, "legal_name": legal_name,
                                       "process_json": process_json})

        print("Lista de processos enviada com sucesso! \n")
    except requests.exceptions.ConnectionError as e:
        print(f"Error: {e}")
        exit()



def init(server_data, motherboard_id):
    process_json = []

    count = 0

    while True:
        process_json.append(captura_processos())

        if len(process_json) == 5:
            upload_process_json(motherboard_id, server_data["server"]["registration_number"],
                                server_data["server"]["legal_name"], process_json)
            process_json.clear()