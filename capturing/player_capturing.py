import psutil

def get_qtd_connections(port):
    quant = 0

    connections = psutil.net_connections()

    for conn in connections:
        if conn.laddr:
            if conn.laddr.port == port:
                if conn.status == 'ESTABLISHED':
                    quant += 1

    return quant


print(get_qtd_connections(443))