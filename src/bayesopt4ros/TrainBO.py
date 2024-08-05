from __future__ import annotations
from bayesopt import BayesianOptimization as bo
import torch
import numpy as np
import socket


TCP_IP = "192.168.178.138"
TCP_PORT = 5000

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client_socket.connect((TCP_IP, TCP_PORT))

opt = bo.from_file("forrester_ei.yaml")

opt._load_prev_bayesopt("2024-08-01-20-54-17")

#choose your poison

c_n = torch.tensor([1])
c_n = c_n.squeeze()
opt.x_new = opt.next(None, c_n)

client_socket.sendall(np.array([1.0], dtype=np.float64))


while 1:

    reward_data = client_socket.recv(64)
    reward = torch.tensor([np.frombuffer(reward_data, dtype=np.float64).tolist()])
    print("reward: ", reward)

    context_data = client_socket.recv(64)
    c_n = torch.tensor(np.frombuffer(context_data, dtype=np.float64).tolist())
    #print("context: ", c_n)
    c_n = torch.tensor([1])

    opt.x_new = opt.next(reward, c_n)

    print("x_new: ", opt.x_new)
    tensor_data = opt.x_new.detach().numpy().flatten()
    client_socket.sendall(np.array(tensor_data, dtype=np.float64))





