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
#simple 37 laps
#2024-07-07-08-59-25
#66
#2024-07-07-19-10-39
#76
#2024-07-07-21-30-30
#85
#2024-07-08-10-06-55
#------------------------------------
#1st complexity
#25
#2024-07-13-12-19-31
#50
#2024-07-12-11-46-34
#76
#2024-07-12-14-45-41
#100
#2024-07-12-16-59-32
#146
#2024-07-13-13-40-51
#150
#2024-07-13-18-50-27
#------------------------------------
#2nd complexity
#6
#2024-07-14-00-06-34
#25
#2024-07-14-00-32-34
#50
#2024-07-15-13-26-18
#71
#2024-07-08-14-11-14
#100
#2024-07-08-19-26-36
#110
#2024-07-15-17-21-27
#150
#2024-07-15-20-12-51
#

#------------------------------------
#3rd complexity
#25
#2024-07-13-21-23-31
#35
#2024-07-09-15-10-03
#43
#2024-07-09-17-00-53
#53
#2024-07-10-20-53-36
#70
#2024-07-11-16-53-13
#90
#2024-07-11-18-42-35
#100
#2024-07-11-23-00-20
#122
#2024-07-14-09-43-14
#140
#2024-07-14-19-49-01
#150
#2024-07-15-11-32-09
#------------------------------------
#2024-06-26-13-01-38
#2024-06-26-23-37-22
#2024-06-27-15-00-24
#2024-06-28-15-39-12
#2024-06-28-16-25-11
#lower_bound: [0.5,0.9,0.5],upper_bound: [2.0,1.1,2.0] 50 laps 2nd place
#lower_bound: [0.5,0.9,0.5],upper_bound: [2.5,1.1,2.5] 30 laps 1st place but broke the simulation
#lower_bound: [0.5,0.9,0.5],upper_bound: [2.5,1.1,2.5] 15 laps 1st place but broke the simulation
#2024-06-23-14-52-06 , 2024-06-24-12-06-05 50 laps 2nd place continouiation
#2024-06-30-22-27-08 100 lap corner update
opt._load_prev_bayesopt("2024-07-15-17-21-27")

#choose your poison

c_n = torch.randn(1, 9)
c_n = c_n.squeeze()
opt.x_new = opt.next(None, c_n)

client_socket.sendall(np.array([1.0], dtype=np.float64))


while 1:

    reward_data = client_socket.recv(64)
    reward = torch.tensor([np.frombuffer(reward_data, dtype=np.float64).tolist()])
    print("reward: ", reward)

    context_data = client_socket.recv(640)
    c_n = torch.tensor(np.frombuffer(context_data, dtype=np.float64).tolist())
    print("context: ", c_n)

    opt.x_new = opt.next(reward, c_n)

    print("x_new: ", opt.x_new)
    tensor_data = opt.x_new.detach().numpy().flatten()
    client_socket.sendall(np.array(tensor_data, dtype=np.float64))





