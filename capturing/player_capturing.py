import time

import psutil
import requests
from faker import Faker
import random

import dotenv

dotenv.load_dotenv()
import os

fake = Faker()

ip_cache = {}

def init(server_data):
    ip = requests.get('https://api.ipify.org').text
    location = get_location(ip)

    connections = dict({
        "server_data": {
            **server_data["server"],
            **location,
        },
        "connections_data": get_connections(server_data["server"]["port"])
    })

    print(connections)


def init_faker(server_data, motherboard_id, registration_number, legal_name, connections_json):
    ip = requests.get('https://api.ipify.org').text
    location = get_location(ip)

    server_data["server"]["ip"] = ip

    while True:
        players_difference = random.randint(0, 5)
        add_players = False if random.randint(0, 2) == 0 else True
        if players_difference >= len(ip_cache):
            add_players = True

        print(add_players)

        for _ in range(players_difference):
            if not add_players:
                ip_cache.popitem()
            else:
                generate_fake_connections()



        connections = dict({
            "server_data": {
                **server_data["server"],
                **location
            },
            "connections_data": {
                "quant_players": len(ip_cache),
                "players_data": list(ip_cache.values())
            }
        })

        print(len(ip_cache))

        requests.post(f"http://{os.environ["WEB_DATA_VIZ_URL"]}/bi/dashboard/real-time/receive-data", json={"data": connections})
        requests.post(f"http://{os.environ["DATA_TRANSFER_API"]}/s3/raw/process/upload",
                      json={"motherboard_uuid": motherboard_id, "registration_number": registration_number,
                            "legal_name": legal_name,
                            "process_json": connections_json})

        time.sleep(1)


def generate_fake_connections():
    player_ip = fake.ipv4_public()

    if player_ip in ip_cache:
        return ip_cache[player_ip]

    player_location = get_location(player_ip)

    player_data = [
        player_ip,
        25565,
        {
            "country": player_location["country"],
            "city": player_location["city"],
            "region": player_location["region"],
            "continent_code": player_location["continentCode"],
            "zip": player_location["zip"],
            "lat": player_location["lat"],
            "lon": player_location["lon"]
        }
    ]

    ip_cache[player_ip] = player_data

    return player_data


def get_location(ip):
    return requests.get(f"http://ip-api.com/json/{ip}?fields=message,continent,continentCode,country,city,region,zip,lat,lon").json()


def get_connections(port):
    quant = 0

    players_data = []

    connections = psutil.net_connections()

    for conn in connections:
        if conn.laddr:
            if conn.laddr.port == port:
                if conn.status == 'ESTABLISHED':
                    quant += 1
                    player_ip = conn.laddr.ip
                    player_port = conn.laddr.port
                    player_location = requests.get(f"http://ip-api.com/json/{player_ip}").json()

                    players_data.append([player_ip, player_port, {
                        "country": player_location["country"],
                        "city": player_location["city"],
                        "region": player_location["region"],
                        "zip": player_location["zip"],
                        "lat": player_location["lat"],
                        "lon": player_location["lon"]
                    }])


    return {"quant_players": quant, "players_data": players_data}