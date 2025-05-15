from datetime import datetime

import requests
import platform
import subprocess
import psutil

from capturing.hardware_capturing import init as hardware_capturing
import threading

def init():
    print("Consultando dados cadastrais do servidor...")
    motherboard_id = get_motherboard_id()

    try:
        server_data = requests.get(f"http://localhost/server/get/components?motherboardID={motherboard_id}").json()
    except Exception:
        print("Servidor não cadastrado, execute o script de cadastro primeiro.")
        exit()

    print(f"Tag_name: \033[1;36m{server_data['server']["tag_name"]}\033[0m \n")

    hardware_capturing_thread = threading.Thread(target=hardware_capturing, args=(server_data, motherboard_id,))

    print("Iniciando captura de hardware...")
    hardware_capturing_thread.start()

    hardware_capturing_thread.join()

    print("Script de captura encerrando...")



# def init():
#     print("Consultando dados cadastrais do servidor...")
#     motherboard_id = get_motherboard_id()
#
#     try:
#         server_data = requests.get(f"http://44.223.112.30/server/get/components?motherboardID={motherboard_id}").json()
#     except Exception:
#         print("Servidor não cadastrado, execute o script de cadastro primeiro.")
#         exit()
#
#     print(f"Tag_name: \033[1;36m{server_data['server']["tag_name"]}\033[0m \n")
#
#     print("Iniciando captura de dados...")
#
#         time.sleep(3)
#

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



init()


