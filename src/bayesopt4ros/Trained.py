from __future__ import annotations
from contextual_bayesopt import ContextualBayesianOptimization as cbo
import torch
import numpy as np
import socket


TCP_IP = "192.168.178.138"
TCP_PORT = 5000

client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client_socket.connect((TCP_IP, TCP_PORT))

opt = cbo.from_file("forrester_ei.yaml")

#opt._load_prev_bayesopt("2024-08-07-22-29-55")
#150
#opt._load_prev_bayesopt("2024-08-08-22-03-35")
#200
opt._load_prev_bayesopt("2024-08-08-22-03-35")

#choose your poison

#c_n = torch.randn(1, 4)
#c_n = c_n.squeeze()
#opt.x_new = opt.next(None, c_n)

client_socket.sendall(np.array(torch.tensor(1.0), dtype=np.float64))


while 1:

    reward_data = client_socket.recv(64)
    #reward = torch.tensor([np.frombuffer(reward_data, dtype=np.float64).tolist()])
    #print("reward: ", reward)

    context_data = client_socket.recv(640)
    c_n = torch.tensor(np.frombuffer(context_data, dtype=np.float64).tolist())
    print("context: ", c_n)
    opt.prev_context = opt.context
    # self.context = torch.tensor(c_n_plus)
    opt.context = c_n.clone().detach().requires_grad_(True)

    opt.x_new = opt._get_next_x()

    print("x_new: ", opt.x_new)
    tensor_data = opt.x_new.numpy().flatten()
    client_socket.sendall(np.array(opt.x_new, dtype=np.float64))




