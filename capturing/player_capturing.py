import time

import psutil
import requests
from faker import Faker
import random

fake = Faker()

ip_cache = {}

def init(server_data):
    connections = dict({
        "server_data": server_data["server"],
        "connections_data": get_connections(server_data["server"]["port"])
    })

    print(connections)


def init_faker(server_data):
    while True:
        players_difference = random.randint(0, 50)
        add_players = True if random.randint(0, 1) == 0 else False
        if players_difference > len(ip_cache):
            add_players = True

        print(add_players)

        for _ in range(players_difference):
            if not add_players:
                ip_cache.popitem()
            else:
                generate_fake_connections()


        connections = dict({
            "server_data": server_data["server"],
            "connections_data": {
                "quant_players": len(ip_cache),
                "players_data": list(ip_cache.values())
            }
        })

        print(connections)

        time.sleep(3)


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
            "zip": player_location["zip"],
            "lat": player_location["lat"],
            "lon": player_location["lon"]
        }
    ]

    ip_cache[player_ip] = player_data

    return player_data


def get_location(ip):
    return requests.get(f"http://ip-api.com/json/{ip}").json()


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