import psutil
import requests
from faker import Faker
import random

fake = Faker("en_US")

ip_cache = {}

def init(server_data):
    connections = dict({
        "server_data": server_data["server"],
        "connections_data": get_connections(server_data["server"]["port"])
    })

    print(connections)


def init_faker(server_data):
    qtd_connections = random.randint(0, 200)

    connections_data = [generate_fake_connections() for _ in range(qtd_connections)]

    connections = dict({
        "server_data": server_data["server"],
        "connections_data": {
            "quant_players": qtd_connections,
            "players_data": connections_data
        }
    })

    print(connections)


def generate_fake_connections():
    player_ip = fake.ipv4_public()

    player_location = get_location(player_ip)

    return [
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


def get_location(ip):
    if ip in ip_cache:
        return ip_cache[ip]

    player_location = requests.get(f"http://ip-api.com/json/{ip}").json()
    ip_cache[ip] = player_location

    return player_location


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